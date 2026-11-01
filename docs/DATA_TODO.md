# KATARA: Daftar Data yang Perlu Dicari

Dibuat dari audit isi `assets/content/ms-deli/` (hasil konversi `konten/`). Aturan proyek: **semua isi harus datang dari sumber/penutur, bukan dikarang**. Dokumen ini adalah daftar kerja riset kamu.

Cara memakai: kerjakan dari prioritas P0 ke bawah. Hasil riset taruh di `konten/linguanusa_konten_draf_v0.1.json` (atau versi baru), lalu jalankan `dart run tool/build_content.dart` dan naikkan `content_version`.

## Kondisi data saat ini

| Data | Jumlah | Yang kosong |
| --- | --- | --- |
| Kata (`words`) | 67 | **Jawi 67/67 kosong**, audio 0, gambar 0 |
| Frasa (`phrases`) | 10 | **Jawi 10/10 kosong**, audio 0, catatan budaya minim |
| Kalimat (`sentences`) | 10 | Terlalu sedikit untuk latihan isi-kosong dan susun kalimat |
| Dialog (`dialogues`) | 2 | Belum dipakai di pelajaran |
| Huruf Jawi (`letters`) | 6 | Hanya 6 huruf tambahan, belum ada alfabet dasar |
| Artikel (`articles`) | 3 (Putri Hijau, Istana Maimun, Guru Patimpus) | **Isi 3/3 kosong**, sumber kosong |
| Kartu koleksi (`collection_cards`) | 5 (Istana Maimun, Meriam Puntung, Tanjak, dst.) | **Fakta 5/5 kosong**, gambar kosong |
| Kredit (`credits.json`) | kosong | Nama penutur dan ahli |
| Status validasi | semua `draft` | Belum ada yang `speaker_checked` |
| Daerah lain | 1 aktif + 1 placeholder | Nama daerah berikutnya belum ditentukan |

Kategori kata sekarang: sapaan 6, angka 12, keluarga 8, makanan 10, tanya 7, aktivitas 5, waktu 6, pekan 3, rumah 6, perasaan 4.

---

## P0. Validasi penutur (paling berdampak)

Tanpa ini semua konten tetap berlabel "Draf".

- [ ] Cari **minimal 2 penutur asli Melayu Deli** (Medan, Deli Serdang, Langkat, Serdang Bedagai) dari generasi berbeda.
- [ ] Cek ke penutur: tiap kata dan frasa di `words.json` dan `phrases.json` apakah **dipakai sehari-hari** dan ejaan latinnya.
- [ ] Khusus 7 kata ragam baku, tanyakan apakah orang Deli benar memakainya, atau punya padanan lain: `Isnin`, `Khamis`, `Ahad`, `bilik`, `tingkap`, `seluar`, `kasut`.
- [ ] Catat per penutur: nama (atau inisial), umur, asal kampung, tanggal wawancara, izin dikreditkan (ya/tidak).
- [ ] Tandai hasilnya per item: `speaker_checked` atau koreksi.

## P0. Isi artikel budaya (3 artikel masih kosong)

Untuk tiap artikel butuh: teks 200 sampai 400 kata, minimal 2 sumber, daftar klaim yang harus diverifikasi.

- [ ] **Putri Hijau**: versi cerita yang diterima di Deli, asal usul legenda, kaitan dengan Meriam Puntung dan Kerajaan Haru/Deli Tua. Cari sumber sejarah vs cerita rakyat, tandai mana yang legenda.
- [ ] **Istana Maimun**: tahun pembangunan, pembangun/arsitek, Sultan yang memerintah, gaya arsitektur, kondisi sekarang. Cek ke Dinas Kebudayaan Medan atau buku sejarah Kesultanan Deli.
- [ ] **Guru Patimpus**: peran dalam pendirian Medan, asal usul, tahun yang dikutip. Banyak versi tahun, catat perbedaannya.
- [ ] Kutipan sumber format: penulis, judul, tahun, penerbit/URL, tanggal akses.
- [ ] Tentukan status tiap artikel: `draft` atau `expert_verified` (butuh sejarawan/budayawan).

## P0. Aksara Jawi

- [ ] Tulisan **Jawi untuk 67 kata**. Cek ejaan Jawi baku (kamus Dewan Bahasa dan Pustaka atau Pedoman Ejaan Jawi), jangan transliterasi mesin.
- [ ] Tulisan Jawi untuk 10 frasa.
- [ ] Verifikasi ke orang yang paham Jawi (guru, budayawan, MABMI, atau pengajar Jawi).
- [ ] Alfabet Jawi dasar (28+ huruf) bila mau pelajaran Jawi lengkap, bukan hanya 6 huruf tambahan.
- [ ] Aturan sambung huruf dan huruf yang tidak menyambung ke kiri (ا د ذ ر ز و).
- [ ] Contoh kata Jawi tiap huruf (sudah ada 6, tambah untuk huruf dasar).

## P1. Fakta kartu koleksi (5 kartu kosong)

Satu fakta pendek (1 sampai 2 kalimat) per kartu, plus gambar bebas hak cipta.

- [ ] Istana Maimun
- [ ] Meriam Puntung
- [ ] Tanjak (makna, cara pakai, perbedaan lipatan bila ada)
- [ ] Dua kartu lain di `collection_cards.json` (cek nama di file)
- [ ] **Makna warna kuning, hijau, merah** busana adat Melayu: masih `[verifikasi]`, jangan tampil sebelum ada sumber.
- [ ] Ide kartu tambahan: Pantun, Songket, Rumah Melayu, Masjid Raya Al-Mashun, Tjong A Fie Mansion, Bolu Meranti, Teh Tarik/Kopi Medan (hanya bila ada sumber).

## P1. Audio

Aplikasi sudah siap audio (`AudioService`). Tinggal isi `audio_path`.

- [ ] Rekam 67 kata dan 10 frasa oleh penutur asli. Format `.mp3` atau `.ogg`, mono, 44.1 kHz, bersih dari noise.
- [ ] Penamaan: `assets/audio/ms-deli/w_0001.mp3`, dst. sesuai `id`.
- [ ] Izin tertulis penutur untuk memakai suara di aplikasi.
- [ ] Efek suara UI: benar, salah, selesai pelajaran, naik level (CC0, contoh: freesound.org, kenney.nl).

## P1. Gambar

- [ ] Gambar untuk kata konkret (makanan, rumah, keluarga) agar bisa jadi latihan `image_to_word`: minimal 20 gambar.
- [ ] Foto/ilustrasi tiap kartu koleksi dan artikel.
- [ ] Syarat: lisensi CC0, CC-BY, atau buatan sendiri. Catat atribusi di `credits.json`.
- [ ] Ilustrasi **Si Rebung** asli (4 ekspresi) dan pakaian adat (opsional, Fase 8).

## P1. Perbanyak materi latihan

- [ ] **Kalimat contoh**: dari 10 jadi minimal 40, supaya latihan susun kalimat dan isi-kosong bervariasi. Tiap kalimat: Deli, Indonesia, kata yang dipakai.
- [ ] **Dialog**: dari 2 jadi minimal 6 (di pekan, di rumah, bertamu, tanya jalan, di kedai kopi, perkenalan). Tiap dialog 6 sampai 10 baris.
- [ ] **Frasa harian**: dari 10 jadi 30 (salam waktu, terima kasih, minta maaf, tawar-menawar, pamit).
- [ ] **Kosakata Level 2 dan 3**: tambah kategori yang belum ada: tubuh, pakaian, hewan, alam/cuaca, transportasi, pekerjaan, warna, kata kerja umum, kata sifat umum, arah dan tempat.
- [ ] **Pantun**: kumpulkan 10 sampai 20 pantun Melayu (domain publik/anonim, atau izin tertulis) untuk pelajaran `complete_pantun` (Fase lanjutan).
- [ ] **Peribahasa dan ungkapan** Melayu Deli, lengkap dengan arti.
- [ ] **Bank soal budaya**: 20 soal tambahan dengan sumber. Soal yang faktanya belum pasti beri `needs_verification: true`.
- [ ] **Pasangan perbedaan Deli vs Indonesia** (mis. "mane" vs "mana") untuk catatan lafal.

## P2. Catatan bahasa

- [ ] Perbedaan lafal Deli (akhiran "e", "o") vs Melayu baku: tulis aturan singkat dengan contoh.
- [ ] Tingkat tutur dan kesopanan (kepada orang tua, sebaya) bila ada.
- [ ] Kosakata yang **dihindari/tabu**, kata serapan dari Tamil, Minang, Karo, Hokkien yang lazim di Medan.
- [ ] Kata yang artinya berbeda antar daerah Melayu (berguna saat daerah baru ditambah).

## P2. Kredit, kebijakan, dan legal

- [ ] `credits.json`: daftar penutur, peninjau ahli, kontributor, sumber gambar/audio.
- [ ] **Kebijakan privasi final** (Fase 7): data apa dikumpulkan, cara hapus akun, kontak resmi. Bisa pakai generator privacy policy lalu sesuaikan.
- [ ] Email kontak resmi untuk laporan kesalahan.
- [ ] Lisensi konten (mis. CC BY-SA) dan lisensi kode, biar jelas bagi kontributor.
- [ ] Izin dari lembaga adat (MABMI Sumut, Kesultanan Deli) bila memakai istilah atau simbol adat secara resmi.
- [ ] Cek lisensi font Nunito dan Noto Naskh Arabic (OFL, sudah aman, simpan salinan lisensinya).

## P2. Daerah Melayu berikutnya (Fase 9)

Spesifikasi melarang menebak nama daerah. Putuskan sendiri:

- [ ] Daftar daerah berikutnya (contoh kandidat yang kamu pilih sendiri: Langkat, Serdang, Riau, Kepulauan Riau, Jambi, Pontianak, Palembang, Brunei, Malaysia).
- [ ] Label wilayah tiap daerah.
- [ ] Warna aksen (`accent_hex`) tiap daerah.
- [ ] Sumber penutur dan konten tiap daerah, dengan struktur file sama seperti `ms-deli`.

## P3. Untuk rilis

- [ ] Ikon aplikasi dan splash final (`android/app/src/main/res/mipmap-*`).
- [ ] Screenshot Play Store (5 sampai 8), deskripsi singkat dan panjang, kategori, kebijakan privasi URL.
- [ ] Beta tester: 5 sampai 10 pengguna nyata (penutur dan non-penutur) untuk uji alur dan bahasa.
- [ ] Formulir umpan balik sederhana.

---

## Template pencatatan sumber

Salin tiap kali menambah data:

```
Item        : (id, mis. ms-deli:w:0012 atau artikel)
Isi         : 
Sumber      : penutur / buku / situs / lembaga
Detail      : nama, umur, asal / penulis, judul, tahun, URL
Tanggal     : 
Status      : draft | speaker_checked | expert_verified
Izin kredit : ya / tidak
Catatan     : 
```

## Urutan kerja yang disarankan

1. Wawancara penutur (kata, frasa, audio, kalimat, dialog) dalam satu sesi, rekam sekalian.
2. Cari tulisan Jawi dan verifikasi.
3. Tulis 3 artikel dengan sumber.
4. Isi fakta kartu koleksi dan cari gambar berlisensi.
5. Baru tambah materi Level 2 dan 3.
