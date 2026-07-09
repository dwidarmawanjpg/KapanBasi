# KapanBasi

Aplikasi manajemen makanan untuk melacak masa kadaluarsa (expired date) barang belanjaan dan bahan makanan, mencegah sisa makanan (food waste), dan memaksimalkan penggunaan stok dapur Anda. Dibangun menggunakan Flutter dan Supabase.

## Prasyarat (Prerequisites)

Sebelum Anda mulai, pastikan Anda telah menginstal beberapa perangkat lunak berikut:

*   **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (versi stabil terbaru)
*   **[Dart SDK](https://dart.dev/get-dart)** (sudah termasuk dalam instalasi Flutter)
*   **Editor/IDE**: Disarankan menggunakan [VS Code](https://code.visualstudio.com/) atau [Android Studio](https://developer.android.com/studio) dengan ekstensi/plugin Flutter dan Dart.
*   **[Git](https://git-scm.com/downloads)** (untuk manajemen versi)
*   **Akun [Supabase](https://supabase.com/)** (untuk backend/database - jika Anda ingin setup proyek Supabase sendiri)

## Memulai Cepat (Getting Started)

Ikuti langkah-langkah di bawah ini untuk mengatur dan menjalankan proyek di lingkungan pengembangan lokal Anda.

### 1. Clone Repositori

```bash
git clone https://github.com/dwidarmawan/KapanBasi.git
cd KapanBasi
```

### 2. Instal Dependensi

Setelah masuk ke dalam folder proyek, jalankan perintah ini untuk mengunduh semua paket yang dibutuhkan:

```bash
flutter pub get
```

### 3. Konfigurasi Lingkungan (Environment Setup)

Proyek ini menggunakan Supabase sebagai backend. Anda memerlukan URL Supabase dan *anon key* untuk terhubung ke database.

1.  Buat file bernama `.env` di root direktori proyek (sejajar dengan `pubspec.yaml`).
2.  Tambahkan konfigurasi berikut ke dalam file `.env`:

```env
SUPABASE_URL=YOUR_SUPABASE_PROJECT_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

> **Penting:** Jangan pernah melakukan *commit* file `.env` ke public repository. File ini sudah dimasukkan ke dalam `.gitignore`.

*(Jika ada instruksi spesifik untuk setup database/schema Supabase lokal untuk dev, bisa ditambahkan di sini, merujuk ke file `supabase_schema.sql` jika ada)*

### 4. Jalankan Aplikasi

Setelah semuanya diatur, Anda dapat menjalankan aplikasi pada perangkat atau emulator pilihan Anda:

```bash
# Menjalankan di perangkat yang terhubung atau emulator default
flutter run
```

Atau melalui IDE Anda (misalnya menekan `F5` di VS Code).

## Struktur Proyek & Pengembangan

Proyek ini dibangun dengan struktur yang terorganisir untuk memudahkan pengembangan. Berikut gambaran singkatnya:

*   **`lib/`**: Kode utama aplikasi Flutter (Dart).
    *   (Anda dapat menyesuaikan bagian ini dengan struktur folder spesifik aplikasi Anda, contohnya: `screens/`, `widgets/`, `services/`, `models/`, dll.)
*   **`android/`**, **`ios/`**, **`web/`** dll.: File konfigurasi spesifik platform.
*   **`backend/`**: (Jika folder ini berisi file spesifik backend atau edge functions).
*   **`supabase_schema.sql`**: Berisi skema database untuk proyek Supabase.

### Panduan Berkontribusi (Contribution Guide)

Jika Anda ingin berkontribusi dalam pengembangan aplikasi ini, silakan ikuti alur berikut:

1.  Buat *branch* baru dari `main` untuk fitur atau perbaikan bug Anda (`git checkout -b feature/nama-fitur-baru`).
2.  Lakukan perubahan kode Anda. Pastikan untuk mengikuti standar penulisan kode (linter).
3.  Jalankan analyzer untuk memastikan tidak ada masalah statis: `flutter analyze`.
4.  Lakukan *commit* dengan pesan yang deskriptif dan jelas (`git commit -m "feat: Menambahkan fitur X"`).
5.  *Push branch* Anda ke repositori (`git push origin feature/nama-fitur-baru`).
6.  Buat *Pull Request* (PR) untuk direview.

## Bantuan & Dokumentasi Tambahan

Beberapa sumber daya untuk membantu Anda:

*   [Dokumentasi Resmi Flutter](https://docs.flutter.dev/)
*   [Dokumentasi Supabase](https://supabase.com/docs)
*   [Dart Packages (pub.dev)](https://pub.dev/)

---
