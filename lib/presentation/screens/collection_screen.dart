import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/food_model.dart';
import '../providers/foods_provider.dart';
import '../widgets/food_card.dart';
import '../../data/services/notification_service.dart';

/// Filter tab yang tersedia di halaman Collection.
enum CollectionFilter { semua, aktif, basi, selesai }

/// Menentukan kolom tanggal mana yang dipakai saat memfilter rentang tanggal.
enum DateFilterMode { tanggalMasuk, tanggalKedaluwarsa }

/// Halaman Collection: menampilkan riwayat SELURUH barang yang pernah dicatat,
/// baik yang masih aktif, sudah basi, maupun yang sudah ditandai "Selesai".
/// Bersifat semi-immutable: hanya menyediakan aksi Hapus & Kembalikan ke Aktif (tanpa Edit).
///
/// Filter tersedia dalam 2 tingkat:
/// 1. Pencarian & status (selalu terlihat) -> search bar + chip status.
/// 2. Filter lanjutan (jarang dipakai) -> kategori & rentang tanggal, dibuka lewat bottom sheet.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  CollectionFilter _selectedFilter = CollectionFilter.semua;
  String? _selectedCategory; // null = Semua Kategori
  DateFilterMode _dateFilterMode = DateFilterMode.tanggalMasuk;
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  bool get _hasAdvancedFilter =>
      _selectedCategory != null || _selectedDateRange != null;

  int get _advancedFilterCount =>
      (_selectedCategory != null ? 1 : 0) +
      (_selectedDateRange != null ? 1 : 0);

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

  bool _matchesDateRange(FoodModel food) {
    if (_selectedDateRange == null) return true;

    final target = _dateFilterMode == DateFilterMode.tanggalMasuk
        ? food.startDate
        : food.expiryDate;
    final targetDay = DateTime(target.year, target.month, target.day);
    final from = DateTime(
      _selectedDateRange!.start.year,
      _selectedDateRange!.start.month,
      _selectedDateRange!.start.day,
    );
    final to = DateTime(
      _selectedDateRange!.end.year,
      _selectedDateRange!.end.month,
      _selectedDateRange!.end.day,
    );

    return !targetDay.isBefore(from) && !targetDay.isAfter(to);
  }

  List<FoodModel> _applyFilter(List<FoodModel> foods) {
    // Riwayat diurutkan dari yang terbaru masuk (Tanggal Masuk descending)
    final sorted = [...foods]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return sorted.where((food) {
      // 1. Filter status
      final bool statusMatch;
      switch (_selectedFilter) {
        case CollectionFilter.semua:
          statusMatch = true;
          break;
        case CollectionFilter.aktif:
          statusMatch = !food.isConsumed && !_isExpired(food);
          break;
        case CollectionFilter.basi:
          statusMatch = !food.isConsumed && _isExpired(food);
          break;
        case CollectionFilter.selesai:
          statusMatch = food.isConsumed;
          break;
      }
      if (!statusMatch) return false;

      // 2. Filter kategori
      if (_selectedCategory != null && food.category != _selectedCategory) {
        return false;
      }

      // 3. Filter rentang tanggal
      if (!_matchesDateRange(food)) return false;

      // 4. Filter keyword pencarian (nama)
      if (_searchQuery.isNotEmpty &&
          !food.name.toLowerCase().contains(_searchQuery)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionFoodsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(collectionFoodsProvider);
          await ref.read(collectionFoodsProvider.future);
        },
        child: Column(
          children: [
            collectionAsync.maybeWhen(
              data: (foods) => _buildSearchAndFilterBar(foods),
              orElse: () => _buildSearchAndFilterBar(const []),
            ),
            _buildStatusTabs(),
            if (_hasAdvancedFilter) _buildActiveFilterChips(),
            Expanded(
              child: collectionAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
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
                          'Gagal Memuat Riwayat',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              ref.invalidate(collectionFoodsProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (foods) {
                  final filtered = _applyFilter(foods);

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      foods.isEmpty
                                          ? Icons.history_rounded
                                          : Icons.search_off_rounded,
                                      size: 64,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    foods.isEmpty
                                        ? 'Belum Ada Riwayat'
                                        : 'Tidak Ditemukan',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    foods.isEmpty
                                        ? 'Riwayat barang yang pernah dicatat akan muncul di sini.'
                                        : 'Coba ubah kata kunci atau filter yang digunakan.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final food = filtered[index];
                      return FoodCard(
                        food: food,
                        onTap: () => _showCollectionActionSheet(context, food),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Search bar keyword + tombol Filter Lanjutan (kategori & tanggal)
  Widget _buildSearchAndFilterBar(List<FoodModel> foods) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama makanan...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            label: Text(_advancedFilterCount.toString()),
            isLabelVisible: _advancedFilterCount > 0,
            child: IconButton.filledTonal(
              onPressed: () => _showAdvancedFilterSheet(context, foods),
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Filter Lanjutan',
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented tab filter status: Semua / Aktif / Basi / Selesai
  Widget _buildStatusTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: CollectionFilter.values.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_filterLabel(filter)),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedFilter = filter),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Menampilkan chip ringkasan filter lanjutan yang sedang aktif, dengan opsi hapus cepat.
  Widget _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (_selectedCategory != null) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text('Kategori: $_selectedCategory'),
            onDeleted: () => setState(() => _selectedCategory = null),
          ),
        ),
      );
    }

    if (_selectedDateRange != null) {
      final formatter = DateFormat('dd MMM yyyy');
      final modeLabel = _dateFilterMode == DateFilterMode.tanggalMasuk
          ? 'Masuk'
          : 'Kedaluwarsa';
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text(
              '$modeLabel: ${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}',
            ),
            onDeleted: () => setState(() => _selectedDateRange = null),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }

  String _filterLabel(CollectionFilter filter) {
    switch (filter) {
      case CollectionFilter.semua:
        return 'Semua';
      case CollectionFilter.aktif:
        return 'Aktif';
      case CollectionFilter.basi:
        return 'Basi';
      case CollectionFilter.selesai:
        return 'Selesai';
    }
  }

  /// Bottom sheet Filter Lanjutan: Kategori (dropdown dinamis) & Rentang Tanggal.
  void _showAdvancedFilterSheet(BuildContext context, List<FoodModel> foods) {
    // Ambil daftar kategori unik yang benar-benar ada di data, agar opsi selalu relevan.
    final categories = foods.map((f) => f.category).toSet().toList()..sort();

    String? tempCategory = _selectedCategory;
    DateFilterMode tempMode = _dateFilterMode;
    DateTimeRange? tempRange = _selectedDateRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[350],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Filter Lanjutan',
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Kategori
                  Text(
                    'Kategori',
                    style: Theme.of(sheetContext).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: tempCategory,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Semua Kategori'),
                      ),
                      ...categories.map(
                        (c) =>
                            DropdownMenuItem<String?>(value: c, child: Text(c)),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => tempCategory = value),
                  ),
                  const SizedBox(height: 20),

                  // Mode tanggal
                  Text(
                    'Filter Berdasarkan',
                    style: Theme.of(sheetContext).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<DateFilterMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: DateFilterMode.tanggalMasuk,
                          label: Text(
                            'Tanggal Masuk',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        ButtonSegment(
                          value: DateFilterMode.tanggalKedaluwarsa,
                          label: Text(
                            'Tanggal Kedaluwarsa',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      selected: {tempMode},
                      onSelectionChanged: (newSelection) {
                        setSheetState(() => tempMode = newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.standard,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rentang tanggal
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: sheetContext,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 5),
                        initialDateRange: tempRange,
                      );
                      if (picked != null) {
                        setSheetState(() => tempRange = picked);
                      }
                    },
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(
                      tempRange == null
                          ? 'Pilih Rentang Tanggal'
                          : '${DateFormat('dd MMM yyyy').format(tempRange!.start)} - ${DateFormat('dd MMM yyyy').format(tempRange!.end)}',
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      IconButton.outlined(
                        onPressed: () {
                          setSheetState(() {
                            tempCategory = null;
                            tempRange = null;
                            tempMode = DateFilterMode.tanggalMasuk;
                          });
                        },
                        tooltip: 'Reset Filter',
                        icon: const Icon(Icons.refresh_rounded),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = tempCategory;
                              _dateFilterMode = tempMode;
                              _selectedDateRange = tempRange;
                            });
                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom sheet aksi khusus Collection: Kembalikan ke Aktif & Hapus (tanpa Edit).
  void _showCollectionActionSheet(BuildContext context, FoodModel food) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isExpired = _isExpired(food);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(
                food.name,
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (food.isConsumed
                                ? Colors.grey
                                : (isExpired
                                      ? AppColors.riskHigh
                                      : AppColors.riskLow))
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    food.isConsumed
                        ? 'Selesai Dikonsumsi'
                        : (isExpired ? 'Sudah Basi' : 'Masih Aktif'),
                    style: TextStyle(
                      color: food.isConsumed
                          ? Colors.grey[700]
                          : (isExpired
                                ? AppColors.riskHigh
                                : AppColors.riskLow),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(sheetContext, 'Kategori:', food.category),
                    const Divider(height: 20),
                    _buildDetailRow(
                      sheetContext,
                      'Tempat Penyimpanan:',
                      food.storageLocation,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      sheetContext,
                      'Tanggal Masuk:',
                      DateFormat('dd MMM yyyy').format(food.startDate),
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      sheetContext,
                      'Tanggal Kedaluwarsa:',
                      DateFormat('dd MMM yyyy').format(food.expiryDate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Catatan: Collection tidak menyediakan Edit penuh.
              // Jika item masih ditandai selesai, tawarkan opsi "Kembalikan ke Aktif".
              if (food.isConsumed) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _restoreToActive(context, food);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await _deleteFromCollection(context, food);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text('Hapus dari Riwayat'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _restoreToActive(BuildContext context, FoodModel food) async {
    try {
      final updatedFood = food.copyWith(isConsumed: false);
      await ref.read(supabaseServiceProvider).updateFood(updatedFood);
      // Item dikembalikan ke aktif — jadwalkan kembali notif kedaluwarsanya
      await NotificationService().scheduleFoodExpiryNotification(updatedFood);
      ref.invalidate(collectionFoodsProvider);
      ref.invalidate(foodsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item dikembalikan ke daftar aktif!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.riskLow,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengembalikan item: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteFromCollection(
    BuildContext context,
    FoodModel food,
  ) async {
    try {
      await ref.read(supabaseServiceProvider).deleteFood(food.id);
      await NotificationService().cancelFoodExpiryNotification(food.id);
      ref.invalidate(collectionFoodsProvider);
      ref.invalidate(foodsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item berhasil dihapus dari riwayat!'),
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
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
