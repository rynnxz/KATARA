# Laporan Validasi & Kontrol Kualitas Data (Data Quality Control)

**Tanggal Pemeriksaan:** 10 November 2026  
**Status Validasi:** LULUS (*0 Critical Errors*)

---

## 1. Ringkasan Pemeriksaan Otomatis

Pemeriksaan kualitas dijalankan secara terprogram terhadap seluruh file di `raw/`, `curated/`, `references/`, `exports/`, dan `schemas/`:

| Parameter Pemeriksaan | Hasil | Detail |
|---|---|---|
| Validitas Sintaks JSON | **LULUS** | Seluruh 20 file JSON berhasil di-serialize dan di-parse sesuai standar RFC 8259. |
| Pemeriksaan ID Duplikat | **LULUS** | `358` ID unik diperiksa lintas 7 kategori data + 12 ID sumber (`SRC-0001`–`SRC-0012`); **0 duplikat**. |
| Pemeriksaan Entri Kosakata Duplikat | **LULUS** | Kombinasi `(normalized_term, part_of_speech, dialect)` diperiksa pada `215` entri; **0 duplikat**. |
| Konsistensi Skema JSON | **LULUS** | Seluruh field wajib (*required properties*) dan tipe data sesuai dengan 8 file di `schemas/`. |
| Validitas & Keberadaan URL Sumber | **LULUS** | Seluruh `12` sumber referensi memiliki URL valid dan tidak menggunakan domain contoh/palsu. |
| Integritas Referensi Sumber (`source_ids`) | **LULUS** | `892` tautan `source_ids` pada entri berhasil diverifikasi terhadap `references/sources.json`. |
| Integritas Referensi Silang Kalimat (`related_vocab_ids`) | **LULUS** | `181` referensi ID kosakata di dalam `sentences.json` valid dan merujuk ke `vocabulary.json`. |
| Pemfilteran Atribusi Dialek (`curated/`) | **LULUS** | 3 entri `disputed` dan 2 entri `rejected` (dialek Melayu Perak) disimpan di `raw/` sebagai jejak audit tetapi dikecualikan dari `curated/`. |

---

## 2. Distribusi Tingkat Keyakinan (*Confidence*) & Status Validasi

- **Total Entri Raw**: `358`
- **Total Entri Curated**: `353`
- **Status `verified`**: `348` entri (97.2%)
- **Status `needs_review`**: `5` entri
- **Status `disputed`**: `3` entri
- **Status `rejected`**: `2` entri

---

## 3. Jejak Audit Entri Non-Verified (`needs_review`, `disputed`, `rejected`)

Sesuai aturan pengumpulan data (Bagian 10 Master Prompt), tidak ada data bermasalah atau meragukan yang dihapus secara diam-diam. Seluruhnya dipertahankan di dalam direktori `raw/` dengan catatan eksplisit:

- [needs_review] MD-000052 (Isnin): Hasil audit baku_cek (w052): "Isnin" adalah bentuk Melayu klasik/liturgis (dan baku Malaysia); dalam percakapan harian Melayu Deli modern di Medan, penutur lebih sering memakai "Senin/Senen". Perlu konfirmasi apakah tetap diajarkan sebagai ragam sastra/adat.
- [needs_review] MD-000053 (Khamis): Hasil audit baku_cek (w053): "Khamis" merupakan ragam tulis Jawi/klasik; dalam tuturan lisan harian masyarakat Deli lebih umum terdengar "Kamis". Disimpan dengan status needs_review.
- [needs_review] MD-000062 (seluar): Hasil audit baku_cek (w062): "Seluar" dipakai dalam konteks busana adat Melayu Deli dan oleh penutur tua; dalam percakapan harian di Medan kini lebih dominan "celana/celane".
- [needs_review] MD-000063 (kasut): Hasil audit baku_cek (w063): Dalam Melayu Deli tradisional "kasut" merujuk pada selop/alas kaki adat; untuk sepatu modern sehari-hari penutur memakai kata "sepatu".
- [disputed] MD-000211 (bah): Status disputed: Partikel "bah" sangat populer dalam dialek Melayu Medan perkotaan akibat kontak intensif dengan bahasa-bahasa Batak, tetapi BUKAN partikel asli Bahasa Melayu Deli tradisional/istana. Disimpan di raw/ dengan label melayu_medan_kolokial.
- [disputed] MD-000212 (kelen): Status disputed: Sangat umum dalam bahasa pergaulan lintas etnis Kota Medan, namun dalam ragam Melayu Deli santun lebih dipilih "kalian" atau "awak semua".
- [disputed] MD-000213 (hang): Status disputed: Lebih khas pada dialek Melayu Kedah/Pulau Pinang dan kantong pesisir tertentu; di Deli inti lebih dominan "awak" dan "kau". Perlu verifikasi penutur asli per kecamatan.
- [rejected] MD-000214 (kome): Status rejected (Salah Atribusi Dialek): Berdasarkan verifikasi PRPM DBP (SRC-0012), "kome" adalah pronomina khas Loghat Perak (Malaysia), bukan kosakata Bahasa Melayu Deli. Disimpan di raw/ sebagai rekam audit dan dikeluarkan dari curated/.
- [rejected] MD-000215 (mike): Status rejected (Salah Atribusi Dialek): Berdasarkan verifikasi PRPM DBP (SRC-0012), "mike/mika" adalah pronomina khas Loghat Perak/Pahang, bukan Bahasa Melayu Deli. Disimpan di raw/ sebagai rekam jejak kualitas data dan dikeluarkan dari curated/.
- [needs_review] EXP-000040 (Kurang asam!): Perlu konfirmasi penutur asli apakah perlu dimasukkan ke materi belajar tingkat lanjut.
