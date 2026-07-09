import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../data/models/food_model.dart';

/// Ambang batas (dalam hari) sebelum kedaluwarsa yang menandakan status "Kritis".
/// Sesuai ketentuan: 1 minggu (7 hari) sebelum tanggal kedaluwarsa.
const int kCriticalThresholdDays = 7;

/// Status kesegaran bahan makanan yang disinkronkan di seluruh aplikasi.
/// Catatan: konsep "Selesai" sudah dihapus total (lihat rekap fix Home/History).
/// Status kini murni berdasar selisih hari terhadap tanggal kedaluwarsa.
enum FoodStatus { aman, kritis, basi }

/// Kelas hasil perhitungan status: label, warna, dan sisa hari.
class FoodStatusInfo {
  final FoodStatus status;
  final String label;
  final Color color;
  final int differenceInDays; // Bisa negatif jika sudah basi

  const FoodStatusInfo({
    required this.status,
    required this.label,
    required this.color,
    required this.differenceInDays,
  });
}

/// Menghitung status kesegaran [food] secara konsisten.
/// - "Aman"   : lebih dari 7 hari menuju kedaluwarsa.
/// - "Kritis" : 0-7 hari menuju kedaluwarsa (termasuk hari ini/besok).
/// - "Basi"   : sudah melewati tanggal kedaluwarsa.
FoodStatusInfo getFoodStatus(FoodModel food) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiry = DateTime(
    food.expiryDate.year,
    food.expiryDate.month,
    food.expiryDate.day,
  );
  final differenceInDays = expiry.difference(today).inDays;

  if (differenceInDays < 0) {
    return FoodStatusInfo(
      status: FoodStatus.basi,
      label: 'Basi',
      color: AppColors.riskHigh,
      differenceInDays: differenceInDays,
    );
  }

  if (differenceInDays <= kCriticalThresholdDays) {
    return FoodStatusInfo(
      status: FoodStatus.kritis,
      label: 'Kritis',
      color: AppColors.riskMedium,
      differenceInDays: differenceInDays,
    );
  }

  return FoodStatusInfo(
    status: FoodStatus.aman,
    label: 'Aman',
    color: AppColors.riskLow,
    differenceInDays: differenceInDays,
  );
}