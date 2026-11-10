# Laporan Riset Linguistik & Provenans Data: Bahasa Melayu Palembang (`melayu_palembang`)

**Tanggal Laporan:** 11 November 2026  
**Kode Bahasa / Modul:** `ms-palembang` (`melayu_palembang`)  
**Wilayah Tutur:** Kota Palembang (Seberang Ilir, Seberang Ulu, Tepian Sungai Musi) dan wilayah sekitar di Sumatera Selatan  

---

## 1. Karakteristik Linguistik & Diglosia Bahasa Melayu Palembang

1. **Sistem Dua Tingkat Tutur (Diglosia):**
   - **Baso Palembang Alus (*Bebaso*):** Ragam tinggi dan santun yang berakar pada tradisi Kesultanan Palembang Darussalam, digunakan ketika berbicara kepada orang tua, sesepuh (*Yayi*, *Nyai*), ulama, serta dalam upacara adat (*madik*, *menyengguk*, *ngelamar*, *munggah*). Contoh kosakata khas *Bebaso*: **kulo** (saya), **niko** (Anda), **pundi** (mana), **sinten** (siapa), **napi** (apa), **pinten** (berapa), **nedo** (tidak), **rompok** (rumah), **tedoh** (makan), **sare** (tidur), **wangsul** (pulang), **rawuh** (datang), **krihin** (dahulu), dan **kemawon** (saja).
   - **Baso Palembang Sari-sari:** Ragam pergaulan sehari-hari yang menjadi *lingua franca* di Palembang dan Sumatera Selatan.

2. **Ciri Fonologis Utama:**
   - **Korespondensi Vokal Akhir `/a/` Menjadi `[ɔ]` (Ditulis `-o`):** Vokal `/a/` pada posisi akhir terbuka dan sejumlah suku tertutup berubah menjadi `[ɔ]`, seperti *apo* (apa), *siapo* (siapa), *mano* (mana), *ngapo* (mengapa), *kito* (kita), *galo* (semua), *cindo* (cantik), *mejo* (meja), dan *jendelo* (jendela).
   - **Perubahan Konsonan Akhir `/-r/` dan `/-l/` pada Kata Tertentu Menjadi Hentian Glotal `[ʔ]` (Ditulis `-k`):** Misalnya *besar* -> **besak** `[bəsaʔ]`, *tidur* -> **tiduk** `[tidoʔ]`, *kecil* -> **kecik** `[kətʃiʔ]`, *ambil* -> **ambek** `[ambeʔ]`.
   - **Pelemahan Vokal `/a/` pada Suku Akhir Tertutup Menjadi Pepet `[ə]` (Ditulis `-e-`):** Misalnya *dalam* -> **dalem** `[daləm]`, *malam* -> **malem** `[maləm]`, *pedas* -> **pedes** `[pədəs]`, *dekat* -> **deket** `[dəkət]`, *kental* -> **kentel** `[kəntəl]`.

3. **Morfologi & Partikel Khas:**
   - Prefiks aktif nasal `N-` (*nyingok*, *ngambek*, *ngenjuk*, *meli*, *nyirup*), prefiks `be-` (*begesah*, *begawe*, *bekayuh*), dan sufiks benefaktif/kausatif **`-ke`** (*ambekke*, *belike*, *bentangke*).
   - Partikel dan adverbia ikonik: **nian** (sekali/sangat), **bae** (saja), **pulo** (pula), **galo** (semua), **dak** (tidak), **katek** (tidak ada), **la** (sudah), dan **agek** (nanti).
   - Orientasi spasial khas perairan dan rumah panggung: **ulu** vs **ilir**, **pucuk** (atas) vs **bawah**, serta **jabo** (luar) vs **dalem** (dalam).

---

## 2. Daftar Sumber Rujukan Terdokumentasi (6 Sumber)

| ID Sumber | Judul & Penulis | Tahun | Penerbit / Repositori |
| --- | --- | --- | --- |
| `SRC-PLG-0001` | *Kamus Bahasa Palembang - Indonesia* (Tim Balai Bahasa Sumsel) | 2016 | Balai Bahasa Provinsi Sumatera Selatan (`https://balaibahasasumsel.kemdikbud.go.id/`) |
| `SRC-PLG-0002` | *Struktur Bahasa Palembang* (R.M. Arif, Zainal Abidin Gani, dkk.) | 1981 | Pusat Pembinaan dan Pengembangan Bahasa Kemdikbud (`https://repositori.kemdikbud.go.id/`) |
| `SRC-PLG-0003` | *Morfologi dan Sintaksis Bahasa Melayu Palembang* (Muslimin dkk.) | 1986 | Pusat Pembinaan dan Pengembangan Bahasa Kemdikbud (`https://repositori.kemdikbud.go.id/`) |
| `SRC-PLG-0004` | *Pemertahanan Bahasa Palembang Alus (Bebaso) di Kalangan Masyarakat Palembang* | 2020 | Universitas Sriwijaya (`https://repository.unsri.ac.id/`) |
| `SRC-PLG-0005` | *Warisan Budaya Takbenda Sumatera Selatan: Kuliner, Songket, Rumah Limas, dan Adat Palembang* | 2022 | Kemendikbudristek RI (`https://warisanbudaya.kemdikbud.go.id/`) |
| `SRC-PLG-0006` | *Leksikon Ekologi Sungai Musi dan Budaya Perairan dalam Bahasa Melayu Palembang* | 2021 | UIN Raden Fatah Palembang (`https://jurnal.radenfatah.ac.id/`) |

---

## 3. Statistik Korpus & Distribusi Verifikasi

- **Total Kosakata Terkurasi (`vocabulary`):** `308` lema (mencakup leksikon *Sari-sari* dan *Bebaso*)
- **Total Kosakata Mentah (`raw/palembang_research_corpus.json`):** `311` lema (termasuk `2` lema `rejected` dan `1` lema `disputed`)
- **Distribusi Status Verifikasi Kurasi:** `306` lema `verified` (`99,35%`) dan `2` lema `needs_review` (`0,65%`).
- **Jumlah Kategori Kosakata:** `10` kategori (`greetings_and_address`, `pronouns_and_particles`, `bebaso_high_register`, `kinship_and_society`, `musi_riverine_and_nature`, `food_and_culinary`, `household_and_architecture`, `daily_actions`, `qualities_and_feelings`, `culture_and_tradition`)
- **Total Ekspresi & Ungkapan:** `40` ekspresi
- **Total Kalimat Contoh:** `353` kalimat (`45` kalimat mandiri + `308` kalimat contoh leksikal)
- **Total Percakapan Kontekstual:** `10` dialog (mencakup dialog *Sari-sari* dan dialog *Bebaso*)
- **Total Soal Kuis:** `110` soal
- **Keterbatasan Data:** Kosakata *Bebaso* yang terdokumentasi difokuskan pada kosakata aktif yang masih dikenali dalam silaturahmi keluarga dan upacara adat di Seberang Ilir serta Seberang Ulu; leksikon arkais naskah keraton abad ke-18 masih memerlukan digitasi filologis terpisah.
