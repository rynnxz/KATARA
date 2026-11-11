# Kebijakan Dukungan Jangka Panjang (LTS & Versioning Policy) — KATARA

Dokumen ini menetapkan aturan penomoran versi (*Semantic Versioning*), kompatibilitas skema basis data SQLite, masa dukungan katalog modul unduhan, serta mekanisme penghentian bertahap (*deprecation*) untuk menjamin aplikasi **KATARA (`id.katara.app`)** tetap stabil dalam jangka panjang.

---

## 1. Aturan Semantic Versioning (`MAJOR.MINOR.PATCH+BUILD`)

KATARA mengikuti standar **SemVer 2.0.0** pada `pubspec.yaml`:
- **`MAJOR` (`1.x.x`):** Perubahan arsitektur besar atau perubahan skema katalog/cloud yang tidak kompatibel ke belakang (*breaking changes*).
- **`MINOR` (`x.1.x`):** Penambahan dialek baru, fitur pembelajaran baru, atau migrasi skema SQLite penambahan kolom/tabel yang bersifat *backward-compatible*.
- **`PATCH` (`x.x.1`):** Perbaikan bug, peningkatan kontras aksesibilitas, pembaruan keamanan, dan perbaikan leksikografis korpus.
- **`+BUILD` (`+3`):** Nomor kode versi integer Android (`versionCode`) yang selalu bertambah secara monotonik setiap rilis APK.

---

## 2. Kebijakan Kompatibilitas Katalog Modul (`min_app_version` & `content_version`)

1. **`min_app_version` pada `module_catalog.json`:**
   - Menentukan versi aplikasi minimum yang diizinkan untuk mengunduh format katalog terbaru.
   - Diperiksa oleh `ModuleDownloadService.isAppUpdateRequired(currentVersion, minAppVersion)`.
   - Bahkan ketika versi aplikasi pengguna lebih lama dari `min_app_version`, **seluruh modul yang sudah terpasang di perangkat tetap 100% dapat digunakan secara offline tanpa pemblokiran paksa**.
2. **`content_version` & Proteksi Anti-Downgrade:**
   - Setiap pembaruan korpus dialek wajib menaikkan integer `content_version` secara monotonik (`1 -> 2 -> 3`).
   - `ModuleDownloadService` secara otomatis menolak pemasangan paket modul dengan `version < existing.version` untuk mencegah serangan *downgrade*.
3. **Kill-Switch Modul (`revoked_modules`):**
   - Jika ditemukan cacat konten atau masalah keamanan pada suatu paket ZIP modul, pengembang dapat mencantumkan ID kursus (mis. `"ms-langkat"`) pada array `"revoked_modules"` di `module_catalog.json` yang ditandatangani dengan Ed25519.
   - Modul bawaan `"ms-deli"` dikecualikan secara permanen dari pencabutan agar aplikasi selalu memiliki minimal satu kurikulum aktif secara luring.

---

## 3. Jaminan Migrasi Basis Data Lokal (`Drift` SQLite)

1. **Prinsip Nol Kehilangan Progres (*Zero Progress Loss*):**
   - Setiap kenaikan `schemaVersion` pada `AppDatabase` wajib mempertahankan tabel `user_stats`, `course_progress`, `word_mastery`, `achievements_unlocked`, `collection_unlocked`, `xp_events`, dan `streak_history`.
2. **Migrasi Idempoten:**
   - Seluruh penambahan kolom wajib menggunakan pemeriksaan `PRAGMA table_info(...)` (`_addColumnIfMissing`) dan seluruh tabel baru wajib menggunakan `CREATE TABLE IF NOT EXISTS`.
3. **Pengujian Wajib sebelum Rilis:**
   - Setiap perubahan skema wajib diuji di [`test/migrations/schema_migration_test.dart`](../test/migrations/schema_migration_test.dart).

---

## 4. Jendela Dukungan & Deprecation Window

- Setiap format `module_catalog.json` didukung minimal selama **12 bulan** sejak tanggal rilis minor berikutnya.
- Kosakata atau soal kuis yang direvisi tidak dihapus secara kasar dari SQLite, melainkan ditandai dengan kolom `deprecated = 1` agar riwayat penguasaan kata (`word_mastery`) pengguna lama tidak pernah menghasilkan referensi yatim (*dangling foreign key*).
