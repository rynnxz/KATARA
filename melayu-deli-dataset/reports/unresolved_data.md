# Laporan Data yang Memerlukan Verifikasi Lanjutan (`unresolved_data.md`)

Dokumen ini memuat daftar entri yang memiliki status `needs_review`, `disputed`, atau `rejected` beserta analisis permasalahan dan rekomendasi tindak lanjut oleh penutur asli (*native speaker*) Bahasa Melayu Deli.

---

## 1. Entri Berstatus `needs_review` (Perlu Konfirmasi Penutur Asli / Kurator Kurikulum)

Entri berikut terbukti ada dalam khazanah bahasa Melayu, namun memerlukan keputusan kuratorial apakah akan dipertahankan sebagai bentuk utama di aplikasi KATARA atau diganti dengan padanan lisan harian yang lebih lazim di Deli:

### A. Kosakata (`vocabulary.json`)
| ID | Istilah | Makna | Legacy ID | Catatan & Pertanyaan Verifikasi |
|---|---|---|---|---|
| `MD-000052` | **Isnin** | Senin (hari pertama dalam pekan kerja) | `w052` | Hasil audit baku_cek (w052): "Isnin" adalah bentuk Melayu klasik/liturgis (dan baku Malaysia); dalam percakapan harian Melayu Deli modern di Medan, penutur lebih sering memakai "Senin/Senen". Perlu konfirmasi apakah tetap diajarkan sebagai ragam sastra/adat. |
| `MD-000053` | **Khamis** | Kamis (hari keempat dalam pekan kerja) | `w053` | Hasil audit baku_cek (w053): "Khamis" merupakan ragam tulis Jawi/klasik; dalam tuturan lisan harian masyarakat Deli lebih umum terdengar "Kamis". Disimpan dengan status needs_review. |
| `MD-000062` | **seluar** | celana | `w062` | Hasil audit baku_cek (w062): "Seluar" dipakai dalam konteks busana adat Melayu Deli dan oleh penutur tua; dalam percakapan harian di Medan kini lebih dominan "celana/celane". |
| `MD-000063` | **kasut** | alas kaki; sepatu atau selop tradisional | `w063` | Hasil audit baku_cek (w063): Dalam Melayu Deli tradisional "kasut" merujuk pada selop/alas kaki adat; untuk sepatu modern sehari-hari penutur memakai kata "sepatu". |

### B. Ungkapan (`expressions.json`)
| ID | Ungkapan | Makna | Catatan & Pertanyaan Verifikasi |
|---|---|---|---|
| `EXP-000040` | **Kurang asam!** | Kurang ajar! (ungkapan kejengkelan yang diperhalus dengan eufemisme kuliner "asam" agar tidak terdengar kasar) | Perlu konfirmasi penutur asli apakah perlu dimasukkan ke materi belajar tingkat lanjut. |

---

## 2. Entri Berstatus `disputed` (Perdebatan Batas Dialek Melayu Deli vs. Slang Medan / Dialek Tetangga)

Entri berikut sering terdengar di Kota Medan atau kawasan Selat Malaka, tetapi memiliki atribusi dialek yang diperdebatkan dalam literatur sosiolinguistik. Entri ini **disimpan di `raw/vocabulary.json`** untuk dokumentasi ilmiah, namun **dikecualikan dari `curated/vocabulary.json`**:

| ID | Istilah | Label Dialek | Makna | Alasan Status `disputed` |
|---|---|---|---|---|
| `MD-000211` | **bah** | `melayu_medan_kolokial` | partikel penegas akhir kalimat atau kata seru keheranan di wilayah Medan (pengaruh kontak bahasa Batak di Sumatera Utara) | Status disputed: Partikel "bah" sangat populer dalam dialek Melayu Medan perkotaan akibat kontak intensif dengan bahasa-bahasa Batak, tetapi BUKAN partikel asli Bahasa Melayu Deli tradisional/istana. Disimpan di raw/ dengan label melayu_medan_kolokial. |
| `MD-000212` | **kelen** | `melayu_medan_kolokial` | kalian (bentuk monoftongisasi kolokial dari "kalian" dalam bahasa pergaulan Kota Medan) | Status disputed: Sangat umum dalam bahasa pergaulan lintas etnis Kota Medan, namun dalam ragam Melayu Deli santun lebih dipilih "kalian" atau "awak semua". |
| `MD-000213` | **hang** | `melayu_pesisir_utara` | engkau; kamu (kata ganti orang kedua tunggal akrab yang berkerabat dengan Melayu Kedah/Utara dan sebagian pesisir) | Status disputed: Lebih khas pada dialek Melayu Kedah/Pulau Pinang dan kantong pesisir tertentu; di Deli inti lebih dominan "awak" dan "kau". Perlu verifikasi penutur asli per kecamatan. |

---

## 3. Entri Berstatus `rejected` (Bukan Kosakata Bahasa Melayu Deli)

Entri berikut sering disalahartikan sebagai kata Melayu umum atau Melayu Sumatera Utara di internet, padahal merupakan pronomina khas dialek Melayu Perak (Semenanjung Malaysia) berdasarkan *Pusat Rujukan Persuratan Melayu* (`SRC-0012`). Entri ini **ditolak (`rejected`)** dan tidak dimasukkan ke dataset terkurasi:

| ID | Istilah | Dialek Asli | Makna | Alasan Penolakan (`rejected`) |
|---|---|---|---|---|
| `MD-000214` | **kome** | `melayu_perak` | kami / kalian (pronomina persona dialek Melayu Perak, Malaysia) | Status rejected (Salah Atribusi Dialek): Berdasarkan verifikasi PRPM DBP (SRC-0012), "kome" adalah pronomina khas Loghat Perak (Malaysia), bukan kosakata Bahasa Melayu Deli. Disimpan di raw/ sebagai rekam audit dan dikeluarkan dari curated/. |
| `MD-000215` | **mike** | `melayu_perak` | kamu / engkau (pronomina persona kedua dialek Melayu Perak, Malaysia) | Status rejected (Salah Atribusi Dialek): Berdasarkan verifikasi PRPM DBP (SRC-0012), "mike/mika" adalah pronomina khas Loghat Perak/Pahang, bukan Bahasa Melayu Deli. Disimpan di raw/ sebagai rekam jejak kualitas data dan dikeluarkan dari curated/. |
