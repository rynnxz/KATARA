# Diagnosis Kegagalan Unduh Modul (`v1.1.0` / `v1.1.1`)

## 1. Gejala di Perangkat Pengguna

Setelah autentikasi Google Sign-In diperbaiki pada rilis `v1.1.1`, pengguna mencoba mengunduh modul **Melayu Palembang** (`ms-palembang`) dari layar **Pilih Daerah & Modul Melayu** (`RegionPickerScreen`).

- Unduhan **tidak** lagi gagal dengan `HTTP 404`.
- Unduhan berhenti setelah progres mencapai tahap verifikasi dengan pesan:
  > `"Berkas unduhan modul Melayu Palembang tidak utuh karena gangguan jaringan. Silakan ketuk Coba Lagi."`
- Mengetuk **Coba Lagi** berulang kali menghasilkan pesan galat yang sama meskipun koneksi internet perangkat stabil.

---

## 2. Tabel Perbandingan Bukti (`Katalog-APK` vs `Katalog-Rilis` vs `ZIP-Lokal` vs `ZIP-Rilis`)

Data berikut diambil langsung dari pemeriksaan berkas lokal repositori dan aset publik di GitHub Release `v1.1.0` (`https://github.com/rynnxz/KATARA/releases/tag/v1.1.0`) menggunakan `gh release view` dan `Get-FileHash -Algorithm SHA256`:

### A. Modul Melayu Langkat (`ms-langkat` / `module_langkat.zip`)

| Sumber Data | URL / Lokasi Berkas | `size_bytes` | `sha256` | Status |
| :--- | :--- | ---: | :--- | :--- |
| **Katalog Bundled APK** (`assets/content/module_catalog.json` & `courses.json`) | `.../releases/download/v1.1.1/module_langkat.zip` | `82277` | `d36f24b2679ccc22b1326f58180f0c7b56e1c77ff7537c7030612950fc3bdb4b` | Tag `v1.1.1` belum dipublikasikan (`HTTP 404`) |
| **ZIP Lokal Workspace** (`dist/releases/v1.1.0/` & `v1.1.1/module_langkat.zip`) | Berkas lokal hasil build terakhir | `82277` | `d36f24b2679ccc22b1326f58180f0c7b56e1c77ff7537c7030612950fc3bdb4b` | Tertimpa ulang saat `build_modules.dart` dijalankan |
| **Pin Fallback di Kode** (`ModuleDownloadService.trustedFallbackReleases`) | `.../releases/download/v1.1.0/module_langkat.zip` | - | `b9c2aaa268ad3e0b9eb1b75c4bf71fff7932c17fd20c8b018f530a985559cdb0` | Hash usang dari `docs/DEPLOYMENT_AND_RELEASES.md` |
| **Katalog Rilis GitHub `v1.1.0`** (`module_catalog.json` di GitHub Release) | `.../releases/download/v1.1.0/module_catalog.json` | `82273` | `14d67a18958686b4af5462eb69493ebe767ae5c817628ca9b0548e205b282eb7` | **Tidak memiliki `signature_ed25519`** |
| **ZIP Rilis GitHub `v1.1.0`** (`module_langkat.zip` di GitHub Release) | `.../releases/download/v1.1.0/module_langkat.zip` | `82273` | `14d67a18958686b4af5462eb69493ebe767ae5c817628ca9b0548e205b282eb7` | **Berkas aktual yang diunduh oleh perangkat (`HTTP 200`)** |

### B. Modul Melayu Palembang (`ms-palembang` / `module_palembang.zip`)

| Sumber Data | URL / Lokasi Berkas | `size_bytes` | `sha256` | Status |
| :--- | :--- | ---: | :--- | :--- |
| **Katalog Bundled APK** (`assets/content/module_catalog.json` & `courses.json`) | `.../releases/download/v1.1.1/module_palembang.zip` | `84247` | `1ab88a4fb291fd8d279a9432e7cb5284127fa2bdc052885b1131611ce56c6a25` | Tag `v1.1.1` belum dipublikasikan (`HTTP 404`) |
| **ZIP Lokal Workspace** (`dist/releases/v1.1.0/` & `v1.1.1/module_palembang.zip`) | Berkas lokal hasil build terakhir | `84247` | `1ab88a4fb291fd8d279a9432e7cb5284127fa2bdc052885b1131611ce56c6a25` | Tertimpa ulang saat `build_modules.dart` dijalankan |
| **Pin Fallback di Kode** (`ModuleDownloadService.trustedFallbackReleases`) | `.../releases/download/v1.1.0/module_palembang.zip` | - | `16185eb07de40d307eaeea7cdb1f07aad270093cac0d4c19c62e083052956497` | Hash usang dari `docs/DEPLOYMENT_AND_RELEASES.md` |
| **Katalog Rilis GitHub `v1.1.0`** (`module_catalog.json` di GitHub Release) | `.../releases/download/v1.1.0/module_catalog.json` | `84219` | `e722ece7be49798a10306363569701bebb34ca9e041c6a0f712b692c575df680` | **Tidak memiliki `signature_ed25519`** |
| **ZIP Rilis GitHub `v1.1.0`** (`module_palembang.zip` di GitHub Release) | `.../releases/download/v1.1.0/module_palembang.zip` | `84219` | `e722ece7be49798a10306363569701bebb34ca9e041c6a0f712b692c575df680` | **Berkas aktual yang diunduh oleh perangkat (`HTTP 200`)** |

---

## 3. Urutan Kejadian di Kode (`Root Cause Trace`)

1. **Non-Determinisme Pembuatan Arsip ZIP (`tool/build_modules.dart` baris 664-671):**
   - `ArchiveFile(entry.key, jsonBytes.length, jsonBytes)` pada paket `archive` secara bawaan mengisi `lastModTime = DateTime.now().millisecondsSinceEpoch ~/ 1000`.
   - Setiap kali `dart run tool/build_modules.dart` dijalankan, header waktu DOS di dalam ZIP berubah sehingga menghasilkan digest SHA-256 yang berbeda walaupun isi JSON tidak berubah.
   - Selain itu, skrip menulis ulang `dist/releases/v1.1.0/*.zip` dan `dist/releases/v1.1.1/*.zip` secara bersamaan, sehingga berkas lokal `v1.1.0` tidak lagi identik dengan aset yang sudah terunggah di GitHub Release `v1.1.0`.

2. **Jatuhnya Unduhan ke URL Fallback dengan Hash Usang (`lib/services/module_download_service.dart` baris 769-799):**
   - Katalog bawaan di dalam APK menunjuk ke `https://github.com/rynnxz/KATARA/releases/download/v1.1.1/module_palembang.zip`.
   - Karena rilis GitHub `v1.1.1` belum dibuat, GitHub mengembalikan `HTTP 404`.
   - `_fetchModuleBytesWithFallback` menangkap `HTTP 404` dan beralih ke `trustedFallbackReleases['ms-palembang']` yang mengunduh `https://github.com/rynnxz/KATARA/releases/download/v1.1.0/module_palembang.zip` (`HTTP 200 OK`, `84219` byte, SHA-256 aktual `e722ece7be49798a10306363569701bebb34ca9e041c6a0f712b692c575df680`).
   - Akan tetapi, `trustedFallbackReleases['ms-palembang'].sha256` berisi nilai lama dari `docs/DEPLOYMENT_AND_RELEASES.md` (`16185eb07de40d307eaeea7cdb1f07aad270093cac0d4c19c62e083052956497`), bukan hash aset rilis GitHub `v1.1.0` yang sebenarnya (`e722ece7...`).

3. **Kegagalan Verifikasi SHA-256 (`lib/services/module_download_service.dart` baris 517-522):**
   - `verifyAndExtractArchive` menghitung `sha256.convert(zipBytes)` (`e722ece7...`) dan membandingkannya dengan `expectedSha256` (`16185eb0...`).
   - Karena tidak cocok, fungsi melempar:
     `ModuleDownloadException('Checksum SHA-256 modul tidak cocok (diharapkan 16185eb0..., diterima e722ece7...).')`

4. **Pemetaan Pesan Galat yang Menyesatkan (`lib/services/module_download_service.dart` baris 56-60):**
   - `ModuleDownloadErrorMapper.toUserMessage` memeriksa:
     ```dart
     if (raw.contains('sha-256') || raw.contains('checksum') || raw.contains('rusak')) {
       return 'Berkas unduhan $target tidak utuh karena gangguan jaringan. Silakan ketuk Coba Lagi.';
     }
     ```
   - Akibatnya, ketidakcocokan SHA-256 antara katalog dan aset rilis dilaporkan kepada pengguna seolah-olah terjadi gangguan jaringan.

---

## 4. Rencana Perbaikan Menyeluruh

1. **Builder ZIP Deterministik (`tool/build_modules.dart`):**
   - Mengurutkan nama berkas di dalam arsip secara leksikografis.
   - Menetapkan `lastModTime` tetap (`2026-01-01T00:00:00Z` / epoch `1767225600`), izin berkas tetap (`0644`), `ownerId = 0`, `groupId = 0`, dan tingkat kompresi tetap (`DeflateLevel.defaultCompression`).
2. **Satu Sumber Kebenaran & Skrip Verifikasi Rilis (`tool/verify_release.dart`):**
   - Menghitung `sha256` dan `size_bytes` langsung dari berkas ZIP final.
   - Menyediakan `tool/verify_release.dart` yang memverifikasi kesesuaian byte dan SHA-256 antara `assets/content/module_catalog.json`, `assets/content/courses.json`, `dist/releases/*/module_catalog.json`, dan `dist/releases/*/module_*.zip`, serta memvalidasi tanda tangan digital Ed25519.
3. **Sinkronisasi Katalog Remote Bertanda Tangan Ed25519 (`ModuleDownloadService`):**
   - Mengunduh `module_catalog.json` terbaru dari GitHub Releases terlebih dahulu, memverifikasi tanda tangan Ed25519 (`CatalogSignatureVerifier.verifyCatalog`) dan proteksi anti-downgrade (`catalog_version`), lalu menggunakannya sebagai sumber kebenaran `download_url`, `sha256`, dan `size_bytes`. Jika perangkat luring atau gagal mengambil katalog remote, aplikasi jatuh kembali ke katalog lokal/bundled.
4. **Klasifikasi Galat yang Jujur & Pembatasan Retry (`ModuleDownloadErrorMapper` & `RegionPickerScreen`):**
   - Memisahkan galat jaringan (`networkDisconnected`, `timeout`), server (`serverUnavailable`), ukuran berkas tidak lengkap (`incompleteFile`), dan kegagalan verifikasi keamanan SHA-256 (`securityVerificationFailed`).
   - Membatasi percobaan ulang pada galat verifikasi keamanan maksimal 2 kali sebelum mengarahkan pengguna memperbarui aplikasi.

---

## 5. Hasil Build Deterministik & Paritas Katalog (`Setelah Perbaikan`)

Setelah `tool/build_modules.dart` diperbaiki dengan epoch tetap (`1767225600` / `2026-01-01T00:00:00Z`), urutan berkas terurut leksikografis, dan kanonikalisasi JSON, pengujian dua kali berturut-turut menghasilkan digest SHA-256 yang 100% identik:

| Berkas | Ukuran Deterministik (`size_bytes`) | SHA-256 Deterministik |
| :--- | ---: | :--- |
| `module_langkat.zip` | `71391` | `3ed866afaeb72c1354d4927e651ca9c7fd1e4adf21d6810e462dacbb58562f6f` |
| `module_palembang.zip` | `74307` | `f75c27e1f28c06bece0cfe5a6deea6f40d40457b614a986d431dde22cabc2095` |
| `module_catalog.json` | `2302` | `12e574ae6e244916562a4ec93105fa048cabdf9607abc7a4d1e849352cf2389b` |

