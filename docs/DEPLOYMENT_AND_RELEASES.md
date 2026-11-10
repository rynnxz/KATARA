# Panduan Deployment & Rilis GitHub (`v1.1.0`)

Dokumen ini menjelaskan cara membangun berkas APK rilis produksi serta mengunggah aset modul dialek terpisah ke **GitHub Releases** (`https://github.com/rynnxz/KATARA/releases`).

---

## 1. Membangun APK Produksi & Modul Unduhan

Jalankan perintah berikut dari direktori akar repositori:

```powershell
# 1. Pastikan korpus, aset bawaan ms-deli, dan ZIP modul unduhan mutakhir
dart run tool/build_dialect_datasets.dart
dart run tool/build_content.dart
dart run tool/build_modules.dart

# 2. Bangun APK rilis produksi
flutter build apk --release

# 3. Salin APK ke direktori distribusi rilis v1.1.0
Copy-Item build/app/outputs/flutter-apk/app-release.apk dist/releases/v1.1.0/katara-v1.1.0-release.apk -Force
```

---

## 2. Daftar Aset Rilis `dist/releases/v1.1.0/`

Setiap rilis pada GitHub (`tag: v1.1.0`) menyertakan 4 aset utama di dalam folder `dist/releases/v1.1.0/`:

| Nama Berkas | Fungsi | Ukuran | SHA-256 |
|---|---|---|---|
| `katara-v1.1.0-release.apk` | Pemasang aplikasi Android utama (`id.katara.app`) dengan modul bawaan Melayu Deli. | ~54 MB | Dihasilkan saat build rilis |
| `module_langkat.zip` | Paket modul unduhan mandiri Bahasa Melayu Langkat (308 kata, 10 dialog, 110 kuis). | `82.273 byte` | `b9c2aaa268ad3e0b9eb1b75c4bf71fff7932c17fd20c8b018f530a985559cdb0` |
| `module_palembang.zip` | Paket modul unduhan mandiri Bahasa Melayu Palembang (308 kata, 10 dialog, 110 kuis). | `84.219 byte` | `16185eb07de40d307eaeea7cdb1f07aad270093cac0d4c19c62e083052956497` |
| `module_catalog.json` | Manifest katalog modul beserta URL unduhan dan hash SHA-256. | `1.816 byte` | - |

---

## 3. Langkah Publikasi ke GitHub Releases

1. **Push Kode & Tag ke Repositori GitHub:**
   ```powershell
   git remote set-url origin https://github.com/rynnxz/KATARA.git
   git push -u origin master
   git tag v1.1.0
   git push origin v1.1.0
   ```

2. **Buat Rilis via GitHub CLI (`gh`) atau Web UI:**
   ```powershell
   gh release create v1.1.0 `
     dist/releases/v1.1.0/katara-v1.1.0-release.apk `
     dist/releases/v1.1.0/module_langkat.zip `
     dist/releases/v1.1.0/module_palembang.zip `
     dist/releases/v1.1.0/module_catalog.json `
     --title "KATARA v1.1.0 - Ekspansi Multi-Dialek Melayu (Deli, Langkat, Palembang)" `
     --notes "Rilis produksi KATARA v1.1.0 dengan modul bawaan Melayu Deli serta modul unduhan mandiri Melayu Langkat & Melayu Palembang."
   ```
