# KATARA — Spesifikasi Build untuk Agentic AI

> Taruh file ini di repo sebagai `docs/KATARA_SPEC.md`. Buat juga `AGENTS.md` (atau `CLAUDE.md`) di root yang isinya satu baris: "Baca dan patuhi `docs/KATARA_SPEC.md` sebelum mengerjakan apa pun."

---

## 0. Cara kerja agent (WAJIB dibaca dulu)

Kamu membangun **KATARA**, aplikasi belajar bahasa + budaya Melayu bergaya Duolingo dengan banyak gamifikasi. Dibuat oleh satu developer mahasiswa, tanpa modal, jadi **semua harus gratis dan sederhana**.

**Aturan kerja:**

1. Kerjakan **per fase** (bagian 15), berurutan. Jangan loncat. Selesaikan semua *acceptance criteria* fase itu sebelum lanjut.
2. Tiap fase: buat rencana singkat di `docs/PROGRESS.md`, kerjakan, jalankan `flutter analyze` dan `flutter test` sampai bersih, lalu centang checklist fase.
3. Keputusan yang menyimpang dari spesifikasi ini → tulis di `docs/DECISIONS.md` (tanggal, alasan). Kalau ragu soal hal besar, **tanya developer** daripada menebak.
4. **Jangan** menambah layanan berbayar, Cloud Functions, backend sendiri, iklan, atau analytics pihak ketiga. Jangan menambah paket di luar daftar bagian 3 tanpa alasan tertulis di `DECISIONS.md`.
5. **Jangan mengubah isi folder `konten/`.** Itu sumber data milik developer. Hanya baca.
6. **Jangan mengarang konten bahasa/budaya.** Kosakata, frasa, fakta sejarah hanya boleh berasal dari `konten/`. Kalau data kurang, tampilkan state kosong atau tulis TODO, jangan isi sendiri.
7. Kode dalam bahasa Inggris (nama variabel, class). Teks tampilan ke pengguna dalam bahasa Indonesia.
8. Commit kecil dan sering, pesan commit jelas (`feat:`, `fix:`, `chore:`, `docs:`).

**Definisi "bisa digunakan" (target MVP, akhir Fase 6):**

- Install di Android, buka tanpa internet.
- Pilih Melayu → Melayu Deli → masuk peta.
- Menyelesaikan pelajaran Level 1 lengkap dengan berbagai tipe latihan.
- XP, level, streak, koin tersimpan dan bertahan setelah app ditutup.
- Ada review/latihan kata lemah, kamus, misi harian, lencana, notifikasi pengingat streak.
- Tema terang dan gelap. Tidak crash. Semua konten ditandai status validasi.

---

## 1. Ringkasan produk

| Hal | Isi |
| --- | --- |
| Nama | **KATARA** |
| Platform | Android dulu (Flutter), iOS menyusul |
| Bahasa antarmuka | Indonesia |
| Mode | Offline-first |
| Konten awal | Melayu Deli (dari `konten/`) |
| Konten masa depan | Daerah Melayu lainnya; struktur harus siap sejak awal |
| Loop utama | Pilih daerah → peta unit → pelajaran 3–5 menit → hasil (XP/bintang/streak) → ulangi |

---

## 2. Keputusan yang sudah dikunci

### 2.1 Arsitektur dua lapis (gratis)

- **Lapis 1 — dari hari pertama:** SQLite lokal memakai `drift`. Isi: konten (words, phrases, exercises, dst.) dan progres (XP, streak, word_mastery). Biaya Rp0, jalan tanpa internet, cepat.
- **Lapis 2 — ditunda sampai Fase 7:** Firestore **hanya** untuk sinkron progres akun. **Konten tidak pernah ada di Firestore.**

Sebelum Fase 7, **jangan** memasang Firebase sama sekali. Tapi desain repository sehingga Firebase bisa ditambah tanpa mengubah UI (bagian 7).

### 2.2 Keamanan (ringkas, detail di bagian 8)

- Konten itu publik. Yang dijaga hanya data pengguna.
- Firestore Rules: pengguna hanya akses `users/{uid}` miliknya; koleksi konten `allow write: if false`.
- Mode tamu pakai Anonymous Auth, bisa di-upgrade ke Google/email tanpa kehilangan progres.
- Nyalakan App Check (Play Integrity).
- Simpan data pribadi seminimal mungkin (uid, progres, statistik). Siapkan kebijakan privasi sederhana.
- Anti-curang XP di server **ditunda** sampai ada liga (butuh paket Blaze).

### 2.3 Cache & kecepatan (ringkas, detail di bagian 9)

- SQLite lokal = cache terbaik.
- Audio: `just_audio` + pra-muat audio pelajaran berikutnya.
- Sinkron Firestore **sekali per pelajaran selesai** (satu write batch), bukan per soal.
- Notifikasi streak: `flutter_local_notifications` (tanpa FCM/server).
- State management: **Riverpod**.

### 2.4 Audio

Audio **belum ada**. Bangun semua fitur audio sebagai antarmuka (`AudioService`) dengan implementasi kosong. UI menyembunyikan latihan yang butuh audio bila `audio_path` kosong. Saat file audio datang, cukup taruh di `assets/audio/` dan isi `audio_path` di data.

### 2.5 Multi-daerah

Aplikasi **bukan hanya Melayu Deli**. Hierarki: **Melayu (induk) → daerah/dialek (anak)**. Pemain memilih daerah dulu sebelum masuk peta. Detail di bagian 5.

---

## 3. Tech stack

| Kebutuhan | Paket |
| --- | --- |
| Framework | Flutter (stable terbaru), Dart 3 |
| Database lokal | `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `drift_dev` + `build_runner` (dev) |
| State | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` (dev) |
| Navigasi | `go_router` |
| Audio | `just_audio` |
| Notifikasi lokal | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Pengaturan sederhana | `shared_preferences` |
| Animasi | `flutter_animate`, `confetti` |
| Haptic | `HapticFeedback` bawaan Flutter |
| Kode berasal data | `freezed` + `json_serializable` (opsional, untuk model JSON) |
| Test | `flutter_test`, `mocktail` |
| Lint | `flutter_lints` (atau `very_good_analysis`) |
| **Fase 7 saja** | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_app_check`, `google_sign_in` |

**Font:** bundel di `assets/fonts/` (jangan unduh runtime, harus offline). Lisensi OFL.

- UI: **Nunito** (bulat, ramah).
- Aksara Jawi: **Noto Naskh Arabic** (atau Scheherazade New). **Verifikasi** huruf ڠ ݢ ڤ ڽ چ ۏ tampil benar sebelum dipakai.

---

## 4. Struktur repo

```
katara/
├─ AGENTS.md                  # satu baris: patuhi docs/KATARA_SPEC.md
├─ docs/
│  ├─ KATARA_SPEC.md          # file ini
│  ├─ PROGRESS.md             # catatan per fase (agent isi)
│  ├─ DECISIONS.md            # keputusan menyimpang (agent isi)
│  └─ privacy-policy.md       # draf kebijakan privasi (Fase 7)
├─ konten/                    # SUMBER konten milik developer (docx + json). READ-ONLY
├─ tool/
│  └─ build_content.dart      # konversi konten/*.json → assets/content/** (Fase 2)
├─ assets/
│  ├─ content/                # hasil konversi (JSON ternormalisasi, di-commit)
│  │  ├─ manifest.json
│  │  ├─ courses.json
│  │  └─ ms-deli/             # satu folder per course
│  ├─ audio/                  # kosong dulu
│  ├─ images/
│  └─ fonts/
├─ lib/
│  ├─ main.dart
│  ├─ app/                    # router, tema, bootstrap
│  ├─ core/                   # util, constants, extensions
│  ├─ data/
│  │  ├─ db/                  # drift: tables, DAOs, app_database.dart
│  │  ├─ content/             # ContentSeeder, content models
│  │  └─ repositories/        # interface + impl (Local*, nanti Remote*/Sync*)
│  ├─ domain/                 # entity, aturan game (xp, level, streak, srs)
│  ├─ engine/                 # exercise generator + session controller
│  ├─ services/               # audio, notifications, settings
│  └─ features/
│     ├─ onboarding/
│     ├─ region_picker/
│     ├─ path_map/
│     ├─ lesson/
│     ├─ practice/
│     ├─ dictionary/
│     ├─ culture/
│     ├─ quests/
│     ├─ shop/
│     ├─ profile/
│     └─ settings/
└─ test/
```

---

## 5. Arsitektur konten & multi-daerah

### 5.1 Hierarki

```
Rumpun/Bahasa  (language)     contoh: Melayu
 └─ Daerah     (course)       contoh: Melayu Deli  ← yang punya peta, kosakata, pelajaran
      └─ Unit → Lesson → Exercise
```

- **`courses` adalah satu-satunya tempat konten menempel.** Kosakata, unit, artikel, kartu selalu punya `course_id`.
- Node induk (`Melayu`) tidak punya konten sendiri. Ia hanya pengelompokan di layar pemilih.
- Daerah dengan `status = coming_soon` tampil sebagai kartu terkunci "Segera hadir" dan **tidak bisa dibuka**. Jangan membuat konten palsu untuk mereka.
- Daftar daerah lain **ditentukan developer** nanti. Di data awal cukup: `Melayu Deli` (aktif) dan satu placeholder `Melayu lainnya` (coming_soon). Jangan menebak nama daerah.

### 5.2 `assets/content/courses.json` (contoh bentuk)

```json
{
  "languages": [
    { "id": "ms", "name": "Melayu", "tagline": "Bahasa serumpun Nusantara", "order": 1 }
  ],
  "courses": [
    {
      "id": "ms-deli",
      "language_id": "ms",
      "name": "Melayu Deli",
      "region_label": "Medan & Sumatera Utara",
      "status": "active",
      "accent_hex": "#F5B700",
      "content_version": 1,
      "has_jawi": true
    },
    {
      "id": "ms-other",
      "language_id": "ms",
      "name": "Melayu lainnya",
      "region_label": "Segera hadir",
      "status": "coming_soon",
      "accent_hex": "#9AA0A6",
      "content_version": 0,
      "has_jawi": false
    }
  ]
}
```

### 5.3 Konten per course (folder `assets/content/<course_id>/`)

| File | Isi |
| --- | --- |
| `words.json` | kosakata |
| `phrases.json` | frasa harian |
| `sentences.json` | kalimat contoh (boleh kosong dulu) |
| `dialogues.json` | dialog (boleh kosong dulu) |
| `letters.json` | huruf Jawi (jika `has_jawi`) |
| `articles.json` | artikel budaya |
| `units.json` | unit + lesson + susunan latihan |
| `quiz_bank.json` | bank soal tulisan tangan (dari kuis 40 soal) |
| `collection_cards.json` | kartu koleksi (boleh kosong dulu) |

### 5.4 Skema minimal tiap entitas

Semua entitas wajib punya **`id` stabil** (string, tidak pernah berubah, agar progres pengguna tidak rusak saat konten diperbarui). Format: `<course>:<jenis>:<nomor>`, misal `ms-deli:w:0042`.

**word**
```json
{
  "id": "ms-deli:w:0001",
  "deli": "mane",
  "indonesia": "mana",
  "jawi": null,
  "category": "pronomina_tanya",
  "level": 1,
  "pos": "tanya",
  "register": "deli",
  "audio_path": null,
  "image_path": null,
  "validation_status": "draft"
}
```

- `register`: `"deli"` (ciri lafal Deli) atau `"baku"` (ragam baku yang perlu dicek apakah dipakai sehari-hari, misal tingkap, bilik, seluar, kasut, Isnin, Khamis).
- `validation_status`: `draft` | `speaker_checked` | `expert_verified`.

**phrase**: `id, deli, indonesia, jawi, level, audio_path, cultural_note, validation_status`

**letter (Jawi)**: `id, glyph, sound, example_word_jawi, example_word_latin, forms {isolated, initial, medial, final}, connects_to_next (bool)`

**article**: `id, title, body_markdown, sources[], verification_notes, status, card_id, unlock_after_unit_id`

**unit**: `id, title, theme, order, level, lessons[]`

**lesson**: `id, unit_id, order, kind (vocab|phrase|jawi|dialogue|culture|review|boss), item_refs[] (id word/phrase/letter/dialogue), xp_reward`

**quiz_bank item**: `id, prompt, options[], correct_index, topic, validation_status, needs_verification (bool)`

### 5.5 Langkah wajib pertama untuk konten (Fase 2)

1. **Baca isi `konten/` dulu** (docx dan json). Laporkan ke developer: file apa saja, skema aslinya, jumlah entitas, dan **selisih** terhadap skema 5.4.
2. Tulis `tool/build_content.dart` yang memetakan JSON asli ke skema 5.4. **Jangan menyuruh developer menulis ulang datanya.** Mappingnya yang menyesuaikan.
3. Kalau `docx` dan `json` bertentangan, **json menang**, dan catat pertentangan di `docs/PROGRESS.md`.
4. Item yang bertanda perlu verifikasi di sumber (mis. soal kuis tentang tahun pendirian) diberi `needs_verification: true`. **Jangan tampilkan soal `needs_verification` di mode normal** (filter di engine); hanya boleh muncul di mode debug.
5. Beri `id` stabil secara deterministik (urut + prefiks), simpan peta id di `tool/id_map.json` agar re-run tidak mengubah id.
6. `manifest.json` berisi `content_version` per course dan checksum, dipakai seeder.

---

## 6. Database lokal (drift)

### 6.1 Tabel konten (read-only dari sisi app)

`languages`, `courses`, `words`, `phrases`, `sentences`, `dialogues`, `dialogue_lines`, `letters`, `articles`, `units`, `lessons`, `lesson_items`, `quiz_bank`, `collection_cards`, `content_meta` (course_id, content_version).

Semua tabel konten punya `course_id` dan kolom sesuai skema 5.4.

### 6.2 Tabel progres (milik pengguna)

| Tabel | Kolom |
| --- | --- |
| `user_stats` | id=1, xp_total, level, coins, hearts, hearts_updated_at, streak_current, streak_best, last_active_date (`YYYY-MM-DD` lokal), streak_freezes, daily_goal_minutes, active_course_id, updated_at |
| `course_progress` | course_id, lesson_id, stars (0–3), best_score, completed_at |
| `word_mastery` | course_id, item_id, item_type (word/phrase/letter), strength (0–5), correct_count, wrong_count, last_seen_at, next_review_at |
| `daily_quests` | date, quest_id, progress, target, claimed |
| `achievements_unlocked` | achievement_id, unlocked_at |
| `collection_unlocked` | card_id, unlocked_at |
| `inventory` | item_id, qty (freeze, pakaian maskot, tema) |
| `xp_log` | id, date, course_id, amount, source (dipakai ringkasan mingguan) |
| `pending_sync` | id, entity, payload_json, created_at (disiapkan kosong, dipakai Fase 7) |

**Aturan:** XP, koin, streak, dan level bersifat **global** (satu pengguna). Progres pelajaran, penguasaan kata, dan koleksi bersifat **per course**.

### 6.3 Seeding & update konten

- `ContentSeeder` membaca `assets/content/**` saat pertama kali jalan dan tiap kali `content_version` di manifest lebih besar dari `content_meta`.
- Pakai **upsert berdasarkan `id`**. Jangan hapus tabel progres. Item yang hilang dari konten baru ditandai `deprecated` (jangan dihapus bila ada progres terkait).
- Seeding berjalan di isolate/background dengan indikator di splash, dan **harus selesai < 2 detik** untuk ±200 kata.
- Gunakan transaksi dan batch insert.
- Tulis test: seed dua kali tidak menggandakan data; update versi mempertahankan progres.

### 6.4 Pola repository

Definisikan interface di `domain/` dan implementasinya di `data/repositories/`:

```dart
abstract class ProgressRepository {
  Stream<UserStats> watchStats();
  Future<LessonResult> completeLesson(LessonAttempt attempt); // satu transaksi
  Future<List<WordMastery>> dueForReview(String courseId, {int limit = 20});
}
```

UI **hanya** bergantung pada interface ini lewat Riverpod provider. Di Fase 7, tambahkan `SyncingProgressRepository` yang membungkus `LocalProgressRepository` — UI tidak berubah.

---

## 7. Lapis 2: Firestore (Fase 7, jangan dikerjakan lebih awal)

### 7.1 Struktur dokumen

```
users/{uid}                              # doc: profil ringan + statistik global
  stats: { xp_total, level, coins, streak_current, streak_best, last_active_date, updated_at }
users/{uid}/course_progress/{courseId}   # satu doc per course, berisi map lessonId → {stars, best_score, completed_at}
users/{uid}/mastery/{courseId}           # satu doc per course, map itemId → {strength, next_review_at, updated_at}
```

Konten **tidak** disimpan di Firestore. Tidak ada koleksi `content`. (Kalau nanti ada, rules sudah menolak write.)

### 7.2 Aturan sinkron

- **Tulis:** satu `WriteBatch` per pelajaran selesai (maks ~3 write: stats, course_progress, mastery). Jangan menulis per soal.
- **Baca:** saat login dan saat app dibuka (maksimal sekali per sesi).
- **Penggabungan (merge) lokal ↔ cloud:** `xp_total`, `streak_best`, `stars`, `best_score` = nilai terbesar; `coins`/`hearts` = yang `updated_at` terbaru; mastery per item = yang `updated_at` terbaru.
- Offline: antrekan di `pending_sync`, kirim saat online.
- Kuota gratis (Spark): ±20.000 write/hari, cukup untuk ribuan pelajaran selesai. Tambahkan log debug penghitung write.

### 7.3 Auth

- Awal app: **Anonymous Auth** otomatis (mode tamu).
- Upgrade ke Google/email dengan `linkWithCredential` agar `uid` dan progres tidak hilang.
- Jika akun Google sudah punya data di cloud, tampilkan dialog pilih: gabungkan / pakai data cloud / pakai data perangkat ini.

---

## 8. Keamanan

### 8.1 Firestore Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Data pengguna: hanya pemiliknya
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // Konten (kalau suatu hari dibuat): publik baca, tidak ada yang bisa tulis dari app
    match /content/{document=**} {
      allow read: if true;
      allow write: if false;
    }

    // Selain itu tolak
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Edit konten hanya lewat Console atau panel admin (di luar scope MVP).

### 8.2 Checklist keamanan

- [ ] Anonymous Auth untuk tamu, upgrade tanpa kehilangan data
- [ ] App Check aktif (Play Integrity untuk Android), enforcement dinyalakan setelah diuji
- [ ] Tidak ada API key rahasia/server di repo. (Config Firebase klien itu publik, tapi dilindungi Rules + App Check.)
- [ ] Data yang disimpan: uid, progres, statistik saja. Tanpa nama/email di dokumen progres (email hanya di Firebase Auth)
- [ ] Draf `docs/privacy-policy.md` sederhana: data apa dikumpulkan, untuk apa, cara hapus akun
- [ ] Fitur "Hapus akun & data" di Pengaturan (hapus doc Firestore + akun Auth + data lokal)
- [ ] Anti-curang XP: **sengaja tidak dikerjakan** sampai ada liga. Catat di `DECISIONS.md`

---

## 9. Cache & kecepatan

- SQLite lokal adalah sumber kebenaran; **tidak ada loading jaringan** saat belajar.
- Query: pakai index pada `(course_id, level)`, `(course_id, item_id)`, `next_review_at`. Gunakan `watch` stream drift untuk UI reaktif.
- **Audio:** `AudioService` (interface) → `JustAudioService` + `NoopAudioService`. Saat pelajaran dimulai, pra-muat audio soal berikutnya (1–2 ke depan) selagi pemain menjawab. Bila `audio_path == null`, jangan buat soal bertipe dengar dan sembunyikan tombol speaker.
- **Notifikasi streak:** `flutter_local_notifications` terjadwal harian pada jam pilihan pengguna. Batalkan dan jadwalkan ulang setiap app dibuka (kalau pemain sudah belajar hari itu, jadwalkan mulai besok). Minta izin notifikasi Android 13+ dengan konteks yang jelas (bukan saat first launch mentah).
- **Gambar:** pakai aset terbundel; `precacheImage` untuk gambar pelajaran berikutnya.
- Target kinerja: cold start < 2 detik pada perangkat menengah; transisi soal 60 fps; tidak ada jank di layar peta.

---

## 10. Design system

### 10.1 Prinsip

Hangat, ramah, bernuansa Melayu tanpa terasa kuno. Warna kuning, hijau, merah dalam busana adat dipakai sebagai identitas (makna kuning = kebesaran/kerajaan berasal dari draf artikel dan masih `[verifikasi]`, jadi jangan klaim makna di UI sebelum divalidasi; boleh dipakai sebagai warna saja).

### 10.2 Token warna

| Token | Terang | Gelap | Pemakaian |
| --- | --- | --- | --- |
| `primary` (Hijau Rebung) | `#1E7F5C` | `#3FBF8A` | tombol utama, node aktif |
| `primaryDark` | `#14573F` | `#2C9A6C` | tepi bawah tombol (efek 3D), pressed |
| `onPrimary` | `#FFFFFF` | `#0F1F18` | teks di atas primary |
| `secondary` (Kuning Diraja) | `#F5B700` | `#FFC933` | XP, bintang, aksen, sorotan |
| `onSecondary` | `#2B2118` | `#2B2118` | teks di atas kuning |
| `accent` (Merah Songket) | `#A62B2B` | `#E0605F` | aksen dekoratif, badge langka |
| `bg` | `#FFF9EC` | `#15110C` | latar layar |
| `surface` | `#FFFFFF` | `#211B14` | kartu |
| `surfaceAlt` | `#F6EEDC` | `#2C241A` | latar bagian, chip |
| `outline` | `#E5D9BF` | `#3B3224` | garis, tepi kartu |
| `ink` | `#2B2118` | `#F6EDDC` | teks utama |
| `inkMuted` | `#6B5E4B` | `#B9AB92` | teks sekunder |
| `success` | `#2E9E5B` | `#4CD08A` | jawaban benar |
| `error` | `#D2453B` | `#FF6B6B` | jawaban salah |
| `streak` | `#F28C28` | `#FFA94D` | api streak |
| `heart` | `#E5484D` | `#FF7A7E` | nyawa |
| `coin` | `#E0A800` | `#FFD54F` | koin |

Aturan:

- Kontras teks minimal **WCAG AA** (4.5:1 untuk teks biasa). Periksa kombinasi `onPrimary` / `onSecondary` dan `inkMuted` di atas `bg`.
- Jangan mengandalkan warna saja untuk benar/salah: tambah ikon (✓ / ✗) dan teks.
- Tiap course punya `accent_hex` sendiri (di `courses.json`). Wrap peta dan kartu course dengan `CourseTheme` yang menimpa `secondary` saja. Course `coming_soon` tampil monokrom (abu-abu).

### 10.3 Tipografi

| Gaya | Font | Ukuran/berat |
| --- | --- | --- |
| Display | Nunito | 28–32 / 800 |
| Judul | Nunito | 20–22 / 700 |
| Body | Nunito | 16 / 500 |
| Label/caption | Nunito | 12–14 / 600 |
| Jawi | Noto Naskh Arabic | 28–40, `TextDirection.rtl` |

Teks Jawi selalu dibungkus `Directionality(textDirection: TextDirection.rtl)`. Latin tetap LTR. Uji rendering campuran dalam satu baris.

### 10.4 Komponen inti (buat reusable di `lib/app/widgets/`)

- `KButton` (primer/sekunder/outline, gaya 3D dengan tepi bawah, state pressed/disabled/loading)
- `KCard`, `KChip`, `KProgressBar` (animasi), `KHeaderStats` (streak, koin, nyawa, XP)
- `PathNode` (terkunci / aktif / selesai / boss, dengan bintang)
- `ExerciseScaffold` (progress bar atas, area soal, bar umpan balik bawah benar/salah)
- `ResultBurst` (konfeti + hitung naik XP)
- `MascotView(state)` — **placeholder** (lingkaran/ikon sederhana) dengan state: idle, happy, sad, cheer. Ilustrasi asli menyusul; nama dan wujud maskot **tanya developer**.
- `PatternBackground` — motif pucuk rebung digambar dengan `CustomPainter` (tanpa aset), opasitas rendah, dipakai di splash, header, layar hasil.

### 10.5 Gerak & suara

- Durasi 150–300 ms, kurva halus. Hormati pengaturan "kurangi animasi" sistem.
- Haptic ringan saat benar/salah/naik level.
- Efek suara: antarmuka siap (`SfxService`), file menyusul. Jangan crash bila file tidak ada.

---

## 11. Screen dan navigasi

### 11.1 Peta navigasi (`go_router`)

```
/splash
/onboarding           (3 slide → tujuan → target harian → nama)
/region               ← PEMILIH BAHASA/DAERAH (baru, penting)
/home (shell, bottom nav)
  ├─ /home/learn      (peta jalur)
  ├─ /home/practice
  ├─ /home/culture
  ├─ /home/quests     (misi + lencana)
  └─ /home/profile
/unit/:id
/lesson/:id           (sesi latihan, fullscreen, tanpa bottom nav)
/lesson/:id/result
/levelup
/dictionary
/jawi                 (muncul bila course.has_jawi)
/article/:id
/collection
/shop
/settings
/about                (kredit + status validasi konten)
```

### 11.2 Alur pilih daerah

1. **Pertama kali:** Splash → Onboarding → `/region` → `/home`.
2. `/region` menampilkan **induk** (Melayu) sebagai judul bagian, di bawahnya **kartu daerah**:
   - Aktif: kartu berwarna, nama daerah, label wilayah, progres (% pelajaran selesai), tombol "Mulai"/"Lanjut".
   - `coming_soon`: kartu abu-abu, ikon gembok, "Segera hadir". Tap → bottom sheet singkat (boleh dikosongkan dulu).
3. Bila hanya ada **satu bahasa induk**, lewati pemilihan induk dan langsung tampil daftar daerahnya. Kode harus mendukung banyak induk (daftar induk → daftar daerah) walau UI sekarang hanya satu.
4. Bila hanya ada **satu daerah aktif**, tetap tampilkan `/region` pada kali pertama (agar pemain melihat struktur "Melayu → Deli" dan bahwa daerah lain akan datang), tapi ingat pilihan; kali berikutnya langsung ke `/home`.
5. **Ganti daerah kapan saja:** ketuk nama daerah di header peta atau tombol di Profil → buka `/region` sebagai bottom sheet/layar. Pilihan disimpan di `user_stats.active_course_id`. XP/koin/streak tetap global; peta dan progres mengikuti course aktif.

### 11.3 Fungsi tiap screen

| Screen | Fungsi |
| --- | --- |
| Splash | Logo, jalankan `ContentSeeder`, cek pengaturan, arahkan ke onboarding atau home |
| Onboarding | 3 slide nilai app; tujuan belajar; target harian (5/10/20 menit); nama panggilan (opsional); tanpa wajib akun |
| Region | Pilih daerah (11.2) |
| Learn (peta) | Jalur unit berkelok; node pelajaran (terkunci/aktif/selesai/boss); header `KHeaderStats`; nama daerah aktif; tombol lanjut besar ke pelajaran berikutnya |
| Unit detail | Ringkasan unit, daftar pelajaran, kata yang akan dipelajari, tombol mulai |
| Lesson | Satu soal per layar, progress bar, tombol Periksa, umpan balik benar/salah dengan penjelasan, antrean ulang soal salah, hati/nyawa (bila aktif) |
| Result | XP, akurasi, bintang, kata baru, streak naik, hadiah; tombol Lanjut/Ulangi |
| Level up | Animasi, gelar baru, hadiah |
| Practice | Latihan kata lemah (SRS), kuis cepat 30 detik, latihan Jawi, latihan acak per kategori |
| Dictionary | Cari + filter kategori kata yang sudah dipelajari; detail kata (arti, contoh, Jawi, audio bila ada, badge status validasi) |
| Jawi | Peta khusus aksara: kartu huruf, bentuk huruf, aturan sambung, latihan |
| Culture | Daftar artikel (terkunci sampai unit tertentu), kartu koleksi |
| Article | Isi artikel, sumber/sitasi, badge "draf/terverifikasi", kuis mini, kartu koleksi terbuka |
| Quests | Misi harian/mingguan, klaim hadiah, daftar lencana |
| Shop | Beli streak freeze, isi nyawa, tema, pakaian maskot dengan koin |
| Profile | Avatar/maskot, gelar, level, XP, kalender streak, statistik, lencana, ganti daerah |
| Settings | Target harian, jam pengingat, suara, haptic, tema (terang/gelap/sistem), tampilan Jawi/Latin, hapus data |
| About | Kredit penutur & ahli (isi dari data), status validasi konten, kebijakan privasi |
| Laporkan kesalahan | Tombol di soal/kata: simpan lokal ke `reports` (kirim nanti di Fase 7+) |

---

## 12. Aturan gamifikasi (semua angka di `assets/content/game_config.json`, jangan di-hardcode)

### 12.1 XP & level

- Selesai pelajaran: **10 XP**; +**5** bila tanpa salah; +**1** per 5 jawaban benar beruntun (maks +5).
- Review: 5–10 XP. Boss unit: 25 XP. Misi harian selesai semua: 20 XP.
- Level: `xpToNext(level) = 50 × level`. Contoh: Lv1→2 butuh 50, Lv2→3 butuh 100.
- Gelar:

| Level | Gelar |
| --- | --- |
| 1–4 | Perantau |
| 5–9 | Anak Pekan |
| 10–14 | Penutur Muda |
| 15–19 | Pandai Pantun |
| 20–29 | Orang Kaya |
| 30+ | Datuk Bahasa |

- Hadiah naik level: koin (level × 5), buka item/konten tertentu sesuai config.
- Tulis unit test untuk fungsi XP/level (batas nilai, naik beberapa level sekaligus).

### 12.2 Streak

- Hari dihitung dari tanggal **lokal perangkat** (`YYYY-MM-DD`). Pelajaran selesai hari itu = streak aman.
- Kemarin ada, hari ini belum → streak masih hidup. Lewat sehari penuh → reset ke 0 kecuali `streak_freezes > 0` (pakai satu otomatis).
- Tampilkan kalender streak di Profil.
- Uji: hari berganti, perubahan zona waktu, jam tengah malam.

### 12.3 Nyawa (hearts)

- Maks 5. Salah = −1. Pulih 1 tiap 30 menit (hitung dari `hearts_updated_at`, tanpa timer latar).
- **Mati di Level 1 (config `hearts_enabled_from_level: 2`)**: pemula tidak kehilangan nyawa.
- Habis: opsi menunggu, latihan ulang untuk pulih, atau tukar koin.
- Pengaturan "Mode santai" mematikan nyawa sepenuhnya.

### 12.4 Koin & toko

- Koin dari pelajaran (3–5), misi, lencana, peti harian.
- Barang awal: streak freeze, isi nyawa penuh, tema warna. Pakaian maskot menyusul setelah maskot ada.

### 12.5 Misi & lencana

- 3 misi harian acak dari pool: selesaikan 2 pelajaran; dapat 50 XP; 10 jawaban benar beruntun; 1 latihan Jawi (hanya bila `has_jawi`); baca 1 artikel.
- Selesai semua misi → peti hadiah (koin acak dalam rentang config).
- Lencana awal: Langkah Pertama, Api Kecil (streak 3), Api Besar (streak 30), Penyapa, Tukang Tanya, Pantun Pertama, Sempurna ×10, Penjelajah Budaya. Definisikan syarat sebagai data (`achievements.json`), evaluasi oleh satu `AchievementEngine`.

### 12.6 Bintang & penguasaan

- Bintang per pelajaran: ≥95% = 3, ≥80% = 2, selesai = 1.
- `strength` kata 0–5: benar +1 (maks 5), salah −1 (min 0).

### 12.7 Spaced repetition (sederhana)

Interval berdasarkan `strength`: 0→besok, 1→1 hari, 2→3 hari, 3→7 hari, 4→14 hari, 5→30 hari. Salah → `strength−1`, `next_review_at = besok`. Mode Practice "Latihan kata lemah" mengambil item dengan `next_review_at <= now`, urut paling terlambat.

---

## 13. Engine latihan

Satu modul di `lib/engine/`, murni Dart (tanpa Flutter), mudah diuji. Ini jantung app.

### 13.1 Tipe latihan MVP

| Kode | Tipe | Syarat data |
| --- | --- | --- |
| `mcq_translate` | Pilih arti | word/phrase |
| `mcq_reverse` | Pilih kata Deli dari arti Indonesia | word/phrase |
| `match_pairs` | Pasangkan kartu Deli ↔ Indonesia | ≥4 item |
| `fill_blank` | Isi bagian kosong kalimat | sentence/phrase |
| `build_sentence` | Susun potongan kata | phrase/sentence |
| `image_to_word` | Gambar → kata | `image_path` ada |
| `listen_choose` | Dengar lalu pilih | `audio_path` ada (**disaring bila kosong**) |
| `jawi_recognize` | Huruf → bunyi | letters ada |
| `jawi_read` | Kata Jawi → Latin | word.jawi ada |
| `culture_tf` | Benar/Salah dari artikel | article + quiz |
| `quiz_bank_item` | Soal tulisan tangan | `needs_verification == false` |

Tipe lanjutan (nanti): `listen_type`, `type_translation`, `jawi_write`, `complete_pantun`, `dialogue_reply`, `speed_round`.

### 13.2 Generator

- Masukan: `Lesson` + item_refs + riwayat penguasaan.
- Keluaran: daftar `Exercise` 8–12 buah, **minimal 4 tipe berbeda** bila data memungkinkan, **tidak ada tipe sama lebih dari 2 berturut-turut**.
- Pengecoh: 3 item acak dari **kategori dan tipe kata yang sama**, bukan item yang sama atau sinonim; deterministik bila diberi `seed` (agar bisa diuji).
- Item baru diperkenalkan dulu dengan kartu "kenalan" (kata + arti + contoh) sebelum diuji.
- Jawaban salah masuk **antrean ulang** di akhir sesi (maks 1 kali ulang per soal).
- Normalisasi jawaban ketik: abaikan huruf besar, spasi ganda, tanda baca akhir.

### 13.3 Sesi

`LessonSessionController` (Riverpod Notifier) mengelola: indeks soal, hati, combo, skor, antrean ulang, hasil. Di akhir → panggil `ProgressRepository.completeLesson(...)` **sekali** dalam satu transaksi drift (update progres, XP, streak, mastery, misi, lencana, koleksi).

---

## 14. Penanganan status validasi konten

- Semua konten awal berstatus `draft`.
- Tampilkan badge kecil "Draf" pada kartu kata/artikel yang belum `speaker_checked`. Jangan membuat kesan "resmi".
- Layar About menjelaskan status validasi dan memberi kredit (isi dari file `assets/content/credits.json`; kosong dulu).
- Tombol "Laporkan kesalahan" ada di soal, kata, dan artikel.
- Soal/artikel dengan `needs_verification: true` disembunyikan dari pengguna biasa.

---

## 15. Rencana fase (kerjakan berurutan)

### Fase 0 — Scaffold
- Buat project Flutter `katara`, atur package id, lint, struktur folder (bagian 4), Riverpod, go_router.
- Tulis `AGENTS.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`.
- **Selesai bila:** app jalan menampilkan layar kosong, `flutter analyze` bersih, CI lokal (`flutter test`) hijau.

### Fase 1 — Design system
- Implementasi token warna terang/gelap, tipografi, tema Material 3 kustom, komponen di 10.4 (dengan `MascotView` placeholder dan `PatternBackground`).
- Halaman `/dev/gallery` (hanya debug) menampilkan semua komponen di kedua tema.
- **Selesai bila:** gallery tampil benar di terang dan gelap; kontras AA terverifikasi; font Jawi menampilkan huruf ڠ ݢ ڤ ڽ چ ۏ dengan benar.

### Fase 2 — Database & konten
- Skema drift (bagian 6), DAO, repository interface + implementasi lokal.
- Baca `konten/`, laporkan skema aslinya, tulis `tool/build_content.dart` (5.5), hasilkan `assets/content/**`.
- `ContentSeeder` dengan upsert dan versi.
- **Selesai bila:** data Melayu Deli termuat di SQLite; test seeder lulus (idempoten, progres selamat saat update konten); laporan jumlah entitas dicatat di `PROGRESS.md`.

### Fase 3 — Engine latihan
- Generator, tipe MVP (kecuali yang butuh audio/gambar tidak tersedia), sesi controller, unit test (seed deterministik, aturan variasi, antrean ulang).
- **Selesai bila:** test engine lulus; ada layar debug yang menjalankan satu sesi dari data nyata.

### Fase 4 — Alur layar inti (inilah loop yang bisa dimainkan)
- Splash, onboarding ringkas, **region picker**, peta belajar, unit detail, lesson, result, level up.
- Progres tersimpan; layar peta mengikuti progres (node terbuka bertahap).
- **Selesai bila:** dari install baru, pemain memilih Melayu → Melayu Deli → menyelesaikan 1 pelajaran → XP/bintang tersimpan dan terlihat setelah restart, tanpa internet.

### Fase 5 — Gamifikasi
- Streak, nyawa (aturan Level 1), koin, toko dasar, misi harian, lencana, bintang, SRS + mode Practice, kamus, profil.
- Notifikasi pengingat streak lokal.
- **Selesai bila:** semua aturan bagian 12 punya unit test; notifikasi terjadwal ulang saat app dibuka; ringkasan semua tersimpan setelah restart.

### Fase 6 — Budaya, Jawi, poles → **MVP "bisa digunakan"**
- Ruang Budaya, artikel, kartu koleksi, layar Jawi (bila data ada), About + badge validasi, Pengaturan lengkap, mode gelap, laporan kesalahan lokal.
- Pass performa (cold start, jank), aksesibilitas (ukuran teks, kontras, label semantik).
- Build APK rilis dan uji di perangkat nyata.
- **Selesai bila:** seluruh daftar "Definisi bisa digunakan" (bagian 0) terpenuhi.

### Fase 7 — Akun & sinkron (lapis 2)
- Pasang Firebase, Anonymous Auth, upgrade ke Google/email, Firestore sync (bagian 7), Rules (8.1), App Check, hapus akun, kebijakan privasi.
- **Selesai bila:** progres berpindah antar-perangkat; Rules diuji (akses uid lain ditolak); jumlah write per pelajaran ≤ 3.

### Fase 8 — Audio & maskot (saat aset datang)
- Isi `audio_path`, aktifkan `JustAudioService`, latihan `listen_*`, pra-muat audio, efek suara, ilustrasi maskot & pakaian adat.

### Fase 9 — Daerah baru
- Tambah course baru lewat **data saja**: entri `courses.json` + folder `assets/content/<course_id>/`, naikkan `content_version`. **Tidak boleh perlu mengubah kode UI/engine.** Bila perlu, itu bug arsitektur: perbaiki dulu.

---

## 16. Kualitas & uji

- `flutter analyze` tanpa warning sebelum commit fase.
- Unit test wajib: aturan XP/level, streak (tepi hari), hearts regen, SRS, generator latihan, seeder, merge sinkron (Fase 7).
- Widget test untuk `ExerciseScaffold` (benar/salah) dan region picker (aktif vs `coming_soon`).
- Uji manual tiap akhir fase di perangkat Android nyata, termasuk mode pesawat.
- Jangan ada `print` tertinggal; gunakan logger.
- Error handling: tidak ada layar merah; tampilkan state error ramah + opsi coba lagi.

---

## 17. Di luar cakupan (jangan dikerjakan sekarang)

- Liga mingguan, teman, tantangan 1 lawan 1 (butuh server dan pengguna).
- Validasi XP di server, Cloud Functions, FCM.
- Panel admin konten.
- Pengenalan suara (speech recognition).
- Iklan, langganan, pembayaran.
- iOS (hanya pastikan kode tidak mengunci ke Android bila mudah).

---

## 18. Hal yang perlu ditanyakan ke developer (jangan ditebak)

1. Isi dan skema asli `konten/` (setelah dibaca di Fase 2: laporkan selisih).
2. Nama dan wujud maskot.
3. Package id/bundle id (mis. `id.katara.app`).
4. Daftar daerah Melayu berikutnya dan label wilayahnya.
5. Teks kebijakan privasi final dan kontak resmi.
6. Apakah Level 1 benar-benar tanpa nyawa, atau pakai "mode santai" sebagai pilihan saja.
