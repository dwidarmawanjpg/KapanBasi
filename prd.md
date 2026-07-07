# Product Requirements Document (PRD)
**Proyek:** KapanBasi Mobile App  
**Platform:** Android & iOS (Flutter)  
**Versi Dokumen:** 1.2 (Pembaruan UI/UX, Lokasi Penyimpanan, Standar Pengujian & Database)  

---

## 1. Ringkasan Eksekutif (Executive Summary)
**KapanBasi** adalah aplikasi *mobile* yang dirancang untuk membantu pengguna melacak masa kedaluwarsa bahan makanan dan produk rumah tangga. Aplikasi ini bertujuan menekan angka *food waste* dengan memberikan visibilitas yang interaktif mengenai tenggat waktu konsumsi dan lokasi penyimpanan suatu produk.

## 2. Tujuan & Sasaran Proyek (Goals & Objectives)
### A. Tujuan Pengguna (User Goals)
* Memudahkan pencatatan detail barang masuk, termasuk jumlah dan lokasi penyimpanannya.
* Memberikan peringatan visual yang cepat dan jelas saat suatu barang sudah melewati batas waktu konsumsinya (basi).
* Memberikan pengalaman visual (UI/UX) yang menarik, bersih, dan modern.

### B. Tujuan Teknis & Akademis (Technical & Academic Goals)
* Menghasilkan antarmuka yang responsif dan proporsional (*Zero Overflow*).
* Memastikan struktur *source code* modular menggunakan *Clean Architecture*.
* Memenuhi standar evaluasi perancangan sistem informasi, meliputi dokumentasi alur kerja (BPMN) dan pengujian logika kode (*Basis Path Testing*).

---

## 3. Ruang Lingkup Fungsional (Functional Scope)

### Modul 1: Autentikasi Pengguna (Login & Register)
Antarmuka pendaftaran dan masuk yang modern dengan jarak (*padding*) yang nyaman.
* **Halaman Login:** Input Email, Password (dengan ikon mata untuk sembunyikan/tampilkan sandi), tombol "Masuk", dan tautan pendaftaran.
* **Halaman Register:** Input Nama Lengkap, Email, Password, Konfirmasi Password, dan tombol "Daftar".

### Modul 2: Beranda (Dashboard / Home)
Pusat informasi utama dengan desain *card* yang menarik dan dinamis.
* **Daftar Inventaris:** Menampilkan Nama, Kategori, Tempat Penyimpanan, Gambar, dan Tanggal Kedaluwarsa.
* **Logika Pengurutan:** Data diurutkan secara *ascending* (tanggal kedaluwarsa terdekat di posisi teratas).
* **Indikator Kedaluwarsa (PENTING):** 
  * Jika tanggal saat ini **belum melewati** `expiry_date`: Tampilkan sisa hari dengan warna aman (misal: hijau/teks biasa).
  * Jika tanggal saat ini **sudah melewati** `expiry_date`: Tampilkan *badge* atau teks peringatan visual mencolok (misal: label merah bertuliskan **"Sudah Basi!"** atau **"Kedaluwarsa"**).
* **Navigasi Bawah:** *Bottom Navigation Bar* modern untuk berpindah ke modul Profil/Pengaturan.

### Modul 3: Formulir Pencatatan (Tambah Bahan Makanan)
Halaman input data dengan *layout* yang rapi menggunakan `Expanded` pada elemen yang sejajar agar tidak terjadi *overflow*.
* **Input Visual:** Area unggah foto/gambar barang.
* **Input Teks Dasar:** Nama Makanan.
* **Input Dropdown / Pilihan:** 
  * Kategori (Buah, Sayur, Minuman, dsb.)
  * Satuan (Liter, Kg, Pcs)
  * **Tempat Penyimpanan:** (misal: Kulkas Bawah, *Freezer*, Lemari Dapur, Meja Makan).
* **Input Kuantitas:** Jumlah Stok (*TextField* khusus angka).
* **Input Tanggal:** Tanggal Kedaluwarsa (*Date Picker*).
* **Input Catatan:** Area teks multiline untuk catatan tambahan.
* **Aksi:** Tombol "Simpan Bahan Makanan" dengan desain *rounded* yang menarik.

### Modul 4: Profil & Pengaturan (Settings)
Halaman kontrol pengguna dengan tata letak yang bersih dan profesional.
* **Informasi Akun:** Menampilkan foto profil (*avatar*), nama, dan email pengguna.
* **Menu Pengaturan:** 
  * Preferensi UI (misal: pengaturan notifikasi atau tema aplikasi).
  * Manajemen Data (opsi pengelolaan akun).
* **Aksi:** Tombol "Logout" / Keluar yang jelas.

---

## 4. Persyaratan Teknis (Technical Requirements)
* **Frontend:** Flutter (Dart).
* **Desain UI/UX:** Fokus pada estetika visual, *white space* yang cukup, dan komponen yang konsisten (mengacu pada *prototype* Figma).
* **Backend:** Supabase (PostgreSQL, Auth, Storage) — *Mode dummy data digunakan selama fase penyelesaian desain UI*.
* **State Management:** Disesuaikan dengan *Clean Architecture*.

---

## 5. Rancangan Basis Data (Database Schema - Supabase/PostgreSQL)

Karena aplikasi ini menggunakan Supabase, autentikasi utama (Email & Password) akan ditangani secara otomatis oleh skema bawaan `auth.users`. Namun, kita memerlukan tabel kustom di skema `public` untuk menyimpan profil pengguna dan data inventaris makanan.

### A. Tabel: `profiles`
Tabel ini digunakan untuk menyimpan data profil tambahan dari pengguna yang mendaftar. Terhubung langsung dengan sistem autentikasi Supabase.

| Kolom | Tipe Data | Constraints / Keterangan |
| :--- | :--- | :--- |
| `id` | `UUID` | **Primary Key**, *Foreign Key* ke `auth.users.id` (otomatis terbuat saat register). |
| `full_name` | `TEXT` | *Not Null*. Nama lengkap pengguna. |
| `email` | `TEXT` | *Not Null*, *Unique*. Alamat email pengguna. |
| `avatar_url` | `TEXT` | *Nullable*. Tautan gambar profil pengguna (jika ada). |
| `created_at` | `TIMESTAMPTZ` | *Default: now()*. Waktu akun dibuat. |

### B. Tabel: `foods`
Tabel utama untuk menyimpan catatan inventaris bahan makanan. Setiap baris data dimiliki oleh satu pengguna secara spesifik.

| Kolom | Tipe Data | Constraints / Keterangan |
| :--- | :--- | :--- |
| `id` | `UUID` | **Primary Key**, *Default: gen_random_uuid()*. |
| `user_id` | `UUID` | **Foreign Key** ke `profiles.id`. *Not Null*. Memastikan data hanya bisa dilihat oleh pemiliknya. |
| `name` | `TEXT` | *Not Null*. Nama bahan makanan/produk. |
| `category` | `TEXT` | *Not Null*. Kategori (Bahan Mentah, Minuman, Sayur, dll). |
| `storage_location` | `TEXT` | *Not Null*. Tempat penyimpanan (Kulkas, Lemari, dll). |
| `quantity` | `NUMERIC` / `INT` | *Not Null*. Jumlah stok barang. |
| `unit` | `TEXT` | *Not Null*. Satuan stok (Liter, Kg, Pcs, dll). |
| `expiry_date` | `DATE` | *Not Null*. Tanggal kedaluwarsa barang. |
| `image_url` | `TEXT` | *Nullable*. Tautan gambar fisik barang (disimpan di Supabase Storage). |
| `notes` | `TEXT` | *Nullable*. Catatan tambahan opsional. |
| `created_at` | `TIMESTAMPTZ` | *Default: now()*. Waktu data ditambahkan. |

### C. Keamanan Data (Row Level Security - RLS)
Untuk memastikan keamanan privasi, tabel `foods` wajib mengaktifkan fitur **RLS (Row Level Security)** di Supabase dengan kebijakan (*Policy*) berikut:
1. **SELECT:** Pengguna hanya dapat membaca data yang kolom `user_id`-nya cocok dengan ID mereka sendiri yang sedang *login*.
2. **INSERT/UPDATE/DELETE:** Pengguna hanya dapat menambah, mengubah, atau menghapus data milik mereka sendiri.

---

## 6. Kriteria Penerimaan & Pengujian (QA & Acceptance Criteria)
Standar yang wajib diselesaikan sesuai dengan arahan dan evaluasi proyek:

1. **Kualitas Antarmuka (UI/UX):** 
   * Form "Tambah Bahan Makanan" bebas dari peringatan garis kuning-hitam (*Right overflowed by X pixels*).
   * Tampilan halaman Beranda, Login, Register, dan Settings sudah dirender sepenuhnya (menggunakan data *dummy* statis) dengan desain yang rapi dan menarik.
2. **Pengujian Fungsionalitas Visual:**
   * Kartu/item makanan simulasi yang tanggal kedaluwarsanya di-*setting* ke masa lalu **wajib** berhasil menampilkan pesan/tanda merah "Sudah Basi" atau indikator serupa.
   * Lokasi penyimpanan berhasil ditampilkan di dalam desain kartu makanan di halaman Home.
3. **Dokumentasi & Standar Evaluasi Akademis:**
   * **BPMN (Business Process Model and Notation):** Menyiapkan diagram alur proses bisnis dari pencatatan barang hingga notifikasi kedaluwarsa.
   * **Basis Path Testing:** Melakukan perhitungan *Cyclomatic Complexity* pada fungsi logika penentu status kedaluwarsa untuk memastikan seluruh kemungkinan rute (belum basi vs. sudah basi) telah teruji.

---

## 7. Status Implementasi & Alur Teknis Terintegrasi (Implementation Status)

Berikut adalah ringkasan teknis mengenai fitur dan konfigurasi yang telah berhasil diimplementasikan pada proyek KapanBasi:

### A. Arsitektur Komunikasi Client-Server
1. **Custom Express Backend:**
   * Backend kustom berbasis Node.js/Express berjalan di port `5000` ([server.js](file:///C:/Users/Abay/OneDrive/Documents/KAPANBASI%20MOBILE/backend/server.js)).
   * Bertindak sebagai API Gateway yang menjembatani aplikasi Flutter dengan Supabase.
   * Menyediakan endpoint registrasi (`/api/auth/register`), masuk (`/api/auth/login`), profil (`/api/profile`), CRUD makanan (`/api/foods`), lokasi penyimpanan (`/api/storage-locations`), serta unggah berkas gambar (`/api/upload`).
2. **Koneksi USB Debugging (ADB Port Reverse):**
   * Agar aplikasi Flutter pada HP fisik dapat mengakses server backend di komputer lokal melalui koneksi USB, port forwarding dikonfigurasi menggunakan ADB:
     ```powershell
     adb reverse tcp:5000 tcp:5000
     ```
   * Konfigurasi URL API di file [.env](file:///C:/Users/Abay/OneDrive/Documents/KAPANBASI%20MOBILE/.env) menggunakan alamat `http://localhost:5000`.

### B. Mekanisme Autentikasi & Sinkronisasi Sesi
1. **Manual Session Recovery:**
   * Token autentikasi (`access_token` dan `refresh_token`) yang dihasilkan oleh Supabase di sisi server backend dikirim kembali ke client Flutter.
   * Di sisi Flutter, token disinkronkan secara manual menggunakan metode `setSession` dari SDK Supabase di file [auth_provider.dart](file:///C:/Users/Abay/OneDrive/Documents/KAPANBASI%20MOBILE/lib/presentation/providers/auth_provider.dart) agar SDK lokal tetap sinkron dan dapat melakukan request data:
     ```dart
     await Supabase.instance.client.auth.setSession(
       refreshToken,
       accessToken: accessToken,
     );
     ```
2. **Reactive Auth State Monitoring:**
   * Status login aplikasi (`isLoggedInProvider`) dikonfigurasi reaktif memantau stream `onAuthStateChange` dari Supabase:
     ```dart
     final subscription = client.auth.onAuthStateChange.listen((data) {
       ref.read(isLoggedInProvider.notifier).state = data.session != null;
     });
     ```
   * Ini memastikan perpindahan halaman otomatis (dari form Login/Register langsung ke Dashboard) berjalan lancar sesaat setelah token sesi berhasil disinkronkan pada proses registrasi maupun login.

### C. Konfigurasi Basis Data & Keamanan Supabase
1. **Sinkronisasi Otomatis Profil:**
   * Mengimplementasikan trigger PostgreSQL `on_auth_user_created` di Supabase untuk menyalin data user baru secara otomatis dari `auth.users` ke tabel `public.profiles` saat registrasi sukses dilakukan.
2. **Row Level Security (RLS) & Kebijakan (Policies):**
   * Kebijakan keamanan tingkat baris diaktifkan secara ketat pada tabel `profiles` dan `foods` di database.
   * Pengguna hanya diizinkan untuk melihat, menambah, mengubah, dan menghapus data yang dimiliki oleh ID mereka sendiri (`auth.uid() = user_id`).
   * Supabase Storage (bucket `food-images`) dikonfigurasi dengan kebijakan unggah bagi pengguna terautentikasi dan akses baca publik untuk visualisasi gambar makanan.