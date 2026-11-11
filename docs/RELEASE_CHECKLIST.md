# Daftar Periksa Pra-Rilis (Release Checklist) — KATARA

Gunakan daftar periksa 10 langkah ini sebelum menerbitkan tag rilis baru atau mengunggah APK dan paket modul ke GitHub Releases.

---

## 10 Langkah Verifikasi Wajib Pra-Rilis

- [x] **1. Keutuhan Folder `konten/` (Read-Only):**
  Pastikan `git status konten/` bersih dan tidak ada satu pun berkas di dalam `konten/` yang diubah.
- [x] **2. Bebas Kredensial & Kunci Privat di Git:**
  Pastikan `.jks`, `.keystore`, `key.properties`, `.keys/`, dan `build/symbols/` tercantum di `.gitignore` dan tidak terlacak oleh `git status`.
- [x] **3. Analisis Statis Bersih (`0` Error & `0` Warning):**
  Jalankan `flutter analyze` dan pastikan keluar dengan pesan `No issues found!`.
- [x] **4. Audit Kontras Warna WCAG 2.1 AA+/AAA:**
  Jalankan `flutter test test/contrast_audit_test.dart test/design_system_test.dart` dan pastikan seluruh pasangan teks/latar kartu berwarna, badge, chip, dan banner memenuhi ambang WCAG AA/AAA serta bebas kebocoran `Hasil audit ...`.
- [x] **5. Audit Aturan Keamanan Cloud Firestore:**
  Jalankan `flutter test test/firestore_rules/firestore_rules_test.dart` dan validasi sintaks `firestore.rules`.
- [x] **6. Kompilasi & Penandatanganan Ed25519 Katalog Modul:**
  Jalankan `dart run tool/build_modules.dart` untuk menghasilkan `module_langkat.zip`, `module_palembang.zip`, dan `module_catalog.json` bertanda tangan Ed25519, lalu verifikasi dengan `flutter test test/module_security_test.dart`.
- [x] **7. Verifikasi Migrasi Skema SQLite (`v1 -> v2`):**
  Jalankan `flutter test test/migrations/schema_migration_test.dart` untuk memastikan pengguna versi lama tidak kehilangan progres belajar saat memperbarui aplikasi.
- [x] **8. Verifikasi Google Sign-In & Ketahanan Mode Tamu:**
  Jalankan `flutter test test/auth_error_mapper_test.dart` dan pastikan sidik jari SHA-1 & SHA-256 sertifikat penandatangan APK telah terdaftar di proyek Firebase `katara-melayu`.
- [x] **9. Build APK Rilis dengan R8 Minification & Dart Obfuscation:**
  Jalankan perintah:
  ```powershell
  flutter build apk --release --obfuscate --split-debug-info=build/symbols
  ```
- [x] **10. Pencatatan Checksum SHA-256 Artefak Rilis:**
  Salin APK hasil build ke `dist/releases/v<versi>/katara-v<versi>-release.apk`, hitung ukuran byte dan hash SHA-256 untuk APK serta seluruh berkas `module_*.zip`, lalu catat di `docs/PROGRESS.md`.
