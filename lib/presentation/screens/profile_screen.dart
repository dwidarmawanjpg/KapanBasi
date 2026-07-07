import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/foods_provider.dart';

/// Halaman Profil dan Pengaturan.
/// Menampilkan statistik pantry secara real-time dari foodsProvider (Riverpod)
/// serta opsi pengaturan preferensi aplikasi.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau foodsProvider untuk menampilkan statistik pantry dinamis secara terstruktur
    final foodsAsync = ref.watch(foodsProvider);
    // Memantau userProfileProvider secara dinamis
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            // 1. Bagian Info User / Avatar
            profileAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('Gagal memuat profil', style: TextStyle(color: Colors.red)),
                ),
              ),
              data: (profile) {
                final fullName = profile?['full_name'] ?? 'Pengguna KapanBasi';
                final email = profile?['email'] ?? '';
                final avatarUrl = profile?['avatar_url'] as String?;
                final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P';

                return Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(
                                initial,
                                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // 2. Bagian Statistik Pantry (Dinamis dari foodsProvider)
            foodsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Gagal memuat statistik pantry',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              data: (foods) {
                final total = foods.length;
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                
                final expired = foods.where((f) {
                  final expiry = DateTime(f.expiryDate.year, f.expiryDate.month, f.expiryDate.day);
                  return expiry.difference(today).inDays < 0;
                }).length;

                final urgent = foods.where((f) {
                  final expiry = DateTime(f.expiryDate.year, f.expiryDate.month, f.expiryDate.day);
                  final diff = expiry.difference(today).inDays;
                  return diff >= 0 && diff <= 3;
                }).length;

                final safe = total - expired - urgent;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(context, total.toString(), 'Total Item', AppColors.primary),
                      _buildStatItem(context, expired.toString(), 'Basi', AppColors.riskHigh),
                      _buildStatItem(context, urgent.toString(), 'Kritis', AppColors.secondary),
                      _buildStatItem(context, safe.toString(), 'Aman', AppColors.riskLow),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // 3. Bagian Daftar Opsi Pengaturan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildSettingTile(
                    context: context,
                    icon: Icons.notifications_active_rounded,
                    title: 'Jadwal Pengingat',
                    subtitle: 'Pukul 08:00 Pagi',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Konfigurasi pengingat diaktifkan')),
                      );
                    },
                  ),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.brightness_6_rounded,
                    title: 'Tema Aplikasi',
                    subtitle: 'Mengikuti Sistem OS',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ubah tema akan tersedia di rilis berikutnya')),
                      );
                    },
                  ),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: 'Bantuan & Dukungan',
                    subtitle: 'Pusat bantuan KapanBasi?',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Membuka pusat bantuan...')),
                      );
                    },
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text(
                      'Keluar Akun',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      // Proses logout secara dinamis
                      await ref.read(authServiceProvider).logout();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Anda telah keluar dari akun.'),
                          backgroundColor: AppColors.riskLow,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget untuk item statistik
  Widget _buildStatItem(BuildContext context, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Helper widget untuk ListTile pengaturan
  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
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
}
