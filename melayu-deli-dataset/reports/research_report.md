# Laporan Penelitian & Kurasi Dataset Bahasa Melayu Deli

**Tanggal Laporan:** 10 November 2026  
**Target Aplikasi:** KATARA (*LinguaNusa*) — Pembelajaran Bahasa & Budaya Melayu Deli  
**Status Integrasi:** *Read-Only / Menunggu Persetujuan Manusia (Phase 7)*

---

## 1. Ringkasan Penelitian

Penelitian ini membangun *Knowledge Base* dan dataset terstruktur **Bahasa Melayu Deli** (`ms-deli`) berdasarkan rujukan leksikografi, monograf linguistik Pusat Pembinaan dan Pengembangan Bahasa (Kemdikbud), kamus Balai Bahasa Provinsi Sumatera Utara, tesis dan jurnal ilmiah Universitas Sumatera Utara (USU), serta dokumentasi Warisan Budaya Takbenda (WBTb) Indonesia.

Secara keseluruhan, penelitian ini menghasilkan **358 entri terstruktur** di direktori `raw/` (dan **353 entri terkurasi** di `curated/` setelah memisahkan entri berstatus `disputed` dan `rejected`) yang didukung oleh **12 sumber referensi ilmiah**. Selain memperluas kosakata, ungkapan, kalimat, kaidah tata bahasa, peribahasa/pantun, serta konteks budaya dan sejarah, penelitian ini juga menyelesaikan **audit menyeluruh terhadap 67 kosakata, 10 frasa, 10 kalimat, 2 dialog, dan 8 entri budaya** pada draf awal aplikasi KATARA (`konten/linguanusa_konten_draf_v0.1.json`).

---

## 2. Tujuan Pengumpulan Data

1. **Memperkaya kosakata Bahasa Melayu Deli** lintas kelas kata (*noun*, *verb*, *adjective*, *adverb*, *pronoun*, *numeral*, *preposition*, *conjunction*, *interjection*, *particle*) dan domain budaya (kekerabatan, sapaan adat, kuliner khas, peralatan rumah tangga, aktivitas harian).
2. **Mengumpulkan ungkapan sehari-hari (*daily expressions*)** yang mencerminkan kesantunan Melayu Deli maupun tuturan akrab di Medan dan Deli Serdang.
3. **Mendokumentasikan contoh kalimat dan percakapan kontekstual** di lingkungan keluarga, pasar (*pajak*), bertamu, dan kenduri adat.
4. **Menyusun kaidah tata bahasa (*grammar*) berbasis bukti ilmiah** yang membedakan struktur fonologi, morfologi, dan sintaksis Melayu Deli dari Bahasa Indonesia.
5. **Mengidentifikasi variasi fonologis, ortografis (Latin & Jawi), dan sosiolinguistik** (termasuk perbedaan Bahasa Melayu Deli tradisional vs. Bahasa Indonesia kolokial dialek Medan).
6. **Mengumpulkan peribahasa, idiom, dan pantun adat** (khususnya pantun Telangkai dalam upacara peminangan).
7. **Mendokumentasikan konteks budaya dan sejarah Kesultanan Deli** (termasuk pengisian teks artikel dan fakta kartu koleksi yang sebelumnya masih `null` pada draf awal KATARA).
8. **Menyelesaikan audit catatan `deli_cek` dan `baku_cek`** pada draf konten aplikasi tanpa mengubah kode atau database aplikasi secara langsung.

---

## 3. Metodologi Pencarian & Kurasi

1. **Inspeksi Arsitektur Aplikasi (Read-Only)**: Memeriksa spesifikasi `docs/KATARA_SPEC.md`, skema database SQLite (`lib/data/db/app_database.dart`), generator aset (`tool/build_content.dart`), serta draf konten (`konten/linguanusa_konten_draf_v0.1.json`).
2. **Penelusuran Literatur Ilmiah & Leksikografi**:
   - Kamus rujukan utama: *Kamus Melayu Deli-Indonesia* (Chalil dkk., 1985) dan *Kamus Melayu Sumatera Utara - Indonesia* (Balai Bahasa Sumut, 2018).
   - Monograf struktur bahasa: *Bahasa Melayu Dialek Deli Medan* (Manurung & Zubeirsyah, 1984) dan *Kata Benda dan Kata Sipat Bahasa Melayu Deli* (Muchtar dkk., 1993).
   - Penelitian sosiolinguistik, sastra lisan, dan paremiologi: Tesis USU (Syarfina, 2004), Jurnal *Basastra* (Astari & Mulyadi, 2022), Jurnal *GERAM* (2022), dan repositori WBTb Kemendikbudristek.
3. **Verifikasi Silang & Pemisahan Dialek**:
   - Setiap entri diberi atribut `dialect`, `region`, `confidence` (`high`, `medium`, `low`), dan `verification_status` (`verified`, `needs_review`, `disputed`, `rejected`).
   - Kata dari dialek Melayu lain (seperti pronomina Melayu Perak `kome` dan `mike`) atau ujaran perkotaan Medan yang bersumber dari substratum non-Melayu (seperti partikel `bah` dan pronomina `kelen`) dianalisis secara eksplisit dan dipisahkan dari korpus terkurasi `curated/`.

---

## 4. Daftar Sumber Referensi

| ID Sumber | Tahun | Penulis / Institusi | Judul Sumber | Jenis | Reliabilitas |
|---|---:|---|---|---|---|
| `SRC-0001` | 2026 | Tim Pengembang KATARA (LinguaNusa) | Draf Konten Awal Aplikasi KATARA / LinguaNusa Bahasa Melayu Deli v0.1 | `project_corpus` | `medium` |
| `SRC-0002` | 1985 | Hayati Chalil, Masindan, T. Sita Syaritsa, T. Sylviana Sinar, & Oliviana Harahap (Ed. Siti Aisiyah Ibrahim) | Kamus Melayu Deli-Indonesia | `dictionary` | `high` |
| `SRC-0003` | 1984 | Syahdan Manurung & Zubeirsyah | Bahasa Melayu Dialek Deli Medan | `academic_book` | `high` |
| `SRC-0004` | 1993 | Muhizar Muchtar, Nurhayati Lubis, Namsyah Hot, & Asiah Taty | Kata Benda dan Kata Sipat Bahasa Melayu Deli | `academic_book` | `high` |
| `SRC-0005` | 2018 | Chairani Nasution, Sriasrianti, Anharuddin Hutasuhut, Zufri Hidayat, & Edizal Hatmi | Kamus Melayu Sumatera Utara - Indonesia | `dictionary` | `high` |
| `SRC-0006` | 2004 | Tengku Syarfina | Sistem Sapaan dan Istilah Kekerabatan dalam Bahasa Melayu Deli: Tinjauan Sosiolinguistik | `thesis_dissertation` | `high` |
| `SRC-0007` | 2022 | Astari & Mulyadi | Metafora Binatang dalam Peribahasa Dialek Melayu Deli | `academic_journal` | `high` |
| `SRC-0008` | 2024 | Ibnu Hajar, Kristiawan Indriyanto, & Dian Syahfitri | Representasi Nilai Kearifan Lokal pada Pantun Melayu Deli dan Pelestariannya Melalui Telangkai | `academic_journal` | `high` |
| `SRC-0009` | 2023 | Direktorat Pelindungan Kebudayaan & Dinas Kebudayaan Provinsi Sumatera Utara | Pencatatan Warisan Budaya Takbenda Indonesia: Budaya, Kuliner, dan Tradisi Melayu Deli Sumatera Utara | `cultural_archive` | `high` |
| `SRC-0010` | 1996 | Tengku Luckman Sinar | Sejarah Medan Tempo Doeloe & Kronik Kesultanan Deli | `historical_archive` | `high` |
| `SRC-0011` | 2024 | Kontributor Wikipedia & Wiktionary Bahasa Indonesia | Ensiklopedia Terbuka Bahasa Melayu Deli & Daftar Kosakata Melayu Medan/Deli | `community_documentation` | `medium` |
| `SRC-0012` | 2020 | Dewan Bahasa dan Pustaka (DBP) | Pusat Rujukan Persuratan Melayu (PRPM) — Kamus Bahasa Melayu & Perbandingan Dialek Nusantara | `dictionary` | `high` |

Detail lengkap beserta tautan repositori tersedia di [`references/sources.json`](../references/sources.json) dan [`references/bibliography.md`](../references/bibliography.md).

---

## 5. Jumlah Data per Kategori

Tabel berikut merangkum jumlah data hasil penelitian nyata yang tersimpan di dalam dataset:

| Kategori | Jumlah (Raw) | Terkurasi (Curated) | Terverifikasi (`verified`) | Perlu Tinjauan (`needs_review`) | Diperdebatkan (`disputed`) | Ditolak (`rejected`) |
|---|---:|---:|---:|---:|---:|---:|
| Vocabulary | 215 | 210 | 206 | 4 | 3 | 2 |
| Expressions | 40 | 40 | 39 | 1 | 0 | 0 |
| Sentences | 40 | 40 | 40 | 0 | 0 | 0 |
| Grammar | 15 | 15 | 15 | 0 | 0 | 0 |
| Idioms | 20 | 20 | 20 | 0 | 0 | 0 |
| Cultural Knowledge | 16 | 16 | 16 | 0 | 0 | 0 |
| Historical Knowledge | 12 | 12 | 12 | 0 | 0 | 0 |
| **TOTAL** | **358** | **353** | **348** | **5** | **3** | **2** |

---

## 6. Temuan Penting Penelitian

### A. Hasil Audit Catatan `deli_cek` dan `baku_cek` pada Draf Awal KATARA
1. **Konfirmasi Vokal Akhir Pepet `[-ə]` / `-e` (`deli_cek`)**:
   - Entri `due` (`w008`), `tige` (`w009`), `lime` (`w011`), `bile` (`w042`), `saye` (`w003`), `kite` (`w004`), `ape` (`w037`), `mane` (`w038`), `siape` (`w039`), dan `berape` (`w041`) **terkonfirmasi kuat** dalam *Bahasa Melayu Dialek Deli Medan* (Manurung & Zubeirsyah, 1984) sebagai realisasi fonologis reguler `/-a#/ -> [-ə]`.
   - Entri `lapan` (`w014`) terkonfirmasi mengalami aferesis suku kata awal dari *delapan* dalam tuturan lisan Melayu Deli (`SRC-0002`, `SRC-0003`).
2. **Konfirmasi Deiksis Ganda Pronomina `awak` (`p010` / `MD-000073`)**:
   - Dalam Bahasa Melayu Deli dan Melayu Medan, kata `awak` memiliki **fungsi deiktik ganda** yang bergantung pada konteks pragmatis dan intonasi: (a) pronomina persona pertama tunggal (*saya/aku*) untuk merendahkan diri secara akrab (*"Rumah awak jauh di Labuhan"*), dan (b) pronomina persona kedua tunggal (*kamu/engkau*) saat menyapa lawan bicara sebaya (*"Awak nak ke mane?"*).
3. **Konfirmasi Pergeseran Semantis Khas Deli**:
   - `lemak` (`w031` / `MD-000031`): bermakna **gurih dan sedap** (terutama masakan bersantan atau pulut kuning).
   - `semalam` (`MD-000181`): bermakna **kemarin** (seluruh hari sebelum hari ini), bukan hanya "tadi malam".
   - `pajak` (`MD-000167`): bermakna **pasar tradisional** (tempat jual beli sayur, ikan, dan kebutuhan pokok).
   - `kali` (`MD-000180`): adverbia intensifier pascaposisi bermakna **sangat / sekali** (*lemak kali*, *jauh kali*).
4. **Evaluasi Kosakata Ragam Baku vs. Lisan Harian (`baku_cek`)**:
   - `Ahad` (`w054`), `bilik` (`w059`), dan `tingkap` (`w060`) tercatat sahih dalam *Kamus Melayu Deli-Indonesia* (1985), namun digunakan berdampingan dengan `Minggu`, `kamar`, dan `jendela` pada generasi muda.
   - `Isnin` (`w052`), `Khamis` (`w053`), `seluar` (`w062`), dan `kasut` (`w063`) diberi status `needs_review` karena dalam percakapan lisan harian masyarakat Melayu Deli di Medan saat ini, bentuk `Senin`, `Kamis`, `celana/celane`, dan `sepatu` lebih dominan kecuali dalam konteks busana adat (*seluar teluk belanga*, *kasut manik*).

### B. Kelengkapan Konten Budaya yang Sebelumnya Kosong (`null`)
Draf awal `konten/linguanusa_konten_draf_v0.1.json` memiliki 3 artikel budaya (`art01` Putri Hijau, `art02` Istana Maimun, `art03` Guru Patimpus) dan 5 kartu koleksi (`c01`–`c05`) yang kolom deskripsinya masih `null`. Seluruhnya kini telah dilengkapi dengan narasi ilmiah terverifikasi pada [`raw/cultural_knowledge.json`](../raw/cultural_knowledge.json) (`CUL-000001` s/d `CUL-000007`) dan [`raw/historical_knowledge.json`](../raw/historical_knowledge.json).

---

## 7. Variasi Bahasa yang Ditemukan

1. **Variasi Sub-Wilayah (Pesisir Hilir vs. Perkotaan Medan)**:
   - Komunitas Melayu tua di Labuhan Deli, Marelan, dan Hamparan Perak mempertahankan vokal akhir `[-ə]` (*ape, mane, tige*) dan apokop `/r/` (*kabo, paso*) lebih konsisten dibandingkan penutur muda di pusat Kota Medan yang sering bervariasi dengan vokal `[-a]` akibat kontak intensif dengan Bahasa Indonesia.
2. **Variasi Ortografi (Ejaan `-e` vs. `-a` dan Aksara Jawi)**:
   - Karena bunyi pepet akhir `[-ə]` berada di antara `a` dan `e`, penulisan Latin sehari-hari bervariasi antara ejaan fonetis (`saye`, `ape`, `mane`) dan ejaan etimologis (`saya`, `apa`, `mana`). Dalam dataset ini, ejaan dialektal `-e` disimpan sebagai entri utama untuk kata-kata kunci pembelajaran sesuai `KATARA_SPEC.md`, sedangkan bentuk `-a` didokumentasikan secara sistematis di dalam array `variants`.
3. **Batas Dialek Melayu Deli vs. Bahasa Melayu Medan Kolokial**:
   - Bahasa Melayu Deli asli dibedakan secara tegas dari *slang* perkotaan Medan multietnis. Kata seperti `bah` (`MD-000211`, dari substratum Batak) dan `kelen` (`MD-000212`, bentuk kolokial dari *kalian*) disimpan di `raw/` dengan status `disputed` sebagai pembanding sosiolinguistik, tetapi dikeluarkan dari `curated/`.

---

## 8. Data yang Belum Terverifikasi / Memerlukan Tinjauan Penutur Asli

Terdapat **5 entri berstatus `needs_review`**, **3 entri berstatus `disputed`**, dan **2 entri berstatus `rejected`**. Rincian lengkap dan alasan linguistik setiap item didokumentasikan pada [`reports/unresolved_data.md`](unresolved_data.md).

---

## 9. Keterbatasan Penelitian

1. **Keterbatasan Akses Rekaman Audio Penutur Asli**: Transkripsi fonetis IPA disusun berdasarkan deskripsi fonologis dalam monograf Manurung & Zubeirsyah (1984) serta Chalil dkk. (1985), belum disertai rekaman suara penutur jati (*native audio files*) untuk fitur TTS/audio aplikasi.
2. **Digitalisasi Kamus Cetak Lawas**: Publikasi primer tahun 1984–1993 tersedia sebagai dokumen cetak di repositori Kemendikbud dan Perpustakaan USU sehingga penarikan data dilakukan melalui pencocokan silang katalog, cuplikan terindeks, dan kamus pemutakhiran Balai Bahasa Sumatera Utara (2018).

---

## 10. Rekomendasi Pengembangan & Integrasi ke Aplikasi KATARA

Berdasarkan pemeriksaan terhadap `tool/build_content.dart`, `lib/data/db/app_database.dart`, dan `lib/data/content/content_models.dart`, berikut adalah peta jalan integrasi setelah dataset ini disetujui manusia:

1. **Pemutakhiran `konten/linguanusa_konten_draf_v0.1.json`**:
   - Perbarui 67 entri `words` (`w001`–`w067`) dengan data terverifikasi dari `curated/vocabulary.json` (`MD-000001`–`MD-000067`), termasuk menghapus label sementara `deli_cek` yang sudah terverifikasi dan memperkaya contoh kalimat.
   - Tambahkan **139 kosakata baru terkurasi** (`MD-000068`–`MD-000210`) ke dalam daftar `words` dan petakan ke unit pembelajaran baru (Unit 9 s/d Unit 16: *Kekerabatan Lanjut, Kuliner Khas Deli, Adat & Kenduri, Alam Pesisir, Percakapan Pasar*).
2. **Pengisian Konten Budaya (`articles` & `cultural_cards`)**:
   - Isi field `content` / `summary` yang masih `null` pada `art01`–`art03` dan `c01`–`c05` menggunakan data dari `CUL-000001` s/d `CUL-000007` di [`raw/cultural_knowledge.json`](../raw/cultural_knowledge.json).
3. **Penambahan Tabel / Modul Tata Bahasa & Peribahasa**:
   - Data pada [`raw/grammar.json`](../raw/grammar.json) (`GRM-000001`–`GRM-000015`) dan [`raw/idioms.json`](../raw/idioms.json) (`IDM-000001`–`IDM-000020`) siap dijadikan kartu tips tata bahasa (*Grammar Tips*) di setiap awal *Lesson* serta konten *Mini Story* / *Pantun Adat* pada fitur Eksplorasi Budaya.
4. **Kompilasi Ulang Aset Offline (`tool/build_content.dart`)**:
   - Setelah `konten/linguanusa_konten_draf_v0.1.json` diperbarui atas persetujuan manusia, jalankan `dart run tool/build_content.dart` untuk menghasilkan ID stabil baru di `tool/id_map.json` dan memperbarui bundel JSON di `assets/content/ms-deli/`.
