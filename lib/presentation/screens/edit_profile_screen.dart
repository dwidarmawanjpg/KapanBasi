import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/uuid_generator.dart';
import '../providers/auth_provider.dart';
import '../providers/foods_provider.dart';

/// Halaman edit profil: mengubah nama dan foto avatar pengguna.
/// Foto diunggah ke Supabase Storage melalui endpoint upload yang sama
/// dengan gambar makanan agar tidak perlu bucket baru.
class EditProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> currentProfile;
  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  File? _newAvatarFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.currentProfile['full_name'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 512,
    );
    if (picked != null && mounted) {
      setState(() => _newAvatarFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      String? newAvatarUrl = widget.currentProfile['avatar_url'] as String?;

      // Unggah foto baru jika pengguna memilih
      if (_newAvatarFile != null) {
        final fileName = '${UuidGenerator.generate()}.jpg';
        newAvatarUrl = await service.uploadImage(
          _newAvatarFile!.path,
          fileName,
        );
      }

      await service.updateProfile(
        fullName: _nameController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      // Paksa reload profil di ProfileScreen
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.riskLow,
          ),
        );
        Navigator.pop(context, true);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatarUrl = widget.currentProfile['avatar_url'] as String?;
    final fullName = widget.currentProfile['full_name'] as String? ?? 'P';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Simpan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar picker
              GestureDetector(
                onTap: _isLoading ? null : _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary,
                      backgroundImage: _newAvatarFile != null
                          ? FileImage(_newAvatarFile!)
                          : (currentAvatarUrl != null &&
                                        currentAvatarUrl.isNotEmpty
                                    ? NetworkImage(currentAvatarUrl)
                                    : null)
                                as ImageProvider?,
                      child:
                          (_newAvatarFile == null &&
                              (currentAvatarUrl == null ||
                                  currentAvatarUrl.isEmpty))
                          ? Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 48,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ketuk foto untuk mengubah',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),

              // Nama lengkap
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  if (v.trim().length < 2) {
                    return 'Nama minimal 2 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email (read-only — tidak bisa diubah via profil)
              TextFormField(
                initialValue: widget.currentProfile['email'] as String? ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'Email tidak dapat diubah dari sini',
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
