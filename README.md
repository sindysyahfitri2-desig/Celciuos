# Panduan Struktur Aplikasi Kasir Celcious Coffee

Dokumen ini menjelaskan folder dan file aplikasi Flutter dengan bahasa sederhana.
Mulai dari bagian **"Kalau mau mengubah..."** jika belum tahu harus membuka file yang mana.

## Gambaran paling sederhana

Kode aplikasi dibagi berdasarkan tugas:

| Bagian | Artinya | Contoh |
|---|---|---|
| `presentation` | Tampilan yang dilihat dan ditekan pengguna: halaman, tombol, dialog, animasi. | Halaman checkout dan tombol Bayar. |
| `application` | Aturan/proses: menghitung, memvalidasi, memfilter, dan mengatur alur. | Menghitung total belanja dan diskon. |
| `data` | Sumber dan penyimpanan data yang digunakan bersama oleh fitur. | Daftar produk dan transaksi. |
| `ui` | Tampilan umum yang digunakan lebih dari satu fitur. | Navigasi kasir dan kartu produk. |
| `assets` | Gambar dan berkas visual aplikasi. | Foto produk dan logo. |
| `test` | Pemeriksaan otomatis agar perilaku aplikasi tetap sesuai. | Tes hitung diskon dan tutup shift. |

Alur sederhananya:

```text
Pengguna menekan tampilan (presentation)
              ↓
Aturan aplikasi menjalankan proses (application)
              ↓
Data dibaca/disimpan (data)
              ↓
Hasil ditampilkan kembali (presentation)
```

`application` tidak harus ada untuk setiap halaman sederhana. Untuk halaman yang
memiliki aturan bisnis, utamakan menaruh aturan tersebut di `application`, bukan
mencampurnya dengan widget tampilan.

## Kalau mau mengubah...

| Yang ingin diubah | Mulai dari file/folder |
|---|---|
| Tampilan Login, dialog identitas, atau tujuan setelah login | `lib/features/auth/presentation/login_page.dart` |
| Validasi username/password atau permintaan Login ke API | `lib/features/auth/application/login_controller.dart` |
| Tampilan produk yang dipakai Kasir/umum | `lib/ui/pages/ProdukPage.dart` |
| Produk di area Owner: tambah, edit, hapus, kategori | `lib/features/owner/presentation/pages/KelolaProduk.dart` dan `lib/features/owner/application/product_management_service.dart` |
| Keranjang Kasir | `lib/features/kasir/application/cashier_cart_controller.dart` |
| Harga, PPN, diskon, dan total checkout | `lib/features/kasir/application/cashier_checkout_pricing.dart` |
| Tampilan checkout dan alur pilih pembayaran | `lib/features/kasir/presentation/checkout_page.dart` |
| Penyimpanan order/transaksi pembayaran | `lib/features/kasir/application/cashier_transaction_service.dart` |
| Mulai atau validasi shift | `lib/features/kasir/application/cashier_shift_service.dart` |
| Daftar pesanan yang belum selesai | `lib/features/kasir/application/cashier_order_service.dart` dan `lib/features/kasir/presentation/Transaksi.dart` |
| Rekap Owner: model dan sumber data | `lib/features/owner/application/kt_model.dart` dan `kt_data_service.dart` |
| Tampilan Kelola Transaksi Owner | `lib/features/owner/presentation/pages/Transaksi/Kelola_Transaksi.dart` |
| Hitungan laporan dan data kas laci | `lib/features/reports/application/report_service.dart` |
| Tampilan laporan, filter, tabel, dan unduh Excel | `lib/ui/pages/LaporanPage.dart` |
| Validasi dan simpan PPN | `lib/features/settings/application/settings_service.dart` |
| Tampilan pengaturan Owner, QRIS, atau logo toko | `lib/features/owner/presentation/pages/PengaturanPage.dart` |
| Nama/jumlah/daftar staf | `lib/features/owner/application/staff_directory_controller.dart` dan `lib/features/owner/presentation/pages/KelolaStaf.dart` |
| Navigasi Kasir | `lib/ui/widgets/Navigation.dart` |
| Navigasi Owner | `lib/features/owner/presentation/widgets/Navigation.dart` |
| Foto produk/logo | `assets/images/` |
| Data persisten produk/transaksi | File yang sesuai di `lib/data/` |
| Memulai aplikasi atau urutan pemuatan data | `lib/main.dart` |

**Jangan menaruh kode hitung/simpan baru di widget tampilan jika prosesnya merupakan
aturan bisnis.** Taruh proses tersebut di `application`, lalu panggil dari halaman
`presentation`.

## Peta folder proyek

```text
lib/
├── main.dart
├── data/
├── features/
│   ├── auth/
│   ├── kasir/
│   ├── owner/
│   ├── reports/
│   └── settings/
└── ui/
    ├── pages/
    └── widgets/

assets/
└── images/

test/
```

Folder platform seperti `android/`, `ios/`, `web/`, `windows/`, `linux/`, dan
`macos/` berisi konfigurasi agar Flutter bisa dijalankan pada platform tersebut.
Biasanya pekerjaan tampilan dan aturan aplikasi dilakukan di `lib/`, bukan dengan
mengubah berkas platform.

## Titik mulai aplikasi

### `lib/main.dart`

Titik masuk aplikasi. Sebelum menampilkan Login, aplikasi memuat:

- `TransactionStore` untuk transaksi dan shift.
- `ProdukData` untuk daftar produk.
- `AppBrandingStore` untuk branding/logo.

Jika pemuatan berhasil, halaman Login dibuka. Jika gagal, aplikasi menampilkan
pesan dan tombol untuk mencoba memuat ulang.

Alur pengguna setelah aplikasi terbuka:

1. `LoginPage` mengumpulkan username dan password.
2. `LoginController` memeriksa input lalu mengirim `POST /api/login`.
3. Jika berhasil, role `owner` membuka `DashboardOwner`, sedangkan role `kasir`
   membuka `kasirPage`.
4. Navigasi Owner dan Kasir dibuat terpisah. Pengaturan ada di navigasi Owner.

### Backend Laravel (`celcious-backend/`)

Backend adalah proyek tersendiri, bukan bagian dari proses Flutter. Flutter
tidak menyalakan server Laravel secara otomatis. File API yang penting:

- `routes/api.php`: mendaftarkan endpoint Login, logout, profil, kategori, dan
  produk.
- `app/Http/Controllers/Api/AuthController.php`: memeriksa akun pada tabel
  `pengguna`, membuat token Sanctum, dan mengembalikan objek `pengguna`.
- `database/seeders/PenggunaSeeder.php`: data akun pengembangan untuk role
  Owner dan Kasir. Seeder harus sudah dijalankan agar akun contoh tersedia.

Endpoint `POST /api/login` adalah endpoint publik. Endpoint seperti `/api/user`,
`/api/logout`, kategori, dan produk berada di grup `auth:sanctum`; permintaan
tersebut memerlukan token. Aplikasi Flutter saat ini memakai endpoint Login
untuk autentikasi dan menggunakan role dari respons untuk memilih halaman.

Jangan menyamakan data lokal aplikasi dengan database backend: produk, transaksi,
shift, PPN, QRIS, dan logo di Flutter memakai penyimpanan perangkat (`SharedPreferences`
atau penyimpanan file). Data lokal ini tidak otomatis dibagikan ke komputer
admin, backend, atau instalasi aplikasi lain.

### `pubspec.yaml`

Konfigurasi Flutter, versi SDK, paket yang dipakai, dan daftar aset. Folder
`assets/images/` didaftarkan di sini agar gambar dapat dipanggil sebagai asset.
`pubspec.lock` adalah hasil penguncian versi paket; jangan mengeditnya untuk
mengubah tampilan.

## Folder `lib/features/`

Fitur dikelompokkan berdasarkan bagian sistem. Di dalam fitur, `presentation`
adalah antarmuka dan `application` adalah pekerjaan/aturan fitur.

### `lib/features/auth/` — Login dan autentikasi

- `presentation/login_page.dart`: tampilan Login, validasi hasil login,
  konfirmasi identitas dan role, lalu membuka area Owner atau Kasir.
- `application/login_controller.dart`: validasi username/password, mengirim
  permintaan `POST /api/login`, membaca nama dan role dari respons, dan
  melaporkan kegagalan ke tampilan. Registrasi akun tidak tersedia di aplikasi.

Perubahan tampilan dilakukan di halaman; perubahan aturan autentikasi dilakukan
di controller. Jangan mengubah alamat, format, atau perilaku backend tanpa
memang diminta.

Login membutuhkan backend Laravel yang berjalan dan dapat dijangkau. Controller
memakai `http://10.0.2.2:8000` di emulator Android dan
`http://127.0.0.1:8000` pada platform lain secara default. `10.0.2.2` adalah
alamat khusus emulator untuk mengakses komputer host; HP fisik atau komputer
lain memerlukan alamat IP/host backend yang sesuai. Backend dan Flutter adalah
dua proses terpisah: menjalankan aplikasi Flutter saja tidak menyalakan backend.
Format respons Login yang dipakai aplikasi harus memiliki `token` dan objek
`pengguna` yang memuat `nama` serta `role` (`owner` atau `kasir`).

### `lib/features/kasir/` — Area Kasir

#### `presentation/`

- `kasir_page.dart`: halaman Kasir, alur shift, katalog di sisi Kasir, keranjang,
  dan navigasi ke checkout.
- `checkout_page.dart`: tampilan checkout, input diskon, pemilihan metode
  pembayaran, bukti pembayaran, dan konfirmasi pelanggan.
- `Transaksi.dart`: daftar pesanan yang belum selesai, pencarian/filter, serta
  membuka kembali pesanan untuk dilanjutkan.
- `Transaksi_Berhasil.dart`: halaman konfirmasi transaksi selesai.

#### `application/`

- `cashier_cart_controller.dart`: tambah/hapus item, catatan item, kuantitas,
  jumlah item, dan nilai keranjang.
- `cashier_checkout_pricing.dart`: subtotal, PPN, diskon rupiah/persen, total
  akhir, dan jumlah item checkout.
- `cashier_order_service.dart`: penggabungan pesanan tersimpan, filter pesanan,
  pembuatan data keranjang untuk checkout, dan format Rupiah.
- `cashier_shift_service.dart`: validasi data kasir/kas awal dan mulai shift.
- `cashier_transaction_service.dart`: membuat kode pesanan serta menyimpan
  pesanan belum dibayar dan transaksi yang dibayar.

`checkout_page.dart` tetap mengatur dialog dan langkah interaksi pengguna;
perhitungan dan proses simpan transaksi dikerjakan oleh kelas `application`.

### `lib/features/owner/` — Area Owner

#### `presentation/pages/`

- `Dashboard.dart`: kerangka Dashboard Owner dan perpindahan antar menu.
- `KelolaProduk.dart`: tampilan daftar produk, form tambah, dialog edit/hapus,
  kategori, dan status produk.
- `KelolaStaf.dart`: tampilan pencarian, daftar, pengubahan nama, dan foto staf.
- `PengaturanPage.dart`: tampilan pengaturan toko milik Owner, termasuk tarif,
  QRIS, logo, dan opsi perangkat.
- `Transaksi/Kelola_Transaksi.dart`: tampilan rekap shift, riwayat, pencarian,
  dan ringkasan transaksi.
- `Transaksi/Modal_keuntungan.dart`: komponen tampilan modal dan keuntungan.
- `Transaksi/Riwayat_transaksi.dart`: komponen tampilan riwayat transaksi.

#### `presentation/widgets/`

- `Navigation.dart`: komponen navigasi Owner untuk layar besar dan kecil.

#### `application/`

- `product_management_service.dart`: baca/simpan kategori dan aturan tambah,
  edit, hapus, serta aktif/nonaktif produk.
- `staff_directory_controller.dart`: daftar staf, pencarian, dan perubahan nama.
- `kt_model.dart`: bentuk data rekap/transaksi Owner dan helper presentasi
  angka/tanggal yang digunakan komponen transaksi Owner.
- `kt_data_service.dart`: menyediakan data contoh untuk preview dan mengubah
  data `TransactionStore` menjadi rekap shift Owner.

Dashboard Owner menampilkan Dashboard, Laporan, Produk, Transaksi, Kelola Staf,
Profil, dan Pengaturan. Menu Pengaturan tersedia di navigasi Owner untuk layar
besar maupun kecil. Menu Profil sudah terdaftar di navigasi, tetapi belum
memiliki halaman profil terpisah di pemetaan konten Dashboard.

### `lib/features/reports/` — Pengolahan data laporan

- `application/report_service.dart`: membaca transaksi, order, riwayat shift,
  kas laci, dan menyusunnya menjadi data laporan. Pending tetap dapat muncul
  dengan statusnya, tetapi tidak dihitung sebagai transaksi lunas/penjualan.

Layar, filter, tabel, dialog shift, dan ekspor Excel laporan berada di
`lib/ui/pages/LaporanPage.dart`.

### `lib/features/settings/` — Aturan pengaturan

- `application/settings_service.dart`: memvalidasi angka PPN 0–100 persen dan
  menyimpan tarif PPN melalui penyimpanan transaksi.
- Tampilan pengaturan Owner berada di `lib/features/owner/presentation/pages/PengaturanPage.dart`.

## Folder `lib/data/` — Penyimpanan bersama

Data di sini dipakai lintas halaman. Jika perlu mengubah cara penyimpanan atau
bentuk data bersama, periksa dampaknya pada semua fitur yang menggunakannya.

| File | Tanggung jawab |
|---|---|
| `transaction_store.dart` | Menyimpan dan memulihkan transaksi, pesanan belum selesai, tarif PPN, shift aktif/riwayat, dan kas laci. |
| `produk_data.dart` | Daftar produk bersama untuk Kasir, Owner, dan katalog; mendukung penyimpanan perubahan produk dan gambar. |
| `qris_store.dart` | Menyimpan dan memuat gambar QRIS di perangkat. |
| `payment_proof_store.dart` | Menyimpan bukti pembayaran yang dipilih atau diambil. |
| `app_branding_store.dart` | Menyimpan dan memuat logo/branding toko. |

Jangan membuat sumber daftar produk atau transaksi kedua di halaman. Gunakan
store yang sesuai supaya perubahan terlihat konsisten di seluruh fitur.
Sebagian besar data tersebut tersimpan lokal di perangkat. Data lokal tidak
otomatis dibagikan ke komputer admin, backend, atau instalasi aplikasi lain;
fitur sinkronisasi perlu dibuat terpisah jika dibutuhkan.

## Folder `lib/ui/` — Halaman dan widget bersama

### `lib/ui/pages/`

- `home_page.dart`: memilih jenis pesanan sebelum melanjutkan alur Kasir.
- `ProdukPage.dart`: katalog produk yang dipakai sebagai halaman umum.
- `LaporanPage.dart`: tampilan laporan keuangan dan kas laci, filter, dialog
  pengelolaan shift, serta ekspor ke Excel; pemrosesan data dilakukan oleh
  `ReportService`.

### `lib/ui/widgets/`

- `Navigation.dart`: shell/sidebar/bottom navigation untuk area Kasir dan
  halaman yang dapat diakses Kasir. Pengaturan tidak ditampilkan di menu Kasir.
- `product_cart.dart`: kartu produk dan kontrol kuantitas.
- `product_image.dart`: tampilan gambar produk dan fallback jika gambar tidak
  bisa dibaca.
- `Bukti_camera.dart`: komponen kamera untuk mengambil bukti pembayaran.
- `app_branding_logo.dart`: menampilkan logo toko dengan fallback.

## Folder `assets/images/`

Tempat gambar lokal yang dipakai aplikasi, misalnya foto menu, latar Login,
QRIS, dan logo. Daftar asset didaftarkan lewat `pubspec.yaml`.

Untuk memakai gambar, pastikan file memang ada dan path yang ditulis di kode
sesuai nama file persis, termasuk spasi, underscore, dan huruf besar/kecil.
Sebagian nama gambar memiliki varian dengan spasi dan underscore; jangan
menghapus atau mengganti nama sebelum mencari pemakaian path-nya.

## Folder `test/` — Pemeriksaan otomatis

- `application_services_test.dart`: tes perhitungan checkout dan validasi/simpan
  tarif PPN.
- `login_controller_test.dart`: tes Login memakai mock endpoint backend dan
  validasi input yang harus berhenti sebelum mengirim request.
- `report_service_test.dart`: tes transaksi paid/pending dan hitungan kas.
- `produk_data_test.dart`: tes penyimpanan produk serta alur Owner/katalog/Kasir.
- `shift_close_flow_test.dart`: tes alur tutup shift dari laporan kas laci.
- `widget_test.dart`: tes aplikasi, login Owner, responsivitas halaman utama,
  tampilan checkout, serta tampilan halaman Pengaturan.

Jalankan semua tes dari terminal pada folder proyek:

```powershell
flutter test
```

Periksa error dan lint statis:

```powershell
flutter analyze --no-pub
```

## File yang perlu diketahui di luar `lib/`

- `README.md`: panduan struktur ini.
- `pubspec.yaml`: konfigurasi dan dependensi Flutter.
- `pubspec.lock`: versi paket yang dipakai saat ini.
- `analysis_options.yaml`: aturan analisis/lint Dart.
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`: konfigurasi
  platform Flutter.
- `celcious-backend/`: proyek backend terpisah dari kode Flutter; bukan tempat
  untuk mengubah tampilan Flutter.

## Catatan penting

- Perubahan UI biasanya hanya menyentuh `presentation` atau `ui`.
- Perubahan aturan bisnis dilakukan di `application`.
- Perubahan sumber/persistensi data dilakukan dengan hati-hati di `data`.
- Backend dan kontrak API yang sudah ada tidak diubah oleh pemisahan struktur
  Flutter ini.
- `lib/transaction_store.dart` adalah berkas lama berisi TODO saja. Store
  transaksi yang dipakai aplikasi adalah `lib/data/transaction_store.dart`.
- Jangan menghapus file hanya karena tampak tidak dipakai sebelum memeriksa
  import dan menjalankan tes.
