import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/food_model.dart';
import '../providers/foods_provider.dart';
import '../widgets/food_card.dart';
import 'add_food_screen.dart';

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
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
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
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
  void _showFoodDetailBottomSheet(BuildContext context, WidgetRef ref, FoodModel food) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final expiry = DateTime(food.expiryDate.year, food.expiryDate.month, food.expiryDate.day);
        final diff = expiry.difference(today).inDays;
        final bool isExpired = diff < 0;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                food.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Category Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    food.category,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Dates & Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context, 
                      'Tanggal Masuk:', 
                      DateFormat('dd MMM yyyy').format(food.startDate)
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      context, 
                      'Tanggal Kedaluwarsa:', 
                      DateFormat('dd MMM yyyy').format(food.expiryDate),
                      valueColor: isExpired ? Colors.redAccent : Colors.green,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      context, 
                      'Status Masa Aktif:', 
                      isExpired 
                          ? 'Sudah Basi (${diff.abs()} hari lalu)' 
                          : (diff == 0 ? 'Kedaluwarsa Hari Ini' : '$diff hari lagi'),
                      valueColor: isExpired ? Colors.redAccent : Colors.green,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Actions (Edit & Selesai)
              Row(
                children: [
                  // Edit Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Tutup bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddFoodScreen(foodToEdit: food),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Selesai (Mark as consumed) Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context); // Tutup bottom sheet
                        
                        try {
                          final updatedFood = food.copyWith(isConsumed: true);
                          await ref.read(supabaseServiceProvider).updateFood(updatedFood);
                          ref.invalidate(foodsProvider);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Item berhasil diselesaikan!'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menyelesaikan item: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: const Text('Selesai'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Hapus Button
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context); // Tutup bottom sheet
                  
                  try {
                    await ref.read(supabaseServiceProvider).deleteFood(food.id);
                    ref.invalidate(foodsProvider);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Item berhasil dihapus!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.grey,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menghapus item: $e'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text('Hapus Item'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context, 
    String label, 
    String value, {
    Color? valueColor, 
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}
