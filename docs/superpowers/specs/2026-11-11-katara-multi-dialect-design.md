# Desain Arsitektur Pengembangan KATARA Multi-Dialek, Offline-First, Firebase Sync & Modul Unduhan Terpisah

**Tanggal:** 11 November 2026  
**Proyek:** KATARA (`id.katara.app`)  
**Repositori GitHub Target:** `https://github.com/rynnxz/KATARA.git`  
**Proyek Firebase Target:** `katara-melayu` (`236754467620`)  

---

## 1. Tujuan & Latar Belakang (Intent & The Why)

KATARA telah memiliki fondasi aplikasi pembelajaran Bahasa dan Budaya Melayu Deli (Fase 0–6 selesai, offline-first di atas SQLite `drift`, Riverpod, `go_router`, serta korpus ilmiah `melayu-deli-dataset/`). Pengembangan tahap ini memperluas KATARA menjadi **platform pembelajaran Bahasa Melayu multi-dialek** yang:

1. **Menjaga ukuran APK tetap ringan**: hanya **Melayu Deli (`ms-deli`)** yang dibundel di dalam APK (`assets/content/ms-deli/`).
2. **Menyediakan modul dialek terpisah yang dapat diunduh sesuai pilihan pengguna**: **Melayu Langkat (`ms-langkat`)** dan **Melayu Palembang (`ms-palembang`)** dikemas sebagai file ZIP eksternal (`dist/releases/v1.1.0/module_langkat.zip` dan `module_palembang.zip`) yang di-host di GitHub Releases (`https://github.com/rynnxz/KATARA/releases/download/v1.1.0/...`) sehingga ukuran instalasi awal aplikasi tidak membengkak.
3. **Menjamin kualitas linguistik berbasis riset dan provenance**: setiap kosakata, frasa, kalimat, dialog, kuis, dan artikel memiliki atribusi sumber akademik/leksikografi nyata, tingkat kepercayaan (`high`, `medium`, `low`), serta status verifikasi (`verified`, `needs_review`, `disputed`, `rejected`).
4. **Mendukung sinkronisasi cloud opsional via Firebase (`katara-melayu`)**: pengguna tetap dapat belajar 100% offline sebagai tamu (*Guest Mode*), dan bila memilih login Google, progres disinkronkan secara aman ke Cloud Firestore menggunakan *idempotent event ledger* serta aturan resolusi konflik per entitas.
5. **Meningkatkan pengalaman belajar interaktif & UI/UX**: identitas warna per dialek (Deli Amber, Langkat Emerald, Palembang Maroon) dengan kontras WCAG AA, kartu taktil 3D dengan ornamen budaya spesifik wilayah, fitur **Perbandingan Dialek**, **Tantangan Harian (Daily Challenge)**, **Latihan Percakapan (Conversation Practice)**, **Panduan Pelafalan (Pronunciation Learning)**, serta halaman **Tentang & Referensi** yang dapat diakses penuh secara offline.

---

## 2. Goals, Non-Goals, & Anti-Goals

### Goals
- Mempertahankan seluruh progres dan fitur eksisting (`schemaVersion: 1 -> 2` dengan migrasi SQLite tanpa merusak data pengguna).
- Menyediakan 3 dialek:
  1. **Melayu Deli (`ms-deli` / `melayu_deli`)**: Bundled di APK (`is_bundled: true`), warna identitas Amber/Warm Gold (`#F5B700`), dilengkapi audit kualitas dan laporan `docs/reports/research_report_deli.md`.
  2. **Melayu Langkat (`ms-langkat` / `melayu_langkat`)**: Downloadable module (`is_bundled: false`), warna identitas Emerald/Mint (`#1E7F5C` / `#10B981`), fokus wilayah Stabat, Tanjung Pura, Secanggang, dan Langkat Hilir/Hulu, dilengkapi laporan `docs/reports/research_report_langkat.md`.
  3. **Melayu Palembang (`ms-palembang` / `melayu_palembang`)**: Downloadable module (`is_bundled: false`), warna identitas Maroon/Coral (`#A62B2B` / `#D9534F`), mencakup ragam *Sari-sari* (sehari-hari) dan *Bebaso* (halus) di kawasan perkotaan Palembang (Ilir/Ulu) dan sekitarnya, dilengkapi laporan `docs/reports/research_report_palembang.md`.
- Memisahkan data penelitian (`raw/` — termasuk `needs_review`, `disputed`, `rejected`) dari dataset produksi (`curated/` & paket modul ZIP — hanya `verified` dan item transparan yang memenuhi syarat, tanpa pernah menyertakan `rejected`).
- Mengimplementasikan `ModuleDownloadService` dengan unduhan HTTP streaming (persentase progres), validasi ukuran & SHA-256, validasi versi manifest, ekstraksi ZIP aman dari *path traversal* (`..`), instalasi atomik ke direktori dokumen aplikasi (`<appDocDir>/modules/<courseId>/`), serta fitur *Install, Update, Delete (tanpa menghapus progres belajar), Retry*, dan *Local File Import / Fallback* untuk pengujian offline sebelum GitHub Release dipublikasikan.
- Mengintegrasikan Firebase Authentication (Anonymous Guest + Google Sign-In opsional + `linkWithCredential`) dan Cloud Firestore pada proyek `katara-melayu` beserta `firestore.rules`.

### Non-Goals
- Membangun backend kustom berbayar atau Cloud Functions di luar paket gratis (Spark) Firebase.
- Membundel aset ZIP Melayu Langkat atau Melayu Palembang ke dalam `pubspec.yaml` (`assets:`) yang akan memperbesar ukuran APK.

### Anti-Goals (Kegagalan fatal walaupun secara teknis berjalan)
- Mengarang kosakata, URL referensi palsu, atau mengklaim audio TTS sebagai rekaman penutur asli.
- Menghapus progres belajar ketika pengguna menghapus modul unduhan atau ketika melakukan logout.
- Memaksa pengguna login untuk mengakses materi pembelajaran inti.
- Menimpa total XP secara buta saat sinkronisasi dua perangkat sehingga aktivitas dari salah satu perangkat hilang.

---

## 3. Batasan & Kondisi Eksisting (Constraints)

1. **Kepatuhan `konten/` Read-Only**: Sesuai `docs/KATARA_SPEC.md`, isi folder `konten/` tidak boleh diubah. Dataset riset disimpan di folder terpisah (`melayu-deli-dataset/`, `melayu-langkat-dataset/`, `melayu-palembang-dataset/`), dan dikompilasi oleh `tool/build_content.dart` serta `tool/build_modules.dart`.
2. **ID Stabil & Kompatibilitas Skema**: Aplikasi eksisting menggunakan `course_id` (`ms-deli`, `ms-langkat`, `ms-palembang`) yang terpetakan 1-ke-1 dengan `dialect_id` (`melayu_deli`, `melayu_langkat`, `melayu_palembang`). Seluruh entitas mempertahankan format ID deterministik (`<course_id>:<type>:<num>`).
3. **Kredensial Firebase & GitHub**:
   - Proyek Firebase `katara-melayu` tersedia di Firebase CLI (`akbarriansyah339@gmail.com`). Aplikasi Android `id.katara.app` akan didaftarkan/diambil konfigurasi `android/app/google-services.json`-nya melalui Firebase CLI/MCP.
   - Remote Git akan diarahkan ke `https://github.com/rynnxz/KATARA.git`. Paket rilis (`app-release.apk`, `module_langkat.zip`, `module_palembang.zip`, `module_catalog.json`) disiapkan di `dist/releases/v1.1.0/` siap unggah ke GitHub Releases.

---

## 4. Pendekatan yang Dipilih (Approaches)

### Pendekatan A — Bundled Primary APK + Separate Release ZIP Modules + Dual-Source Importer (Dipilih Developer)
- **APK Utama (`app-release.apk`)**: Hanya membundel `ms-deli` (`assets/content/ms-deli/`) dan katalog awal `assets/content/module_catalog.json`.
- **Modul Unduhan Terpisah (`module_langkat.zip` & `module_palembang.zip`)**: Disimpan di luar bundel aset APK (`dist/releases/v1.1.0/`). Saat pengguna memilih unduh di aplikasi:
  1. Aplikasi mengambil katalog terbaru dari URL GitHub Raw/Pages (`https://raw.githubusercontent.com/rynnxz/KATARA/main/dist/releases/v1.1.0/module_catalog.json`) dengan fallback katalog terbundel jika offline.
  2. Aplikasi mengunduh file ZIP dari GitHub Releases (`https://github.com/rynnxz/KATARA/releases/download/v1.1.0/module_<dialect>.zip`) ke direktori sementara (`<tempDir>/module_downloads/`).
  3. Untuk mendukung pengujian lokal sebelum GitHub Release di-publish (atau instalasi manual di daerah tanpa sinyal), `ModuleDownloadService` juga mendukung *local staging directory / file picker import* yang melewati pipa validasi SHA-256 dan ekstraksi atomik yang persis sama.
- **Alasan pemilihan**: Menjaga ukuran APK tetap kecil dan modular sesuai permintaan pengguna, sambil memastikan fitur unduh/instal/hapus dapat diuji 100% secara nyata.

### Alternatif yang Ditolak: Pendekatan B — Membundel Semua ZIP di dalam Assets APK
- Ditolak karena membuat ukuran APK membengkak seiring bertambahnya dialek baru, bertentangan dengan tujuan modularitas.

---

## 5. Rincian Desain Teknis

### 5.1 Skema Database Lokal (`AppDatabase` Migration `v1 -> v2`)
Migrasi `onUpgrade(m, from, to)` dari versi 1 ke versi 2 akan mempertahankan seluruh 25 tabel lama dan menambahkan/memperluas:
1. **Kolom tambahan pada tabel eksisting (`words`, `phrases`, `sentences`, `courses`, `user_stats`, `course_progress`, `word_mastery`)**:
   - ` words`: `pronunciation TEXT`, `example_sentence TEXT`, `example_translation TEXT`, `usage_context TEXT`, `region TEXT`, `variants_json TEXT`, `confidence TEXT DEFAULT 'high'`, `sources_json TEXT`.
   - `courses` (dialects): `dialect_id TEXT`, `is_bundled INTEGER DEFAULT 0`, `is_installed INTEGER DEFAULT 0`, `installed_version INTEGER DEFAULT 0`, `download_url TEXT`, `sha256 TEXT`, `size_bytes INTEGER DEFAULT 0`, `color_identity_json TEXT`.
   - Metadata sinkronisasi pada `user_stats`, `course_progress`, `word_mastery`, `achievements_unlocked`: `created_at TEXT`, `updated_at TEXT`, `is_synced INTEGER DEFAULT 0`, `deleted_at TEXT`, `device_id TEXT`, `revision INTEGER DEFAULT 1`.
2. **Tabel Baru di `schemaVersion = 2`**:
   - `installed_modules`: `module_id TEXT PRIMARY KEY`, `course_id TEXT NOT NULL`, `version INTEGER NOT NULL`, `is_bundled INTEGER NOT NULL`, `install_path TEXT`, `sha256 TEXT NOT NULL`, `size_bytes INTEGER NOT NULL`, `installed_at TEXT NOT NULL`, `updated_at TEXT NOT NULL`.
   - `dialect_references`: `id TEXT PRIMARY KEY`, `course_id TEXT NOT NULL`, `dialect_id TEXT NOT NULL`, `title TEXT NOT NULL`, `author TEXT NOT NULL`, `publication_year INTEGER`, `publisher TEXT`, `source_type TEXT NOT NULL`, `url TEXT`, `accessed_at TEXT`, `reliability TEXT NOT NULL`, `supported_domain TEXT`.
   - `xp_events` (Idempotent XP Ledger): `event_id TEXT PRIMARY KEY`, `course_id TEXT NOT NULL`, `amount INTEGER NOT NULL`, `source TEXT NOT NULL`, `device_id TEXT NOT NULL`, `created_at TEXT NOT NULL`, `is_synced INTEGER NOT NULL DEFAULT 0`.
   - `streak_history`: `date TEXT PRIMARY KEY`, `course_id TEXT NOT NULL`, `xp_earned INTEGER NOT NULL`, `lessons_completed INTEGER NOT NULL`, `freeze_used INTEGER NOT NULL DEFAULT 0`, `device_id TEXT NOT NULL`, `updated_at TEXT NOT NULL`, `is_synced INTEGER NOT NULL DEFAULT 0`.
   - `sync_queue`: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `operation_id TEXT NOT NULL UNIQUE`, `entity_type TEXT NOT NULL`, `entity_id TEXT NOT NULL`, `operation TEXT NOT NULL`, `payload_json TEXT NOT NULL`, `retry_count INTEGER NOT NULL DEFAULT 0`, `next_retry_at TEXT`, `last_error TEXT`, `created_at TEXT NOT NULL`.
   - `user_profiles`: `uid TEXT PRIMARY KEY`, `email TEXT`, `display_name TEXT`, `photo_url TEXT`, `is_anonymous INTEGER NOT NULL DEFAULT 1`, `device_id TEXT NOT NULL`, `revision INTEGER NOT NULL DEFAULT 1`, `last_synced_at TEXT`, `created_at TEXT NOT NULL`, `updated_at TEXT NOT NULL`.

### 5.2 Struktur Paket Modul Unduhan (`module_langkat.zip` & `module_palembang.zip`)
Setiap arsip ZIP berisi struktur standar sesuai spesifikasi:
```text
module_<dialect>/
├── metadata.json          # id, course_id, dialect_id, version, sha256, counts, regions
├── lessons.json           # daftar unit & lesson terstruktur
├── vocabulary.json        # kosakata + makna + IPA + contoh kalimat + provenance sources
├── phrases.json           # sapaan & ungkapan khas
├── sentences.json         # kalimat kontekstual
├── quizzes.json           # soal kuis terverifikasi
├── conversations.json     # dialog percakapan
├── references.json        # daftar pustaka akademik & leksikografi dialek tersebut
├── articles.json          # artikel budaya & kaidah fonologi/tata bahasa
├── collection_cards.json  # kartu koleksi budaya
├── audio/                 # direktori aset audio (opsional/placeholder jujur)
└── images/                # direktori ilustrasi budaya (opsional)
```
Saat modul diinstal oleh `ModuleManagerService`, `ContentSeeder.seedFromDirectory(Directory moduleDir)` mem-parsing file JSON tersebut dan melakukan transaksi *upsert* ke SQLite lokal serta mencatatnya di `installed_modules`. Saat modul dihapus, baris konten dialek tersebut dibersihkan dari SQLite dan folder `<appDocDir>/modules/<courseId>/` dihapus, **tetapi tabel `course_progress`, `word_mastery`, `xp_events`, dan `xp_log` untuk `course_id` tersebut tidak dihapus**.

### 5.3 Riset Linguistik & Target Dataset
- **Melayu Deli (`melayu_deli` / `ms-deli`)**:
  - Memperluas korpus yang sudah ada (210 kata, 40 frasa, 35 kalimat, 5 dialog, 62 kuis, 14 artikel, 12 sumber) hingga mencapai target ≥300 kosakata, ≥100 contoh kalimat (gabungan kalimat mandiri & contoh kalimat terverifikasi pada entri kosakata), ≥15 materi/unit pembelajaran, ≥10 kategori, ≥10 percakapan, ≥100 soal kuis, dan ≥85% berstatus `verified`.
- **Melayu Langkat (`melayu_langkat` / `ms-langkat`)**:
  - Fokus wilayah: **Stabat**, **Tanjung Pura**, **Secanggang**, **Pangkalan Brandan / Babalan**, dan **Bahorok**.
  - Rujukan primer & akademik: penelitian dialektologi/leksikografi Melayu Langkat (USU, UNIMED, Balai Bahasa Sumatera Utara, *Kamus Melayu Sumatera Utara - Indonesia* 2018, penelitian variasi geografis Pesisir Secanggang vs. Tanjung Pura vs. Stabat, tradisi sastra lisan & pantun Langkat).
  - Mencatat karakteristik fonologi khas Langkat (pepet akhir `[-ə]`, uvular/velar `/r/`, kosakata khas pesisir Secanggang & keraton Tanjung Pura) tanpa menyeragamkan seluruh kecamatan.
- **Melayu Palembang (`melayu_palembang` / `ms-palembang`)**:
  - Fokus wilayah: **Palembang Kota (Seberang Ilir & Seberang Ulu)** serta batas penggunaannya terhadap ragam Musi/Banyuasin.
  - Membedakan dua tingkatan sosial bahasa (*undak-usuk*): **Baso Palembang Alus (*Bebaso*)** dan **Baso Palembang Sari-sari** (sehari-hari).
  - Rujukan primer & akademik: *Kamus Bahasa Palembang - Indonesia* (Balai Bahasa Sumatera Selatan / Kemdikbud), *Struktur Bahasa Palembang* (Pusat Pembinaan dan Pengembangan Bahasa), publikasi akademik Universitas Sriwijaya (UNSRI) dan UIN Raden Fatah Palembang, serta dokumentasi ungkapan/peribahasa Palembang.
  - Mencatat karakteristik fonologi khas Palembang (pergeseran vokal Proto-Melayu `*-a > -o` pada ragam *Sari-sari* seperti *apo, mano, kito, galo*, diftongisasi, serta leksikon khas *Bebaso* seperti *kulo, niku, pundi, laju*).
- **Laporan Riset**:
  - Menghasilkan `docs/reports/research_report_deli.md`, `docs/reports/research_report_langkat.md`, dan `docs/reports/research_report_palembang.md` berisi statistik lengkap (total terkumpul, tervalidasi, `needs_review`, `disputed`, `rejected`, jumlah sumber unik, cakupan wilayah, dan persentase kelengkapan).

### 5.4 Firebase Integration & Offline-First Sync Engine (`katara-melayu`)
- **Autentikasi (`AuthService`)**:
  - Aplikasi berjalan penuh dalam **Guest Mode** secara default tanpa memaksa login.
  - Pengguna dapat masuk dengan **Google Sign-In** kapan saja melalui layar Profil atau Pengaturan.
  - Jika sebelumnya sudah ada progres lokal (atau Anonymous Auth), `AuthService` menggabungkan progres lokal ke akun Google (`linkWithCredential` atau *local-to-cloud idempotent merge*) sehingga tidak ada XP, bintang, atau streak yang hilang.
  - Saat *logout*, sesi Firebase diputus namun data SQLite lokal tetap utuh.
- **Sync Engine & Conflict Resolution (`SyncEngine`)**:
  - Setiap perubahan progres lokal menulis ke SQLite terlebih dahulu dan menambahkan item ke `sync_queue` (`is_synced = 0`).
  - Saat perangkat online dan pengguna terautentikasi Google, `SyncEngine` mengirim perubahan dengan *exponential backoff* (`baseDelay * 2^retryCount`).
  - **Aturan Resolusi Konflik per Entitas**:
    1. **XP**: menggunakan koleksi/dokumen `xp_events` dengan `event_id` deterministik/UUID unik; total XP dihitung dari penggabungan (*union*) event ID yang belum tercatat + rekonsiliasi aman, bukan sekadar `max(xp)`.
    2. **Lesson Completion (`course_progress`)**: digabungkan per `(course_id, lesson_id)` dengan `stars = max(local.stars, remote.stars)` dan `best_score = max(local.bestScore, remote.bestScore)`.
    3. **Quiz / Word Mastery (`word_mastery`)**: digabungkan per `(course_id, item_id)` berdasarkan `updated_at` terbaru dan akumulasi riwayat.
    4. **Streak (`streak_history`)**: dihitung ulang dari gabungan tanggal aktivitas tervalidasi di `streak_history` (`YYYY-MM-DD` lokal).
    5. **Profile & Settings**: menggunakan nomor `revision` tertinggi dan `updated_at` terbaru.
    6. **Achievements & Collection Cards**: menggunakan operasi himpunan *union* berdasarkan `achievement_id` / `card_id`.
  - **Status Indikator UI**: komponen `SyncStatusBadge` menampilkan state `Synced`, `Syncing`, `Offline`, `Sync failed`, atau `Pending changes (N)` lengkap dengan ikon semantik (bukan warna saja).

### 5.5 UI/UX, Identitas Warna Dialek, & Fitur Pembelajaran Interaktif
- **Dialect Color Identity (`CourseTheme` & `KataraPalette`)**:
  - **Melayu Deli (`ms-deli`)**: Amber / Warm Gold (`#F5B700`, aksen gelap `#B8860B`, permukaan lembut `#FFF8E1`).
  - **Melayu Langkat (`ms-langkat`)**: Emerald / Mint (`#1E7F5C`, aksen mint `#10B981`, permukaan lembut `#E8F6F0`).
  - **Melayu Palembang (`ms-palembang`)**: Maroon / Coral (`#8B1E24`, aksen koral `#D9534F`, permukaan lembut `#FCEEEF`).
  - Seluruh kombinasi teks/latar belakang diverifikasi secara terprogram melalui `KataraColors.contrastRatio(...) >= 4.5` (WCAG AA) pada tema terang dan gelap.
- **Tactile Cards & Cultural Micro-Illustrations**:
  - Kartu menggunakan radius `20px`, border `2px`, shadow bawah taktil `4px` yang bergeser `2px` saat ditekan, serta `DialectOrnamentPainter` (`CustomPainter` ringan: Pucuk Rebung Deli, Payung/Tanjak Langkat, Motif Songket/Jembatan Ampera Palembang).
- **10 Variasi Pembelajaran Interaktif**:
  1. *Vocabulary cards* (`intro_card` + flashcard flip dengan audio/IPA & provenance).
  2. *Word matching* (`match_pairs`).
  3. *Multiple choice* (`mcq_translate` & `mcq_reverse`).
  4. *Listening quiz* (`listen_choose` — aktif bila audio tersedia, atau mode fonetik terpandu).
  5. *Pronunciation learning* (panduan artikulasi IPA, pemenggalan suku kata, dan kaidah fonologi khas dialek seperti pepet `-e` Deli/Langkat vs vokal `-o` Palembang).
  6. *Fill in the blanks* (`fill_blank`).
  7. *Sentence arrangement* (`build_sentence`).
  8. *Daily challenge* (tantangan harian lintas kategori dengan bonus XP & koin).
  9. *Dialect comparison* (layar & tabel perbandingan interaktif **Indonesia | Melayu Deli | Melayu Langkat | Melayu Palembang** yang hanya menampilkan entri tervalidasi beserta wilayah dan sumbernya).
  10. *Conversation practice* (simulasi dialog interaktif langkah-demi-langkah dengan pilihan respons kontekstual).
- **Halaman Tentang & Referensi (`AboutScreen` / `/about`)**:
  - 5 bagian lengkap yang 100% tersedia offline dari SQLite `dialect_references` & `credits.json`:
    - **A. Tentang Aplikasi** (nama, deskripsi, versi, pengembang, tujuan).
    - **B. Sumber Data Bahasa per Dialek** (filter Melayu Deli, Melayu Langkat, Melayu Palembang; menampilkan judul, penulis/lembaga, tahun, jenis sumber, cakupan data, dan tombol buka URL).
    - **C. Atribusi Konten & Aset** (font OFL, ilustrasi vektor in-house, lisensi).
    - **D. Metodologi Penelitian** (tahapan pengumpulan, klasifikasi `high/medium/low`, dan validasi `verified/needs_review/disputed/rejected`).
    - **E. Keterbatasan Data** (penjelasan variasi geografis, sosial/register seperti *Bebaso* vs *Sari-sari*, generasional, serta penafian bahwa aplikasi bukan otoritas linguistik tunggal).

---

## 6. Keputusan Teknis oleh Builder (Builder Calls)

1. **Paket Tambahan di `pubspec.yaml`**:
   - `archive`: untuk ekstraksi dan pembuatan ZIP (`module_langkat.zip`, `module_palembang.zip`) dengan validasi *path traversal*.
   - `http`: untuk mengunduh katalog manifest dan paket ZIP modul dengan streaming byte progress.
   - `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`: untuk autentikasi Google opsional dan sinkronisasi Firestore pada proyek `katara-melayu`.
   - `url_launcher`: untuk membuka tautan referensi akademik pada layar **Tentang & Referensi**.
2. **Keamanan Ekstraksi ZIP**:
   - Setiap nama entri di dalam ZIP diperiksa terhadap karakter `..`, awalan `/`, atau `\` absolut sebelum ditulis ke disk; ekstraksi dilakukan ke folder staging `<appDocDir>/modules/.staging_<courseId>/` lalu di-rename secara atomik ke `<appDocDir>/modules/<courseId>/` setelah semua file wajib (`metadata.json`, `lessons.json`, `vocabulary.json`, `quizzes.json`, `conversations.json`, `references.json`) terverifikasi.
