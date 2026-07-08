import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/food_model.dart';
import '../../data/services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../providers/foods_provider.dart';
import '../providers/settings_provider.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

/// Halaman Profil & Pengaturan (Modul 4).
///
/// Fitur yang tersedia:
/// - Tampil info akun (avatar, nama, email) + shortcut Edit Profil
/// - Statistik pantry real-time dari foodsProvider
/// - Toggle tema aplikasi (Terang / Gelap / Ikuti Sistem) dengan persistensi
/// - Pengingat harian (on/off + atur jam) dengan notifikasi lokal nyata
/// - Navigasi ke halaman Ganti Password
/// - Tombol Logout
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final foodsAsync = ref.watch(foodsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final reminderEnabled = ref.watch(reminderEnabledProvider);
    final reminderTime = ref.watch(reminderTimeProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Kartu Info User ──────────────────────────────────────
            profileAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Gagal memuat profil',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              data: (profile) {
                final fullName =
                    profile?['full_name'] as String? ?? 'Pengguna KapanBasi';
                final email = profile?['email'] as String? ?? '';
                final avatarUrl = profile?['avatar_url'] as String?;
                final initial = fullName.isNotEmpty
                    ? fullName[0].toUpperCase()
                    : 'P';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primary,
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 38,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            fullName,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (profile == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfileScreen(
                                    currentProfile: profile,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Profil'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // ── 2. Statistik Pantry ─────────────────────────────────────
            foodsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const SizedBox.shrink(),
              data: (foods) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final total = foods.length;
                final expired = foods.where((f) {
                  final expiry = DateTime(
                    f.expiryDate.year,
                    f.expiryDate.month,
                    f.expiryDate.day,
                  );
                  return expiry.difference(today).inDays < 0;
                }).length;
                final urgent = foods.where((f) {
                  final expiry = DateTime(
                    f.expiryDate.year,
                    f.expiryDate.month,
                    f.expiryDate.day,
                  );
                  final diff = expiry.difference(today).inDays;
                  return diff >= 0 && diff <= 3;
                }).length;
                final safe = total - expired - urgent;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        context,
                        total.toString(),
                        'Total',
                        AppColors.primary,
                      ),
                      _buildStatItem(
                        context,
                        expired.toString(),
                        'Basi',
                        AppColors.riskHigh,
                      ),
                      _buildStatItem(
                        context,
                        urgent.toString(),
                        'Kritis',
                        AppColors.secondary,
                      ),
                      _buildStatItem(
                        context,
                        safe.toString(),
                        'Aman',
                        AppColors.riskLow,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // ── 3. Section: Preferensi ──────────────────────────────────
            _buildSectionHeader(context, 'Preferensi'),
            const SizedBox(height: 8),

            // Tema Aplikasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    _themeModeIcon(themeMode),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Tema Aplikasi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _themeModeName(themeMode),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => _showThemeDialog(context, ref, themeMode),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Pengingat Harian
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        Icons.notifications_active_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text(
                        'Pengingat Harian',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        reminderEnabled
                            ? 'Aktif — pukul ${reminderTime.format(context)}'
                            : 'Nonaktif',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: reminderEnabled,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onChanged: (val) => _toggleReminder(
                        context,
                        ref,
                        val,
                        reminderTime,
                        foodsAsync.value ?? [],
                      ),
                    ),
                    if (reminderEnabled) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          'Atur Jam Pengingat',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        trailing: Text(
                          reminderTime.format(context),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        onTap: () => _pickReminderTime(
                          context,
                          ref,
                          reminderTime,
                          foodsAsync.value ?? [],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── 4. Section: Akun ────────────────────────────────────────
            _buildSectionHeader(context, 'Akun'),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSettingTile(
                    context: context,
                    icon: Icons.lock_outline_rounded,
                    title: 'Ganti Password',
                    subtitle: 'Perbarui kata sandi akun kamu',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: 'Bantuan & Dukungan',
                    subtitle: 'Pertanyaan seputar KapanBasi?',
                    onTap: () => _showHelpDialog(context),
                  ),
                  const Divider(height: 32),
                  // Logout
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Keluar Akun',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () => _confirmLogout(context, ref),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Helpers: Widget ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  // ─── Helpers: Logic ─────────────────────────────────────────────────────────

  String _themeModeName(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Tema Terang',
    ThemeMode.dark => 'Tema Gelap',
    ThemeMode.system => 'Ikuti Sistem',
  };

  IconData _themeModeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
    ThemeMode.system => Icons.brightness_auto_rounded,
  };

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Tema Aplikasi'),
        content: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (val) {
            if (val != null) Navigator.pop(ctx, val);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                value: mode,
                title: Text(_themeModeName(mode)),
                secondary: Icon(_themeModeIcon(mode)),
              );
            }).toList(),
          ),
        ),
      ),
    ).then((selected) {
      if (selected != null) {
        ref.read(settingsServiceProvider).setThemeMode(selected);
      }
    });
  }

  Future<void> _toggleReminder(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
    TimeOfDay time,
    List<FoodModel> foods,
  ) async {
    await ref
        .read(settingsServiceProvider)
        .setDailyReminder(enabled: enabled, time: time, foods: foods);
    if (context.mounted && enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengingat diaktifkan — setiap hari pukul ${time.format(context)}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.riskLow,
        ),
      );
    }
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay current,
    List<FoodModel> foods,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: 'Pilih jam pengingat harian',
    );
    if (picked != null && picked != current) {
      await ref
          .read(settingsServiceProvider)
          .setDailyReminder(enabled: true, time: picked, foods: foods);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pengingat diperbarui ke pukul ${picked.format(context)}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.riskLow,
          ),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bantuan & Dukungan'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpItem(
                question: 'Bagaimana cara menambah bahan makanan?',
                answer:
                    'Tekan tombol + di halaman Home, lalu isi nama, kategori, tanggal kedaluwarsa, dan informasi lainnya.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                question: 'Apa itu status "Basi"?',
                answer:
                    'Item ditandai "Basi" jika tanggal hari ini sudah melewati tanggal kedaluwarsa yang dicatat.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                question: 'Apa bedanya Home dan Collection?',
                answer:
                    'Home hanya menampilkan item aktif yang belum selesai dikonsumsi. Collection adalah riwayat lengkap semua item, termasuk yang sudah selesai.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                question: 'Apakah data saya aman?',
                answer:
                    'Ya. Setiap pengguna hanya bisa melihat dan mengubah data miliknya sendiri (dilindungi Row Level Security Supabase).',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Akun?'),
        content: const Text(
          'Kamu akan keluar dari KapanBasi. Data pantry-mu tetap tersimpan di server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Batalkan semua notifikasi aktif sebelum logout agar
              // tidak ada pengingat yang menggantung untuk akun ini.
              await NotificationService().cancelDailyReminder();
              await ref.read(authServiceProvider).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

/// Widget helper untuk item FAQ di dialog bantuan.
class _HelpItem extends StatelessWidget {
  final String question;
  final String answer;
  const _HelpItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(answer, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
