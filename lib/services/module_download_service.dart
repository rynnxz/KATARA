import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:katara/data/content/content_models.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:path_provider/path_provider.dart';

class ModuleDownloadException implements Exception {
  const ModuleDownloadException(this.message);
  final String message;

  @override
  String toString() => 'ModuleDownloadException: $message';
}

typedef ModuleBytesFetcher = Future<Uint8List> Function(
  ModuleCatalogItemModel item,
  void Function(double progress)? onProgress,
);

class ModuleDownloadService {
  ModuleDownloadService({
    required this.db,
    required this.seeder,
    Future<Directory> Function()? installRootDirectoryProvider,
    this.bytesFetcher,
    http.Client? httpClient,
  })  : _installRootDirectoryProvider =
            installRootDirectoryProvider ?? _defaultInstallRoot,
        _httpClient = httpClient ?? http.Client();

  final AppDatabase db;
  final ContentSeeder seeder;
  final Future<Directory> Function() _installRootDirectoryProvider;
  final ModuleBytesFetcher? bytesFetcher;
  final http.Client _httpClient;

  static Future<Directory> _defaultInstallRoot() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/modules');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<ModuleCatalogItemModel>> loadCatalog() async {
    String rawJson;
    final localReleaseCatalog = File('dist/releases/v1.1.0/module_catalog.json');
    if (localReleaseCatalog.existsSync()) {
      rawJson = localReleaseCatalog.readAsStringSync();
    } else {
      final assetFile = File('assets/content/module_catalog.json');
      if (assetFile.existsSync()) {
        rawJson = assetFile.readAsStringSync();
      } else {
        rawJson = await rootBundle.loadString('assets/content/module_catalog.json');
      }
    }

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final list = (decoded['modules'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return list.map(ModuleCatalogItemModel.fromJson).toList();
  }

  Future<List<InstalledModuleModel>> getInstalledModules() async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect('SELECT * FROM installed_modules ORDER BY is_bundled DESC, course_id ASC')
        .get();
    return rows.map((r) => InstalledModuleModel.fromJson(r.data)).toList();
  }

  Future<InstalledModuleModel?> getInstalledModule(String courseId) async {
    await db.ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM installed_modules WHERE course_id = ? LIMIT 1',
      variables: [Variable.withString(courseId)],
    ).get();
    if (rows.isEmpty) return null;
    return InstalledModuleModel.fromJson(rows.first.data);
  }

  Future<InstalledModuleModel> installModule(
    ModuleCatalogItemModel item, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.05);

    final zipBytes = bytesFetcher != null
        ? await bytesFetcher!(item, onProgress)
        : await _fetchModuleBytes(item, onProgress);

    onProgress?.call(0.65);

    final installRoot = await _installRootDirectoryProvider();
    final stagingDir = Directory('${installRoot.path}/${item.courseId}.tmp');
    final finalDir = Directory('${installRoot.path}/${item.courseId}');

    if (stagingDir.existsSync()) {
      await stagingDir.delete(recursive: true);
    }

    await verifyAndExtractArchive(
      zipBytes: zipBytes,
      expectedSha256: item.sha256,
      targetDir: stagingDir,
    );

    onProgress?.call(0.80);

    if (finalDir.existsSync()) {
      await finalDir.delete(recursive: true);
    }
    await stagingDir.rename(finalDir.path);

    await seeder.seedCourseFromDirectory(
      courseId: item.courseId,
      directory: finalDir,
      sizeBytes: zipBytes.length,
      sha256Hash: item.sha256 ?? '',
      version: item.version.toString(),
    );

    onProgress?.call(1.0);

    final installed = await getInstalledModule(item.courseId);
    if (installed == null) {
      throw const ModuleDownloadException(
        'Modul gagal dicatat ke dalam database setelah ekstraksi.',
      );
    }
    return installed;
  }

  Future<void> verifyAndExtractArchive({
    required Uint8List zipBytes,
    required String? expectedSha256,
    required Directory targetDir,
  }) async {
    if (zipBytes.isEmpty) {
      throw const ModuleDownloadException('Paket modul kosong.');
    }

    if (expectedSha256 != null && expectedSha256.isNotEmpty) {
      final actualHash = sha256.convert(zipBytes).toString();
      if (actualHash.toLowerCase() != expectedSha256.toLowerCase()) {
        throw ModuleDownloadException(
          'Checksum SHA-256 modul tidak cocok (diharapkan $expectedSha256, diterima $actualHash).',
        );
      }
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (e) {
      throw ModuleDownloadException('Arsip ZIP modul rusak atau tidak valid: $e');
    }

    if (archive.files.isEmpty) {
      throw const ModuleDownloadException('Arsip ZIP modul tidak berisi file.');
    }

    for (final file in archive.files) {
      final entryName = file.name.replaceAll('\\', '/');
      if (entryName.contains('..') ||
          entryName.startsWith('/') ||
          entryName.contains(':')) {
        throw ModuleDownloadException(
          'Entri ZIP tidak aman ditolak: ${file.name}',
        );
      }
    }

    if (!targetDir.existsSync()) {
      await targetDir.create(recursive: true);
    }

    for (final file in archive.files) {
      if (!file.isFile) continue;
      final entryName = file.name.replaceAll('\\', '/');
      final outFile = File('${targetDir.path}/$entryName');
      await outFile.parent.create(recursive: true);
      final content = file.content as List<int>;
      await outFile.writeAsBytes(content, flush: true);
    }
  }

  Future<void> uninstallModule(String courseId) async {
    if (courseId == 'ms-deli') {
      throw const ModuleDownloadException(
        'Modul utama Melayu Deli adalah modul bawaan dan tidak dapat dihapus.',
      );
    }

    final installRoot = await _installRootDirectoryProvider();
    final modDir = Directory('${installRoot.path}/$courseId');
    if (modDir.existsSync()) {
      await modDir.delete(recursive: true);
    }

    await seeder.uninstallCourseContent(courseId);
  }

  Future<Uint8List> _fetchModuleBytes(
    ModuleCatalogItemModel item,
    void Function(double progress)? onProgress,
  ) async {
    // Check local release folder first (supports offline testing and bundled dev environments)
    final archiveFileName = item.archiveFilename ??
        (item.downloadUrl?.split('/').last ?? '${item.courseId}.zip');
    final localCandidates = [
      File('dist/releases/v1.1.0/$archiveFileName'),
      File('dist/releases/$archiveFileName'),
    ];
    for (final candidate in localCandidates) {
      if (candidate.existsSync()) {
        onProgress?.call(0.35);
        final bytes = await candidate.readAsBytes();
        onProgress?.call(0.60);
        return bytes;
      }
    }

    // Otherwise stream via HTTP from GitHub Releases
    try {
      final url = item.downloadUrl;
      if (url == null || url.isEmpty) {
        throw const ModuleDownloadException('URL unduhan modul tidak tersedia.');
      }
      final request = http.Request('GET', Uri.parse(url));
      final response = await _httpClient.send(request);
      if (response.statusCode != 200) {
        throw ModuleDownloadException(
          'Gagal mengunduh modul dari server (HTTP ${response.statusCode}).',
        );
      }

      final totalBytes = response.contentLength ?? item.sizeBytes;
      final builder = BytesBuilder(copy: false);
      var received = 0;

      await for (final chunk in response.stream) {
        builder.add(chunk);
        received += chunk.length;
        if (totalBytes > 0) {
          final ratio = (received / totalBytes).clamp(0.0, 1.0);
          onProgress?.call(0.05 + (ratio * 0.55));
        }
      }
      return builder.takeBytes();
    } catch (e) {
      if (e is ModuleDownloadException) rethrow;
      throw ModuleDownloadException('Koneksi unduhan modul terputus: $e');
    }
  }
}
