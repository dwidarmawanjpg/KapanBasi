import 'package:flutter/material.dart';

/// Class yang menyimpan token warna aplikasi "KapanBasi".
/// Mengadopsi prinsip Design System agar tidak ada hardcoding warna di UI.
class AppColors {
  AppColors._();

  // =========================================================================
  // Brand Colors (Tema Utama: Emerald Green & Amber)
  // =========================================================================
  static const Color primary = Color(
    0xFF10B981,
  ); // Emerald Green (Kesegaran makanan)
  static const Color primaryLight = Color(0xFF34D399); // Light Emerald
  static const Color primaryDark = Color(0xFF047857); // Dark Emerald

  static const Color secondary = Color(
    0xFFF59E0B,
  ); // Amber/Orange (Status kedaluwarsa)
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondaryDark = Color(0xFFB45309);

  // =========================================================================
  // Status & Expiry Risk Colors (Berdasarkan tingkat kedekatan basi)
  // =========================================================================
  static const Color riskHigh = Color(
    0xFFEF4444,
  ); // Merah: Sudah kedaluwarsa / Kritis (< 1 hari)
  static const Color riskMedium = Color(
    0xFFF59E0B,
  ); // Amber: Segera kedaluwarsa (1-3 hari)
  static const Color riskLow = Color(
    0xFF10B981,
  ); // Hijau: Masih aman (> 3 hari)
  static const Color riskNone = Color(
    0xFF9CA3AF,
  ); // Abu-abu: Tidak memiliki kedaluwarsa / Unknown

  // =========================================================================
  // Neutral Colors (Light Mode)
  // =========================================================================
  static const Color bgLight = Color(
    0xFFF9FAFB,
  ); // Latar belakang abu-abu sangat terang
  static const Color surfaceLight = Colors.white; // Card, Dialog, NavigationBar
  static const Color textPrimaryLight = Color(
    0xFF111827,
  ); // Teks utama (Hitam/Gray 900)
  static const Color textSecondaryLight = Color(
    0xFF4B5563,
  ); // Teks sekunder (Gray 600)
  static const Color borderLight = Color(0xFFE5E7EB); // Garis batas (Gray 200)

  // =========================================================================
  // Neutral Colors (Dark Mode)
  // =========================================================================
  static const Color bgDark = Color(
    0xFF0F172A,
  ); // Slate 900 (Latar belakang gelap modern)
  static const Color surfaceDark = Color(
    0xFF1E293B,
  ); // Slate 800 (Card dan Bar di tema gelap)
  static const Color textPrimaryDark = Color(
    0xFFF8FAFC,
  ); // Teks utama terang (Slate 50)
  static const Color textSecondaryDark = Color(
    0xFF94A3B8,
  ); // Teks sekunder redup (Slate 400)
  static const Color borderDark = Color(
    0xFF334155,
  ); // Garis batas gelap (Slate 700)
}
