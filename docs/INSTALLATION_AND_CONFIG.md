# Panduan Instalasi & Konfigurasi KATARA

Dokumen ini menjelaskan prasyarat lingkungan pengembangan, langkah instalasi lokal, konfigurasi Firebase (`katara-melayu`), serta pengujian otomatis aplikasi **KATARA (`id.katara.app`)**.

---

## 1. Prasyarat Sistem

- **Flutter SDK:** `>= 3.41.0` (Dart SDK `>= 3.9.0`)
- **Android SDK:** API 34 / 35 dengan JDK 17+
- **Node.js & npx (Opsional untuk Firebase CLI):** `npx firebase-tools`

---

## 2. Langkah Instalasi Lokal

1. **Kloning Repositori:**
   ```powershell
   git clone https://github.com/rynnxz/KATARA.git
   cd KATARA
   ```

2. **Pasang Dependensi Paket Dart/Flutter:**
   ```powershell
   flutter pub get
   ```

3. **Bangun Ulang Korpus & Paket Modul (Opsional bila mengubah data bahasa):**
   ```powershell
   dart run tool/build_dialect_datasets.dart
   dart run tool/build_content.dart
   dart run tool/build_modules.dart
   ```

4. **Jalankan Aplikasi di Perangkat / Emulator Android:**
   ```powershell
   flutter run
   ```

---

## 3. Konfigurasi Firebase (`katara-melayu`)

KATARA dirancang **100% offline-first**: seluruh fitur belajar, kuis, kamus, latihan SRS, dan modul dialek berfungsi penuh tanpa akun maupun internet. Firebase digunakan secara opsional untuk **Google Sign-In** dan **Sinkronisasi Progres Lintas Perangkat**.

### Identitas Proyek Firebase
- **Project ID:** `katara-melayu`
- **Project Number:** `236754467620`
- **Android Package Name:** `id.katara.app` (`1:236754467620:android:603644d507d0290562d1b1`)
- **Berkas Konfigurasi:**
  - [`android/app/google-services.json`](../android/app/google-services.json)
  - [`lib/firebase_options.dart`](../lib/firebase_options.dart)
  - [`firestore.rules`](../firestore.rules)
  - [`firebase.json`](../firebase.json) & [`.firebaserc`](../.firebaserc)

### Menerapkan Aturan Keamanan Firestore (`firestore.rules`)
```powershell
npx firebase-tools deploy --only firestore:rules --project katara-melayu
```

### Mengaktifkan Google Sign-In di Firebase Console
1. Buka **Firebase Console** -> proyek **KATARA (`katara-melayu`)** -> **Authentication** -> **Sign-in method**.
2. Aktifkan penyedia **Google** dan **Anonymous**.
3. Pastikan sidik jari sertifikat SHA-1 dan SHA-256 keystore debug/release terdaftar pada pengaturan aplikasi Android `id.katara.app`.

---

## 4. Menjalankan Pengujian Otomatis & Analisis Statis

```powershell
# Analisis statis kode Dart/Flutter
flutter analyze

# Jalankan seluruh rangkaian pengujian unit, migrasi DB, integritas dataset, dan widget UI
flutter test
```
