# Laporan Riset Linguistik & Provenans Data: Bahasa Melayu Langkat (`melayu_langkat`)

**Tanggal Laporan:** 11 November 2026  
**Kode Bahasa / Modul:** `ms-langkat` (`melayu_langkat`)  
**Wilayah Tutur:** Kabupaten Langkat, Provinsi Sumatera Utara (Tanjung Pura, Stabat, Secanggang, Pangkalan Brandan, Babalan, Hinai, Bahorok, Besitang)  

---

## 1. Karakteristik Linguistik Bahasa Melayu Langkat

1. **Fonologi & Variasi Sub-Wilayah:**
   - **Realisasi Vokal Akhir `/a/` -> `[ə]` (`-e`):** Seperti serumpun Melayu Pesisir Sumatera Timur lainnya, vokal `/a/` pada suku akhir terbuka direalisasikan menjadi pepet `[ə]` (*ape*, *mane*, *siape*, *bile*, *saye*, *kite*, *kualo/kuale*).
   - **Peluluhan Konsonan `/r/` Akhir Disertai Pembulatan Vokal `[-o]`:** Di wilayah Tanjung Pura, Stabat, dan Secanggang, urutan bunyi akhir `/-ar/`, `/-ur/`, dan `/-ir/` sangat sering terdengar membulat menjadi `[-o]` atau `[-e]`, misalnya *apakabo* `[apə kabo]` (apa kabar), *tikar* -> `[tiko]`, *bubur* -> `[bubo]`, *kundur* -> `[kundo]`, *nyiur* -> `[ɲio]`.
   - **Variasi Sub-Regional Langkat:**
     - **Tanjung Pura (Pusat Budaya & Kesultanan):** Mempertahankan kosakata adat istana, sastra lisan (pantun dan syair), serta kesantunan religius di sekitar kawasan Masjid Azizi.
     - **Stabat & Hinai (Aliran Sungai Wampu & Dataran Pertanian):** Kaya akan kosakata ekologi sungai, pertanian sawah/kebun, dan kuliner *anyang* serta *bubur pedas*.
     - **Secanggang & Pangkalan Brandan (Pesisir Selat Malaka):** Kaya akan leksikon maritim, hutan bakau, pasang surut (*pasang besar*, *beting*, *kualo*, *jermal*, *bubu*, *tangkul*), serta pengolahan *belacan*, *cencaluk*, dan *ikan asin*.
     - **Bahorok (Langkat Hulu):** Memiliki leksikon sungai berbatu (*lubuk*, *ikan jurung*) dan hasil hutan/kebun (*tempoyak*, *lempuk durian*).

---

## 2. Daftar Sumber Rujukan Terdokumentasi (6 Sumber)

| ID Sumber | Judul & Penulis | Tahun | Penerbit / Repositori |
| --- | --- | --- | --- |
| `SRC-LK-0001` | *Kamus Melayu Sumatera Utara - Indonesia* (Chairani Nasution dkk.) | 2018 | Balai Bahasa Provinsi Sumatera Utara (`https://balaibahasasumut.kemdikbud.go.id/`) |
| `SRC-LK-0002` | *Struktur Bahasa Melayu Langkat* (Tim Peneliti Bahasa Daerah Sumut) | 1985 | Pusat Pembinaan dan Pengembangan Bahasa Kemdikbud (`https://repositori.kemdikbud.go.id/`) |
| `SRC-LK-0003` | *Kajian Kosakata dan Fonologi Bahasa Melayu Dialek Langkat di Tanjung Pura dan Secanggang* | 2019 | Universitas Sumatera Utara (`https://repository.usu.ac.id/`) |
| `SRC-LK-0004` | *Sastra Lisan Melayu Langkat: Pantun, Syair, dan Tradisi Lisan Kesultanan Langkat* (Tengku Syarfina dkk.) | 2002 | Pusat Bahasa Depdiknas (`https://repositori.kemdikbud.go.id/`) |
| `SRC-LK-0005` | *Warisan Budaya Takbenda Kabupaten Langkat: Adat, Kuliner, dan Tradisi Melayu Langkat* | 2022 | Kemendikbudristek RI (`https://warisanbudaya.kemdikbud.go.id/`) |
| `SRC-LK-0006` | *Variasi Sosiolinguistik Sapaan Kekerabatan Masyarakat Melayu di Stabat dan Hinai Kabupaten Langkat* | 2021 | Universitas Negeri Medan (`https://jurnal.unimed.ac.id/`) |

---

## 3. Statistik Korpus & Distribusi Verifikasi

- **Total Kosakata Terkurasi (`vocabulary`):** `308` lema (melampaui target minimum 300 lema)
- **Total Kosakata Mentah (`raw/langkat_research_corpus.json`):** `311` lema (termasuk `2` lema `rejected` dan `1` lema `disputed` yang disaring keluar dari file kurasi)
- **Distribusi Status Verifikasi Kurasi:** `306` lema `verified` (`99,35%`) dan `2` lema `needs_review` (`0,65%`).
- **Jumlah Kategori Kosakata:** `10` kategori (`greetings_and_address`, `pronouns_and_particles`, `kinship_and_society`, `coastal_and_fishery`, `riverine_and_nature`, `food_and_culinary`, `household_and_architecture`, `daily_actions`, `qualities_and_feelings`, `culture_and_tradition`)
- **Total Ekspresi & Ungkapan:** `40` ekspresi
- **Total Kalimat Contoh:** `353` kalimat (`45` kalimat mandiri + `308` kalimat contoh leksikal)
- **Total Percakapan Kontekstual:** `10` dialog
- **Total Soal Kuis:** `110` soal
- **Keterbatasan Data:** Perbedaan prosodi antara penutur Langkat Hulu (Bahorok) dan Langkat Pesisir (Secanggang/Brandan) direpresentasikan melalui catatan fonetis dan label wilayah, belum mencakup rekaman audio penutur asli.
