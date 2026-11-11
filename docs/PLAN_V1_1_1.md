# Rencana Implementasi Perbaikan & Peningkatan UX (`PLAN_V1_1_1.md`)

Dokumen ini menyajikan rencana kerja terstruktur berdasarkan hasil diagnostik perangkat nyata dan audit seluruh layar (`docs/SCREEN_AUDIT.md`). Sesuai prosedur kerja, **implementasi kode produk (`lib/`, `android/`, `pubspec.yaml`) pada Tahap 2 hanya akan dijalankan setelah rencana ini disetujui oleh pemilik proyek.**

---

## 1. Ringkasan Temuan & Peta Risiko

| Kategori Prioritas | Jumlah Item | Cakupan Utama | Tingkat Risiko & Mitigasi |
|---|---|---|---|
| **P0 (Blocker Rilis)** | 2 item (`UI-001`, `UI-002`) | **A1.** Gagal Login Google (`oauth_client: []` kosong di `google-services.json`).<br>**A2.** Gagal unduh modul (`HTTP 404` pada URL tag `v1.1.1` + bocornya teks `ModuleDownloadException:` di UI). | **Tinggi** bila tidak ditangani karena menghambat alur sinkronisasi cloud dan pemasangan modul dialek di perangkat nyata. Dimitigasi dengan fallback otomatis ke aset rilis `v1.1.0` (`HTTP 200`) + penjaga sesi Tamu. |
| **P1 (High Priority UX & Branding)** | 7 item (`UI-003` s/d `UI-009`) | **B1.** Ikon aplikasi & notifikasi **Si Rebung**.<br>**B2.** Native splash Android 12+ & layar `/welcome` (Login Google vs Tamu).<br>**B3.** Penghapusan fitur "vocal" (`PronunciationGuideScreen`).<br>**B4.** Komponen `KFilterBar` & perbaikan tata letak `DialectComparisonScreen`.<br>**UI-008 & UI-009.** Kejujuran badge SHA-256 & pembersihan kartu usang `Melayu lainnya`. | **Sedang**. Perubahan menyentuh rute awal (`/splash -> /welcome`) dan manifest Android. Dimitigasi dengan pengujian widget menyeluruh dan fallback aman ke `/home/learn` bagi pengguna lama. |
| **P2 (Medium Polish & Multi-Dialect Consistency)** | 10 item (`UI-010` s/d `UI-019`) | Konsistensi label kursus aktif (tidak meng-hardcode `"Melayu Deli"` saat belajar Langkat/Palembang), pencegahan overflow `Row` kata+badge di `UnitDetailScreen` & `DictionaryScreen`, loading state tombol sinkronisasi di `ProfileScreen`. | **Rendah**. Perubahan terlokalisasi pada tampilan teks dan pembungkusan `Wrap`/`Flexible`. |
| **P3 (Low / Housekeeping)** | 3 item (`UI-020` s/d `UI-022`) | Label versi `v1.1.1` di `AboutScreen`, reset preferensi `auth_mode` saat hapus semua data lokal, dan peningkatan tinggi sentuh minimum `KChip` menjadi `48dp`. | **Sangat Rendah**. |

---

## 2. Diagnosis & Rancangan Solusi Item Utama (`A1`, `A2`, `B1`, `B2`, `B3`, `B4`)

### A1. Penyelesaian Masalah Login Google di Perangkat Nyata (`UI-001` - P0)

- **Bukti Akar Masalah**:
  1. Pemanggilan `firebase_get_sdk_config` pada proyek Firebase `katara-melayu` menunjukkan bahwa blok `"oauth_client": []` untuk `id.katara.app` masih berupa array kosong (`[]`).
  2. Walaupun sidik jari sertifikat `SHA-1` (`FD:30:99:39:F8:49:0E:C3:E1:56:AC:61:57:46:7F:78:A1:0C:6D:6F`) dan `SHA-256` sudah terdaftar di Firebase, **penyedia masuk Google (*Google Sign-In provider*) pada menu `Firebase Console -> Authentication -> Sign-in method` belum diaktifkan**, sehingga OAuth 2.0 Web Client ID (`client_type: 3`) dan Android Client ID (`client_type: 1`) belum dibuat oleh Google Cloud.
- **Rancangan Perbaikan di Kode & Dokumentasi**:
  1. **Dukungan `serverClientId` & Konfigurasi `GoogleSignIn` (`lib/services/firebase_sync_service.dart`)**:
     - Konfigurasi instance `GoogleSignIn(scopes: const ['email', 'profile'], serverClientId: ...)` yang membaca `GOOGLE_WEB_CLIENT_ID` dari `String.fromEnvironment('GOOGLE_WEB_CLIENT_ID')` bila disuplai saat build, atau otomatis menggunakan `default_web_client_id` dari `google-services.json` setelah diunduh ulang.
     - Validasi bahwa `googleAuth.idToken` atau `googleAuth.accessToken` tidak kosong sebelum memanggil `FirebaseAuth.instance.signInWithCredential`.
  2. **Deteksi Konfigurasi OAuth & Panel Diagnostik Debug**:
     - Tambahkan helper diagnostik (hanya aktif pada `kDebugMode`) di halaman Pengaturan/Profil yang memeriksa apakah `google-services.json` sudah memiliki OAuth client terkonfigurasi, sehingga developer dapat memverifikasi kesiapan login Google dalam satu ketukan.
  3. **Ketahanan Alur Pengguna (Zero Dead-End)**:
     - Baik di `WelcomeScreen` maupun `ProfileScreen`, bila login Google gagal (karena tanpa internet atau konfigurasi OAuth belum selesai di konsol), tampilkan pesan ramah dari `AuthErrorMapper` beserta tombol aksi langsung **"Lanjut sebagai Tamu"** agar pengguna tidak pernah tertahan di layar masuk.

---

### A2. Penyelesaian `HTTP 404` Unduh Modul Bahasa & Perbaikan UX (`UI-002`, `UI-008`, `UI-009` - P0/P1)

- **Bukti Akar Masalah**:
  1. Pemeriksaan `curl.exe -sIL` membuktikan:
     - `https://github.com/rynnxz/KATARA/releases/download/v1.1.0/module_langkat.zip` -> **`HTTP 200 OK`** (`82.273` byte).
     - `https://github.com/rynnxz/KATARA/releases/download/v1.1.0/module_palembang.zip` -> **`HTTP 200 OK`** (`84.219` byte).
     - `https://github.com/rynnxz/KATARA/releases/download/v1.1.1/module_langkat.zip` -> **`HTTP 404 Not Found`** (karena tag rilis `v1.1.1` belum diunggah ke GitHub Releases saat APK `v1.1.1` diuji di ponsel).
  2. `RegionPickerScreen._handleDownload` (`baris 168–172`) menampilkan `Text('Gagal mengunduh modul ${course.name}: $e')`, yang mencetak nama class internal `ModuleDownloadException: ...` ke layar pengguna.
  3. Kartu modul yang belum diunduh menampilkan badge `"SHA-256 Terverifikasi"` secara prematur.
  4. Baris placeholder lama `ms-other` (`"Melayu lainnya • Segera hadir"`) masih tersisa di SQLite perangkat yang melakukan upgrade dari versi awal.
- **Rancangan Perbaikan di Kode**:
  1. **Mekanisme Multi-URL Fallback dengan Verifikasi SHA-256 Ketat (`lib/services/module_download_service.dart`)**:
     - Saat mengunduh modul, `ModuleDownloadService` akan mencoba URL utama dari katalog (`v1.1.1`). Apabila server mengembalikan `HTTP 404` (misalnya rilis tag baru belum dipublikasikan di GitHub), layanan secara otomatis jatuh-balik (*fallback*) ke URL rilis stabil `v1.1.0` (`https://github.com/rynnxz/KATARA/releases/download/v1.1.0/module_langkat.zip` / `module_palembang.zip`) yang sudah aktif dan mengembalikan `HTTP 200`!
     - Verifikasi keamanan SHA-256 tetap wajib 100%: layanan memverifikasi hash terhadap daftar putih checksum resmi yang ditandatangani untuk paket `v1.1.1` maupun `v1.1.0`, lengkap dengan perlindungan *zip-slip*, *zip-bomb*, dan validasi skema JSON sebelum menyentuh database.
  2. **Pemetaan Pesan Galat Unduhan Ramah Pengguna (`ModuleDownloadErrorMapper`)**:
     - Buat fungsi pemetaan khusus yang menerjemahkan galat jaringan, `HTTP 404`, timeout, penyimpanan penuh, atau ketidakcocokan checksum menjadi pesan Bahasa Indonesia yang jelas tanpa pernah menampilkan string `ModuleDownloadException` atau stack trace.
     - Tambahkan aksi `SnackBarAction(label: 'Coba Lagi', ...)` dan tombol **Batalkan** saat unduhan sedang berjalan.
  3. **Status Kartu Modul yang Jujur di `RegionPickerScreen`**:
     - **Belum Diunduh**: menampilkan chip `"Ukuran ~80 KB"` dan `"Cek SHA-256 saat pasang"` (bukan `"SHA-256 Terverifikasi"`).
     - **Sedang Mengunduh**: menampilkan `KProgressBar` persentase + status tahapan (`Mengunduh paket...` -> `Memverifikasi SHA-256...` -> `Memasang ke kamus...`).
     - **Terpasang**: menampilkan chip `"Terpasang • SHA-256 Terverifikasi"` dengan tombol **Mulai / Lanjut** dan ikon hapus berkas modul.
  4. **Pembersihan Kursus Placeholder Usang (`lib/data/content/content_seeder.dart`)**:
     - Hapus baris kursus di luar daftar resmi `courses.json` (`DELETE FROM courses WHERE id NOT IN ('ms-deli', 'ms-langkat', 'ms-palembang')`) saat `seedIfNeeded()` berjalan, sehingga kartu `"Melayu lainnya • Segera hadir"` hilang secara bersih.

---

### B1. Ikon Aplikasi & Notifikasi = Maskot Si Rebung (`UI-003` - P1)

- **Rancangan Teknis**:
  1. Buat skrip generator deterministik `test/tools/generate_branding_assets_test.dart` (dijalankan melalui `flutter test` agar memiliki akses penuh ke `dart:ui` `Canvas`, `PictureRecorder`, dan `_SiRebungPainter` dari `MascotView` tanpa bergantung pada tool eksternal):
     - **`assets/branding/app_icon_1024.png`** (`1024x1024` px): Latar hijau Melayu kerajaan (`#0F5238`) dengan lingkaran aksen emas hangat dan maskot **Si Rebung** (`MascotState.happy`) yang tajam di tengah.
     - **`assets/branding/app_icon_foreground.png`** (`1024x1024` px transparan): Maskot **Si Rebung** ditempatkan tepat di dalam *safe zone* tengah (`66%` diameter = `676x676` px) agar tidak terpotong oleh masker lingkaran/squircle/teardrop Android Adaptive Icon.
     - **`assets/branding/app_icon_monochrome.png`** (`1024x1024` px transparan): Siluet satu warna **Si Rebung** bertanjak Melayu untuk mendukung *Themed Icons* pada Android 13+.
     - **`assets/branding/splash_mascot.png`** (`768x768` px transparan): Gambar maskot **Si Rebung** untuk native splash screen.
     - **`android/app/src/main/res/drawable/ic_stat_katara.png`** (`96x96` px): Ikon notifikasi siluet putih di atas latar transparan sesuai spesifikasi bilah status Android.
  2. Konfigurasi `flutter_launcher_icons` di `pubspec.yaml` dan jalankan generator untuk memperbarui seluruh `mipmap-mdpi` s/d `mipmap-xxxhdpi` serta `mipmap-anydpi-v26/ic_launcher.xml`.
  3. Perbarui `LocalNotificationService` (`lib/services/notification_service.dart:58`) agar menggunakan `'@drawable/ic_stat_katara'` sebagai ikon notifikasi.

---

### B2. Native Splash Screen + Layar `/welcome` (Login atau Mode Tamu) (`UI-004` - P1)

- **Rancangan Native Splash (`flutter_native_splash`)**:
  - Tambahkan konfigurasi `flutter_native_splash` untuk Android (termasuk Android 12+ `SplashScreen` API di `values-v31` dan `values-night-v31`):
    - Warna latar mode terang: `#FFF8EC` (Krem Lontar).
    - Warna latar mode gelap: `#121A16` (Hijau Malam).
    - Gambar tengah: `assets/branding/splash_mascot.png` (Si Rebung).
  - Pada `SplashScreen` (`/splash`), jalankan animasi transisi singkat (`MascotState.idle -> MascotState.happy`, durasi `<= 900ms`, otomatis dilewati bila `MediaQuery.disableAnimationsOf(context) == true`) sembari menunggu proses `seedIfNeeded()` selesai.
- **Rancangan Alur & Layar `/welcome` (`lib/features/onboarding/welcome_screen.dart`)**:
  - **Alur Navigasi Baru**:
    - **Pengguna Baru**: `/splash` -> `/welcome` (pilih Masuk dengan Google atau Lanjut sebagai Tamu) -> `/onboarding` -> `/region` -> `/home/learn`.
    - **Pengguna Lama** (`onboardingCompleted == true` & `activeCourseId` terisi): `/splash` -> langsung `/home/learn` (tidak menampilkan `/welcome` lagi).
  - **Desain `WelcomeScreen` (Zero Dark Pattern)**:
    - Menampilkan maskot **Si Rebung**, judul hangat **"Selamat Datang di KATARA"**, dan penjelasan singkat bahwa seluruh kamus, pelajaran, aksara Jawi, dan budaya Melayu dapat diakses 100% secara luring.
    - **Tombol 1 (`KButton` Primer)**: **"Masuk dengan Google"** (dengan subteks manfaat: *"Cadangkan & sinkronkan XP, streak, dan progres belajarmu lintas perangkat"*).
    - **Tombol 2 (`KButton` Outline/Sekunder ukuran penuh yang setara)**: **"Lanjut sebagai Tamu"** (dengan subteks jelas: *"Belajar langsung tanpa akun. 100% fitur lengkap secara offline, dan bisa ditautkan ke Google kapan saja di menu Profil"*).
    - Menyimpan pilihan ke `SettingsService` (`authMode`: `'google'` atau `'guest'`, `hasSeenWelcome`: `true`).

---

### B3. Penghapusan Bagian "Vocal" (`UI-005` - P1, Menunggu Konfirmasi Pengguna)

- **Hasil Inventarisasi Codebase**:
  - Satu-satunya layar/fitur yang secara khusus membahas **"vokal"** adalah **`PronunciationGuideScreen`** (`lib/features/practice/pronunciation_guide_screen.dart`, rute `/practice/pronunciation`), yang diakses dari kartu **"Panduan Lafal & Fonologi — Kaidah vokal akhir [-e] vs [-o] & glotal"** pada `PracticeScreen` (`baris 445–471`).
- **Dua Opsi Interpretasi (untuk dikonfirmasi pengguna sebelum dieksekusi)**:
  - **Opsi B3-A (Direkomendasikan)**: Menghapus layar `PronunciationGuideScreen` (`lib/features/practice/pronunciation_guide_screen.dart`), menghapus rutenya di `lib/app/router.dart`, dan menghapus kartu menu **"Panduan Lafal & Fonologi (Kaidah vokal akhir [-e] vs [-o])"** di `PracticeScreen`, sambil tetap mempertahankan teks transkripsi fonetik `[a.pə]` sebagai informasi bantu di Kamus dan Perbandingan Dialek.
  - **Opsi B3-B**: Selain menghapus `PronunciationGuideScreen`, juga menyembunyikan seluruh tampilan transkripsi fonetik `[...]` pada kartu `DialectComparisonScreen` dan `DictionaryScreen`.

---

### B4. Komponen `KFilterBar` & Perbaikan `DialectComparisonScreen` (`UI-006`, `UI-007` - P1)

- **Rancangan Komponen Bersama `KFilterBar` (`lib/app/widgets/k_filter_bar.dart`)**:
  - Menggantikan `SingleChildScrollView(scrollDirection: Axis.horizontal)` yang memotong chip kategori di tepi layar.
  - Menggunakan tata letak **`Wrap` multi-baris yang responsif** (`spacing: 8`, `runSpacing: 8`) dengan opsi mode ringkas (menampilkan kategori utama + chip **"Kategori Lainnya (+N)"** yang memperluas seluruh chip di tempat atau membuka lembar pilih kategori) sehingga **tidak ada satu pun chip yang terpotong di tepi layar** pada lebar `320dp`, `360dp`, maupun `412dp`.
  - Setiap chip menampilkan label dan jumlah item, misalnya: `Semua (110)`, `Sapaan (12)`, `Kata Tanya (8)`, `Keluarga (14)`.
  - Mendukung pemilihan multi-kategori (`Set<String> selectedCategories`):
    - Mengetuk kategori mengaktifkan/menonaktifkan kategori tersebut.
    - Mengetuk `Semua` (atau tombol `Atur ulang`) menghapus seluruh filter kategori aktif.
  - Menampilkan baris status hasil di bawah filter: `"Menampilkan X dari Y entri"` beserta tombol teks **"Atur ulang filter"** bila ada filter atau kata kunci pencarian yang aktif.
- **Perbaikan Kartu Perbandingan Dialek (`DialectComparisonScreen`)**:
  - Pendekkan `hintText` pencarian menjadi **`"Cari kata atau arti"`** agar tidak pernah terpotong pada layar sempit, dan tambahkan *debounce* `180ms`.
  - Ubah `_DialectVariantTile` agar tidak memaksakan badge dialek, kata utama, dan transkripsi fonetik panjang (`[a.po] (Sari-sari) / [na.pi] (Bebaso)`) ke dalam satu baris `Row` sempit: tempatkan kata utama di sebelah badge dialek, dan letakkan transkripsi fonetik/tingkat tutur di baris bawah atau `Wrap` dengan `Flexible` sehingga bersih dari *overflow* pada `textScale 2.0x`.
  - Tambahkan sitasi sumber ringkas (`Sumber: Balai Bahasa Sumut & Balai Bahasa Sumsel`) pada kotak catatan linguistik di bawah kartu.

---

## 3. Daftar Backlog Lengkap & Kriteria Penerimaan (`P0` -> `P3`)

### Prioritas P0 (Blocker)

| ID | Tugas | Berkas yang Disentuh | Kriteria Penerimaan (Testable Acceptance Criteria) | Rencana Pengujian | Estimasi |
|---|---|---|---|---|---|
| **P0-1** (`UI-001`) | Hardening alur Google Sign-In, dukungan `serverClientId`, diagnostik OAuth debug, dan loading state tombol login. | `lib/services/firebase_sync_service.dart`, `lib/services/auth_error_mapper.dart`, `lib/features/profile/profile_screen.dart`, `docs/GOOGLE_SIGNIN_SETUP.md` | 1. Tombol login Google menampilkan spinner dan nonaktif selama proses berjalan.<br>2. Jika `oauth_client` belum terisi atau perangkat offline, muncul pesan ramah Bahasa Indonesia + opsi lanjut sebagai Tamu tanpa crash.<br>3. Saat `kDebugMode`, tersedia indikator status konfigurasi OAuth `google-services.json`. | Unit test `test/auth_error_mapper_test.dart` & `test/cloud_sync_test.dart`. | **M** |
| **P0-2** (`UI-002`) | Multi-URL fallback unduhan modul (`v1.1.1` -> `v1.1.0` `HTTP 200`), mapper galat unduhan ramah pengguna, tombol Coba Lagi. | `lib/services/module_download_service.dart`, `lib/features/region_picker/region_picker_screen.dart`, `assets/content/courses.json`, `assets/content/module_catalog.json` | 1. Mengunduh modul Melayu Langkat & Palembang pada perangkat nyata berhasil `HTTP 200` dan lulus verifikasi SHA-256.<br>2. Jika jaringan mati/404, UI **tidak pernah** menampilkan teks `ModuleDownloadException:`; muncul pesan ramah + tombol `Coba Lagi`. | Unit & widget test `test/module_security_test.dart` & `test/module_download_ux_test.dart`. | **M** |

### Prioritas P1 (High Priority UX & Branding)

| ID | Tugas | Berkas yang Disentuh | Kriteria Penerimaan (Testable Acceptance Criteria) | Rencana Pengujian | Estimasi |
|---|---|---|---|---|---|
| **P1-1** (`UI-003`) | Generator ikon **Si Rebung** (`1024x1024`, adaptive foreground, monochrome, notification icon) & konfigurasi `flutter_launcher_icons`. | `test/tools/generate_branding_assets_test.dart`, `assets/branding/*`, `pubspec.yaml`, `android/app/src/main/res/**`, `lib/services/notification_service.dart` | 1. Seluruh berkas `ic_launcher.png`, `ic_launcher_foreground.png`, `ic_launcher_monochrome.png`, dan `ic_stat_katara.png` terbuat dari maskot Si Rebung.<br>2. `NotificationService` memakai `@drawable/ic_stat_katara`. | Verifikasi berkas hasil generate & unit test `notification_service_test.dart`. | **M** |
| **P1-2** (`UI-004`) | Native splash screen (`flutter_native_splash` Android 12+) & layar `/welcome` (Masuk dengan Google vs Lanjut sebagai Tamu). | `pubspec.yaml`, `android/app/src/main/res/**`, `lib/features/onboarding/splash_screen.dart`, `lib/features/onboarding/welcome_screen.dart`, `lib/services/settings_service.dart`, `lib/app/router.dart` | 1. Tidak ada *white flash* saat aplikasi dibuka di Android 12+.<br>2. Pengguna baru diarahkan `/splash -> /welcome -> /onboarding -> /region -> /home/learn`.<br>3. Pengguna lama langsung `/splash -> /home/learn`.<br>4. Pilihan Tamu & Google tampil setara tanpa *dark pattern*. | Widget test baru `test/welcome_flow_test.dart` (uji pengguna baru, pilih Tamu, pilih Google gagal -> fallback Tamu, pengguna lama). | **M** |
| **P1-3** (`UI-005`) | Penghapusan bagian "vocal" (`PronunciationGuideScreen` / sesuai konfirmasi pengguna). | `lib/app/router.dart`, `lib/features/practice/practice_screen.dart`, `lib/features/practice/pronunciation_guide_screen.dart`, `test/multi_dialect_test.dart` | 1. Rute `/practice/pronunciation` dan tombol menunya di `PracticeScreen` bersih tanpa dead code atau broken link.<br>2. Tata letak `PracticeScreen` tetap seimbang. | Widget test `PracticeScreen` & `flutter analyze` nol warning. | **S** |
| **P1-4** (`UI-006`, `UI-007`) | Pembuatan `KFilterBar` multi-pilih responsif & perbaikan tata letak `DialectComparisonScreen`. | `lib/app/widgets/k_filter_bar.dart`, `lib/features/dialect_comparison/dialect_comparison_screen.dart` | 1. Tidak ada chip kategori yang terpotong di tepi layar pada lebar `320dp`, `360dp`, dan `412dp` (`textScale` `1.0x`, `1.3x`, `2.0x`).<br>2. Mendukung multi-pilih kategori, reset `Semua`, penghitung hasil, dan empty state dengan tombol reset.<br>3. Kartu Palembang tidak overflow pada teks fonetik panjang. | Widget test baru `test/k_filter_bar_test.dart` & `test/dialect_comparison_layout_test.dart`. | **M** |
| **P1-5** (`UI-008`, `UI-009`) | Kejujuran lencana SHA-256 sebelum vs sesudah unduh & pembersihan kursus usang `Melayu lainnya`. | `lib/features/region_picker/region_picker_screen.dart`, `lib/data/content/content_seeder.dart` | 1. Kartu modul yang belum diunduh tidak menampilkan `"SHA-256 Terverifikasi"`, melainkan `"Cek SHA-256 saat pasang"`.<br>2. Kartu `"Melayu lainnya • Segera hadir"` dihapus otomatis dari DB saat startup. | Widget test `RegionPickerScreen` & test migrasi/seeder. | **S** |

### Prioritas P2 & P3 (Penyempurnaan Lintas Layar)

| ID | Tugas | Berkas yang Disentuh | Kriteria Penerimaan (Testable Acceptance Criteria) | Estimasi |
|---|---|---|---|---|
| **P2-1** (`UI-010`) | Terapkan `KFilterBar` & pembungkusan `Wrap` judul kata + badge pada `DictionaryScreen`. | `lib/features/dictionary/dictionary_screen.dart` | Kategori kamus tidak terpotong di tepi kanan; tidak ada overflow pada kata panjang di layar `320dp`. | **S** |
| **P2-2** (`UI-011`, `UI-012`) | Perbaikan redundansi nama `"Perantau"` & tampilan status sinkronisasi terakhir di `ProfileScreen`. | `lib/features/profile/profile_screen.dart`, `lib/features/onboarding/onboarding_screen.dart` | Nama default tidak mengulang kata `"Perantau"` dua kali berurutan; baris XP aman pada `320dp`. | **S** |
| **P2-3** (`UI-013` s/d `UI-019`) | Konsistensi label multi-dialek di `LearnMapScreen`, `UnitDetailScreen`, `LessonScreen`, `LessonResultScreen`, `CultureScreen`, `JawiScreen`, dan responsivitas 1-kolom `PracticeScreen` di layar sempit. | `lib/features/path_map/*`, `lib/features/lesson/*`, `lib/features/culture/*`, `lib/features/practice/practice_screen.dart` | Label menyesuaikan kursus aktif (`Melayu Deli`, `Melayu Langkat`, `Melayu Palembang`); laporan kesalahan di pelajaran mencatat `courseId` yang benar. | **S** |
| **P3-1** (`UI-020` s/d `UI-022`) | Pembaruan label versi `v1.1.1` di `AboutScreen`, reset `auth_mode` saat hapus semua data di `SettingsScreen`, dan tinggi sentuh minimum `48dp` di `KChip`. | `lib/features/settings/about_screen.dart`, `lib/features/settings/settings_screen.dart`, `lib/app/widgets/k_chip.dart` | Seluruh target sentuh `KChip` aktif `>= 48dp`; reset data mengembalikan pengguna ke alur `/welcome`. | **S** |

---

## 4. Milestone Rilis & Rencana Rollback

- **Milestone `v1.1.1` (Target Eksekusi Tahap 2 & Tahap 3 Saat Ini)**:
  - Mencakup seluruh item **P0**, **P1**, serta perbaikan ringan **P2/P3** karena seluruh perubahan P2/P3 bersifat lokal dan berisiko sangat rendah (`S`).
- **Rencana Rollback**:
  - Seluruh perubahan Tahap 2 dilakukan di atas commit bersih `9489114`.
  - Apabila ditemukan regresi pada native splash atau launcher icon di perangkat tertentu, konfigurasi resource Android dapat dikembalikan melalui `git checkout HEAD -- android/app/src/main/res` tanpa memengaruhi skema database pengguna (`schemaVersion = 4` tetap kompatibel mundur).

---

## 5. Checklist Tindakan Manual Developer (Berurutan)

1. **Aktifkan Provider Google Sign-In di Firebase Console (Wajib untuk `A1`)**:
   - Buka [Firebase Console — Authentication Sign-in Method (`katara-melayu`)](https://console.firebase.google.com/project/katara-melayu/authentication/providers).
   - Klik **Google** -> aktifkan toggle **Enable** -> pilih email dukungan proyek (`akbarriansyah339@gmail.com`) -> klik **Save**.
   - Unduh ulang berkas `google-services.json` (atau beri tahu agen setelah toggle diaktifkan agar agen mengunduhnya otomatis via `firebase_get_sdk_config`) sehingga array `"oauth_client"` berisi `client_type: 1` (Android) dan `client_type: 3` (Web Client ID).
2. **Publikasi Aset Rilis `v1.1.1` di GitHub Releases (Untuk `A2`)**:
   - Catatan: Dengan perbaikan **P0-2** (multi-URL fallback ke `v1.1.0`), aplikasi sudah bisa mengunduh `module_langkat.zip` dan `module_palembang.zip` secara langsung dari rilis `v1.1.0` yang saat ini aktif (`HTTP 200`).
   - Saat mempublikasikan rilis `v1.1.1` di GitHub (`https://github.com/rynnxz/KATARA/releases/new?tag=v1.1.1`), unggah 4 berkas dari `dist/releases/v1.1.1/`:
     1. `katara-v1.1.1-release.apk`
     2. `module_catalog.json`
     3. `module_langkat.zip`
     4. `module_palembang.zip`

---

## 6. Pertanyaan Terbuka (Wajib Dikonfirmasi Sebelum Masuk Tahap 2)

Mohon konfirmasi Anda atas 3 poin berikut sebelum kami mengeksekusi perubahan kode di **Tahap 2**:

1. **Konfirmasi Item B3 ("Menghapus bagian vocal")**:
   - Apakah yang Anda maksud dengan menghapus bagian **"vocal"** adalah:
     - **Opsi A (Rekomendasi)**: Menghapus fitur/halaman **Panduan Lafal & Fonologi** (`/practice/pronunciation` yang berisi penjelasan *"Pelemahan Vokal Akhir [-a] menjadi [-e] / [-o]"*) beserta kartu menunya di halaman **Latihan**, tetapi **tetap mempertahankan** teks cara baca `[a.pə]` di dalam Kamus dan Perbandingan Dialek?
     - **Opsi B**: Menghapus halaman **Panduan Lafal & Fonologi** **sekaligus** menghapus seluruh teks cara baca `[...]` pada kartu Kamus dan Perbandingan Dialek?
2. **Konfirmasi Item A2 (Strategi Hosting Unduhan Modul)**:
   - Kami menemukan bahwa URL rilis `v1.1.0` di GitHub (`.../releases/download/v1.1.0/module_langkat.zip`) **sudah aktif (`HTTP 200 OK`)**, sedangkan `v1.1.1` mengembalikan `HTTP 404` karena tag `v1.1.1` belum dibuat di GitHub Releases.
   - Apakah Anda setuju kami mengimplementasikan **Multi-URL Fallback** (mencoba URL rilis terbaru `v1.1.1` terlebih dahulu, lalu otomatis fallback ke URL rilis `v1.1.0` yang sudah `HTTP 200` dengan verifikasi SHA-256 resmi) sehingga unduhan modul di ponsel Anda **langsung berhasil sekarang juga** tanpa harus menunggu pembuatan tag rilis baru di GitHub?
3. **Konfirmasi Item A1 (Aktivasi Google Sign-In di Firebase Console)**:
   - Apakah Anda ingin mengaktifkan toggle **Google** di [Firebase Console -> Authentication -> Sign-in method](https://console.firebase.google.com/project/katara-melayu/authentication/providers) sekarang (sehingga kami bisa langsung menarik `google-services.json` terbaru yang berisi `oauth_client` sebelum mem-build APK), atau lanjutkan implementasi kode Tahap 2 terlebih dahulu?
