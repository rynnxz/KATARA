# Laporan Audit Keamanan Menyeluruh & Runbook Insiden — KATARA (`v1.1.1`)

- **Aplikasi:** KATARA (`id.katara.app`)
- **Versi Audit:** `1.1.1+3`
- **Tanggal Audit:** 11 November 2026
- **Cakupan Audit:** Autentikasi (Firebase Auth & Google Sign-In), Aturan Keamanan Cloud Firestore (`firestore.rules`), Rantai Pasok Modul Bahasa Unduhan (`ModuleDownloadService` & `CatalogSignatureVerifier`), Penyimpanan Lokal SQLite (`AppDatabase` & `ContentSeeder`), Konfigurasi APK Android & R8 (`AndroidManifest.xml`, `build.gradle.kts`, `proguard-rules.pro`), serta Kebocoran Data Internal/UI.

---

## 1. Ringkasan Eksekutif & Matriks Temuan

Seluruh permukaan serangan aplikasi telah diaudit secara statis dan dinamis. Dari **12 temuan keamanan** (`SEC-001` s/d `SEC-012`), **11 temuan** (termasuk seluruh temuan *Critical*, *High*, dan *Medium*) telah **diperbaiki dan diverifikasi dengan pengujian otomatis (`fixed`)**, sementara **1 temuan risiko rendah (`SEC-009`)** didokumentasikan sebagai **risiko yang diterima (`accepted`)** beserta mitigasi kompensasi berlapis.

| ID | Judul Temuan | Severity | Komponen | Status | Bukti Pengujian |
| --- | --- | --- | --- | --- | --- |
| `SEC-001` | Katalog & Paket Modul ZIP Tanpa Tanda Tangan Asimetris (Risiko Supply-Chain / MITM) | **Critical** | `lib/services/module_download_service.dart`, `lib/services/catalog_signature_verifier.dart` | `fixed` | `test/module_security_test.dart` (#1) |
| `SEC-002` | Aturan Keamanan Firestore Longgar terhadap Field Tak Terdaftar & Nilai Negatif/Ekstrem | **High** | `firestore.rules` | `fixed` | `test/firestore_rules/firestore_rules_test.dart` (#1–#6) |
| `SEC-003` | Risiko Penimpaan Modul Bawaan (`ms-deli`) & Injeksi Lintas Kursus pada Ekstraksi ZIP | **High** | `lib/services/module_download_service.dart`, `lib/data/content/content_seeder.dart` | `fixed` | `test/module_security_test.dart` (#5) |
| `SEC-004` | Kerentanan Decompression Bomb (*Zip-Bomb*), *Zip-Slip*, & Berkas Non-JSON pada Unduhan Modul | **High** | `lib/services/module_download_service.dart` | `fixed` | `test/module_security_test.dart` (#3, #4) |
| `SEC-005` | Tidak Adanya Pembatasan Domain Unduhan (SSRF/Redirect ke Host Asing) & Proteksi Anti-Downgrade | **High** | `lib/services/module_download_service.dart` | `fixed` | `test/module_security_test.dart` (#2, #6) |
| `SEC-006` | Kegagalan Google Sign-In (`ApiException: 10`) & Kebocoran `PlatformException` Mentah ke UI | **Medium** | `android/app/build.gradle.kts`, `lib/services/auth_error_mapper.dart`, `lib/features/profile/profile_screen.dart` | `fixed` | `test/auth_error_mapper_test.dart` (#1–#6) |
| `SEC-007` | Tidak Adanya Fitur Penghapusan Akun & Data Cloud Mandiri (Kepatuhan UU PDP & Kebijakan Toko Aplikasi) | **Medium** | `lib/services/firebase_sync_service.dart`, `lib/features/profile/profile_screen.dart` | `fixed` | `test/firestore_rules/firestore_rules_test.dart` |
| `SEC-008` | `android:allowBackup` Aktif & Cleartext Traffic Tidak Diblokir Eksplisit di `AndroidManifest.xml` | **Medium** | `android/app/src/main/AndroidManifest.xml`, `res/xml/network_security_config.xml` | `fixed` | Inspeksi Manifest & Build Rilis |
| `SEC-009` | Database SQLite Lokal Disimpan Tanpa Enkripsi Blok (`SQLCipher`) | **Low** | `lib/data/db/app_database.dart` | `accepted` | Mitigasi PII Minimization + `allowBackup="false"` |
| `SEC-010` | Rute Internal `/dev/gallery` & Konfigurasi R8/Obfuscation Belum Diperketat untuk Build Rilis | **Low** | `lib/app/router.dart`, `android/app/build.gradle.kts`, `proguard-rules.pro` | `fixed` | Build APK Rilis Obfuscated |
| `SEC-011` | Kebocoran Catatan Audit Internal (`Hasil audit deli_cek (w009):`) ke Layar Pengguna | **Low** | `lib/data/content/content_models.dart`, `tool/build_content.dart` | `fixed` | `test/contrast_audit_test.dart` (#4) |
| `SEC-012` | Kebocoran Path Sistem File Lokal Developer (`file:///c:/lomba/...`) pada Dokumentasi Repo | **Info** | `docs/INSTALLATION_AND_CONFIG.md`, `docs/MODULE_STRUCTURE.md` | `fixed` | Pemeriksaan Statis `docs/*.md` |

---

## 2. Detail Temuan Keamanan (`SEC-001` s/d `SEC-012`)

### `SEC-001` — Katalog & Paket Modul ZIP Tanpa Tanda Tangan Asimetris
- **Severity:** `Critical`
- **Lokasi:** [`lib/services/catalog_signature_verifier.dart`](../lib/services/catalog_signature_verifier.dart), [`lib/services/module_download_service.dart`](../lib/services/module_download_service.dart) (`L166-L231`), [`tool/build_modules.dart`](../tool/build_modules.dart)
- **Skenario Serangan Konkret:**
  Jika penyerang berhasil memodifikasi berkas `module_catalog.json` (misalnya melalui cache CDN perantara atau kompromi aset rilis tanpa akses ke kunci privat pengembang), penyerang dapat mengganti baik `download_url` maupun nilai `sha256` secara bersamaan sehingga aplikasi mengunduh arsip ZIP berbahaya yang lolos pemeriksaan SHA-256 biasa.
- **Bukti / Safe PoC:**
  Pada versi `v1.1.0`, `module_catalog.json` hanya memuat hash `sha256` tanpa tanda tangan digital asimetris.
- **Rekomendasi & Perbaikan:**
  1. Mengimplementasikan verifikasi tanda tangan digital **Ed25519 (RFC 8032)** murni di [`CatalogSignatureVerifier`](../lib/services/catalog_signature_verifier.dart) dengan kunci publik tertanam di kode aplikasi (`57ee50c3b50ecc5775b50a45e6c2d67e3cb03a4a977be93caf156b88cd145466`).
  2. Menyimpan kunci privat (`seed` 32 byte) di `.keys/catalog_ed25519.seed` yang masuk daftar `.gitignore` (tidak pernah masuk ke bundel APK atau repositori publik).
  3. Menandatangani kanonikalisasi JSON (`catalog_version`, `min_app_version`, `revoked_modules`, dan daftar `modules`) saat menjalankan `dart run tool/build_modules.dart`.
- **Status:** `fixed` (Diverifikasi oleh `test/module_security_test.dart` tes #1).

---

### `SEC-002` — Aturan Keamanan Firestore Longgar terhadap Field Tak Terdaftar & Nilai Ekstrem
- **Severity:** `High`
- **Lokasi:** [`firestore.rules`](../firestore.rules) (`L1-L504`)
- **Skenario Serangan Konkret:**
  Pengguna yang terautentikasi (termasuk pengguna anonim) dapat memanggil REST API Firestore secara langsung menggunakan token ID mereka untuk:
  1. Menyuntikkan field sembarang berukuran besar (`payload_bloat`) ke dokumen `users/{uid}/xp_events/{id}` untuk menghabiskan kuota penyimpanan proyek Firebase.
  2. Menuliskan nilai `total_xp: 999999999` atau `delta_xp: -50000` atau `stars: 99` untuk merusak integritas papan peringkat/statistik.
- **Bukti / Safe PoC:**
  Pemeriksaan skema pada [`test/firestore_rules/firestore_rules_test.dart`](../test/firestore_rules/firestore_rules_test.dart).
- **Rekomendasi & Perbaikan:**
  Memperketat [`firestore.rules`](../firestore.rules) dengan fungsi bantu `hasOnlyAllowedFields(allowedList)`, batas ukuran string/list, rentang nilai ketat (`stars` `0..3`, `best_score` `0..100`, `delta_xp` `1..500`, `total_xp` `0..10000000`), isolasi kepemilikan `request.auth.uid == uid`, izin `allow delete: if isOwner(uid)` untuk penghapusan akun mandiri, serta `match /{document=**} { allow read, write: if false; }` di bagian akhir.
- **Status:** `fixed` (Diverifikasi dengan validator resmi Firebase MCP `OK: No errors detected` dan `test/firestore_rules/firestore_rules_test.dart`).

---

### `SEC-003` — Risiko Penimpaan Modul Bawaan (`ms-deli`) & Injeksi Lintas Kursus
- **Severity:** `High`
- **Lokasi:** [`lib/services/module_download_service.dart`](../lib/services/module_download_service.dart) (`L288-L298`, `L519-L625`), [`lib/data/content/content_seeder.dart`](../lib/data/content/content_seeder.dart) (`L173-L211`)
- **Skenario Serangan Konkret:**
  Paket modul pihak ketiga untuk `ms-langkat` dapat menyertakan baris di dalam `words.json` dengan `"id": "ms-deli:w:0001"` atau `"course_id": "ms-deli"`. Karena SQLite menggunakan `INSERT ... ON CONFLICT(id) DO UPDATE`, modul eksternal tersebut dapat merusak atau memalsukan kosakata modul inti bawaan **Melayu Deli (`ms-deli`)**.
- **Bukti / Safe PoC:**
  Pengujian injeksi `"id": "ms-deli:w:0001"` di dalam arsip `ms-langkat` pada `test/module_security_test.dart` (#5).
- **Rekomendasi & Perbaikan:**
  1. Menolak secara eksplisit setiap instalasi atau penghapusan modul dengan `courseId == 'ms-deli'`.
  2. Memvalidasi seluruh berkas JSON hasil ekstraksi di `ModuleDownloadService.validateExtractedModuleDirectory` dan `ContentSeeder.seedCourseFromDirectory` agar setiap elemen memiliki `course_id == targetCourseId` dan tidak ada `id` yang berawalan `ms-deli:`.
- **Status:** `fixed` (Diverifikasi oleh `test/module_security_test.dart` tes #5).

---

### `SEC-004` — Kerentanan Decompression Bomb (*Zip-Bomb*), *Zip-Slip*, & Berkas Non-JSON
- **Severity:** `High`
- **Lokasi:** [`lib/services/module_download_service.dart`](../lib/services/module_download_service.dart) (`L66-L91`, `L404-L515`)
- **Skenario Serangan Konkret:**
  Arsip ZIP berukuran kecil (mis. 100 KB) yang berisi karakter berulang dapat mengembang menjadi ratusan megabyte di memori/penyimpanan (*Out-of-Memory* / *Disk Exhaustion*), atau menyertakan nama berkas `../../lib/evil.so` (*Zip-Slip*) maupun skrip `.sh`.
- **Bukti / Safe PoC:**
  Pengujian payload rasio kompresi `> 30:1`, entri `../evil.json`, dan `evil.sh` pada `test/module_security_test.dart` (#3, #4).
- **Rekomendasi & Perbaikan:**
  1. Membatasi ukuran unduhan maksimum `25 MB`, ukuran satu berkas hasil ekstraksi `10 MB`, total ukuran ekstraksi `30 MB`, jumlah berkas maksimum `64`, dan rasio kompresi maksimum `30:1`.
  2. Menerapkan daftar putih ketat (`allowedArchiveFiles`) yang hanya mengizinkan berkas JSON tingkat atas (`manifest.json`, `words.json`, `phrases.json`, dll.).
  3. Memverifikasi `resolveSymbolicLinksSync()` agar setiap berkas hasil ekstraksi tetap berada di dalam direktori staging `.tmp`.
- **Status:** `fixed` (Diverifikasi oleh `test/module_security_test.dart` tes #3 & #4).

---

### `SEC-005` — Pembatasan Domain Unduhan (HTTPS Allowlist) & Proteksi Anti-Downgrade
- **Severity:** `High`
- **Lokasi:** [`lib/services/module_download_service.dart`](../lib/services/module_download_service.dart) (`L72-L76`, `L147-L163`, `L308-L316`)
- **Skenario Serangan Konkret:**
  Tanpa daftar putih host dan pemeriksaan versi, URL unduhan dapat diarahkan ke koneksi `http://` tidak terenkripsi atau server eksternal tidak resmi, serta penyerang dapat memaksa perangkat memasang versi modul lama (`version: 1`) yang sudah memiliki rujukan usang di atas modul baru (`version: 2`).
- **Bukti / Safe PoC:**
  Pengujian URL `http://` dan host `evil.example.com` serta downgrade `v2 -> v1` pada `test/module_security_test.dart` (#2, #6).
- **Rekomendasi & Perbaikan:**
  1. Mewajibkan skema `https` dan membatasi host hanya pada `github.com`, `objects.githubusercontent.com`, dan `release-assets.githubusercontent.com`.
  2. Menambahkan proteksi anti-downgrade (`item.version < existing.version`) serta mekanisme pencabutan modul (`revoked_modules` kill-switch).
- **Status:** `fixed` (Diverifikasi oleh `test/module_security_test.dart` tes #2 & #6).

---

### `SEC-006` — Kegagalan Google Sign-In (`ApiException: 10`) & Kebocoran Exception Mentah
- **Severity:** `Medium`
- **Lokasi:** [`android/app/build.gradle.kts`](../android/app/build.gradle.kts), [`lib/services/auth_error_mapper.dart`](../lib/services/auth_error_mapper.dart), [`lib/features/profile/profile_screen.dart`](../lib/features/profile/profile_screen.dart)
- **Skenario Serangan / Masalah:**
  Ketidakcocokan SHA-1 keystore dengan proyek Firebase menyebabkan `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)` yang ditampilkan mentah-mentah ke pengguna di `ProfileScreen`, membocorkan detail paket internal Google Play Services.
- **Rekomendasi & Perbaikan:**
  1. Mendaftarkan SHA-1 & SHA-256 sertifikat debug/release ke proyek Firebase `katara-melayu` dan mengaktifkan plugin `com.google.gms.google-services`.
  2. Memetakan seluruh galat autentikasi melalui [`AuthErrorMapper`](../lib/services/auth_error_mapper.dart) menjadi pesan bahasa Indonesia yang ramah pengguna dan menyembunyikan detail teknis di balik `kDebugMode`.
- **Status:** `fixed` (Diverifikasi oleh `test/auth_error_mapper_test.dart`).

---

### `SEC-007` — Penghapusan Akun & Data Cloud Mandiri (Hak untuk Dilupakan / UU PDP)
- **Severity:** `Medium`
- **Lokasi:** [`lib/services/firebase_sync_service.dart`](../lib/services/firebase_sync_service.dart), [`lib/features/profile/profile_screen.dart`](../lib/features/profile/profile_screen.dart)
- **Skenario Masalah:**
  Pengguna yang telah masuk dengan akun Google membutuhkan mekanisme transparan di dalam aplikasi untuk menghapus seluruh data progres di Cloud Firestore beserta akun Firebase Auth mereka tanpa merusak kemampuan belajar offline sebagai Tamu.
- **Rekomendasi & Perbaikan:**
  Menambahkan metode `deleteAccountAndCloudData()` di `FirebaseSyncService` dan tombol **Hapus Akun & Data Cloud** dengan dialog konfirmasi ganda di `ProfileScreen`.
- **Status:** `fixed`.

---

### `SEC-008` — Pengerasan `AndroidManifest.xml` (`allowBackup="false"`, `usesCleartextTraffic="false"`)
- **Severity:** `Medium`
- **Lokasi:** [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml), [`android/app/src/main/res/xml/network_security_config.xml`](../android/app/src/main/res/xml/network_security_config.xml)
- **Skenario Serangan Konkret:**
  Jika `android:allowBackup` tidak dimatikan secara eksplisit, seseorang dengan akses fisik sementara ke perangkat dengan USB debugging aktif dapat menjalankan `adb backup id.katara.app` untuk mengekstrak basis data SQLite dan preferensi lokal. Selain itu, lalu lintas HTTP cleartext harus ditolak di tingkat OS Android.
- **Rekomendasi & Perbaikan:**
  Menetapkan `android:allowBackup="false"`, `android:fullBackupContent="false"`, `android:usesCleartextTraffic="false"`, dan `@xml/network_security_config` dengan `cleartextTrafficPermitted="false"`.
- **Status:** `fixed`.

---

### `SEC-009` — Database SQLite Lokal Disimpan Tanpa Enkripsi Blok (`SQLCipher`)
- **Severity:** `Low`
- **Lokasi:** [`lib/data/db/app_database.dart`](../lib/data/db/app_database.dart)
- **Skenario Serangan Konkret:**
  Pada perangkat Android yang telah di-*root* atau dikompromikan secara fisik, berkas SQLite di direktori sandbox aplikasi (`/data/data/id.katara.app/ databases/`) dapat dibaca oleh proses berhak akses `root`.
- **Alasan Penerimaan Risiko & Mitigasi Kompensasi:**
  Sesuai keputusan arsitektur (`A2`), penambahan `sqlcipher_flutter_libs` akan menambah ukuran biner native sekitar `~4–6 MB` pada APK utama, sedangkan tabel lokal SQLite hanya berisi kosakata publik dan statistik progres belajar (XP, streak, bintang).
  Mitigasi kompensasi yang diterapkan:
  1. **PII Minimization:** Tidak menyimpan token akses OAuth, kata sandi, alamat rumah, atau nomor telepon di dalam SQLite lokal.
  2. **Isolasi Backup ADB:** `android:allowBackup="false"` dan `android:fullBackupContent="false"` mencegah ekstraksi database via `adb backup` pada perangkat non-root.
- **Status:** `accepted`.

---

### `SEC-010` — Pembatasan Rute `/dev/gallery` & Obfuscation Rilis R8
- **Severity:** `Low`
- **Lokasi:** [`lib/app/router.dart`](../lib/app/router.dart) (`L33-L38`, `L143-L147`), [`android/app/build.gradle.kts`](../android/app/build.gradle.kts), [`android/app/proguard-rules.pro`](../android/app/proguard-rules.pro)
- **Skenario Serangan Konkret:**
  Rute pengembangan `/dev/gallery` tidak boleh dapat diakses pada APK rilis, dan simbol kelas Dart/Java harus dikaburkan (*obfuscated*) agar mempersulit rekayasa balik (*reverse engineering*).
- **Rekomendasi & Perbaikan:**
  1. Membatasi pendaftaran rute `/dev/gallery` dengan `if (kDebugMode)` serta menambahkan `redirect` yang mengarahkan `/dev/*` ke `/home/learn` bila `!kDebugMode`.
  2. Mengaktifkan `isMinifyEnabled = true` dan `isShrinkResources = true` di `build.gradle.kts` serta membangun APK rilis dengan `--obfuscate --split-debug-info=build/symbols`.
- **Status:** `fixed`.

---

### `SEC-011` — Kebocoran Catatan Audit Internal (`Hasil audit deli_cek`) ke UI Pengguna
- **Severity:** `Low`
- **Lokasi:** [`lib/data/content/content_models.dart`](../lib/data/content/content_models.dart) (`L198-L209`), [`tool/build_content.dart`](../tool/build_content.dart)
- **Skenario Masalah:**
  Catatan kerja kurator (`Hasil audit deli_cek (w009): ...`) muncul pada kartu `Kenalan Kata Baru` dan lembar detail kamus.
- **Rekomendasi & Perbaikan:**
  Menambahkan filter sanitasi `WordModel.sanitizeUserNotes` dan membersihkan pipeline `tool/build_content.dart`.
- **Status:** `fixed` (Diverifikasi oleh `test/contrast_audit_test.dart` tes #4).

---

### `SEC-012` — Kebocoran Path Lokal Developer (`file:///c:/lomba/...`) di Dokumentasi
- **Severity:** `Info`
- **Lokasi:** [`docs/INSTALLATION_AND_CONFIG.md`](../docs/INSTALLATION_AND_CONFIG.md), [`docs/MODULE_STRUCTURE.md`](../docs/MODULE_STRUCTURE.md)
- **Skenario Masalah:**
  Tautan markdown di dalam dokumentasi repositori mencantumkan path absolut mesin lokal pengembang (`file:///c:/lomba/Budaya%20Go%202026/KATARA/...`).
- **Rekomendasi & Perbaikan:**
  Mengganti seluruh tautan `file:///c:/lomba/...` pada `docs/*.md` menjadi tautan relatif repositori (`../...`).
- **Status:** `fixed`.

---

## 3. Runbook Tanggap Insiden Operasional (Incident Response Runbooks)

Bagian ini memuat prosedur operasional standar (SOP) langkah demi langkah untuk menangani 10 skenario insiden keamanan dan keandalan di lingkungan produksi.

---

### Runbook 1 — Kompromi Firebase API Key / Penyalahgunaan Kuota
- **Gejala / Indikator Deteksi:**
  Lonjakan tidak wajar pada metrik pembacaan/penulisan Cloud Firestore atau pembuatan akun Firebase Authentication di Google Cloud Console / Firebase Usage Dashboard.
- **Langkah Isolasi Darurat (< 15 Menit):**
  1. Buka **Google Cloud Console -> APIs & Services -> Credentials** untuk proyek `katara-melayu`.
  2. Pilih kunci API Android yang terdampak, lalu pastikan **Application restrictions** terkunci ke **Android apps** dengan paket `id.katara.app` dan sidik jari SHA-1 resmi (`FD:30:99:39:F8:49:0E:C3:E1:56:AC:61:57:46:7F:78:A1:0C:6D:6F`).
  3. Batasi **API restrictions** hanya pada layanan yang dibutuhkan: *Identity Toolkit API*, *Token Service API*, *Cloud Firestore API*, dan *Firebase Installations API*.
  4. Di **Firebase Console -> Authentication -> Settings -> User actions**, turunkan batas kuota pendaftaran IP per jam.
- **Langkah Pemulihan & Perbaikan:**
  1. Aktifkan penegakan **Firebase App Check** dengan penyedia **Play Integrity** untuk aplikasi Android `id.katara.app`.
  2. Jika kunci API perlu dirotasi, buat kunci baru dengan batasan SHA-1 yang sama, unduh `google-services.json` baru, perbarui `lib/firebase_options.dart`, dan rilis pembaruan APK.
- **Langkah Verifikasi Pasca-Insiden:**
  Pastikan permintaan REST API tanpa header sertifikat Android (`X-Android-Package` & `X-Android-Cert`) ditolak dengan kode `403 PERMISSION_DENIED`.

---

### Runbook 2 — Kebocoran Keystore Rilis Android (`.jks`)
- **Gejala / Indikator Deteksi:**
  Berkas `.jks` / `.keystore` atau sandi `key.properties` tidak sengaja terekspos di repositori publik, perangkat pengembang hilang, atau terdeteksi APK pihak ketiga yang ditandatangani dengan sertifikat yang sama.
- **Langkah Isolasi Darurat (< 15 Menit):**
  1. **Segera hapus sidik jari SHA-1 dan SHA-256 keystore yang bocor** dari **Firebase Console -> Project Settings -> Your apps (`id.katara.app`)** agar APK bajakan tidak dapat menggunakan Google Sign-In maupun Firebase App Check.
  2. Cabut dan ganti semua GitHub Actions Secrets (`ANDROID_KEYSTORE_BASE64`, `KEY_PASSWORD`, `STORE_PASSWORD`).
- **Langkah Pemulihan & Perbaikan:**
  1. Buat keystore rilis baru (`.jks` RSA 4096-bit) di mesin lokal yang bersih (di luar direktori git):
     ```powershell
     keytool -genkeypair -v -keystore katara-release-new.jks -keyalg RSA -keysize 4096 -validity 10000 -alias katara_release
     ```
  2. Jika menggunakan Google Play App Signing, ajukan **Upload Key Reset** di Google Play Console dengan menyertakan sertifikat `.pem` dari keystore baru.
  3. Daftarkan SHA-1 dan SHA-256 keystore baru ke proyek Firebase `katara-melayu` dan unduh `google-services.json` terbaru.
  4. Jika berkas `.jks` sempat masuk ke riwayat Git, bersihkan riwayat menggunakan `git filter-repo --path <file.jks> --invert-paths` dan minta dukungan GitHub untuk membersihkan cache objek.
- **Langkah Verifikasi Pasca-Insiden:**
  Pastikan `keytool -printcert -jarfile dist/releases/v1.1.1/katara-v1.1.1-release.apk` menampilkan SHA-256 sertifikat baru dan login Google berfungsi normal.

---

### Runbook 3 — Modul ZIP Berbahaya / Katalog Modul Terkompromi di GitHub Release
- **Gejala / Indikator Deteksi:**
  Aset `module_langkat.zip` atau `module_palembang.zip` pada GitHub Releases rusak/termodifikasi, atau ditemukan cacat serius pada paket modul tertentu yang menyebabkan aplikasi gagal memuat pelajaran.
- **Langkah Isolasi Darurat (< 15 Menit):**
  1. Aktifkan **Kill-Switch Modul** dengan menambahkan ID modul terdampak (mis. `"ms-langkat"`) ke array `"revoked_modules"` pada `module_catalog.json`.
  2. Tandatangani ulang `module_catalog.json` dengan kunci privat Ed25519 (`.keys/catalog_ed25519.seed`) dan unggah ke aset rilis GitHub.
  3. Hapus berkas ZIP yang bermasalah dari halaman GitHub Releases.
- **Langkah Pemulihan & Perbaikan:**
  1. Bangun ulang paket modul yang bersih dari korpus terkurasi:
     ```powershell
     dart run tool/build_modules.dart
     ```
  2. Kosongkan kembali `"revoked_modules": []`, tandatangani `module_catalog.json` dengan Ed25519, dan unggah ulang arsip ZIP beserta `module_catalog.json` ke GitHub Releases.
- **Langkah Verifikasi Pasca-Insiden:**
  Jalankan `flutter test test/module_security_test.dart` untuk memastikan tanda tangan Ed25519 dan hash SHA-256 katalog baru terverifikasi `true`.

---

### Runbook 4 — Eksploitasi Firestore Rules / Serangan Penulisan Massal (Spam/DoS)
- **Gejala / Indikator Deteksi:**
  Peringatan penagihan/kuota harian Firestore meningkat drastis atau muncul ribuan dokumen kecil dari satu `uid` dalam waktu singkat.
- **Langkah Isolasi Darurat (< 15 Menit):**
  1. Identifikasi `uid` penyerang dari log **Firebase Console -> Authentication / Firestore Usage**.
  2. Nonaktifkan (`Disable`) atau hapus `uid` tersebut di **Firebase Authentication**.
  3. Jika serangan berlangsung masif dari banyak akun anonim, terapkan aturan darurat sementara (mode baca-saja) melalui CLI:
     ```powershell
     npx firebase-tools deploy --only firestore:rules --project katara-melayu
     ```
- **Langkah Pemulihan & Perbaikan:**
  1. Perketat validasi skema atau batasan ukuran pada [`firestore.rules`](../firestore.rules).
  2. Jalankan pengujian kontrak aturan keamanan:
     ```powershell
     flutter test test/firestore_rules/firestore_rules_test.dart
     ```
  3. Terapkan kembali `firestore.rules` yang telah diperbarui ke produksi.
- **Langkah Verifikasi Pasca-Insiden:**
  Pantau grafik *Firestore Operations* selama 24 jam dan pastikan sinkronisasi pengguna normal kembali berjalan tanpa penolakan palsu.

---

### Runbook 5 — Kompromi Akun GitHub Maintainer / Supply-Chain Attack pada Repo
- **Gejala / Indikator Deteksi:**
  Commit, tag rilis, atau perubahan workflow `.github/workflows/` yang tidak dikenal muncul di repositori `rynnxz/KATARA`.
- **Langkah Isolasi Darurat (< 15 Menit):**
  1. Cabut seluruh sesi aktif, Personal Access Token (PAT), dan SSH key pada akun GitHub yang terdampak; aktifkan ulang 2FA perangkat keras/TOTP.
  2. Nonaktifkan sementara GitHub Actions pada repositori (**Settings -> Actions -> General -> Disable actions**).
  3. Hapus rilis atau tag GitHub yang dibuat oleh penyerang.
- **Langkah Pemulihan & Perbaikan:**
  1. Audit seluruh commit menggunakan `git log --show-signature` dan bandingkan dengan salinan lokal yang tepercaya.
  2. Pastikan `.github/workflows/ci_security_release.yml` hanya menggunakan commit SHA tersemat (*pinned SHA*) untuk setiap action pihak ketiga.
  3. Rotasi kunci privat penandatanganan katalog (`.keys/catalog_ed25519.seed`) dan keystore Android jika sempat tersimpan di GitHub Secrets.
- **Langkah Verifikasi Pasca-Insiden:**
  Jalankan `flutter analyze` dan `flutter test` secara penuh pada cabang `main` yang telah dipulihkan.

---

### Runbook 6 — Kerentanan Zero-Day pada Dependensi Pihak Ketiga (`pubspec.lock` / Gradle)
- **Gejala / Indikator Deteksi:**
  Notifikasi keamanan dari OSV-Scanner, GitHub Dependabot, atau pengumuman CVE pada paket Dart (`archive`, `http`, `drift`, `firebase_*`) atau pustaka Android Gradle.
- **Langkah Isolasi Darurat (< 15 Menit):**
  1. Periksa apakah fungsi yang rentan dipanggil secara langsung oleh KATARA (mis. `ZipDecoder` di `ModuleDownloadService`).
  2. Jika kerentanan berada pada jalur unduhan modul, aktifkan sementara pembatasan melalui `module_catalog.json` (`min_app_version` dinaikkan ke versi tambalan).
- **Langkah Pemulihan & Perbaikan:**
  1. Perbarui paket terdampak ke versi aman:
     ```powershell
     flutter pub upgrade --major-versions <nama_paket>
     ```
  2. Jalankan seluruh pengujian regresi dan keamanan (`flutter test`) serta bangun ulang APK rilis dengan `--obfuscate`.
- **Langkah Verifikasi Pasca-Insiden:**
  Pastikan pemindaian `osv-scanner --lockfile=pubspec.lock` melaporkan `0` kerentanan terbuka.

---

### Runbook 7 — Kegagalan Migrasi Database SQLite di Perangkat Pengguna (Crash Loop Saat Update)
- **Gejala / Indikator Deteksi:**
  Pengguna melaporkan pesan *"Gagal menyiapkan basis data lokal"* di `SplashScreen` setelah memperbarui aplikasi dari versi lama.
- **Langkah Isolasi Darurat (< 15 Menit):**
  1. Tarik sementara APK rilis baru dari halaman unduhan utama dan arahkan tautan rilis ke versi stabil sebelumnya.
  2. Reproduksi skema database versi lama pada `test/migrations/schema_migration_test.dart`.
- **Langkah Pemulihan & Perbaikan:**
  1. Pastikan setiap pernyataan `ALTER TABLE` dan `CREATE TABLE IF NOT EXISTS` di `AppDatabase._migrateV1ToV2` memeriksa keberadaan kolom terlebih dahulu عبر `PRAGMA table_info(...)` sehingga bersifat 100% idempoten.
  2. Jangan pernah menghapus tabel progres (`user_stats`, `course_progress`, `word_mastery`); gunakan transaksi aman.
  3. Tambahkan kasus uji regresi pada `test/migrations/schema_migration_test.dart` dan rilis versi patch baru.
- **Langkah Verifikasi Pasca-Insiden:**
  Jalankan `flutter test test/migrations/schema_migration_test.dart` dan pastikan seluruh data pengguna `v1` tetap utuh setelah migrasi ke `v2`.

---

### Runbook 8 — Laporan Konten Bahasa/Budaya Sensitif atau Salah secara Kultural
- **Gejala / Indikator Deteksi:**
  Laporan masyarakat, penutur jati, atau akademisi Balai Bahasa mengenai kesalahan arti, ejaan Jawi, tingkat tutur (*register*), atau deskripsi adat pada salah satu dialek.
- **Langkah Isolasi Darurat (< 15 Menit):**
  1. Jika kesalahan berada pada modul unduhan (`ms-langkat` / `ms-palembang`) dan bersifat kritis, perbarui paket ZIP modul dan naikkan `content_version` di `module_catalog.json`.
  2. Tandai entri yang sedang ditinjau dengan `"needs_verification": true` atau `"validation_status": "draft"` agar segera disaring dari sesi latihan normal (`ExerciseGenerator` secara otomatis melewati item yang membutuhkan verifikasi).
- **Langkah Pemulihan & Perbaikan:**
  1. Perbaiki entri pada korpus kurasi (`melayu-*-dataset/curated/*_master.json`) dengan merujuk pada kamus resmi Balai Bahasa atau informan penutur jati (**tanpa mengubah folder `konten/`** yang bersifat *read-only*).
  2. Jalankan kembali pipeline kompilasi:
     ```powershell
     dart run tool/build_dialect_datasets.dart
     dart run tool/build_content.dart
     dart run tool/build_modules.dart
     ```
- **Langkah Verifikasi Pasca-Insiden:**
  Jalankan `flutter test test/dataset_integrity_test.dart` untuk memverifikasi keutuhan sitasi dan label validasi.

---

### Runbook 9 — Permintaan Penghapusan Data Pengguna (UU PDP / Hak untuk Dilupakan)
- **Gejala / Indikator Deteksi:**
  Pengguna menekan tombol **Hapus Akun & Data Cloud** di aplikasi, atau mengirimkan permintaan penghapusan data melalui email dukungan resmi (`akbarriansyah339@gmail.com`).
- **Langkah Penanganan Mandiri (Di Dalam Aplikasi):**
  1. Pengguna membuka **Profil -> Hapus Akun & Data Cloud** dan menyetujui dialog konfirmasi.
  2. `FirebaseSyncService.deleteAccountAndCloudData()` menghapus seluruh sub-koleksi (`course_progress`, `word_mastery`, `xp_events`, `streak_history`, `installed_modules`) dan dokumen induk `users/{uid}` di Cloud Firestore, menghapus akun Firebase Auth (`user.delete()`), serta membersihkan tabel `user_profiles` dan `sync_queue` lokal.
- **Langkah Penanganan Manual (Melalui Email Dukungan, SLA <= 7 Hari Kerja):**
  1. Verifikasi kepemilikan alamat email pemohon.
  2. Cari `uid` pengguna di **Firebase Console -> Authentication**.
  3. Hapus dokumen `users/{uid}` beserta seluruh sub-koleksinya di **Cloud Firestore**, lalu hapus akun di **Firebase Authentication**.
- **Langkah Verifikasi Pasca-Insiden:**
  Pastikan kueri `users/{uid}` di Cloud Firestore mengembalikan *non-existent* dan `uid` tidak lagi terdaftar di Firebase Auth.

---

### Runbook 10 — Google Sign-In Tiba-Tiba Gagal di Produksi setelah Update APK / Play Store
- **Gejala / Indikator Deteksi:**
  Pengguna melaporkan pesan *"Konfigurasi login Google belum sesuai untuk build aplikasi ini (Kode 10)"* setelah mengunduh APK rilis baru atau menginstal dari Google Play Store.
- **Langkah Isolasi Darurat (< 15 Menit):**
  1. Periksa sertifikat penandatangan pada APK yang didistribusikan:
     ```powershell
     keytool -printcert -jarfile dist/releases/v1.1.1/katara-v1.1.1-release.apk
     ```
  2. Jika aplikasi didistribusikan melalui Google Play Store dengan **Play App Signing**, buka **Google Play Console -> Setup -> App signing** dan salin **SHA-1** serta **SHA-256** dari **App signing key certificate** (bukan hanya *Upload key certificate*).
- **Langkah Pemulihan & Perbaikan:**
  1. Tambahkan SHA-1 dan SHA-256 tersebut ke **Firebase Console -> Project Settings -> Your apps (`id.katara.app`) -> Add fingerprint** (atau gunakan alat MCP `firebase_create_android_sha`).
  2. Penambahan SHA-1 di sisi server Firebase berlaku seketika untuk klien OAuth Google Play Services bahkan tanpa perlu memaksa pengguna menginstal ulang APK, namun tetap unduh `google-services.json` terbaru untuk rilis berikutnya.
- **Langkah Verifikasi Pasca-Insiden:**
  Uji tombol **Masuk dengan Google** pada APK produksi dan pastikan profil Google beserta sinkronisasi awan langsung aktif tanpa galat.
