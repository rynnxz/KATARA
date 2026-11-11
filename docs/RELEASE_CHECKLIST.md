# Daftar Periksa Pra-Rilis (Release Checklist) — KATARA `v1.1.1`

Gunakan daftar periksa 10 langkah ini sebelum menerbitkan tag rilis baru atau mengunggah APK dan paket modul ke GitHub Releases.

---

## 10 Langkah Verifikasi Wajib Pra-Rilis

- [x] **1. Keutuhan Folder `konten/` (Read-Only):**
  Pastikan `git diff konten/` bersih dan tidak ada satu pun berkas di dalam `konten/` yang diubah.
- [x] **2. Bebas Kredensial & Kunci Privat di Git:**
  Pastikan `.jks`, `.keystore`, `key.properties`, `.keys/`, dan `build/symbols/` tercantum di `.gitignore` dan tidak terlacak oleh `git status`.
- [x] **3. Analisis Statis Bersih (`0` Error & `0` Warning):**
  Jalankan `flutter analyze` dan pastikan keluar dengan pesan `No issues found!`.
- [x] **4. Audit Kontras Warna WCAG 2.1 AA+/AAA & Responsivitas Filter:**
  Jalankan `flutter test test/contrast_audit_test.dart test/design_system_test.dart test/k_filter_bar_test.dart` dan pastikan seluruh pasangan teks/latar kartu berwarna, badge, chip, dan `KFilterBar` bebas overflow serta memenuhi ambang WCAG AA/AAA.
- [x] **5. Audit Aturan Keamanan Cloud Firestore:**
  Jalankan `flutter test test/firestore_rules/firestore_rules_test.dart` dan validasi sintaks `firestore.rules`.
- [x] **6. Kompilasi & Penandatanganan Ed25519 Katalog Modul + Fallback Rilis:**
  Jalankan `dart run tool/build_modules.dart` untuk menghasilkan `module_langkat.zip`, `module_palembang.zip`, dan `module_catalog.json` bertanda tangan Ed25519, lalu verifikasi dengan `flutter test test/module_security_test.dart test/module_download_ux_test.dart`.
- [x] **7. Verifikasi Migrasi Skema SQLite (`v1 -> v2`):**
  Jalankan `flutter test test/migrations/schema_migration_test.dart` untuk memastikan pengguna versi lama tidak kehilangan progres belajar saat memperbarui aplikasi.
- [x] **8. Verifikasi Google Sign-In (`oauth_client`), `/welcome`, & Ketahanan Mode Tamu:**
  Jalankan `flutter test test/auth_error_mapper_test.dart test/welcome_flow_test.dart` dan pastikan `android/app/google-services.json` memuat `client_type: 1` (`id.katara.app`, SHA-1 `fd309939f8490ec3e156ac6157467f78a10c6d6f`) serta `client_type: 3` (`236754467620-r25cf47tinfg0q7m0u244dece33e3ag8.apps.googleusercontent.com`).
- [x] **9. Build APK Rilis dengan R8 Minification & Dart Obfuscation:**
  Jalankan perintah:
  ```powershell
  flutter build apk --release --obfuscate --split-debug-info=build/symbols
  ```
- [x] **10. Pencatatan Checksum SHA-256 Artefak Rilis (`v1.1.1`):**
  - `dist/releases/v1.1.1/katara-v1.1.1-release.apk`: `65,727,877` byte (`62.68 MB`) — SHA-256: `522e95c8ab4d83ae332baf297dbab04231b2c2b29d4a554c088aee5f208782be`
  - `dist/releases/v1.1.1/module_langkat.zip`: `82,277` byte — SHA-256: `d36f24b2679ccc22b1326f58180f0c7b56e1c77ff7537c7030612950fc3bdb4b`
  - `dist/releases/v1.1.1/module_palembang.zip`: `84,247` byte — SHA-256: `1ab88a4fb291fd8d279a9432e7cb5284127fa2bdc052885b1131611ce56c6a25`
  - `dist/releases/v1.1.1/module_catalog.json`: `2,302` byte — SHA-256: `30811bb625ec9b93fbdfcd6df374fd5d2fd9cb591e5d630678d211efca47bdb4`
