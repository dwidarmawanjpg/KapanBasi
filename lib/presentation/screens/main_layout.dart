import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'add_food_screen.dart';
import 'history_screen.dart';
import '../widgets/notification_bell_button.dart';

// State Provider untuk melacak tab index aktif pada BottomNavigationBar
final mainNavigationIndexProvider = StateProvider<int>((ref) => 0);

/// Layout Utama aplikasi yang mengimplementasikan BottomNavigationBar (Home, Collection & Akun)
/// dan menampung FloatingActionButton di tengah.
class MainLayout extends ConsumerWidget {
  final bool isSupabaseConfigured;

  const MainLayout({super.key, required this.isSupabaseConfigured});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(mainNavigationIndexProvider);

    // List halaman berdasarkan indeks tab
    final List<Widget> screens = const [
      HomeScreen(),
      HistoryScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'KapanBasi',
          style: GoogleFonts.fredoka(
            textStyle: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          // Indikator status koneksi Supabase di AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              isSupabaseConfigured ? Icons.cloud_done : Icons.cloud_off,
              color: isSupabaseConfigured
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              size: 24,
            ),
          ),
          // Tombol notifikasi kedaluwarsa - di kanan ikon awan
          const NotificationBellButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner Peringatan jika Supabase belum terkonfigurasi
            if (!isSupabaseConfigured)
              Container(
                width: double.infinity,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mode Demo Aktif: Menampilkan data simulasi lokal. Hubungkan ke Supabase dengan mengatur berkas .env.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: screens[selectedIndex]),
          ],
        ),
      ),

      // Tombol FAB hanya muncul di tab Home (index 0)
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFoodScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              tooltip: 'Tambah Item',
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Tambah',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,

      // Bottom Navigation Bar Material 3 (Mengambil style dari AppTheme secara otomatis)
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(mainNavigationIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// AKHIR DARI LAYOUT UTAMA
// =========================================================================