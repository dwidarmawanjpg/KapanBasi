import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../providers/foods_provider.dart';

/// Halaman ganti password menggunakan endpoint PUT /api/profile/password.
/// Mengikuti pola yang sama dengan form lain di aplikasi ini.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      await service.changePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diperbarui!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.riskLow,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat password baru',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Password baru minimal 6 karakter. Setelah berhasil diganti, kamu perlu login ulang di perangkat lain.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),

              // Password baru
              TextFormField(
                controller: _newPasswordController,
                enabled: !_isLoading,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (v.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Konfirmasi password
              TextFormField(
                controller: _confirmController,
                enabled: !_isLoading,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_reset_rounded),
                  label: Text(_isLoading ? 'Menyimpan...' : 'Ganti Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
