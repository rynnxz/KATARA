# Inventarisasi Skills, Rules, dan Lingkungan Kerja (Tahap 0)

Dokumen ini mencatat seluruh *skills*, *rules*, dan perangkat kerja yang tersedia pada lingkungan pengembangan KATARA beserta alasan pemakaiannya untuk rencana perbaikan & peningkatan UX `v1.1.1`.

---

## 1. Pemeriksaan Lingkungan & Perangkat (`Environment Check`)

Hasil eksekusi diagnostik pada `2026-11-11`:

- **Flutter SDK**: `Flutter 3.47.7 (channel stable, revision abaf9c5237)`
- **Dart SDK**: `Dart 3.13.5 (stable) on "windows_x64"`
- **Perangkat Terhubung (`flutter devices`)**:
  - `Windows (desktop) • windows • windows-x64`
  - `Chrome (web) • chrome • web-javascript`
  - `Edge (web) • edge • web-javascript`
- **Status ADB / Perangkat Fisik Android (`adb devices`)**:
  - Utilitas `adb` tidak terdaftar pada `PATH` shell lokal dan tidak ada perangkat fisik Android atau emulator AVD yang sedang terhubung langsung ke sesi agen.
  - Verifikasi visual otomatis akan dijalankan melalui *widget tests* multi-ukuran layar (`320dp`, `360dp`, `412dp` serta *text scale* `1.0x`, `1.3x`, `2.0x`), sementara pengujian langsung pada ponsel Android fisik dilakukan oleh pemilik proyek menggunakan APK rilis hasil build.
- **Pemeriksaan Endpoint GitHub Releases (`curl -sIL`)**:
  - `https://github.com/rynnxz/KATARA` -> `HTTP 200` (repositori bersifat publik).
  - `https://github.com/rynnxz/KATARA/releases/download/v1.1.0/module_langkat.zip` -> `HTTP 200` (aset rilis `v1.1.0` tersedia dan dapat diunduh publik).
  - `https://github.com/rynnxz/KATARA/releases/download/v1.1.1/module_langkat.zip` -> `HTTP 404` (tag rilis `v1.1.1` belum dipublikasikan ke GitHub Releases).

---

## 2. Aturan Proyek (`Workspace & User Rules`)

| Rule / Dokumen | Lokasi | Dipakai? | Alasan |
|---|---|---|---|
| `AGENTS.md` & `KATARA_SPEC.md` | `AGENTS.md`, `docs/KATARA_SPEC.md` | **Ya** | Spesifikasi utama arsitektur offline-first, palet warna Melayu Deli, maskot Si Rebung, aturan `konten/` read-only, dan transparansi status validasi. |
| `google-cloud-discovery.md` | `.gemini/config/plugins/google-cloud-developer/rules/google-cloud-discovery.md` | **Ya** | Panduan perutean skill Google Cloud dan Firebase. |

---

## 3. Daftar Lengkap Skills & Status Pemakaian

| Skill | Dipakai untuk Tugas | Dipakai? | Alasan |
|---|---|---|---|
| `brainstorming` | Eksplorasi opsi arsitektur alur `/welcome`, ikon Si Rebung, penghapusan fitur "vocal", dan komponen `KFilterBar` | **Ya** | Wajib digunakan sebelum merancang fitur atau mengubah perilaku UI. |
| `writing-plans` | Penyusunan `docs/PLAN_V1_1_1.md` dengan kriteria penerimaan terukur dan rencana pengujian | **Ya** | Menstrukturkan backlog P0/P1/P2/P3 secara sistematis sebelum menyentuh kode produk. |
| `systematic-debugging` | Investigasi akar masalah gagal login Google (`A1`) dan `HTTP 404` unduhan modul (`A2`) | **Ya** | Memastikan diagnosis berbasis bukti (`google-services.json`, status HTTP rilis GitHub) sebelum menulis kode perbaikan. |
| `verification-before-completion` | Verifikasi akhir `flutter analyze`, `flutter test`, dan build APK rilis | **Ya** | Mencegah klaim selesai tanpa bukti kompilasi dan pengujian otomatis yang lulus. |
| `test-driven-development` | Penulisan pengujian unit dan widget (`welcome_flow_test`, `k_filter_bar_test`, `module_download_ux_test`) | **Ya** | Menjamin setiap perubahan perilaku diuji secara deterministik. |
| `antislop` | Filter utama kualitas desain, kode, dan bahasa di seluruh layar | **Ya** | Mencegah pola UI generik dan memastikan standar kualitas visual/teks. |
| `antislop-ui` | Desain layar `/welcome`, kartu pilihan daerah, filter bar, dan hierarki visual | **Ya** | Menjaga konsistensi tipografi, spasi, dan kontras warna Melayu. |
| `antislop-human` | Audit aksesibilitas, kontras WCAG AA+/AAA, target sentuh >= 48dp, dan label semantik | **Ya** | Memastikan seluruh komponen interaktif ramah pembaca layar dan mudah disentuh. |
| `antislop-layoutmobile` | Pencegahan overflow horizontal pada chip filter, kartu perbandingan dialek, dan layar kecil `320dp` | **Ya** | Menangani reflow teks fonetik panjang dan barisan filter di layar ponsel sempit. |
| `antislop-copywriting` | Penulisan mikro-kopi bahasa Indonesia yang jujur, hangat, dan bebas jargon teknis/exception mentah | **Ya** | Mengatur nada bahasa pada layar `/welcome`, pesan galat unduhan modul, dan lencana verifikasi. |
| `antislop-code` | Kebersihan komentar kode pada berkas Dart yang dimodifikasi | **Ya** | Menjaga komentar kode tetap bernilai tanpa komentar redundan. |
| `flutter-build-responsive-layout` | Penyusunan tata letak adaptif pada `KFilterBar`, `DialectComparisonScreen`, `RegionPickerScreen`, dan `WelcomeScreen` | **Ya** | Memastikan UI rapi pada lebar `320dp`–`412dp` dan pembesaran teks hingga `2.0x`. |
| `flutter-fix-layout-issues` | Perbaikan pemotongan chip kategori dan tabrakan badge ukuran modul di `RegionPickerScreen` | **Ya** | Mengatasi masalah pembungkusan baris (`Wrap` vs `Row`) pada komponen kartu dan filter. |
| `flutter-apply-architecture-best-practices` | Pemisahan lapisan UI, state Riverpod, dan layanan pada fitur autentikasi tamu/Google serta unduhan modul | **Ya** | Menjaga arsitektur bersih antara repositori Drift, layanan, dan layar Flutter. |
| `flutter-setup-declarative-routing` | Pembaruan rute `GoRouter` untuk alur `/splash -> /welcome -> /onboarding -> /region -> /home/learn` | **Ya** | Mengatur pengalihan rute awal berdasarkan status `auth_mode` dan `onboardingCompleted`. |
| `flutter-add-widget-test` | Pengujian widget untuk `WelcomeScreen`, `KFilterBar`, `DialectComparisonScreen`, dan `RegionPickerScreen` | **Ya** | Memverifikasi perilaku interaksi pengguna dan ketiadaan overflow secara otomatis. |
| `dart-add-unit-test` | Pengujian unit untuk `ModuleDownloadService`, `AuthErrorMapper`, dan generator ikon | **Ya** | Menguji logika murni dan penanganan galat secara terisolasi. |
| `dart-run-static-analysis` | Eksekusi `flutter analyze` dan `dart format --set-exit-if-changed` | **Ya** | Menjamin nol peringatan linter sebelum kompilasi rilis. |
| `firebase-auth-basics` | Diagnostik konfigurasi OAuth Google Sign-In (`oauth_client`, `client_type: 1` & `3`, `serverClientId`) | **Ya** | Menjelaskan penyebab `oauth_client: []` kosong di `google-services.json` dan langkah aktivasi provider Google. |
| `firebase-firestore` | Sinkronisasi progres pengguna (`users/{uid}`) antara penyimpanan lokal SQLite dan Cloud Firestore | **Ya** | Memastikan struktur koleksi dan penggabungan progres Mode Tamu ke akun Google berjalan aman. |
| `firebase-security-rules-auditor` | Pemeriksaan kepatuhan aturan keamanan `firestore.rules` | **Ya** | Memastikan tidak ada regresi keamanan pada aturan akses dokumen pengguna. |
| `firestore-rules-creation` | Referensi aturan keamanan `firestore.rules` | **Tidak** | Aturan `firestore.rules` sudah diaudit dan diuji pada iterasi sebelumnya; hanya dipakai bila ada perubahan skema koleksi. |
| `firebase-basics` | Pemeriksaan proyek aktif `katara-melayu` dan unduhan konfigurasi SDK (`firebase_get_sdk_config`) | **Ya** | Digunakan untuk memeriksa isi `google-services.json` terbaru dari proyek Firebase. |
| `flutter-use-http-package` | Perbaikan klien HTTP unduhan modul dengan timeout, pembatalan, dan fallback katalog | **Ya** | Dipakai pada `ModuleDownloadService` saat mengunduh paket ZIP modul bahasa. |
| `flutter-implement-json-serialization` | Pemetaan JSON katalog modul dan manifest | **Ya** | Menangani serialisasi aman pada `ModuleCatalogItemModel`. |
| `dart-use-path-package` | Manipulasi path direktori modul dan aset ikon secara lintas platform | **Tidak** | Path modul sudah terkelola dengan aman dan teruji anti-path-traversal. |
| `dart-use-pattern-matching` | Ekspresi `switch` pada pemetaan status modul dan kategori galat | **Ya** | Digunakan pada pemetaan status UI dan pesan galat yang bersih. |
| `android-cli` | Diagnostik proyek Android dan pemeriksaan SDK | **Tidak** | Build dan verifikasi Android dijalankan melalui Gradle dan Flutter CLI standar. |
| `android-device-hub` | Mirroring AVD di panel Device Hub | **Tidak** | Tidak ada AVD atau perangkat fisik yang terhubung ke sesi mesin saat ini. |
| `compose-preview` | Pratinjau Jetpack Compose | **Tidak** | Aplikasi dibangun menggunakan Flutter, bukan Jetpack Compose native. |
| `dart-fix-runtime-errors` | Pemeriksaan runtime error via MCP saat aplikasi berjalan aktif | **Tidak** | Pengujian dijalankan melalui `flutter test` tanpa sesi VM aktif di perangkat fisik. |
| `dart-collect-coverage` | Pengumpulan laporan cakupan LCOV | **Tidak** | Fokus pengujian pada lulusnya seluruh suite unit/widget test dan verifikasi matriks layar. |
| `dart-generate-test-mocks` | Pembuatan mock dengan `mockito` dan `build_runner` | **Tidak** | Proyek menggunakan implementasi palsu (*fakes/in-memory gateway*) yang deterministik tanpa ketergantungan `mockito`. |
| `dart-migrate-to-checks-package` | Migrasi `package:matcher` ke `package:checks` | **Tidak** | Suite pengujian proyek menggunakan `flutter_test` standar. |
| `dart-resolve-package-conflicts` | Penyelesaian konflik versi `pub get` | **Tidak** | Hanya dipakai jika terjadi konflik saat menambahkan `flutter_launcher_icons` atau `flutter_native_splash`. |
| `dart-setup-ffi-assets` | Kompilasi kode C/C++ via Native Assets | **Tidak** | Proyek tidak membuat binding C/C++ kustom. |
| `dart-use-ffigen` | Generator binding FFI | **Tidak** | Proyek tidak menggunakan `package:ffigen`. |
| `dart-use-doc-examples` | Injeksi contoh kode eksternal ke Dartdoc | **Tidak** | Dokumentasi ditulis langsung pada kode dan berkas `docs/`. |
| `dart-use-primary-constructors` | Migrasi sintaks primary constructor eksperimental | **Tidak** | Menggunakan konstruktor standar Dart 3 yang stabil. |
| `dart-write-documentation` | Penulisan komentar dokumentasi `///` pada API publik komponen baru (`KFilterBar`, dsb.) | **Ya** | Menjaga keterbacaan komponen bersama yang baru ditambahkan. |
| `flutter-add-integration-test` | Pengujian integrasi dengan Flutter Driver | **Tidak** | Pengujian alur end-to-end dicakup melalui `flutter_test` widget tests berbasis `ProviderScope`. |
| `flutter-add-widget-preview` | Penambahan `previews.dart` | **Tidak** | Proyek telah memiliki `DevGalleryScreen` (`/dev/gallery`) untuk pratinjau komponen. |
| `flutter-setup-localization` | Konfigurasi `l10n.yaml` multi-bahasa antarmuka | **Tidak** | Antarmuka aplikasi menggunakan Bahasa Indonesia secara penuh sesuai spesifikasi. |
| `firebase-ai-logic-basics` | Integrasi Gemini API di aplikasi web | **Tidak** | KATARA adalah aplikasi belajar bahasa berbasis korpus terverifikasi tanpa generasi konten AI otomatis. |
| `firebase-app-hosting-basics` | Deployment SSR Next.js/Angular | **Tidak** | Aplikasi ini adalah aplikasi mobile Flutter. |
| `firebase-crashlytics` | Integrasi pelaporan crash | **Tidak** | Di luar cakupan perubahan `v1.1.1`. |
| `firebase-data-connect` | Backend PostgreSQL Data Connect | **Tidak** | Penyimpanan menggunakan SQLite (Drift) lokal dan Cloud Firestore. |
| `firebase-hosting-basics` | Hosting situs web statis Firebase | **Tidak** | Distribusi modul utama menggunakan GitHub Releases. |
| `firebase-remote-config-basics` | Konfigurasi Remote Config | **Tidak** | Konfigurasi katalog modul dikelola melalui `module_catalog.json` bertanda tangan Ed25519. |
| `extension-to-functions-codebase` | Konversi Firebase Extension ke Cloud Functions | **Tidak** | Proyek tidak menggunakan Cloud Functions. |
| `gcloud` | Eksekusi perintah `gcloud` CLI | **Tidak** | Tidak diperlukan operasi infrastruktur GCP melalui `gcloud`. |
| `finding-google-skills` | Pencarian katalog skill Google Cloud tambahan | **Tidak** | Skill Firebase dan Flutter yang terpasang sudah mencakup seluruh kebutuhan tugas. |
| `google-cloud-recipe-auth` | Panduan IAM Google Cloud untuk layanan backend | **Tidak** | Autentikasi pengguna akhir ditangani oleh Firebase Auth. |
| `google-cloud-recipe-onboarding` | Inisialisasi proyek GCP baru | **Tidak** | Proyek Firebase `katara-melayu` sudah tersedia dan aktif. |
| `retrieving-developer-knowledge` | Pencarian dokumentasi resmi Google Developer | **Tidak** | Hanya dipakai bila membutuhkan referensi tambahan di luar skill yang sudah dimuat. |
| `gemini-api-dev`, `gemini-live-api-dev`, `gemini-omni-flash-api` | Pengembangan aplikasi berbasis Gemini API | **Tidak** | Proyek tidak memanggil Gemini API. |
| `a11y-debugging`, `chrome-devtools`, `cookie-debugging`, `debug-optimize-lcp`, `memory-leak-debugging`, `troubleshooting`, `chrome-extensions`, `modern-web-guidance` | Debugging web menggunakan Chrome DevTools & pengembangan ekstensi Chrome | **Tidak** | Target utama aplikasi adalah Android native (`id.katara.app`). |
| `roblox-*` (16 skills) | Pengembangan gim Roblox Studio / Luau | **Tidak** | Tidak relevan dengan proyek Flutter KATARA. |
| `agy-customizations`, `antigravity-guide`, `automation`, `generative_ui`, `migrate-agent-settings`, `migrate-workflows`, `plugin`, `ui-plugin-navigation`, `xcode-project-setup` | Kustomisasi internal IDE Antigravity atau proyek Xcode iOS | **Tidak** | Tidak relevan dengan lingkup perbaikan aplikasi Android/Flutter saat ini. |
| `dispatching-parallel-agents`, `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `subagent-driven-development`, `swarm`, `swarm_monitor`, `using-git-worktrees`, `using-superpowers`, `writing-skills` | Alur kerja manajemen sesi & proses agen | **Ya** | Digunakan sebagai pedoman disiplin eksekusi bertahap (`Tahap 0 -> Tahap 1 -> Persetujuan -> Tahap 2 -> Tahap 3`). |
