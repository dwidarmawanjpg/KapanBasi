import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/food_model.dart';
import '../../data/services/supabase_service.dart';

/// Provider global untuk instance [SupabaseService].
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// FutureProvider reaktif untuk memuat daftar bahan makanan dari database Supabase.
final foodsProvider = FutureProvider<List<FoodModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getFoods();
});

/// FutureProvider reaktif untuk memuat daftar lokasi penyimpanan dari database Supabase.
final storageLocationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getStorageLocations();
});
