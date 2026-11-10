# Melayu Deli Knowledge Base & Linguistic Dataset (`melayu-deli-dataset`)

Repositori data terstruktur, terdokumentasi, dan terverifikasi untuk **Bahasa Melayu Deli (`ms-deli`)**, disusun khusus sebagai fondasi *Knowledge Base* aplikasi **KATARA (*LinguaNusa*)** tanpa mengubah kode atau database aplikasi utama sebelum peninjauan manusia (*Human-in-the-Loop*).

---

## Ringkasan Statistik Dataset (v1.0.0)

- **Total Entri Raw (`raw/`)**: **358 entri**
- **Total Entri Terkurasi (`curated/`)**: **353 entri**
- **Total Entri Terverifikasi (`verified`)**: **348 entri**
- **Total Sumber Referensi Ilmiah (`references/`)**: **12 sumber** (`SRC-0001` s/d `SRC-0012`)
- **Cakupan Warisan Draf Awal KATARA**: 100% (67 kosakata `w001`–`w067`, 10 frasa `p001`–`p010`, 10 kalimat `s001`–`s010`, 2 dialog `d001`–`d002`, 3 artikel budaya `art01`–`art03`, dan 5 kartu koleksi `c01`–`c05`).

---

## Struktur Direktori

```text
melayu-deli-dataset/
├── README.md
├── raw/
│   ├── vocabulary.json            # 215 entri kosakata (termasuk needs_review, disputed, rejected)
│   ├── expressions.json           # 40 ungkapan sehari-hari & sapaan adat
│   ├── sentences.json             # 40 kalimat contoh & percakapan kontekstual
│   ├── grammar.json               # 15 kaidah fonologi, morfologi, sintaksis, & ortografi Jawi
│   ├── idioms.json                # 20 peribahasa, idiom, & pantun adat Melayu Deli
│   ├── cultural_knowledge.json    # 16 dokumentasi budaya, kuliner, adat, & sosiolinguistik
│   └── historical_knowledge.json  # 12 tonggak sejarah Kesultanan Deli & perkembangan bahasa
├── curated/
│   ├── vocabulary.json            # 210 kosakata Melayu Deli murni (tanpa disputed/rejected)
│   ├── expressions.json           # 40 ungkapan Melayu Deli terkurasi
│   ├── sentences.json             # 40 kalimat & dialog Melayu Deli terkurasi
│   └── melayu_deli_master.json    # Bundel utama gabungan seluruh kategori terkurasi + metadata
├── references/
│   ├── sources.json               # 12 sumber referensi ilmiah & institusional terstruktur
│   └── bibliography.md            # Daftar pustaka dan rincian sitasi yang mudah dibaca
├── reports/
│   ├── research_report.md         # Laporan utama penelitian, temuan linguistik, & rekomendasi integrasi
│   ├── validation_report.md       # Hasil pemeriksaan kontrol kualitas (QA) otomatis
│   ├── coverage_report.md         # Statistik cakupan kelas kata, kategori semantis, & konten KATARA
│   └── unresolved_data.md         # Daftar entri needs_review, disputed, dan rejected untuk tinjauan
├── exports/
│   ├── melayu_deli_master.csv     # Ekspor tabel datar (CSV) seluruh entri terkurasi
│   └── dataset_statistics.json    # Metrik dan rincian statistik dataset dalam format JSON
└── schemas/
    ├── vocabulary.schema.json
    ├── expression.schema.json
    ├── sentence.schema.json
    ├── grammar.schema.json
    ├── idiom.schema.json
    ├── cultural_knowledge.schema.json
    ├── historical_knowledge.schema.json
    └── source.schema.json
```

---

## Panduan Peninjauan Manusia (Phase 7 — Human Review)

1. Baca laporan penelitian lengkap di [`reports/research_report.md`](reports/research_report.md).
2. Tinjau daftar entri yang membutuhkan konfirmasi penutur asli (`needs_review` dan `disputed`) di [`reports/unresolved_data.md`](reports/unresolved_data.md).
3. Periksa laporan validasi bebas galat di [`reports/validation_report.md`](reports/validation_report.md).
4. Setelah disetujui, ikuti rekomendasi integrasi pada Bagian 10 [`reports/research_report.md`](reports/research_report.md) untuk memperbarui `konten/linguanusa_konten_draf_v0.1.json` dan menjalankan `dart run tool/build_content.dart`.
