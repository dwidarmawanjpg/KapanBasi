# Product Requirements Document (PRD)
**Proyek:** KapanBasi Mobile App  
**Platform:** Android & iOS (Flutter)  
**Versi Dokumen:** 1.5 (Standarisasi Kategori, Threshold Notifikasi Anti-Spam, Sinkronisasi Status Backend, Detail Teknis Kamera)  

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
Pusat informasi utama dengan desain *card* yang menarik dan dinamis. Halaman ini berfungsi sebagai **daftar kerja aktif** — hanya menampilkan barang yang masih perlu dipantau oleh pengguna.
* **Daftar Inventaris:** Menampilkan Nama, Kategori, Tempat Penyimpanan, Gambar, dan Tanggal Kedaluwarsa.
* **Filter Status (PENTING):** Home **hanya menampilkan item dengan `is_consumed = false`**, baik yang masih aman maupun yang sudah kedaluwarsa (basi). Begitu pengguna menandai item sebagai **"Selesai"** (`is_consumed = true`), item tersebut otomatis **hilang dari Home** dan berpindah menjadi riwayat di Modul Collection.
* **Logika Pengurutan:** Data diurutkan secara *ascending* (tanggal kedaluwarsa terdekat di posisi teratas).
* **Indikator Kedaluwarsa (PENTING):** 
  * Jika tanggal saat ini **belum melewati** `expiry_date`: Tampilkan sisa hari dengan warna aman (misal: hijau/teks biasa).
  * Jika tanggal saat ini **sudah melewati** `expiry_date`: Tampilkan *badge* atau teks peringatan visual mencolok (misal: label merah bertuliskan **"Sudah Basi!"** atau **"Kedaluwarsa"**).
* **Navigasi Bawah:** *Bottom Navigation Bar* modern dengan 3 tab: **Home**, **Collection**, dan **Akun/Profil** (lihat Modul 2A dan Modul 4).

### Modul 2A: Collection (Riwayat Barang) — *BARU*
Halaman riwayat lengkap yang mencatat **seluruh barang yang pernah masuk**, tanpa memandang statusnya. Modul ini menjawab kebutuhan pengguna untuk melihat jejak/log seluruh aktivitas pencatatan bahan makanan, termasuk yang sudah ditandai selesai dikonsumsi.
* **Cakupan Data:** Menampilkan semua item dari tabel `foods` milik pengguna (aktif, basi, maupun sudah `is_consumed = true`), diurutkan dari yang terbaru masuk (`created_at` descending).
* **Filter Tab:** Tersedia filter cepat berupa tab: **Semua**, **Aktif** (belum basi & belum selesai), **Basi** (sudah lewat `expiry_date` & belum selesai), **Selesai** (`is_consumed = true`).
* **Aksi yang Diizinkan (Prinsip Riwayat Semi-Immutable):**
  * **Hapus:** Pengguna dapat menghapus entri riwayat yang tidak relevan/salah input.
  * **Kembalikan ke Aktif:** Untuk item yang sudah ditandai "Selesai" secara tidak sengaja, pengguna dapat mengembalikan status `is_consumed` menjadi `false` sehingga item kembali muncul di Home.
  * **Tidak Ada Edit Penuh:** Collection tidak menyediakan form edit detail (nama, kategori, tanggal, dll). Jika pengguna ingin mengubah detail, item harus dikembalikan ke status Aktif terlebih dahulu lalu diedit melalui Home. Ini memastikan hanya ada satu sumber edit data yang sah.
* **Pencarian & Filter Bertingkat (mengantisipasi data yang terus bertambah):**
  * **Search bar** (selalu terlihat di atas): mencari berdasarkan nama bahan makanan, menggunakan *debounce* ±300ms agar tidak membebani performa saat mengetik.
  * **Filter status** (chip, selalu terlihat): Semua/Aktif/Basi/Selesai — dipertahankan sebagai chip karena jumlah opsinya sedikit dan sering dipakai (1 tap langsung pilih).
  * **Filter lanjutan** (disembunyikan di ikon Filter/*bottom sheet*, karena lebih jarang dipakai):
    * **Kategori**: opsi diambil dinamis dari kategori yang benar-benar ada di data pengguna (bukan daftar statis).
    * **Rentang tanggal**: pengguna dapat memilih basis filter (Tanggal Masuk atau Tanggal Kedaluwarsa) lalu memilih rentang tanggal melalui *date range picker*.
  * **Kombinasi filter**: seluruh filter (keyword, status, kategori, rentang tanggal) digabungkan secara **AND** (saling mempersempit hasil).
  * **Catatan skalabilitas**: filtering saat ini dilakukan di sisi klien (*client-side*) karena data bersifat per-pengguna dan volumenya wajar untuk pantry pribadi. Jika ke depannya volume data membesar signifikan, filtering & pencarian sebaiknya dipindah ke query backend (parameter pada `/api/foods`) beserta paginasi — dicatat sebagai potensi optimasi lanjutan, belum diperlukan saat ini.

### Modul 3: Formulir Pencatatan (Tambah Bahan Makanan)
Halaman input data dengan *layout* yang rapi menggunakan `Expanded` pada elemen yang sejajar agar tidak terjadi *overflow*.
* **Input Visual:** Area unggah foto/gambar barang.
* **Input Teks Dasar:** Nama Makanan.
* **Input Dropdown / Pilihan:** 
  * **Kategori** — daftar tetap (*predefined*, konsisten di seluruh aplikasi): Buah, Sayur, Daging & Protein, Dairy & Olahan Susu, Bumbu & Bahan Kering, Minuman, Frozen Food, Makanan Siap Saji/Sisa, Lainnya. Kolom `category` di database tetap bertipe `TEXT` (bukan tabel referensi terpisah), namun karena input selalu berasal dari dropdown ini, nilai yang tersimpan otomatis konsisten dan siap dipakai untuk filter dinamis di Modul 2A.
  * Satuan (Liter, Kg, Pcs)
  * **Tempat Penyimpanan:** (misal: Kulkas Bawah, *Freezer*, Lemari Dapur, Meja Makan).
* **Input Kuantitas:** Jumlah Stok (*TextField* khusus angka).
* **Input Tanggal:** Tanggal Kedaluwarsa (*Date Picker*).
* **Input Catatan:** Area teks multiline untuk catatan tambahan.
* **Aksi:** Tombol "Simpan Bahan Makanan" dengan desain *rounded* yang menarik.

### Modul 3A: Smart Expiry Suggestion (Rencana / On-Hold)
Fitur ini masih berupa rencana pengembangan dan **belum final**, memerlukan koordinasi lebih lanjut sebelum diimplementasikan. Latar belakangnya: pengguna sering kesulitan menentukan estimasi tanggal kedaluwarsa saat mencatat banyak bahan makanan sekaligus (contoh: tempe dan sayur umumnya bertahan sekitar 3 hari). Rencana fitur:
* Saran otomatis `expiry_date` berdasarkan kategori dan/atau nama bahan spesifik, dihitung dari Tanggal Masuk.
* Saran bersifat *default* yang tetap dapat diubah manual oleh pengguna (bukan nilai wajib/terkunci).
* Sumber data referensi masa simpan (per kategori atau per item) masih perlu ditentukan lebih lanjut.
* **Status: Belum dikerjakan.** Dicatat di PRD sebagai kebutuhan masa depan agar tidak hilang dari cakupan proyek.

### Modul 4: Profil & Pengaturan (Settings)
Halaman kontrol pengguna dengan tata letak yang bersih dan profesional.
* **Kartu Informasi Akun:** Menampilkan foto profil (*avatar*), nama lengkap, dan email pengguna secara dinamis dari database. Dilengkapi tombol **"Edit Profil"** yang mengarah ke halaman terpisah.
* **Edit Profil (`edit_profile_screen.dart`):**
  * Mengubah **nama lengkap** pengguna (validasi minimal 2 karakter).
  * Mengunggah **foto avatar** baru dari kamera atau galeri, memanfaatkan endpoint `POST /api/upload` dan bucket `food-images` yang sama dengan gambar makanan. Perubahan disimpan ke tabel `public.profiles` via endpoint `PUT /api/profile`.
  * Email bersifat *read-only* — tidak dapat diubah dari sini karena terikat dengan sistem autentikasi Supabase.
* **Statistik Pantry Real-Time:** Menampilkan 4 angka (Total / Basi / Kritis ≤3 hari / Aman) yang dihitung langsung dari `foodsProvider` tanpa request tambahan.
* **Preferensi UI:**
  * **Tema Aplikasi:** Pilihan Terang / Gelap / Ikuti Sistem via dialog radio button. Pilihan disimpan permanen di `SharedPreferences` dan diterapkan secara reaktif ke seluruh aplikasi melalui `themeModeProvider`.
  * **Pengingat Harian:** Toggle aktif/nonaktif + pengatur jam via `TimePicker`. Saat aktif, menjadwalkan notifikasi lokal berulang setiap hari menggunakan `flutter_local_notifications`. Isi notifikasi diperbarui otomatis setiap kali `foodsProvider` selesai memuat data (menampilkan jumlah item basi/kritis terkini). Preferensi disimpan di `SharedPreferences`.
* **Manajemen Akun:**
  * **Ganti Password (`change_password_screen.dart`):** Form password baru + konfirmasi (minimal 6 karakter), dikirim ke endpoint `PUT /api/profile/password`.
  * **Bantuan & Dukungan:** Dialog FAQ statis yang menjawab pertanyaan umum tentang cara pakai aplikasi.
* **Aksi Logout:** Konfirmasi dialog → batalkan semua notifikasi aktif → panggil `AuthService.logout()` → kembali ke layar Login.
* **Arsitektur Notifikasi:**
  * Notifikasi dijadwalkan **lokal di perangkat** (`flutter_local_notifications` + `timezone`) tanpa server push.
  * **Pengingat harian:** Dijadwalkan ulang (*reschedule*) setiap kali `foodsProvider` berhasil memuat data agar konten mencerminkan kondisi pantry terkini. Ini menggantikan notifikasi harian sebelumnya dengan versi baru yang memiliki hitungan item akurat.
  * **Notifikasi per-item:** Dijadwalkan otomatis saat item ditambah/diedit (`add_food_screen`), dan dibatalkan saat item dihapus atau ditandai selesai (`home_screen`, `collection_screen`). Item yang dikembalikan ke aktif akan dijadwalkan ulang notifikasinya.
  * **Threshold Notifikasi Per-Item (anti-spam):** Notifikasi per-item tidak dikirim setiap ada perubahan kecil, melainkan hanya dijadwalkan pada 3 titik waktu tetap relatif terhadap `expiry_date`: **H-3**, **H-1**, dan **H-0** (hari barang dinyatakan basi). Ini mencegah pengguna menerima notifikasi berlebihan untuk satu barang yang sama.
  * **Anti-Duplikasi dengan Pengingat Harian:** Jika pada hari yang sama sudah ada notifikasi per-item H-0 untuk suatu barang, notifikasi rekap harian tidak perlu menyebut ulang nama barang tersebut secara detail — cukup ditampilkan sebagai bagian dari angka total (basi/kritis) agar pengguna tidak merasa menerima informasi yang sama dua kali.
  * Preferensi pengingat (aktif/nonaktif + jam) dimuat dari `SharedPreferences` sebelum `runApp()` dan di-*override* ke Riverpod `ProviderScope` agar state awal konsisten.

---

## 4. Persyaratan Teknis (Technical Requirements)
* **Frontend:** Flutter (Dart).
* **Desain UI/UX:** Fokus pada estetika visual, *white space* yang cukup, dan komponen yang konsisten (mengacu pada *prototype* Figma).
* **Backend:** Custom Express (Node.js) sebagai API Gateway, terhubung ke Supabase (PostgreSQL, Auth, Storage). Lihat detail arsitektur lengkap di Bagian 7. *(Catatan: mode dummy data hanya dipakai di awal fase desain UI dan sudah digantikan sepenuhnya oleh backend nyata sejak implementasi Bagian 7 selesai.)*
* **State Management:** Riverpod, disesuaikan dengan *Clean Architecture*.
* **Kamera & Galeri:** Package `image_picker` digunakan untuk mengambil foto dari kamera atau memilih dari galeri, baik untuk foto bahan makanan (Modul 3) maupun foto avatar profil (Modul 4). Aplikasi wajib menangani permintaan izin (*permission handling*) akses kamera dan penyimpanan di Android & iOS sebelum membuka picker.

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
| `category` | `TEXT` | *Not Null*. Kategori, diisi dari daftar tetap di form input (Buah, Sayur, Daging & Protein, Dairy & Olahan Susu, Bumbu & Bahan Kering, Minuman, Frozen Food, Makanan Siap Saji/Sisa, Lainnya). Lihat Modul 3. |
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

### D. Status Modul Collection (Riwayat) — v1.3
1. Kolom `is_consumed` pada tabel `foods` sudah tersedia sejak skema awal, namun sebelumnya hanya difungsikan sebagai filter tersembunyi di Home (item `is_consumed = true` disaring keluar oleh `SupabaseService.getFoods()`), tanpa ada halaman riwayat yang menampilkannya kembali.
2. Ditambahkan method `SupabaseService.getAllFoods()` yang mengambil seluruh data tanpa filter, digunakan khusus oleh halaman Collection.
3. Navigasi Bottom Bar diperluas dari 2 tab (Home, Profile) menjadi 3 tab (Home, Collection, Akun) sesuai keputusan pada sesi diskusi PRD v1.3.

### E. Status Modul Profil & Notifikasi — v1.4
1. **Edit Profil:** Halaman `edit_profile_screen.dart` memungkinkan pengguna mengganti nama dan foto profil. Avatar diunggah via `POST /api/upload` (bucket `food-images`) dan profil diperbarui via endpoint baru `PUT /api/profile`.
2. **Ganti Password:** Halaman `change_password_screen.dart` mengirim permintaan ke endpoint baru `PUT /api/profile/password`, yang meneruskan panggilan ke `supabase.auth.updateUser()`.
3. **Toggle Tema:** `themeModeProvider` (Riverpod) di-persist di `SharedPreferences`. `MaterialApp` mengonsumsi provider ini secara reaktif sehingga tema berubah tanpa restart aplikasi.
4. **Notifikasi Lokal:** `NotificationService` (singleton) mengelola dua jenis notifikasi via `flutter_local_notifications`:
   - *Pengingat harian* — dijadwalkan ulang setiap kali `foodsProvider` selesai memuat data agar isinya mencerminkan kondisi pantry terkini.
   - *Notifikasi per-item* — dijadwalkan saat item ditambah/diedit, dan dibatalkan saat item dihapus/selesai dikonsumsi.
5. **Persistensi Pengaturan:** Semua preferensi (tema, pengingat aktif/nonaktif, jam pengingat) dimuat dari `SharedPreferences` sebelum `runApp()` melalui `AppSettingsSnapshot.load()` dan di-*override* ke `ProviderScope`.
