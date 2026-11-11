# Panduan Konfigurasi & Diagnostik Google Sign-In (`id.katara.app`)

Dokumen ini menjelaskan akar masalah `PlatformException(sign_in_failed, t4: 10: , null, null)` pada rilis awal `v1.1.0`, perbaikan yang telah diterapkan di kode pada `v1.1.1`, serta langkah manual di Firebase Console / Google Play Console yang perlu diselesaikan oleh pemilik proyek.

---

## 1. Akar Masalah (`ApiException: 10` / `DEVELOPER_ERROR`)

Pada saat tombol **Masuk dengan Google** ditekan di `v1.1.0`, Google Play Services mengembalikan kode galat `10` (`DEVELOPER_ERROR`, muncul sebagai `t4: 10:` karena nama kelas Play Services di-obfuscate). Penyebab pastinya:

1. **Plugin Gradle `com.google.gms.google-services` belum dipasang** di `android/settings.gradle.kts` dan `android/app/build.gradle.kts`, sehingga berkas `android/app/google-services.json` tidak diproses menjadi resource Android (`default_web_client_id`, `google_app_id`).
2. **Sidik jari sertifikat (`SHA-1` & `SHA-256`) belum terdaftar** pada aplikasi Android `id.katara.app` (`1:236754467620:android:603644d507d0290562d1b1`) di proyek Firebase `katara-melayu`.
3. **Array `"oauth_client": []` di `android/app/google-services.json` masih kosong** karena penyedia masuk **Google** pada menu *Firebase Console -> Authentication -> Sign-in method* belum diaktifkan secara interaktif di konsol web.
4. **Penanganan galat mentah di UI (`ProfileScreen`)**: Blok `catch (e)` sebelumnya menampilkan `$e` secara langsung ke `SnackBar`, sehingga teks teknis `PlatformException(sign_in_failed, t4: 10: ...)` terlihat oleh pengguna.

---

## 2. Apa yang Sudah Diperbaiki Secara Otomatis (`v1.1.1`)

1. **Aktivasi Google Sign-In Provider & Pengisian `oauth_client` di `android/app/google-services.json`**:
   Melalui deklarasi `auth.providers.googleSignIn` di `firebase.json` dan deployment resmi ke proyek Firebase `katara-melayu` (`236754467620`), blok `"oauth_client"` untuk `id.katara.app` kini telah terisi penuh:
   - **Android OAuth Client (`client_type: 1`)**: `236754467620-5c9cderkdrtq5p809nbp9mh5hk0r9a7i.apps.googleusercontent.com` (terikat ke `id.katara.app` dan `certificate_hash: fd309939f8490ec3e156ac6157467f78a10c6d6f`).
   - **Web OAuth Client (`client_type: 3`)**: `236754467620-r25cf47tinfg0q7m0u244dece33e3ag8.apps.googleusercontent.com` (diteruskan sebagai `serverClientId` ke `GoogleSignIn` di `FirestoreCloudSyncGateway`).
2. **Registrasi Sidik Jari Sertifikat ke Firebase (`katara-melayu`)**:
   Sidik jari keystore lokal yang menandatangani APK saat ini telah didaftarkan ke aplikasi `id.katara.app` (`1:236754467620:android:603644d507d0290562d1b1`):
   - **SHA-1**: `FD:30:99:39:F8:49:0E:C3:E1:56:AC:61:57:46:7F:78:A1:0C:6D:6F`
   - **SHA-256**: `4D:F0:66:AC:AE:88:2C:7A:75:63:DD:08:F1:B9:7E:42:69:01:CD:55:68:07:57:C1:D3:5A:8B:B4:02:F6:CF:F7`
3. **Integrasi Plugin Gradle & R8/ProGuard**:
   - Menambahkan `id("com.google.gms.google-services") version "4.4.2"` di `android/settings.gradle.kts` dan `android/app/build.gradle.kts`.
   - Menambahkan dukungan `android/key.properties` untuk *release keystore* (dengan fallback aman ke *debug keystore* bila `key.properties` belum dibuat di mesin lokal).
   - Mengaktifkan `isMinifyEnabled = true`, `isShrinkResources = true`, serta aturan keep `android/app/proguard-rules.pro` untuk `com.google.android.gms.auth.**` dan `com.google.firebase.**`.
4. **Pemetaan Pesan Galat Ramah Pengguna (`AuthErrorMapper`)**:
   - Semua galat `PlatformException` dan `FirebaseAuthException` dipetakan oleh `lib/services/auth_error_mapper.dart` menjadi pesan bahasa Indonesia yang sopan dan jelas.
   - Detail teknis hanya dicatat ke log konsol saat `kDebugMode == true`.
5. **Layar Awal `/welcome` & Perlindungan Mode Tamu (`ConflictResolver`)**:
   - Pengguna baru disajikan layar `/welcome` dengan pilihan setara antara **Masuk dengan Google** dan **Lanjut sebagai Tamu**.
   - Bila login Google gagal atau dibatalkan, sesi Tamu (`guest`) dan progres SQLite lokal tidak tersentuh sama sekali.
   - Bila login Google berhasil, akun anonim ditautkan (`linkWithCredential` dengan fallback ke `signInWithCredential`) dan seluruh progres lokal dijadwalkan untuk digabung (`ConflictResolver`) tanpa menurunkan bintang atau XP.
6. **Fitur Hapus Akun & Data Cloud**:
   - Sesuai UU PDP dan kebijakan Google Play, pengguna yang masuk dengan Google dapat menghapus seluruh dokumen cloud mereka (`users/{uid}` beserta subkoleksi) langsung dari halaman Profil.

---

## 3. Checklist Tindakan Manual untuk Keystore Produksi Baru / Google Play Store

Konfigurasi saat ini sudah siap pakai untuk APK yang ditandatangani dengan keystore lokal (`SHA-1: FD:30:99:39:F8:49:0E:C3:E1:56:AC:61:57:46:7F:78:A1:0C:6D:6F`). Apabila di masa depan Anda membuat keystore produksi baru atau mengunggah ke Google Play Store:

- [x] **Langkah 1 — Aktifkan Provider Google & `oauth_client` di Firebase**:
  Sudah aktif dan terisi otomatis di `android/app/google-services.json` (`client_type: 1` dan `client_type: 3`).

- [ ] **Langkah 2 — Buat Keystore Rilis Produksi Baru (Opsional jika mengganti keystore)**:
  1. Jalankan perintah berikut di luar folder git (atau di `android/`, karena `*.jks` dan `key.properties` sudah masuk `.gitignore`):
     ```powershell
     keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
     ```
  2. Salin `android/key.properties.example` menjadi `android/key.properties` dan isi sandi keystore Anda.
  3. Ambil sidik jari `SHA-1` dan `SHA-256` dari `upload-keystore.jks`:
     ```powershell
     keytool -list -v -keystore android/upload-keystore.jks -alias upload
     ```
  4. Tambahkan `SHA-1` dan `SHA-256` tersebut ke [Project Settings -> Your apps -> `id.katara.app`](https://console.firebase.google.com/project/katara-melayu/settings/general/android:id.katara.app).

- [ ] **Langkah 3 — (Khusus Google Play Store) Tambahkan SHA-1 Play App Signing**:
  1. Jika mengunggah AAB/APK ke Google Play Console, buka **Play Console -> Setup -> App signing**.
  2. Salin **SHA-1** dan **SHA-256** dari bagian **App signing key certificate** (bukan hanya *Upload key certificate*).
  3. Daftarkan keduanya ke Firebase Console pada aplikasi `id.katara.app`, lalu unduh ulang `google-services.json`.
