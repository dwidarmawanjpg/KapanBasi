import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_model.dart';
import '../providers/foods_provider.dart';
import '../widgets/food_card.dart';
import '../widgets/food_detail_bottom_sheet.dart';

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
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
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
