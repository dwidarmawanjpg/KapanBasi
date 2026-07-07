import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/food_model.dart';

/// Card Widget premium untuk menampilkan detail bahan makanan / produk.
/// Mengatur status warna teks kedaluwarsa secara dinamis (Merah/Hijau).
class FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback? onTap;

  const FoodCard({
    super.key,
    required this.food,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(food.expiryDate.year, food.expiryDate.month, food.expiryDate.day);
    final differenceInDays = expiry.difference(today).inDays;

    // Logika warna: Merah jika sudah terlewati (kedaluwarsa), Hijau jika masih aman
    final bool isExpired = differenceInDays < 0;
    final Color statusColor = isExpired ? AppColors.riskHigh : AppColors.riskLow;

    // Format tanggal
    final String formattedStart = DateFormat('dd MMM yyyy').format(food.startDate);
    final String formattedExpiry = DateFormat('dd MMM yyyy').format(food.expiryDate);

    // Keterangan status masa aktif
    String statusText;
    if (isExpired) {
      statusText = 'Kedaluwarsa ${differenceInDays.abs()} hari lalu';
    } else if (differenceInDays == 0) {
      statusText = 'Kedaluwarsa hari ini';
    } else if (differenceInDays == 1) {
      statusText = 'Kedaluwarsa besok';
    } else {
      statusText = '$differenceInDays hari lagi';
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
              const SizedBox(width: 14),

              // 2. Info Detail Makanan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Makanan
                    Text(
                      food.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Kategori & Lokasi Penyimpanan (Badges)
                    Row(
                      children: [
                        _buildBadge(
                          context,
                          food.category,
                          food.category.toLowerCase() == 'minuman' 
                              ? Icons.local_drink_rounded 
                              : Icons.restaurant_rounded,
                        ),
                        const SizedBox(width: 6),
                        _buildBadge(
                          context,
                          food.storageLocation,
                          Icons.kitchen_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tanggal Masuk dan Kedaluwarsa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tgl Masuk',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              formattedStart,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Tgl Kedaluwarsa',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              formattedExpiry,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: statusColor, // Indikator warna merah/hijau tanggal kedaluwarsa
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),
              
              // 3. Status Badge Kanan Atas (Merah/Hijau)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
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
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
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
