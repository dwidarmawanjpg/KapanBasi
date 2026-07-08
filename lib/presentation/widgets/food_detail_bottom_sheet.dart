import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/food_model.dart';
import '../providers/foods_provider.dart';
import '../screens/add_food_screen.dart';
import '../../data/services/notification_service.dart';

class FoodDetailBottomSheet extends ConsumerWidget {
  final FoodModel food;
  final bool isHistoryMode;

  const FoodDetailBottomSheet({
    super.key,
    required this.food,
    this.isHistoryMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      food.expiryDate.year,
      food.expiryDate.month,
      food.expiryDate.day,
    );
    final diff = expiry.difference(today).inDays;
    final bool isExpired = diff < 0;

    Color statusColor;
    String statusText;
    if (food.isConsumed) {
      statusColor = Colors.grey;
      statusText = 'Selesai Dikonsumsi';
    } else if (isExpired) {
      statusColor = Theme.of(context).colorScheme.error;
      statusText = 'Sudah Basi';
    } else {
      statusColor = Theme.of(context).colorScheme.primary;
      statusText = 'Masih Aktif';
    }

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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

          // Category Badge & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Dates & Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                _buildDetailRow(context, 'Tempat Penyimpanan:', food.storageLocation),
                const Divider(height: 20),
                _buildDetailRow(context, 'Jumlah / Kuantitas:', '${food.quantity} ${food.unit}'),
                const Divider(height: 20),
                _buildDetailRow(context, 'Tanggal Masuk:', DateFormat('dd MMM yyyy').format(food.startDate)),
                const Divider(height: 20),
                _buildDetailRow(
                  context,
                  'Tanggal Kedaluwarsa:',
                  DateFormat('dd MMM yyyy').format(food.expiryDate),
                  valueColor: isExpired ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  context,
                  'Status Masa Aktif:',
                  isExpired
                      ? 'Sudah Basi (${diff.abs()} hari lalu)'
                      : (diff == 0 ? 'Kedaluwarsa Hari Ini' : '$diff hari lagi'),
                  valueColor: isExpired ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                  isBold: true,
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  context,
                  'Catatan:',
                  food.notes != null && food.notes!.isNotEmpty ? food.notes! : 'Tidak ada catatan',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Actions
          if (!isHistoryMode) ...[
            // Home Screen actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddFoodScreen(foodToEdit: food)),
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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsDone(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
            TextButton.icon(
              onPressed: () => _deleteFood(context, ref, 'Item'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Hapus Item'),
            ),
          ] else ...[
            // History Screen actions
            if (food.isConsumed) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _restoreToActive(context, ref),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 20),
                      label: const Text('Kembalikan ke Aktif'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextButton.icon(
              onPressed: () => _deleteFood(context, ref, 'Item dari riwayat'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Hapus dari Riwayat'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _markAsDone(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    try {
      final updatedFood = food.copyWith(isConsumed: true);
      await ref.read(supabaseServiceProvider).updateFood(updatedFood);
      await NotificationService().cancelFoodExpiryNotification(food.id);
      ref.invalidate(foodsProvider);
      ref.invalidate(collectionFoodsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item berhasil diselesaikan!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan item: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _restoreToActive(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    try {
      final updatedFood = food.copyWith(isConsumed: false);
      await ref.read(supabaseServiceProvider).updateFood(updatedFood);
      await NotificationService().scheduleFoodExpiryNotification(updatedFood);
      ref.invalidate(collectionFoodsProvider);
      ref.invalidate(foodsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: const Text('Item dikembalikan ke daftar aktif!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengembalikan item: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteFood(BuildContext context, WidgetRef ref, String successMsg) async {
    Navigator.pop(context);
    try {
      await ref.read(supabaseServiceProvider).deleteFood(food.id);
      await NotificationService().cancelFoodExpiryNotification(food.id);
      ref.invalidate(foodsProvider);
      ref.invalidate(collectionFoodsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successMsg berhasil dihapus!'),
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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
