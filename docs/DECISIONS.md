# KATARA — Catatan Keputusan (DECISIONS.md)

Dokumen ini mencatat keputusan arsitektur, klarifikasi developer, dan penyesuaian spesifikasi selama pembangunan KATARA.

## 2026-11-01 — Klarifikasi Awal Developer (Bagian 18)

1. **Cakupan Eksekusi**: Eksekusi berurutan dari Fase 0 hingga Fase 6 (target MVP offline penuh siap pakai).
2. **Package ID / Bundle ID**: `id.katara.app` (diatur pada konfigurasi Android Gradle dan manifest).
3. **Nama & Wujud Maskot**: **Si Rebung** (karakter tunas rebung ramah memakai tanjak Melayu). Diimplementasikan menggunakan `CustomPainter` vektor di `MascotView` dengan 4 state (`idle`, `happy`, `sad`, `cheer`) sehingga tampil tajam tanpa ketergantungan aset eksternal.
4. **Aturan Nyawa (Hearts) Level 1**: Sesuai `konten/linguanusa_konten_draf_v0.1.json` (`level1_aktif: false`) dan Bagian 12.3 (`hearts_enabled_from_level: 2`), pemain di Level 1 tidak kehilangan nyawa saat salah menjawab. Selain itu, ditambahkan toggle "Mode Santai" di Pengaturan untuk mematikan pengurangan nyawa pada semua level.
5. **Daftar Daerah Melayu Berikutnya**: Mengikuti Bagian 5.2, menggunakan satu kartu aktif `Melayu Deli` (`ms-deli`) dan satu kartu placeholder `Melayu lainnya` (`ms-other`, `status: coming_soon`).
6. **Anti-Curang XP di Server**: Sengaja ditunda sampai fitur Liga Mingguan dikerjakan di masa depan (sesuai Bagian 2.2 & 8.2) agar tetap berjalan pada paket gratis tanpa Cloud Functions.

## 2026-11-01 — Penyesuaian Pemetaan Konten & Paket (Fase 0 – Fase 2)

1. **Tambahan Paket Pendukung Lokal**:
   - `path_provider` dan `path`: diperlukan oleh `drift` / `sqlite3` untuk menentukan lokasi file database SQLite di perangkat Android serta pengujian unit.
   - `crypto`: diperlukan oleh `tool/build_content.dart` dan `ContentSeeder` untuk menghitung checksum SHA-256 pada `manifest.json` sesuai Bagian 5.5 poin 6.
2. **Pemetaan Unit Level 2 (`u06`–`u10`) di `tool/build_content.dart`**:
   - Pada `konten/linguanusa_konten_draf_v0.1.json`, daftar `units` hanya mendefinisikan `u01`–`u05` (Level 1), tetapi daftar `words` (`w044`–`w067`) merujuk ke `unit_id` `u06` (`aktivitas`), `u07` (`waktu`), `u08` (`pekan`), `u09` (`rumah`), dan `u10` (`perasaan`) pada Level 2.
   - Agar integritas referensial tetap terjaga dan seluruh 67 kosakata dapat dipelajari serta masuk kamus, `tool/build_content.dart` secara otomatis menurunkan unit Level 2 (`u06`–`u10`) beserta pelajaran kosakatanya dari pengelompokan kata Level 2 tersebut tanpa mengubah file asli di `konten/`.
3. **Harga Koin Default Item Toko (`shop_items`)**:
   - Di `konten/linguanusa_konten_draf_v0.1.json`, kolom `harga_koin` bernilai `null`. Sesuai catatan dokumen sumber ("tentukan saat ekonomi koin diseimbangkan") dan Bagian 12, harga koin ditetapkan di `assets/content/game_config.json` (`streak_freeze`: 50, `heart_refill`: 30, `mascot_tanjak`: 100, `mascot_teluk_belanga`: 120, `theme_songket`: 150, `profile_frame`: 80).
