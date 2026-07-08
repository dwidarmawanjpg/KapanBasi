import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/food_model.dart';
import '../providers/foods_provider.dart';
import 'food_detail_bottom_sheet.dart';

/// Tombol lonceng notifikasi di AppBar.
///
/// Menampilkan badge berisi jumlah bahan makanan yang sudah basi atau akan
/// basi dalam <=3 hari (selaras dengan jendela pengingat H-3 pada
/// [NotificationService]). Saat ditekan, menampilkan daftar ringkas
/// bahan-bahan tersebut agar pengguna bisa langsung cek tanpa scroll
/// seluruh pantry di Home.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodsAsync = ref.watch(foodsProvider);

    final List<FoodModel> urgentFoods = foodsAsync.maybeWhen(
      data: _filterUrgentFoods,
      orElse: () => const [],
    );
    final int badgeCount = urgentFoods.length;

    return IconButton(
      tooltip: 'Notifikasi Kedaluwarsa',
      onPressed: () => _showUrgentFoodsSheet(context, urgentFoods),
      icon: badgeCount > 0
          ? Badge(
              label: Text(badgeCount > 9 ? '9+' : '$badgeCount'),
              backgroundColor: AppColors.riskHigh,
              child: const Icon(Icons.notifications_rounded),
            )
          : const Icon(Icons.notifications_outlined),
    );
  }

  /// Menyaring bahan makanan aktif yang sudah basi (diff < 0) atau akan
  /// basi dalam 0-3 hari ke depan, diurutkan dari yang paling mendesak.
  static List<FoodModel> _filterUrgentFoods(List<FoodModel> foods) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final urgent = foods.where((food) {
      if (food.isConsumed) return false;
      final expiry = DateTime(
        food.expiryDate.year,
        food.expiryDate.month,
        food.expiryDate.day,
      );
      final diff = expiry.difference(today).inDays;
      return diff <= 3;
    }).toList();

    urgent.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return urgent;
  }

  void _showUrgentFoodsSheet(BuildContext context, List<FoodModel> foods) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UrgentFoodsSheet(foods: foods),
    );
  }
}

class _UrgentFoodsSheet extends StatelessWidget {
  final List<FoodModel> foods;

  const _UrgentFoodsSheet({required this.foods});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Segera Kedaluwarsa',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: foods.isEmpty
                    ? _EmptyUrgentState()
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: foods.length,
                        itemBuilder: (context, index) {
                          return _UrgentFoodTile(food: foods[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyUrgentState extends StatelessWidget {
  const _EmptyUrgentState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aman! Tidak ada bahan makanan yang mendekati kedaluwarsa.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgentFoodTile extends StatelessWidget {
  final FoodModel food;

  const _UrgentFoodTile({required this.food});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      food.expiryDate.year,
      food.expiryDate.month,
      food.expiryDate.day,
    );
    final diff = expiry.difference(today).inDays;
    final bool isExpired = diff < 0;

    final Color statusColor = isExpired
        ? AppColors.riskHigh
        : AppColors.riskMedium;
    final String subtitle = isExpired
        ? 'Sudah basi ${diff.abs()} hari lalu'
        : diff == 0
        ? 'Kedaluwarsa hari ini'
        : diff == 1
        ? 'Kedaluwarsa besok'
        : 'Kedaluwarsa $diff hari lagi';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Icon(
          isExpired
              ? Icons.delete_outline_rounded
              : Icons.access_time_rounded,
          color: statusColor,
        ),
      ),
      title: Text(
        food.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => FoodDetailBottomSheet(food: food),
        );
      },
    );
  }
}
