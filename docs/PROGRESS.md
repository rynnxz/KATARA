# KATARA — Progres Pembangunan (PROGRESS.md)

> **Design Read (antislop)**:
> Reading this as: Gamified regional language & cultural learning mobile app (KATARA) for Indonesian learners of Melayu dialects, in a warm Melayu heritage visual language (Hijau Rebung `#1E7F5C`, Kuning Diraja `#F5B700`, Merah Songket `#A62B2B`, Pucuk Rebung geometric motif, tactile 3D bottom-lip cards/buttons), dial `ENERGY 2 / RHYTHM 2 / MOTION 2`.

---

## Fase 0 — Scaffold

### Rencana Singkat
1. Buat project Flutter `katara` dengan package ID `id.katara.app`.
2. Salin `KATARA_SPEC.md` ke `docs/KATARA_SPEC.md`, buat `AGENTS.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`.
3. Pasang paket sesuai Bagian 3 (`flutter_riverpod`, `go_router`, `drift`, `sqlite3_flutter_libs`, `just_audio`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `shared_preferences`, `flutter_animate`, `confetti`, `mocktail`, `flutter_lints`).
4. Bundel font OFL (`Nunito` dan `Noto Naskh Arabic`) di `assets/fonts/` untuk penggunaan 100% offline.
5. Susun struktur direktori `lib/` sesuai Bagian 4 dan pastikan `flutter analyze` serta `flutter test` lulus bersih.

### Status Checklist Fase 0
- [x] Project Flutter `katara` dengan package id `id.katara.app`
- [x] Dokumen `AGENTS.md`, `docs/KATARA_SPEC.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`
- [x] Struktur folder Bagian 4 & konfigurasi Riverpod + `go_router`
- [x] Bundel font offline `Nunito` & `Noto Naskh Arabic`
- [x] `flutter analyze` bersih & `flutter test` hijau

---

## Fase 1 — Design System

### Rencana Singkat
1. Implementasi token warna terang & gelap (`KataraPalette.light` & `KataraPalette.dark`), rumus kontras WCAG AA (`KataraColors.contrastRatio`), serta `CourseTheme` untuk menimpa token `secondary` per daerah.
2. Implementasi tipografi (`Nunito` + `Noto Naskh Arabic`) dan `JawiText` (`Directionality.rtl`).
3. Implementasi komponen reusable di `lib/app/widgets/`: `KButton`, `KCard`, `KChip`, `ValidationStatusBadge`, `KProgressBar`, `KHeaderStats`, `PathNode`, `ExerciseScaffold`, `ResultBurst`, `MascotView` (Si Rebung 4 state), `PatternBackground` (motif Pucuk Rebung).
4. Buat halaman `/dev/gallery` dan unit/widget test verifikasi kontras AA & Jawi (`ڠ ݢ ڤ ڽ چ ۏ`).

### Status Checklist Fase 1
- [x] Token warna terang/gelap & kontras WCAG AA terverifikasi (`test/design_system_test.dart`)
- [x] Komponen reusable Bagian 10.4 lengkap dengan `MascotView` (Si Rebung) dan `PatternBackground` (Pucuk Rebung)
- [x] Layar `/dev/gallery` menampilkan semua komponen di tema terang & gelap
- [x] Font Jawi merender huruf `ڠ ݢ ڤ ڽ چ ۏ` dengan `TextDirection.rtl`

---

## Fase 2 — Database & Konten

### Laporan Inspeksi `konten/` (Bagian 5.5)
- **File sumber**:
  1. `konten/LinguaNusa_Draft_Konten_Level1_v0.1.docx` (dokumen draf naratif Level 1).
  2. `konten/linguanusa_konten_draf_v0.1.json` (data terstruktur utama; sesuai aturan 5.5.3, JSON menjadi sumber otoritatif).
- **Jumlah entitas hasil konversi `tool/build_content.dart` (`ms-deli`)**:
  - `words.json`: **67** kata (`ms-deli:w:0001` s/d `ms-deli:w:0067`; 43 kata Level 1 + 24 kata Level 2).
  - `phrases.json`: **10** frasa harian (`ms-deli:p:0001` s/d `ms-deli:p:0010`).
  - `sentences.json`: **10** kalimat contoh (`ms-deli:s:0001` s/d `ms-deli:s:0010`).
  - `dialogues.json`: **2** dialog percakapan (`ms-deli:d:0001` s/d `ms-deli:d:0002`, total 12 baris).
  - `letters.json`: **6** huruf tambahan Jawi Melayu (`چ ڠ ڤ ݢ ۏ ڽ`).
  - `articles.json`: **3** kerangka artikel budaya (`Istana Maimun`, `Masjid Raya Al-Mashun`, `Busana Adat Melayu Deli`).
  - `collection_cards.json`: **5** kartu koleksi budaya.
  - `units.json`: **10** unit (5 unit Level 1 dari sumber + 5 unit Level 2 hasil pengelompokan `u06`–`u10` agar 24 kata Level 2 dapat dipelajari) dengan total **40** pelajaran (`ms-deli:l:0001` s/d `ms-deli:l:0040`).
  - `quiz_bank.json`: **62** soal kuis (40 soal umum + 22 soal latihan per unit; soal sejarah yang ditandai `[verifikasi]` di sumber diberi `needs_verification: true` dan disembunyikan dari sesi normal).
- **Selisih skema sumber vs Bagian 5.4**:
  - Kolom berbahasa Indonesia di sumber (`arti_id`, `kelas`, `catatan`, `huruf`, `padanan_latin`, `pertanyaan`, `pilihan`, `jawaban_index`) dipetakan otomatis oleh `tool/build_content.dart` ke skema standar Bagian 5.4 tanpa mengubah isi folder `konten/`.
  - Peta ID stabil disimpan di `tool/id_map.json`, dan checksum/versi disimpan di `assets/content/manifest.json`.

### Status Checklist Fase 2
- [x] `tool/build_content.dart` menghasilkan `assets/content/**` dan `tool/id_map.json`
- [x] Skema SQLite (`AppDatabase` via `drift`) memuat 15 tabel konten + 9 tabel progres + tabel `reports`
- [x] `ContentSeeder` idempoten dengan upsert transaksi dan pelestarian progres pengguna saat versi naik
- [x] `ContentRepository` & `ProgressRepository`beserta unit test (`test/seeder_and_repository_test.dart`)

---

## Fase 3 — Engine Latihan

### Rencana Singkat
1. Implementasi `AnswerNormalizer`, `ExerciseItem`, `ExerciseGenerator` (deterministik dengan `seed`, minimal 4 variasi tipe soal per sesi, maksimal 2 tipe sama berturut-turut, saring soal `needs_verification` & item tanpa audio/gambar).
2. Implementasi `LessonSessionEngine` (nyawa, combo, skor, antrean ulang soal salah maksimal 1 kali di akhir sesi).
3. Unit test deterministik di `test/exercise_engine_test.dart` dan tombol uji sesi nyata di `/dev/gallery`.

### Status Checklist Fase 3
- [x] `ExerciseGenerator` mendukung tipe MVP (`intro_card`, `mcq_translate`, `mcq_reverse`, `match_pairs`, `fill_blank`, `build_sentence`, `jawi_recognize`, `jawi_read`, `quiz_bank_item`)
- [x] `LessonSessionEngine` mengelola antrean ulang soal salah maks 1x
- [x] Unit test engine lulus (`test/exercise_engine_test.dart`)

---

## Fase 4 — Alur Layar Inti

### Rencana Singkat
1. Implementasi `/splash` (`SplashScreen`), `/onboarding` (`OnboardingScreen`), `/region` (`RegionPickerScreen` dengan `Melayu Deli` aktif & `Melayu lainnya` `coming_soon`).
2. Implementasi `/home/learn` (`LearnMapScreen`), `/unit/:id` (`UnitDetailScreen`), `/lesson/:id` (`LessonScreen`), `/lesson/:id/result` (`LessonResultScreen`), dan `/levelup` (`LevelUpScreen`).
3. Simpan progres pelajaran dalam satu transaksi Drift dan buka node peta secara bertahap.

### Status Checklist Fase 4
- [x] Alur Splash -> Onboarding -> Region Picker -> Peta Belajar berjalan 100% offline
- [x] Sesi pelajaran menyimpan XP, bintang, koin, streak, dan membuka pelajaran berikutnya
- [x] Widget test untuk Region Picker (`active` vs `coming_soon`) & `ExerciseScaffold`

---

## Fase 5 — Gamifikasi

### Rencana Singkat
1. Implementasi `GamificationRules` & `AchievementEngine` (XP, level, gelar `Perantau`..`Datuk Bahasa`, streak + auto streak freeze, regenerasi nyawa 30 menit + nonaktif di Level 1, bintang, SRS).
2. Implementasi `/home/practice` (`PracticeScreen`), `/dictionary` (`DictionaryScreen`), `/home/quests` (`QuestsScreen`), `/shop` (`ShopScreen`), `/home/profile` (`ProfileScreen`), serta penjadwalan ulang notifikasi streak lokal (`NotificationService`).

### Status Checklist Fase 5
- [x] Unit test aturan XP/level, streak, nyawa, bintang, dan SRS (`test/gamification_rules_test.dart`)
- [x] Layar Latihan (SRS + Kuis 30 Detik + Kategori), Kamus, Misi & Lencana, Toko Koin, dan Profil
- [x] Penjadwalan ulang notifikasi pengingat streak lokal saat aplikasi dibuka

---

## Fase 6 — Budaya, Jawi, Poles -> MVP "Bisa Digunakan"

### Rencana Singkat
1. Implementasi `/home/culture` (`CultureScreen`), `/article/:id` (`ArticleDetailScreen`), `/collection` (`CollectionScreen`), `/jawi` (`JawiScreen`), `/settings` (`SettingsScreen`), `/about` (`AboutScreen`), dan dialog `Laporkan Kesalahan` (`ReportIssueDialog`).
2. Verifikasi tema terang/gelap, aksesibilitas, `dart analyze`, `flutter test`, dan build APK rilis (`flutter build apk --release`).

### Status Checklist Fase 6
- [x] Ruang Budaya, Artikel (dengan state draf jujur), Kartu Koleksi, dan Layar Aksara Jawi
- [x] Layar Pengaturan lengkap (tema terang/gelap/sistem, Mode Santai, pengingat, Jawi, reset data) & Tentang/Validasi Konten
- [x] Fitur Laporkan Kesalahan tersimpan ke tabel lokal `reports`
- [x] Seluruh tes lulus dan APK rilis Android berhasil dibangun
