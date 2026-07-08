import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/uuid_generator.dart';
import '../../data/models/food_model.dart';
import '../providers/foods_provider.dart';
import '../../data/services/notification_service.dart';

/// Halaman untuk menambahkan bahan makanan baru ke Pantry (Mock API / Supabase).
/// Dilengkapi dengan form kategori, lokasi penyimpanan, dan date picker ganda.
class AddFoodScreen extends ConsumerStatefulWidget {
  final FoodModel? foodToEdit;
  const AddFoodScreen({super.key, this.foodToEdit});

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String _selectedCategory = 'Buah';
  String _selectedStorageLocation = 'Kulkas Bawah';
  String _selectedUnit = 'pcs';
  DateTime _selectedStartDate = DateTime.now();
  DateTime? _selectedExpiryDate;
  File? _imageFile;

  bool _isLoading = false;

  final List<String> _categories = [
    'Buah',
    'Sayur',
    'Minuman',
    'Susu & Olahan',
    'Daging & Ikan',
    'Makanan Instan',
    'Bumbu Dapur',
    'Lainnya',
  ];

  final List<String> _units = [
    'pcs',
    'kg',
    'g',
    'pack',
    'liter',
    'ml',
    'botol',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.foodToEdit != null) {
      _nameController.text = widget.foodToEdit!.name;
      _selectedCategory = _categories.contains(widget.foodToEdit!.category)
          ? widget.foodToEdit!.category
          : 'Lainnya';
      _selectedStorageLocation = widget.foodToEdit!.storageLocation;
      _selectedStartDate = widget.foodToEdit!.startDate;
      _selectedExpiryDate = widget.foodToEdit!.expiryDate;
      _quantityController.text = widget.foodToEdit!.quantity.toString();
      _selectedUnit = _units.contains(widget.foodToEdit!.unit)
          ? widget.foodToEdit!.unit
          : 'pcs';
      _notesController.text = widget.foodToEdit!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Fungsi untuk memilih gambar dari kamera atau galeri
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Menampilkan pilihan kamera/galeri dalam Bottom Sheet
  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Membuka Date Picker untuk memilih tanggal masuk
  Future<void> _selectStartDate() async {
    final today = DateTime.now();
    final firstDate = today.subtract(const Duration(days: 365));
    final lastDate = today.add(const Duration(days: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Pilih Tanggal Masuk',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedStartDate = pickedDate;
      });
    }
  }

  /// Membuka Date Picker untuk memilih tanggal kedaluwarsa
  Future<void> _selectExpiryDate() async {
    final today = DateTime.now();
    final firstDate = today.subtract(const Duration(days: 30));
    final lastDate = today.add(const Duration(days: 365 * 5));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? today.add(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Pilih Tanggal Kedaluwarsa',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedExpiryDate = pickedDate;
      });
    }
  }

  /// Mengirim data bahan makanan ke Mock API Service
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih tanggal kedaluwarsa terlebih dahulu!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.riskHigh,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final bool isEditing = widget.foodToEdit != null;
      String? imageUrl;

      // 1. Unggah gambar ke Supabase Storage jika ada foto baru
      if (_imageFile != null) {
        final uniqueFileName = '${UuidGenerator.generate()}.jpg';
        imageUrl = await supabaseService.uploadImage(
          _imageFile!.path,
          uniqueFileName,
        );
      }

      // 2. Buat objek FoodModel baru/update
      final foodItem = FoodModel(
        id: isEditing ? widget.foodToEdit!.id : UuidGenerator.generate(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        storageLocation: _selectedStorageLocation,
        startDate: _selectedStartDate,
        expiryDate: _selectedExpiryDate!,
        imageUrl: imageUrl ?? (isEditing ? widget.foodToEdit!.imageUrl : null),
        isConsumed: isEditing ? widget.foodToEdit!.isConsumed : false,
        quantity: int.tryParse(_quantityController.text) ?? 1,
        unit: _selectedUnit,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // 3. Simpan ke database Supabase
      if (isEditing) {
        await supabaseService.updateFood(foodItem);
      } else {
        await supabaseService.insertFood(foodItem);
      }

      // Batalkan notif lama jika edit, lalu jadwalkan ulang sesuai tanggal baru
      await NotificationService().cancelFoodExpiryNotification(foodItem.id);
      await NotificationService().scheduleFoodExpiryNotification(foodItem);

      // Invalidate foodsProvider secara reaktif agar beranda & statistik terupdate otomatis
      ref.invalidate(foodsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Perubahan berhasil disimpan!'
                  : 'Item berhasil disimpan ke Supabase!',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.riskLow,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Kirim sinyal sukses kembali ke layar utama
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.riskHigh,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedStartDate = DateFormat(
      'dd MMM yyyy',
    ).format(_selectedStartDate);
    final formattedExpiryDate = _selectedExpiryDate == null
        ? 'Pilih Tanggal'
        : DateFormat('dd MMM yyyy').format(_selectedExpiryDate!);

    final storageLocationsAsync = ref.watch(storageLocationsProvider);
    List<String> storageLocations = [
      'Kulkas Bawah',
      'Freezer',
      'Lemari Dapur',
      'Meja Makan',
    ];
    if (storageLocationsAsync.hasValue && storageLocationsAsync.value != null) {
      storageLocations = storageLocationsAsync.value!
          .map((loc) => loc['name'] as String)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.foodToEdit != null ? 'Edit Item' : 'Tambah Item'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menyimpan data makanan...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Ambil Foto / Gambar
                    Center(
                      child: GestureDetector(
                        onTap: _showImageSourceBottomSheet,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : (widget.foodToEdit?.imageUrl != null &&
                                    widget.foodToEdit!.imageUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    widget.foodToEdit!.imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      size: 48,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ambil Foto Makanan (Opsional)',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // B. Input Nama Makanan
                    Text(
                      'Nama Makanan / Minuman',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Misal: Susu UHT Cokelat',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama makanan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // C. Kategori (Full Width)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          items: _categories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // C2. Tempat Penyimpanan
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tempat Penyimpanan',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue:
                              storageLocations.contains(
                                _selectedStorageLocation,
                              )
                              ? _selectedStorageLocation
                              : storageLocations.first,
                          items: storageLocations
                              .map(
                                (loc) => DropdownMenuItem(
                                  value: loc,
                                  child: Text(loc),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStorageLocation = value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // C3. Jumlah & Satuan
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Jumlah Stok
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jumlah Stok',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '1',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Wajib diisi';
                                  }
                                  final num = int.tryParse(value);
                                  if (num == null || num <= 0) {
                                    return 'Harus > 0';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Satuan
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Satuan',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedUnit,
                                items: _units
                                    .map(
                                      (unit) => DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedUnit = value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // C4. Catatan
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Tambahan',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Misal: Simpan di wadah kedap udara',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // D. Tanggal Masuk & Tanggal Kedaluwarsa (Dalam satu Row dengan Expanded untuk mencegah Right Overflow)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tanggal Masuk
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal Masuk',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _selectStartDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          formattedStartDate,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Tanggal Kedaluwarsa
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kedaluwarsa',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _selectExpiryDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          formattedExpiryDate,
                                          style: TextStyle(
                                            color: _selectedExpiryDate == null
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.6)
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // F. Tombol Simpan
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
