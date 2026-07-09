import 'history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_model.dart';
import '../providers/foods_provider.dart';
import '../widgets/food_card.dart';
import '../widgets/food_detail_bottom_sheet.dart';
import 'main_layout.dart' show mainNavigationIndexProvider;



/// Screen utama untuk menampilkan daftar bahan makanan yang dipantau.
/// Menggunakan Riverpod foodsProvider untuk fetching data secara terstruktur (Clean Architecture).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau status reaktif dan memicu fetching data via Riverpod
    final foodsAsync = ref.watch(foodsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Memicu pengambilan ulang data (refetch)
          ref.invalidate(foodsProvider);
          await ref.read(foodsProvider.future);
        },
        child: foodsAsync.when(
          // 1. Loading State
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Mengambil data makanan...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 2. Error State
          error: (error, stackTrace) => Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ups, Gagal Memuat Data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(foodsProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),

          // 3. Success State (Menampilkan daftar makanan atau Empty State)
          data: (foods) {
            if (foods.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.kitchen_rounded,
                                size: 72,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Pantry Anda Kosong',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Silakan tambahkan bahan makanan baru dengan menekan tombol (+) di bawah.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: foods.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _DashboardStatsHeader(foods: foods, ref: ref);
                }
                final food = foods[index - 1];
                return FoodCard(
                  food: food,
                  onTap: () {
                    _showFoodDetailBottomSheet(context, ref, food);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Menampilkan bottom sheet interaktif berisi detail, edit, tandai selesai, dan hapus item
  void _showFoodDetailBottomSheet(
    BuildContext context,
    WidgetRef ref,
    FoodModel food,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return FoodDetailBottomSheet(food: food);
      },
    );
  }
}

/// Helper: apakah item sudah lewat tanggal kedaluwarsa (basi).
bool _isExpired(FoodModel food) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiry = DateTime(
    food.expiryDate.year,
    food.expiryDate.month,
    food.expiryDate.day,
  );
  return expiry.difference(today).inDays < 0;
}

/// Helper: sisa hari menuju kedaluwarsa (bisa negatif jika sudah basi).
int _daysUntilExpiry(FoodModel food) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiry = DateTime(
    food.expiryDate.year,
    food.expiryDate.month,
    food.expiryDate.day,
  );
  return expiry.difference(today).inDays;
}

/// Header dashboard yang tampil di atas daftar Home: 3 kartu statistik
/// (Aman / Kritis / Basi) + progress bar distribusi.
/// Setiap kartu bisa di-tap untuk langsung membuka History dengan filter terkait.
class _DashboardStatsHeader extends StatelessWidget {
  final List<FoodModel> foods;
  final WidgetRef ref;

  const _DashboardStatsHeader({required this.foods, required this.ref});

  static const int _nearExpiryThresholdDays = 7;

  @override
  Widget build(BuildContext context) {
    // `foods` di sini adalah item yang belum ditandai "Selesai" (kritis + basi).
    final basiCount = foods.where(_isExpired).length;
    final nearExpiryCount = foods.where((f) {
      final days = _daysUntilExpiry(f);
      return days >= 0 && days <= _nearExpiryThresholdDays;
    }).length;
    // "Aman" = seluruh item yang TIDAK basi dan TIDAK termasuk hampir
    // kadaluarsa (nearExpiry/Kritis). Sebelumnya hanya mengurangi basiCount
    // saja dari total, sehingga item Kritis ikut terhitung dobel di sini
    // (muncul juga di kartu "Kritis" DAN "Aman" sekaligus). Di-clamp ke 0
    // untuk jaga-jaga terhadap data yang tidak konsisten.
    final rawAmanCount = foods.length - basiCount - nearExpiryCount;
    final aktifCount = rawAmanCount < 0 ? 0 : rawAmanCount;

    final theme = Theme.of(context);
    final warningColor = Colors.orange.shade700;
    final dangerColor = theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Aman',
                  value: aktifCount,
                  icon: Icons.check_circle_outline_rounded,
                  color: theme.colorScheme.primary,
                  onTap: () => _goToHistory(HistoryFilter.aman),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Kritis',
                  value: nearExpiryCount,
                  icon: Icons.access_time_rounded,
                  color: warningColor,
                  onTap: () => _goToHistory(HistoryFilter.kritis),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Basi',
                  value: basiCount,
                  icon: Icons.delete_outline_rounded,
                  color: dangerColor,
                  onTap: () => _goToHistory(HistoryFilter.basi),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatusDistributionBar(
            aktifCount: aktifCount,
            nearExpiryCount: nearExpiryCount,
            basiCount: basiCount,
            warningColor: warningColor,
            dangerColor: dangerColor,
            primaryColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Divider(color: theme.colorScheme.outlineVariant),
        ],
      ),
    );
  }

  /// Pindah ke tab History dengan filter status yang sesuai dengan kartu yang di-tap.
  void _goToHistory(HistoryFilter filter) {
    ref.read(pendingHistoryFilterProvider.notifier).state = filter;
    ref.read(mainNavigationIndexProvider.notifier).state = 1;
  }
}

/// Satu kartu statistik kecil (angka + label + ikon), bisa di-tap.
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bar horizontal kecil yang memvisualisasikan proporsi aman / hampir kadaluarsa / basi
/// tanpa perlu menambah package chart eksternal — cukup Container + Row.
class _StatusDistributionBar extends StatelessWidget {
  final int aktifCount;
  final int nearExpiryCount;
  final int basiCount;
  final Color warningColor;
  final Color dangerColor;
  final Color primaryColor;

  const _StatusDistributionBar({
    required this.aktifCount,
    required this.nearExpiryCount,
    required this.basiCount,
    required this.warningColor,
    required this.dangerColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = aktifCount + nearExpiryCount + basiCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: total == 0
                ? Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)
                : Row(
                    children: [
                      if (aktifCount > 0)
                        Expanded(
                          flex: aktifCount,
                          child: Container(color: primaryColor),
                        ),
                      if (nearExpiryCount > 0)
                        Expanded(
                          flex: nearExpiryCount,
                          child: Container(color: warningColor),
                        ),
                      if (basiCount > 0)
                        Expanded(
                          flex: basiCount,
                          child: Container(color: dangerColor),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Titik warna kecil + label untuk legenda progress bar.
class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendDot({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}