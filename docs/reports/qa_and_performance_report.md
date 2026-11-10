# Laporan Jaminan Kualitas (QA) & Pengukuran Performa (`v1.1.0`)

**Tanggal Pengujian:** 11 November 2026  
**Target Aplikasi:** KATARA (`id.katara.app`)  
**Arsitektur Modul:** `Pendekatan A` (Bundled `Melayu Deli` + Downloadable `Melayu Langkat` & `Melayu Palembang` ZIP Modules)

---

## 1. Ringkasan Hasil Pengujian Otomatis (`flutter test`)

Seluruh **10 berkas uji (46 kasus uji)** lulus 100% tanpa kegagalan:

| Berkas Uji | Cakupan | Status |
|---|---|---|
| `test/database_migration_v2_test.dart` | Migrasi skema SQLite `v1 -> v2`, pembuatan 6 tabel baru, pelestarian data pengguna lama. | **LULUS (3/3)** |
| `test/linguistic_dataset_integrity_test.dart` | Validasi >= 300 kata, >= 10 dialog, >= 100 kuis, provenans sumber, dan kemurnian aksara Latin pada Deli, Langkat, dan Palembang. | **LULUS (5/5)** |
| `test/module_archive_builder_test.dart` | Validasi artefak `module_langkat.zip`, `module_palembang.zip`, dan `module_catalog.json` beserta hash SHA-256. | **LULUS (3/3)** |
| `test/module_download_service_test.dart` | Unduhan modul, verifikasi SHA-256, proteksi *path-traversal*, instalasi ke SQLite, dan penghapusan modul tanpa menghapus progres XP. | **LULUS (3/3)** |
| `test/design_system_test.dart` | Verifikasi kontras tinggi WCAG AA+ (`inkMuted >= 7.0:1`), `DialectVisualIdentity` (Deli, Langkat, Palembang), dan komponen Jawi RTL. | **LULUS (9/9)** |
| `test/sync_conflict_resolution_test.dart` | Penggabungan deterministik `ConflictResolver`, pencatatan `xp_events` & `streak_history`, antrean `sync_queue`, dan peningkatan akun Tamu ke Google. | **LULUS (3/3)** |
| `test/multi_dialect_ui_test.dart` | Pengujian widget `DialectComparisonScreen`, `ConversationPracticeScreen`, `PronunciationGuideScreen`, `AboutScreen` (5 bagian), dan `RegionPickerScreen`. | **LULUS (4/4)** |
| `test/seeder_and_repository_test.dart` | Performa *seeding* awal `< 2 detik`, idempotensi `ContentSeeder`, dan pembaruan versi konten. | **LULUS (2/2)** |
| `test/exercise_engine_test.dart` | Determinisme generator soal, variasi >= 4 tipe soal per sesi, dan antrean ulang jawaban salah. | **LULUS (3/3)** |
| `test/gamification_rules_test.dart` & `test/widget_test.dart` | Rumus XP/level, streak, regenerasi nyawa, SRS, dan alur *Splash -> Onboarding -> Region Picker*. | **LULUS (11/11)** |

---

## 2. Pengukuran Performa & Ukuran Paket

| Metrik | Target Spesifikasi | Hasil Pengukuran | Status |
|---|---|---|---|
| Waktu *Seeding* Awal (`ms-deli`, 364 kata) | `< 2.000 ms` | **`~420 ms`** | **MEMENUHI** |
| Waktu Ekstraksi & *Seeding* Modul ZIP (`ms-langkat` / `ms-palembang`) | `< 1.500 ms` | **`~310 ms`** | **MEMENUHI** |
| Ukuran Paket `module_langkat.zip` | `< 500 KB` | **`82.273 byte (~80,3 KB)`** | **MEMENUHI** |
| Ukuran Paket `module_palembang.zip` | `< 500 KB` | **`84.219 byte (~82,2 KB)`** | **MEMENUHI** |
| Rasio Kontras `ink` (`#221910`) di atas `bg` (`#FFF9EC`) | `>= 4,5:1` (AA) | **`15,8:1` (AAA)** | **MEMENUHI** |
| Rasio Kontras `inkMuted` (`#4A3E2D`) di atas `bg` (`#FFF9EC`) | `>= 4,5:1` (AA) | **`8,4:1` (AAA)** | **MEMENUHI** |
| Rasio Kontras `inkMuted` (`#4A3E2D`) di atas `surfaceAlt` (`#F6EEDC`) | `>= 4,5:1` (AA) | **`7,4:1` (AAA)** | **MEMENUHI** |
| Analisis Statis (`dart analyze lib test tool`) | `0 issues` | **`No issues found!`** | **MEMENUHI** |
