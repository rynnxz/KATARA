# Kebijakan Keamanan (Security Policy) — KATARA

Tim pengembang **KATARA (`id.katara.app`)** berkomitmen menjaga keamanan data pengguna, keutuhan rantai pasok modul bahasa daerah, dan keandalan infrastruktur sinkronisasi awan.

---

## 1. Versi yang Didukung (Supported Versions)

Hanya rilis minor terbaru pada cabang aktif yang menerima pembaruan keamanan (*security patches*):

| Versi Aplikasi | Versi Skema SQLite (`schemaVersion`) | Status Dukungan Keamanan |
| --- | --- | --- |
| `1.1.x` (`>= 1.1.1`) | `v2` | **Didukung Penuh (LTS Aktif)** |
| `1.0.x` | `v1` | Tidak Didukung (Disarankan mutakhirkan ke `>= 1.1.1`) |

---

## 2. Cara Melaporkan Kerentanan (Reporting a Vulnerability)

**Jangan membuka GitHub Issue publik untuk kerentanan keamanan yang belum diperbaiki.**

Silakan laporkan temuan keamanan melalui salah satu jalur privat berikut:
1. **GitHub Private Vulnerability Reporting:** Gunakan tab **Security -> Report a vulnerability** pada repositori [`https://github.com/rynnxz/KATARA/security/advisories/new`](https://github.com/rynnxz/KATARA/security/advisories/new).
2. **Email Keamanan Langsung:** Kirimkan laporan ke **`akbarriansyah339@gmail.com`** dengan subjek `[SECURITY][KATARA] <Ringkasan Temuan>`.

### Informasi yang Diharapkan dalam Laporan
- Deskripsi komponen yang terdampak (mis. `firestore.rules`, `ModuleDownloadService`, autentikasi, atau konfigurasi APK).
- Langkah reproduksi atau *Proof-of-Concept* (PoC) yang aman tanpa merusak data pengguna lain.
- Dampak potensial dan usulan mitigasi (jika ada).

### Komitmen Waktu Tanggap (SLA)
- **Konfirmasi Penerimaan Laporan:** Maksimal **48 jam** sejak laporan diterima.
- **Triase & Penilaian Keparahan:** Maksimal **7 hari kalender**.
- **Rilis Tambalan (*Patch*) untuk Temuan Critical/High:** Maksimal **14 hari kalender**.

---

## 3. Ruang Lingkup Keamanan (Scope)

### Di Dalam Ruang Lingkup (*In-Scope*)
- Aturan keamanan Cloud Firestore ([`firestore.rules`](firestore.rules)) pada proyek `katara-melayu` (isolasi kepemilikan dokumen `users/{uid}`, bypass skema/batas ukuran).
- Verifikasi tanda tangan digital **Ed25519** dan checksum **SHA-256** pada `module_catalog.json` serta ekstraksi arsip ZIP di [`ModuleDownloadService`](lib/services/module_download_service.dart) (*Zip-Slip*, *Zip-Bomb*, injeksi lintas kursus).
- Alur autentikasi Google Sign-In, penautan akun anonim (`linkWithCredential`), dan penghapusan akun/data mandiri di [`FirebaseSyncService`](lib/services/firebase_sync_service.dart).
- Kebocoran kredensial, kunci privat, atau PII pada repositori maupun artefak APK rilis.

### Di Luar Ruang Lingkup (*Out-of-Scope*)
- Manipulasi nilai XP/koin secara lokal pada perangkat milik pengguna sendiri yang telah di-*root* (risiko diterima sesuai [`docs/SECURITY_AUDIT.md`](docs/SECURITY_AUDIT.md) `SEC-009`, selama tidak menembus batas wajar `firestore.rules` atau memengaruhi pengguna lain).
- Serangan rekayasa sosial (*social engineering* / *phishing*) atau serangan Denial-of-Service (DoS) volumetrik terhadap infrastruktur inti GitHub atau Google Cloud.
