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
import 'package:katara/services/catalog_signature_verifier.dart';
import 'package:path_provider/path_provider.dart';

class ModuleDownloadException implements Exception {
  const ModuleDownloadException(this.message);
  final String message;

  @override
  String toString() => 'ModuleDownloadException: $message';
}

class CatalogEnvelopeModel {
  const CatalogEnvelopeModel({
    required this.catalogVersion,
    required this.minAppVersion,
    required this.revokedModules,
    required this.modules,
    required this.signatureVerified,
  });

  final int catalogVersion;
  final String minAppVersion;
  final List<String> revokedModules;
  final List<ModuleCatalogItemModel> modules;
  final bool signatureVerified;

  bool isModuleRevoked(String courseOrModuleId) =>
      revokedModules.contains(courseOrModuleId);
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
    this.publicKeyHex = CatalogSignatureVerifier.embeddedPublicKeyHex,
  })  : _installRootDirectoryProvider =
            installRootDirectoryProvider ?? _defaultInstallRoot,
        _httpClient = httpClient ?? http.Client();

  final AppDatabase db;
  final ContentSeeder seeder;
  final Future<Directory> Function() _installRootDirectoryProvider;
  final ModuleBytesFetcher? bytesFetcher;
  final http.Client _httpClient;
  final String publicKeyHex;

  static const int maxDownloadBytes = 25 * 1024 * 1024; // 25 MB
  static const int maxExtractedFileBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxExtractedTotalBytes = 30 * 1024 * 1024; // 30 MB
  static const int maxArchiveEntries = 64;
  static const double maxCompressionRatio = 30.0;

  static const Set<String> allowedDownloadHosts = {
    'github.com',
    'objects.githubusercontent.com',
    'release-assets.githubusercontent.com',
  };

  static const Set<String> allowedArchiveFiles = {
    'manifest.json',
    'words.json',
    'phrases.json',
    'sentences.json',
    'dialogues.json',
    'conversations.json',
    'letters.json',
    'articles.json',
    'collection_cards.json',
    'cultural_cards.json',
    'units.json',
    'lessons.json',
    'quiz_bank.json',
    'references.json',
    'dialect_references.json',
  };

  static Future<Directory> _defaultInstallRoot() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/modules');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Membersihkan sisa direktori sementara (`*.tmp` / `.staging_*`) saat aplikasi mulai.
  Future<int> cleanupStaleStagingDirectories() async {
    final installRoot = await _installRootDirectoryProvider();
    if (!installRoot.existsSync()) return 0;
    var removed = 0;
    for (final entity in installRoot.listSync()) {
      final baseName = entity.uri.pathSegments
          .where((s) => s.isNotEmpty)
          .lastOrNull ??
          '';
      if (baseName.endsWith('.tmp') || baseName.startsWith('.staging_')) {
        try {
          await entity.delete(recursive: true);
          removed++;
        } catch (_) {}
      }
    }
    return removed;
  }

  /// Membandingkan versi aplikasi (`currentVersion`) terhadap `minAppVersion` (semver `major.minor.patch`).
  static bool isAppUpdateRequired({
    required String currentVersion,
    required String minAppVersion,
  }) {
    List<int> parseSemver(String raw) {
      final clean = raw.split('+').first.split('-').first.trim();
      final parts = clean.split('.');
      return <int>[
        parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0,
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
        parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0,
      ];
    }

    final cur = parseSemver(currentVersion);
    final min = parseSemver(minAppVersion);
    for (var i = 0; i < 3; i++) {
      if (cur[i] < min[i]) return true;
      if (cur[i] > min[i]) return false;
    }
    return false;
  }

  /// Memvalidasi URL unduhan agar wajib memakai HTTPS dan berasal dari domain GitHub Releases resmi.
  static void validateDownloadUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw ModuleDownloadException('URL unduhan tidak valid: $url');
    }
    if (uri.scheme.toLowerCase() != 'https') {
      throw ModuleDownloadException(
        'Keamanan: Unduhan modul wajib menggunakan HTTPS (diterima skema "${uri.scheme}").',
      );
    }
    final host = uri.host.toLowerCase();
    if (!allowedDownloadHosts.contains(host)) {
      throw ModuleDownloadException(
        'Keamanan: Host unduhan "$host" tidak termasuk dalam daftar putih resmi GitHub Releases.',
      );
    }
  }

  /// Memuat dan memverifikasi katalog modul beserta tanda tangan Ed25519 dan kill-switch.
  Future<CatalogEnvelopeModel> loadCatalogEnvelope({
    String? rawJsonOverride,
    bool requireSignature = false,
  }) async {
    String rawJson;
    if (rawJsonOverride != null) {
      rawJson = rawJsonOverride;
    } else {
      final candidates = [
        File('dist/releases/v1.1.1/module_catalog.json'),
        File('dist/releases/v1.1.0/module_catalog.json'),
        File('assets/content/module_catalog.json'),
      ];
      File? found;
      for (final f in candidates) {
        if (f.existsSync()) {
          found = f;
          break;
        }
      }
      if (found != null) {
        rawJson = found.readAsStringSync();
      } else {
        rawJson =
            await rootBundle.loadString('assets/content/module_catalog.json');
      }
    }

    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const ModuleDownloadException('Format JSON katalog modul tidak valid.');
    }

    final hasSigField = decoded.containsKey('signature_ed25519') &&
        (decoded['signature_ed25519'] as String? ?? '').isNotEmpty;
    var sigValid = false;
    if (hasSigField || requireSignature) {
      sigValid = CatalogSignatureVerifier.verifyCatalog(
        decoded,
        publicKeyHex: publicKeyHex,
      );
      if (!sigValid) {
        throw const ModuleDownloadException(
          'Keamanan: Tanda tangan digital Ed25519 pada katalog modul tidak valid atau telah dimodifikasi.',
        );
      }
    }

    final revoked = (decoded['revoked_modules'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final minAppVersion = decoded['min_app_version']?.toString() ?? '1.0.0';
    final rawCatVer = decoded['catalog_version'];
    final catalogVersion = rawCatVer is num
        ? rawCatVer.toInt()
        : int.tryParse(rawCatVer?.toString() ?? '') ?? 1;

    final list = (decoded['modules'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final modules = list.map(ModuleCatalogItemModel.fromJson).toList();

    return CatalogEnvelopeModel(
      catalogVersion: catalogVersion,
      minAppVersion: minAppVersion,
      revokedModules: revoked,
      modules: modules,
      signatureVerified: sigValid,
    );
  }

  Future<List<ModuleCatalogItemModel>> loadCatalog({
    String? rawJsonOverride,
    bool requireSignature = false,
  }) async {
    final env = await loadCatalogEnvelope(
      rawJsonOverride: rawJsonOverride,
      requireSignature: requireSignature,
    );
    return env.modules
        .where((m) =>
            !env.isModuleRevoked(m.courseId) && !env.isModuleRevoked(m.moduleId))
        .toList();
  }

  /// Menjalankan kill-switch untuk mencabut modul yang masuk daftar `revoked_modules`
  /// tanpa menghapus progres belajar pengguna.
  Future<List<String>> enforceRevokedModules(CatalogEnvelopeModel envelope) async {
    final revokedRemoved = <String>[];
    for (final revokedId in envelope.revokedModules) {
      if (revokedId == 'ms-deli') continue;
      final installed = await getInstalledModule(revokedId);
      if (installed != null) {
        await uninstallModule(revokedId);
        revokedRemoved.add(revokedId);
      }
    }
    return revokedRemoved;
  }

  Future<List<InstalledModuleModel>> getInstalledModules() async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM installed_modules ORDER BY is_bundled DESC, course_id ASC',
        )
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
    bool allowDowngrade = false,
    Set<String> revokedModules = const {},
  }) async {
    // 1. Tolak penimpaan modul bawaan ms-deli
    if (item.courseId == 'ms-deli' || item.moduleId == 'ms-deli') {
      throw const ModuleDownloadException(
        'Keamanan: Modul bawaan Melayu Deli (ms-deli) dilindungi dan tidak dapat ditimpa oleh unduhan eksternal.',
      );
    }
    if (!RegExp(r'^ms-[a-z0-9-]+$').hasMatch(item.courseId)) {
      throw ModuleDownloadException(
        'ID kursus modul tidak valid: ${item.courseId}',
      );
    }

    // 2. Tolak modul yang masuk daftar pencabutan (kill-switch)
    if (revokedModules.contains(item.courseId) ||
        revokedModules.contains(item.moduleId)) {
      throw ModuleDownloadException(
        'Modul ${item.courseId} telah dicabut sementara oleh pengembang.',
      );
    }

    // 3. Proteksi anti-downgrade
    final existing = await getInstalledModule(item.courseId);
    if (!allowDowngrade &&
        existing != null &&
        item.version < existing.version) {
      throw ModuleDownloadException(
        'Proteksi anti-downgrade: Versi modul (${item.version}) lebih lama dari versi terpasang (${existing.version}).',
      );
    }

    // 4. Validasi URL HTTPS & host allowlist bila downloadUrl disediakan
    if (item.downloadUrl != null && item.downloadUrl!.isNotEmpty) {
      validateDownloadUrl(item.downloadUrl!);
    }

    // 5. Pastikan hash SHA-256 tersedia dan berformat 64 karakter hex
    final expectedHash = item.sha256?.trim() ?? '';
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(expectedHash)) {
      throw const ModuleDownloadException(
        'Keamanan: Paket modul wajib memiliki checksum SHA-256 (64 hex) yang valid.',
      );
    }

    onProgress?.call(0.05);

    final zipBytes = bytesFetcher != null
        ? await bytesFetcher!(item, onProgress)
        : await _fetchModuleBytes(item, onProgress);

    if (zipBytes.length > maxDownloadBytes) {
      throw const ModuleDownloadException(
        'Keamanan: Ukuran paket modul melebihi batas maksimum 25 MB.',
      );
    }

    onProgress?.call(0.65);

    final installRoot = await _installRootDirectoryProvider();
    final stagingDir = Directory('${installRoot.path}/${item.courseId}.tmp');
    final finalDir = Directory('${installRoot.path}/${item.courseId}');

    if (stagingDir.existsSync()) {
      await stagingDir.delete(recursive: true);
    }

    try {
      await verifyAndExtractArchive(
        zipBytes: zipBytes,
        expectedSha256: expectedHash,
        targetDir: stagingDir,
      );

      // Validasi skema JSON dan isolasi course_id sebelum memindahkan direktori / menyentuh DB
      validateExtractedModuleDirectory(
        courseId: item.courseId,
        directory: stagingDir,
        minContentVersion: existing != null && !allowDowngrade
            ? existing.version
            : 1,
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
        sha256Hash: expectedHash,
        version: item.version.toString(),
      );
    } catch (e) {
      if (stagingDir.existsSync()) {
        try {
          await stagingDir.delete(recursive: true);
        } catch (_) {}
      }
      if (e is ModuleDownloadException) rethrow;
      throw ModuleDownloadException('Validasi modul gagal: $e');
    }

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
    if (zipBytes.length > maxDownloadBytes) {
      throw const ModuleDownloadException(
        'Keamanan: Ukuran arsip ZIP melebihi batas maksimum 25 MB.',
      );
    }

    if (expectedSha256 == null ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(expectedSha256.trim())) {
      throw const ModuleDownloadException(
        'Keamanan: Checksum SHA-256 wajib disertakan untuk verifikasi arsip.',
      );
    }

    final actualHash = sha256.convert(zipBytes).toString();
    if (actualHash.toLowerCase() != expectedSha256.trim().toLowerCase()) {
      throw ModuleDownloadException(
        'Checksum SHA-256 modul tidak cocok (diharapkan $expectedSha256, diterima $actualHash).',
      );
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
    if (archive.files.length > maxArchiveEntries) {
      throw ModuleDownloadException(
        'Keamanan: Jumlah berkas dalam ZIP (${archive.files.length}) melebihi batas maksimum $maxArchiveEntries.',
      );
    }

    var totalExtractedBytes = 0;

    for (final file in archive.files) {
      final entryName = file.name.replaceAll('\\', '/');
      if (entryName.contains('..') ||
          entryName.startsWith('/') ||
          entryName.contains(':')) {
        throw ModuleDownloadException(
          'Keamanan (Zip-Slip): Entri ZIP tidak aman ditolak: ${file.name}',
        );
      }
      if (!file.isFile) continue;

      // Hanya izinkan berkas JSON tingkat atas yang ada di daftar putih
      if (entryName.contains('/') || !allowedArchiveFiles.contains(entryName)) {
        throw ModuleDownloadException(
          'Keamanan: Berkas "$entryName" tidak diizinkan di dalam paket modul bahasa.',
        );
      }

      final content = file.content as List<int>;
      final uncompressedLen = content.length;
      if (uncompressedLen > maxExtractedFileBytes) {
        throw ModuleDownloadException(
          'Keamanan (Zip-Bomb): Ukuran berkas "$entryName" ($uncompressedLen byte) melebihi batas 10 MB.',
        );
      }

      totalExtractedBytes += uncompressedLen;
      if (totalExtractedBytes > maxExtractedTotalBytes) {
        throw const ModuleDownloadException(
          'Keamanan (Zip-Bomb): Total ukuran ekstraksi melebihi batas 30 MB.',
        );
      }
    }

    // Cek rasio kompresi keseluruhan untuk mendeteksi zip-bomb
    if (zipBytes.length >= 512) {
      final ratio = totalExtractedBytes / zipBytes.length;
      if (ratio > maxCompressionRatio) {
        throw ModuleDownloadException(
          'Keamanan (Zip-Bomb): Rasio kompresi tidak wajar (${ratio.toStringAsFixed(1)}:1 > $maxCompressionRatio:1).',
        );
      }
    }

    if (!targetDir.existsSync()) {
      await targetDir.create(recursive: true);
    }
    final canonicalTarget = targetDir.resolveSymbolicLinksSync();

    for (final file in archive.files) {
      if (!file.isFile) continue;
      final entryName = file.name.replaceAll('\\', '/');
      final outFile = File('${targetDir.path}/$entryName');
      await outFile.parent.create(recursive: true);
      final content = file.content as List<int>;
      await outFile.writeAsBytes(content, flush: true);

      final canonicalOut = outFile.resolveSymbolicLinksSync();
      if (!canonicalOut.startsWith(canonicalTarget)) {
        await outFile.delete();
        throw ModuleDownloadException(
          'Keamanan (Path Traversal): Berkas keluar dari direktori target: $entryName',
        );
      }
    }
  }

  /// Memvalidasi struktur skema JSON, tipe data, batas panjang string, dan isolasi `course_id`
  /// pada hasil ekstraksi sebelum dimasukkan ke database SQLite.
  static void validateExtractedModuleDirectory({
    required String courseId,
    required Directory directory,
    int minContentVersion = 1,
  }) {
    if (courseId == 'ms-deli') {
      throw const ModuleDownloadException(
        'Keamanan: Modul bawaan ms-deli tidak boleh ditimpa.',
      );
    }

    final manifestFile = File('${directory.path}/manifest.json');
    final wordsFile = File('${directory.path}/words.json');
    if (!manifestFile.existsSync() || !wordsFile.existsSync()) {
      throw const ModuleDownloadException(
        'Paket modul tidak lengkap: manifest.json dan words.json wajib ada.',
      );
    }

    final dynamic manifestDecoded;
    try {
      manifestDecoded = jsonDecode(manifestFile.readAsStringSync());
    } catch (e) {
      throw ModuleDownloadException('JSON manifest.json rusak: $e');
    }
    if (manifestDecoded is! Map<String, dynamic>) {
      throw const ModuleDownloadException('manifest.json harus berupa objek JSON.');
    }

    final manifestCourseId = manifestDecoded['course_id'] as String?;
    if (manifestCourseId != null && manifestCourseId != courseId) {
      throw ModuleDownloadException(
        'Keamanan: manifest.json mendeklarasikan course_id "$manifestCourseId" yang berbeda dari "$courseId".',
      );
    }
    final contentVersion =
        (manifestDecoded['content_version'] as num?)?.toInt() ?? 1;
    if (contentVersion < minContentVersion) {
      throw ModuleDownloadException(
        'Keamanan (Anti-Downgrade): content_version di manifest ($contentVersion) lebih rendah dari versi minimum ($minContentVersion).',
      );
    }

    for (final fileName in allowedArchiveFiles) {
      if (fileName == 'manifest.json') continue;
      final file = File('${directory.path}/$fileName');
      if (!file.existsSync()) continue;

      final dynamic decoded;
      try {
        decoded = jsonDecode(file.readAsStringSync());
      } catch (e) {
        throw ModuleDownloadException('Berkas JSON $fileName tidak valid: $e');
      }
      if (decoded is! List) {
        throw ModuleDownloadException(
          'Skema $fileName tidak valid: harus berupa JSON Array.',
        );
      }
      if (decoded.length > 10000) {
        throw ModuleDownloadException(
          'Keamanan: Jumlah entri pada $fileName (${decoded.length}) melebihi batas wajar 10.000.',
        );
      }

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          throw ModuleDownloadException(
            'Skema $fileName tidak valid: setiap elemen harus berupa objek JSON.',
          );
        }
        final id = item['id'] ?? item['source_id'];
        if (id is! String || id.trim().isEmpty || id.length > 128) {
          throw ModuleDownloadException(
            'Skema $fileName tidak valid: field "id" wajib berupa string (1..128 karakter).',
          );
        }
        if (id.startsWith('ms-deli:')) {
          throw ModuleDownloadException(
            'Keamanan: Entri "$id" pada $fileName mencoba menimpa namespace ms-deli.',
          );
        }
        final itemCourse = item['course_id'];
        if (itemCourse != null &&
            (itemCourse is! String || itemCourse != courseId)) {
          throw ModuleDownloadException(
            'Keamanan: Entri "$id" pada $fileName memiliki course_id "$itemCourse" yang tidak cocok dengan "$courseId".',
          );
        }

        if (fileName == 'words.json') {
          final term = item['deli'] ?? item['word'];
          final meaning = item['indonesia'] ?? item['meaning'];
          if (term is! String ||
              term.trim().isEmpty ||
              term.length > 256 ||
              meaning is! String ||
              meaning.trim().isEmpty ||
              meaning.length > 512) {
            throw ModuleDownloadException(
              'Skema words.json tidak valid pada entri "$id": kata/arti kosong atau melebihi batas panjang.',
            );
          }
        }
      }
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
    final archiveFileName = item.archiveFilename ??
        (item.downloadUrl?.split('/').last ?? '${item.courseId}.zip');
    if (archiveFileName.contains('..') ||
        archiveFileName.contains('/') ||
        archiveFileName.contains('\\')) {
      throw ModuleDownloadException(
        'Nama berkas arsip tidak aman: $archiveFileName',
      );
    }

    final localCandidates = [
      File('dist/releases/v1.1.1/$archiveFileName'),
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

    try {
      final url = item.downloadUrl;
      if (url == null || url.isEmpty) {
        throw const ModuleDownloadException('URL unduhan modul tidak tersedia.');
      }
      validateDownloadUrl(url);

      final request = http.Request('GET', Uri.parse(url));
      final response = await _httpClient.send(request);
      if (response.statusCode != 200) {
        throw ModuleDownloadException(
          'Gagal mengunduh modul dari server (HTTP ${response.statusCode}).',
        );
      }

      final totalBytes = response.contentLength ?? item.sizeBytes;
      if (totalBytes > maxDownloadBytes) {
        throw const ModuleDownloadException(
          'Keamanan: Ukuran unduhan modul melebihi batas 25 MB.',
        );
      }

      final builder = BytesBuilder(copy: false);
      var received = 0;

      await for (final chunk in response.stream) {
        received += chunk.length;
        if (received > maxDownloadBytes) {
          throw const ModuleDownloadException(
            'Keamanan: Aliran unduhan diputus karena melebihi batas 25 MB.',
          );
        }
        builder.add(chunk);
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
