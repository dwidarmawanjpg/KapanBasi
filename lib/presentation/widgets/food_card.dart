import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/food_model.dart';

/// Card Widget premium untuk menampilkan detail bahan makanan / produk.
/// Mengatur status warna teks kedaluwarsa secara dinamis (Merah/Hijau).
class FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback? onTap;

  const FoodCard({super.key, required this.food, this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      food.expiryDate.year,
      food.expiryDate.month,
      food.expiryDate.day,
    );
    final differenceInDays = expiry.difference(today).inDays;

    final bool isExpired = differenceInDays < 0;
    final bool isNearExpiry = !isExpired && differenceInDays <= 3;

    final Color statusColor = food.isConsumed
        ? AppColors.riskNone
        : isExpired
        ? AppColors.riskHigh
        : isNearExpiry
        ? AppColors.riskMedium
        : AppColors.riskLow;

    // Format tanggal dibuat numerik agar ringkas dan tidak memakan ruang kartu.
    final String formattedExpiry = DateFormat(
      'dd/MM/yyyy',
    ).format(food.expiryDate);

    String statusText;
    if (food.isConsumed) {
      statusText = 'Selesai';
    } else if (isExpired) {
      statusText = 'Basi';
    } else if (differenceInDays == 0) {
      statusText = 'Hari ini';
    } else if (differenceInDays == 1) {
      statusText = 'Besok';
    } else if (isNearExpiry) {
      statusText = '$differenceInDays hari';
    } else {
      statusText = 'Aman';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Gambar/Thumbnail Makanan dengan placeholder premium
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          food.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCategoryIcon(context, food.category),
                        ),
                      )
                    : _buildCategoryIcon(context, food.category),
              ),
              const SizedBox(width: 12),

              // 2. Info Detail Makanan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            food.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(statusText, statusColor),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Kategori & Lokasi Penyimpanan (Badges)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildBadge(
                          context,
                          food.category,
                          food.category.toLowerCase() == 'minuman'
                              ? Icons.local_drink_rounded
                              : Icons.restaurant_rounded,
                        ),
                        _buildBadge(
                          context,
                          food.storageLocation,
                          Icons.kitchen_rounded,
                        ),
                        _buildBadge(
                          context,
                          '${food.quantity} ${food.unit}',
                          Icons.inventory_2_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Icon(Icons.event_rounded, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Kedaluwarsa $formattedExpiry',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Helper untuk membangun Badge kecil
  Widget _buildBadge(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey[600]),
          const SizedBox(width: 3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper untuk menggambar Icon Kategori
  Widget _buildCategoryIcon(BuildContext context, String category) {
    final isDrink = category.toLowerCase() == 'minuman';
    return Icon(
      isDrink ? Icons.local_drink_rounded : Icons.restaurant_rounded,
      color: Theme.of(context).colorScheme.primary,
      size: 32,
    );
  }
}
