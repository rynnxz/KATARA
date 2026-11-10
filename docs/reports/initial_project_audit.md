# Laporan Audit Awal Proyek KATARA (Phase 1 — Existing Project Audit)

**Tanggal Audit:** 11 November 2026  
**Aplikasi:** KATARA (`id.katara.app` v1.0.0+1)  
**Target Pengembangan:** Multi-Dialect (Deli, Langkat, Palembang), Offline-First, Firebase Cloud Sync, Downloadable Dialect Modules, & High-Contrast WCAG AA UI/UX  

---

## 1. Framework & Dependensi Saat Ini

- **Framework:** Flutter (Dart SDK `^3.13.5`, Material 3 kustom).
- **State Management:** `flutter_riverpod: ^3.4.3`.
- **Navigasi:** `go_router: ^18.1.2` (`lib/app/router.dart`).
- **Database Lokal:** `drift: ^2.35.3`, `drift_flutter: ^0.3.1`, `sqlite3_flutter_libs: ^0.6.0+eol`.
- **Utilitas & Layanan Lokal:** `path_provider`, `path`, `crypto` (SHA-256), `just_audio`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `shared_preferences`, `flutter_animate`, `confetti`.
- **Font Terbundel Offline:** `Nunito` (UI Latin) dan `Noto Naskh Arabic` (Aksara Jawi dengan dukungan `چ ڠ ڤ ݢ ۏ ڽ`).
- **Status Paket Belum Terpasang:**
  - `archive` & `http` (dibutuhkan untuk unduhan dan ekstraksi ZIP modul dialek).
  - `url_launcher` (dibutuhkan untuk membuka URL referensi akademik dari layar Tentang & Referensi).
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` (dibutuhkan untuk autentikasi opsional Google & sinkronisasi cloud pada proyek Firebase `katara-melayu`).

---

## 2. Struktur Source Code & Navigasi

- `lib/app/`: konfigurasi `KataraApp`, `appRouterProvider` (`go_router`), `providers.dart`, tema (`katara_colors.dart`, `katara_theme.dart`), dan 11 komponen UI reusable (`KButton`, `KCard`, `KChip`, `KHeaderStats`, `KProgressBar`, `PathNode`, `ExerciseScaffold`, `ResultBurst`, `MascotView` Si Rebung, `PatternBackground` Pucuk Rebung, `ReportIssueDialog`).
- `lib/data/`:
  - `db/app_database.dart`: `AppDatabase` (`schemaVersion: 1`) dengan 15 tabel konten, 9 tabel progres, dan 1 tabel `reports`.
  - `content/`: `content_models.dart` dan `content_seeder.dart` (seeding idempoten dari `assets/content/**`).
  - `repositories/`: `LocalContentRepository` dan `LocalProgressRepository`.
- `lib/domain/`: `user_progress.dart`, interface `ContentRepository` & `ProgressRepository`, `GamificationRules`, dan `AchievementEngine`.
- `lib/engine/`: `ExerciseGenerator`, `LessonSessionEngine`, `AnswerNormalizer`, dan `exercise_models.dart`.
- `lib/features/`: `onboarding/`, `region_picker/`, `path_map/`, `lesson/`, `practice/`, `dictionary/`, `culture/`, `quests/`, `shop/`, `profile/`, `settings/`, `dev/`.

---

## 3. Audit Database Lokal (`AppDatabase` v1)

- **Kelebihan saat ini:**
  - Sudah menerapkan *Local-First Single Source of Truth* dengan pemisahan tegas antara tabel konten (15 tabel) dan tabel progres pengguna (9 tabel).
  - Semua tabel konten sudah memiliki kolom `course_id` dan flag `deprecated` sehingga penghapusan/pembaruan konten tidak merusak histori progres pengguna.
- **Kesenjangan terhadap spesifikasi Multi-Dialek & Cloud Sync (`schemaVersion: 2`):**
  1. Tabel `words` belum menyimpan kolom `pronunciation`, `example_sentence`, `example_translation`, `usage_context`, `region`, `variants_json`, `confidence`, dan `sources_json` secara langsung di SQLite.
  2. Tabel `courses` belum menyimpan metadata modul unduhan (`dialect_id`, `is_bundled`, `is_installed`, `installed_version`, `download_url`, `sha256`, `size_bytes`, `color_identity_json`).
  3. Belum ada tabel `installed_modules`, `dialect_references`, `xp_events` (*idempotent ledger*), `streak_history`, `sync_queue` terstruktur dengan retry/backoff, dan `user_profiles`.
  4. Tabel progres (`user_stats`, `course_progress`, `word_mastery`, `achievements_unlocked`) belum memiliki atribut sinkronisasi lengkap (`created_at`, `is_synced`, `deleted_at`, `device_id`, `revision`).

---

## 4. Audit Dataset Bahasa Melayu Deli (`ms-deli`)

- **Kondisi Saat Ini:**
  - Folder `konten/linguanusa_konten_draf_v0.1.json` (read-only) memiliki 67 kosakata awal, 10 frasa, 10 kalimat, 2 dialog, 6 huruf Jawi, 3 draf artikel, 5 kartu koleksi, dan 62 soal kuis.
  - Folder riset `melayu-deli-dataset/` telah memperluas korpus menjadi **210 kosakata terkurasi** (`215 raw`), **40 ungkapan**, **35 kalimat**, **5 dialog**, **15 kaidah tata bahasa**, **20 peribahasa/pantun**, **14 artikel budaya/sejarah**, dan **12 sumber ilmiah**.
- **Target Peningkatan (`prompt.md` Bagian 4):**
  - Menambah kosakata terkurasi Melayu Deli dari 210 menjadi **≥300 entri**, kalimat mandiri + contoh kalimat kosakata **≥100**, dialog percakapan **≥10**, dan soal kuis **≥100**.
  - Menyusun dataset riset baru untuk **Melayu Langkat (`ms-langkat`)** dan **Melayu Palembang (`ms-palembang`)** dengan standar provenance dan target terukur yang sama.

---

## 5. Audit UI/UX & Kontras Warna (WCAG AA)

- **Temuan Penting:**
  1. Pada `KataraPalette.light`, warna teks sekunder `inkMuted` (`#6B5E4B`) di atas `surfaceAlt` (`#F6EEDC`) atau `outline` (`#E5D9BF`) terlihat agak pudar pada layar cerah (dan pada `outline` rasionya ~4.18:1, di bawah batas 4.5:1).
  2. Pada `KataraTheme._build`, `ColorScheme` Material 3 belum mendefinisikan `onSurfaceVariant`, `inverseSurface`, dan `onInverseSurface` secara eksplisit, sehingga beberapa komponen Material 3 (`NavigationBar`, `SnackBar`, `InputDecoration`, `BottomSheet`) dapat menampilkan teks abu-abu bawaan Material di atas permukaan cerah.
  3. Identitas warna spesifik per dialek (**Deli: Amber/Gold**, **Langkat: Emerald/Mint**, **Palembang: Maroon/Coral**) perlu diperkuat dengan palet pendamping yang teruji kontrasnya (≥4.5:1 untuk semua teks normal dan ≥7.0:1 untuk teks bacaan utama).
