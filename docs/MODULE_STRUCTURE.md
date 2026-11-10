# Arsitektur Modul Multi-Dialek KATARA (`Pendekatan A`)

Dokumen ini menjelaskan struktur paket modul bahasa daerah pada **KATARA (`id.katara.app`)**, alur kompilasi korpus riset ke paket siap pakai, mekanisme verifikasi integritas SHA-256, serta cara menambahkan modul dialek baru di masa mendatang.

---

## 1. Filosofi Arsitektur (`Pendekatan A`: Hybrid Bundled + On-Demand ZIP)

Agar ukuran unduhan awal aplikasi (`app-release.apk`) tetap ringan dan ramah kuota bagi pelajar di berbagai daerah:

1. **Modul Bawaan (`Bundled` di dalam APK):**
   - **Melayu Deli (`ms-deli` / `melayu_deli`)** disertakan langsung di dalam `assets/content/ms-deli/`.
   - Pengguna dapat langsung belajar begitu aplikasi dipasang pertama kali **100% tanpa koneksi internet**.
2. **Modul Unduhan Mandiri (`Downloadable` di luar APK):**
   - **Melayu Langkat (`ms-langkat` / `melayu_langkat`)** -> `dist/releases/v1.1.0/module_langkat.zip` (`82.273 byte`).
   - **Melayu Palembang (`ms-palembang` / `melayu_palembang`)** -> `dist/releases/v1.1.0/module_palembang.zip` (`84.219 byte`).
   - Kedua arsip ZIP ini **tidak dimasukkan ke dalam `pubspec.yaml` `assets:`**, melainkan di-host pada GitHub Releases (`https://github.com/rynnxz/KATARA/releases/download/v1.1.0/...`) dan diunduh sesuai pilihan pengguna melalui [`ModuleDownloadService`](file:///c:/lomba/Budaya%20Go%202026/KATARA/lib/services/module_download_service.dart).

---

## 2. Struktur Direktori Korpus & Paket Modul

```text
KATARA/
├── melayu-deli-dataset/
│   ├── raw/                  # Korpus mentah & ekspansi Melayu Deli
│   ├── curated/              # melayu_deli_master.json (364 kata, 10 dialog, 110 kuis)
│   └── metadata/             # sources.json (12 rujukan), license_and_attribution.json
├── melayu-langkat-dataset/
│   ├── raw/                  # Korpus mentah Melayu Langkat (311 entri)
│   ├── curated/              # melayu_langkat_master.json (308 kata, 10 dialog, 110 kuis)
│   └── metadata/             # sources.json (SRC-LK-0001..0006)
├── melayu-palembang-dataset/
│   ├── raw/                  # Korpus mentah Melayu Palembang Sari-sari & Bebaso (311 entri)
│   ├── curated/              # melayu_palembang_master.json (308 kata, 10 dialog, 110 kuis)
│   └── metadata/             # sources.json (SRC-PLG-0001..0006)
├── assets/content/
│   ├── courses.json          # Daftar kursus (ms-deli: active, ms-langkat & ms-palembang: downloadable)
│   ├── module_catalog.json   # Katalog modul beserta URL unduhan, ukuran byte, dan hash SHA-256
│   └── ms-deli/              # Paket kompilasi bawaan Melayu Deli
└── dist/releases/v1.1.0/
    ├── module_langkat.zip    # Paket modul unduhan Melayu Langkat
    ├── module_palembang.zip  # Paket modul unduhan Melayu Palembang
    └── module_catalog.json   # Manifest katalog rilis GitHub
```

---

## 3. Isi Arsip ZIP Modul (`module_<dialek>.zip`)

Setiap arsip ZIP modul berisi berkas JSON terkompilasi dengan skema yang identik dengan `assets/content/ms-deli/`:

| Berkas | Deskripsi |
|---|---|
| `module_manifest.json` | Metadata modul (`id`, `course_id`, `dialect_id`, `content_version`, `vocabulary_count`, `lesson_count`, `quiz_count`). |
| `words.json` | >= 300 kosakata lengkap dengan `pronunciation`, `example_sentence`, `example_translation`, `raw_register`, `region`, `confidence`, dan `sources`. |
| `phrases.json` | >= 30 frasa dan ungkapan idiomatik beserta catatan budaya (`cultural_note`). |
| `sentences.json` | Kalimat latihan penyusunan kata (`word_arrange`) dengan `word_ids`. |
| `dialogues.json` | 10 percakapan kontekstual multi-giliran (`lines`). |
| `units.json` | 16 unit pembelajaran berjenjang (64 pelajaran: `vocab`, `dialogue`, `review`, `jawi`, `boss`). |
| `letters.json` | Huruf Jawi Melayu beserta bentuk sambung (`isolated`, `initial`, `medial`, `final`). |
| `articles.json` & `cards.json` | Artikel ensiklopedia budaya dan kartu koleksi budaya daerah. |
| `quiz_bank.json` | 110 soal kuis tervalidasi (`mcq`, `fill_blank`, `match`). |
| `references.json` | Daftar pustaka akademik dan monograf Balai Bahasa untuk dialek tersebut. |

---

## 4. Pipeline Kompilasi & Pembuatan Paket Modul

Jalankan ketiga perintah berikut secara berurutan dari direktori akar proyek:

```powershell
# 1. Bangun korpus riset terkurasi (Deli, Langkat, Palembang)
dart run tool/build_dialect_datasets.dart

# 2. Kompilasi modul bawaan Melayu Deli ke assets/content/ms-deli/
dart run tool/build_content.dart

# 3. Bangun arsip ZIP modul unduhan & hitung hash SHA-256 otomatis
dart run tool/build_modules.dart
```

---

## 5. Keamanan & Siklus Hidup Pemasangan Modul

[`ModuleDownloadService`](file:///c:/lomba/Budaya%20Go%202026/KATARA/lib/services/module_download_service.dart) dan [`ContentSeeder`](file:///c:/lomba/Budaya%20Go%202026/KATARA/lib/data/content/content_seeder.dart) menerapkan pengamanan berlapis:
1. **Verifikasi SHA-256:** Hash berkas ZIP yang diunduh dihitung di memori dan dicocokkan dengan `sha256` pada `module_catalog.json`. Jika berbeda, instalasi langsung dibatalkan sebelum menyentuh SQLite.
2. **Proteksi Zip-Slip (Path Traversal):** Setiap nama berkas di dalam ZIP diperiksa terhadap pola `..`, `/`, atau `\`.
3. **Pertukaran Direktori Atomik:** Ekstraksi dilakukan ke direktori sementara `.staging_<courseId>`, divalidasi kelengkapan berkas wajibnya, lalu dipindahkan ke direktori target.
4. **Penghapusan Modul Tanpa Kehilangan Progres:** Saat pengguna menghapus modul (`uninstallModule`), hanya tabel konten baca-saja (`words`, `phrases`, `units`, dll. untuk `course_id` tersebut) dan berkas lokal yang dihapus. Tabel progres pengguna (`course_progress`, `word_mastery`, `xp_events`) tetap utuh.
