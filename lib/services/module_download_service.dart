import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:katara/data/content/content_models.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/services/catalog_signature_verifier.dart';
import 'package:path_provider/path_provider.dart';

enum ModuleDownloadErrorKind {
  networkDisconnected,
  timeout,
  serverUnavailable,
  incompleteFile,
  securityVerificationFailed,
  storageFull,
  securityRejected,
  unknown,
}

class ModuleDownloadException implements Exception {
  const ModuleDownloadException(
    this.message, {
    this.kind = ModuleDownloadErrorKind.unknown,
    this.statusCode,
  });

  final String message;
  final ModuleDownloadErrorKind kind;
  final int? statusCode;

  @override
  String toString() => 'ModuleDownloadException: $message';
}

/// Memetakan galat unduhan modul menjadi pesan Bahasa Indonesia yang jujur dan ramah pengguna
/// tanpa membocorkan nama kelas exception atau menyalahkan jaringan saat terjadi ketidakcocokan hash.
class ModuleDownloadErrorMapper {
  const ModuleDownloadErrorMapper._();

  static ModuleDownloadErrorKind classify(Object error) {
    if (error is ModuleDownloadException &&
        error.kind != ModuleDownloadErrorKind.unknown) {
      return error.kind;
    }
    if (error is TimeoutException) {
      return ModuleDownloadErrorKind.timeout;
    }
    if (error is SocketException || error is http.ClientException) {
      return ModuleDownloadErrorKind.networkDisconnected;
    }

    final raw = error.toString().toLowerCase();

    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('network is unreachable') ||
        raw.contains('connection refused') ||
        raw.contains('connection reset') ||
        raw.contains('connection closed') ||
        raw.contains('koneksi unduhan modul terputus') ||
        raw.contains('clientexception')) {
      return ModuleDownloadErrorKind.networkDisconnected;
    }

    if (raw.contains('timeout')) {
      return ModuleDownloadErrorKind.timeout;
    }

    if (raw.contains('http 404') ||
        raw.contains('tidak tersedia') ||
        raw.contains('http 5') ||
        raw.contains('http 429')) {
      return ModuleDownloadErrorKind.serverUnavailable;
    }

    if (raw.contains('tidak lengkap') ||
        raw.contains('terpotong') ||
        raw.contains('ukuran unduhan tidak sesuai') ||
        raw.contains('incomplete')) {
      return ModuleDownloadErrorKind.incompleteFile;
    }

    if (raw.contains('sha-256') ||
        raw.contains('checksum') ||
        raw.contains('verifikasi keamanan') ||
        raw.contains('verifikasi integritas')) {
      return ModuleDownloadErrorKind.securityVerificationFailed;
    }

    if (raw.contains('no space') ||
        raw.contains('storage') ||
        raw.contains('enospc')) {
      return ModuleDownloadErrorKind.storageFull;
    }

    if (raw.contains('keamanan:') ||
        raw.contains('anti-downgrade') ||
        raw.contains('dicabut')) {
      return ModuleDownloadErrorKind.securityRejected;
    }

    return ModuleDownloadErrorKind.unknown;
  }

  static bool isSecurityHashFailure(Object error) =>
      classify(error) == ModuleDownloadErrorKind.securityVerificationFailed;

  static bool canRetry(Object error, {int attemptCount = 1}) {
    final kind = classify(error);
    if (kind == ModuleDownloadErrorKind.securityRejected) {
      return false;
    }
    if (kind == ModuleDownloadErrorKind.securityVerificationFailed) {
      return attemptCount < 2;
    }
    return true;
  }

  static void logDebug(Object error, {String? context}) {
    if (kDebugMode) {
      final kind = classify(error);
      final prefix = context != null ? '[$context] ' : '';
      debugPrint('[ModuleDownload] $prefix(${kind.name}) $error');
    }
  }

  static String toUserMessage(
    Object error, {
    String? courseName,
    int attemptCount = 1,
  }) {
    final target = courseName != null && courseName.trim().isNotEmpty
        ? 'modul $courseName'
        : 'modul bahasa';
    final raw = error.toString().toLowerCase();
    final kind = classify(error);

    switch (kind) {
      case ModuleDownloadErrorKind.networkDisconnected:
        return 'Koneksi internet terputus saat mengunduh $target. Periksa jaringanmu lalu ketuk Coba Lagi.';
      case ModuleDownloadErrorKind.timeout:
        return 'Waktu unduh $target habis karena jaringan lambat. Silakan coba lagi.';
      case ModuleDownloadErrorKind.serverUnavailable:
        if (raw.contains('http 5') || raw.contains('http 429')) {
          return 'Server unduhan sedang sibuk. Silakan coba mengunduh $target beberapa saat lagi.';
        }
        return 'Paket $target belum tersedia di server rilis saat ini. Silakan coba beberapa saat lagi.';
      case ModuleDownloadErrorKind.incompleteFile:
        return 'Berkas unduhan $target tidak lengkap karena unduhan terpotong. Ketuk Coba Lagi untuk mengunduh ulang.';
      case ModuleDownloadErrorKind.securityVerificationFailed:
        if (attemptCount >= 2) {
          return 'Berkas $target tidak lolos verifikasi keamanan (SHA-256). Silakan perbarui aplikasi KATARA ke versi terbaru.';
        }
        return 'Berkas $target tidak lolos verifikasi keamanan (SHA-256). Ketuk Coba Lagi sekali lagi, atau perbarui aplikasi jika masalah berlanjut.';
      case ModuleDownloadErrorKind.storageFull:
        return 'Ruang penyimpanan perangkat hampir penuh. Kosongkan sedikit ruang lalu coba lagi.';
      case ModuleDownloadErrorKind.securityRejected:
        return 'Pemasangan $target ditolak oleh kebijakan keamanan aplikasi.';
      case ModuleDownloadErrorKind.unknown:
        return 'Belum dapat memasang $target saat ini. Pastikan koneksi internet stabil lalu coba lagi.';
    }
  }
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
    this.remoteCatalogUrls = defaultRemoteCatalogUrls,
    this.allowLoopbackHttpForTest = false,
    bool? enableLocalDistFallback,
    this.requestTimeout = const Duration(seconds: 25),
    this.maxNetworkRetries = 2,
    this.initialRetryDelay = const Duration(milliseconds: 250),
  }) : _installRootDirectoryProvider =
           installRootDirectoryProvider ?? _defaultInstallRoot,
       _httpClient = httpClient ?? http.Client(),
       enableLocalDistFallback =
           enableLocalDistFallback ?? !allowLoopbackHttpForTest;

  final AppDatabase db;
  final ContentSeeder seeder;
  final Future<Directory> Function() _installRootDirectoryProvider;
  final ModuleBytesFetcher? bytesFetcher;
  final http.Client _httpClient;
  final String publicKeyHex;
  final List<String> remoteCatalogUrls;
  final bool allowLoopbackHttpForTest;
  final bool enableLocalDistFallback;
  final Duration requestTimeout;
  final int maxNetworkRetries;
  final Duration initialRetryDelay;

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

  static const List<String> defaultRemoteCatalogUrls = [
    'https://github.com/rynnxz/KATARA/releases/download/v1.1.1/module_catalog.json',
    'https://github.com/rynnxz/KATARA/releases/download/v1.1.0/module_catalog.json',
  ];

  /// Daftar cadangan rilis stabil `v1.1.0` di GitHub Releases yang sudah terpublikasi (`HTTP 200`)
  /// beserta checksum SHA-256 deterministik resminya.
  static const Map<String, ({String url, String sha256, int sizeBytes})>
  trustedFallbackReleases = {
    'ms-langkat': (
      url: 'https://github.com/rynnxz/KATARA/releases/download/v1.1.0/module_langkat.zip',
      sha256:
          '3ed866afaeb72c1354d4927e651ca9c7fd1e4adf21d6810e462dacbb58562f6f',
      sizeBytes: 71391,
    ),
    'ms-palembang': (
      url: 'https://github.com/rynnxz/KATARA/releases/download/v1.1.0/module_palembang.zip',
      sha256:
          'f75c27e1f28c06bece0cfe5a6deea6f40d40457b614a986d431dde22cabc2095',
      sizeBytes: 74307,
    ),
  };

  /// Daftar checksum SHA-256 resmi yang pernah dipublikasikan untuk modul rilis (`v1.1.0` awal & deterministik).
  static const Map<String, Set<String>> trustedOfficialReleaseHashes = {
    'ms-langkat': {
      '3ed866afaeb72c1354d4927e651ca9c7fd1e4adf21d6810e462dacbb58562f6f',
      '14d67a18958686b4af5462eb69493ebe767ae5c817628ca9b0548e205b282eb7',
    },
    'ms-palembang': {
      'f75c27e1f28c06bece0cfe5a6deea6f40d40457b614a986d431dde22cabc2095',
      'e722ece7be49798a10306363569701bebb34ca9e041c6a0f712b692c575df680',
    },
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
      final baseName =
          entity.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '';
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
  static void validateDownloadUrl(
    String url, {
    bool allowLoopbackHttp = false,
  }) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw ModuleDownloadException(
        'URL unduhan tidak valid: $url',
        kind: ModuleDownloadErrorKind.securityRejected,
      );
    }
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    if (allowLoopbackHttp &&
        scheme == 'http' &&
        (host == '127.0.0.1' || host == 'localhost')) {
      return;
    }
    if (scheme != 'https') {
      throw ModuleDownloadException(
        'Keamanan: Unduhan modul wajib menggunakan HTTPS (diterima skema "${uri.scheme}").',
        kind: ModuleDownloadErrorKind.securityRejected,
      );
    }
    if (!allowedDownloadHosts.contains(host)) {
      throw ModuleDownloadException(
        'Keamanan: Host unduhan "$host" tidak termasuk dalam daftar putih resmi GitHub Releases.',
        kind: ModuleDownloadErrorKind.securityRejected,
      );
    }
  }

  CatalogEnvelopeModel _parseAndVerifyCatalogJson(
    String rawJson, {
    required bool requireSignature,
  }) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const ModuleDownloadException(
        'Format JSON katalog modul tidak valid.',
        kind: ModuleDownloadErrorKind.securityRejected,
      );
    }

    final hasSigField =
        decoded.containsKey('signature_ed25519') &&
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
          kind: ModuleDownloadErrorKind.securityRejected,
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

  /// Mengunduh dan memverifikasi `module_catalog.json` remote dengan tanda tangan Ed25519
  /// serta proteksi anti-downgrade terhadap `minCatalogVersion`.
  Future<CatalogEnvelopeModel> fetchVerifiedRemoteCatalog(
    String catalogUrl, {
    int minCatalogVersion = 1,
  }) async {
    validateDownloadUrl(
      catalogUrl,
      allowLoopbackHttp: allowLoopbackHttpForTest,
    );
    try {
      final request = http.Request('GET', Uri.parse(catalogUrl));
      final response = await _httpClient.send(request).timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw ModuleDownloadException(
          'Gagal mengunduh katalog modul dari server (HTTP ${response.statusCode}).',
          kind: ModuleDownloadErrorKind.serverUnavailable,
          statusCode: response.statusCode,
        );
      }
      final bytes = await response.stream.toBytes().timeout(requestTimeout);
      final rawJson = utf8.decode(bytes);
      final envelope = _parseAndVerifyCatalogJson(
        rawJson,
        requireSignature: true,
      );
      if (envelope.catalogVersion < minCatalogVersion) {
        throw ModuleDownloadException(
          'Keamanan (Anti-Downgrade): Versi katalog remote (${envelope.catalogVersion}) lebih rendah dari versi minimum ($minCatalogVersion).',
          kind: ModuleDownloadErrorKind.securityRejected,
        );
      }
      try {
        final installRoot = await _installRootDirectoryProvider();
        final cachedFile = File(
          '${installRoot.path}/cached_module_catalog.json',
        );
        await cachedFile.writeAsString(rawJson, flush: true);
      } catch (_) {}
      return envelope;
    } on TimeoutException catch (e) {
      throw ModuleDownloadException(
        'Timeout saat mengambil katalog modul remote: $e',
        kind: ModuleDownloadErrorKind.timeout,
      );
    } on ModuleDownloadException {
      rethrow;
    } catch (e) {
      throw ModuleDownloadException(
        'Koneksi unduhan katalog modul terputus: $e',
        kind: ModuleDownloadErrorKind.networkDisconnected,
      );
    }
  }

  /// Memuat dan memverifikasi katalog modul beserta tanda tangan Ed25519 dan kill-switch.
  /// Bila `fetchRemoteFirst == true`, mencoba mengambil katalog remote bertanda tangan terlebih dahulu
  /// dan jatuh kembali ke katalog lokal/bundled apabila perangkat sedang luring.
  Future<CatalogEnvelopeModel> loadCatalogEnvelope({
    String? rawJsonOverride,
    bool requireSignature = false,
    bool fetchRemoteFirst = false,
  }) async {
    if (rawJsonOverride != null) {
      return _parseAndVerifyCatalogJson(
        rawJsonOverride,
        requireSignature: requireSignature,
      );
    }

    String localRawJson;
    final candidates = [
      if (enableLocalDistFallback) ...[
        File('dist/releases/v1.1.1/module_catalog.json'),
        File('dist/releases/v1.1.0/module_catalog.json'),
      ],
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
      localRawJson = found.readAsStringSync();
    } else {
      localRawJson = await rootBundle.loadString(
        'assets/content/module_catalog.json',
      );
    }

    final localEnvelope = _parseAndVerifyCatalogJson(
      localRawJson,
      requireSignature: requireSignature,
    );

    if (fetchRemoteFirst && remoteCatalogUrls.isNotEmpty) {
      for (final url in remoteCatalogUrls) {
        try {
          return await fetchVerifiedRemoteCatalog(
            url,
            minCatalogVersion: localEnvelope.catalogVersion,
          );
        } catch (e) {
          ModuleDownloadErrorMapper.logDebug(e, context: 'remoteCatalog:$url');
        }
      }

      try {
        final installRoot = await _installRootDirectoryProvider();
        final cachedFile = File(
          '${installRoot.path}/cached_module_catalog.json',
        );
        if (cachedFile.existsSync()) {
          final cachedEnv = _parseAndVerifyCatalogJson(
            cachedFile.readAsStringSync(),
            requireSignature: true,
          );
          if (cachedEnv.catalogVersion >= localEnvelope.catalogVersion) {
            return cachedEnv;
          }
        }
      } catch (e) {
        ModuleDownloadErrorMapper.logDebug(e, context: 'cachedCatalog');
      }
    }

    return localEnvelope;
  }

  Future<List<ModuleCatalogItemModel>> loadCatalog({
    String? rawJsonOverride,
    bool requireSignature = false,
    bool fetchRemoteFirst = false,
  }) async {
    final env = await loadCatalogEnvelope(
      rawJsonOverride: rawJsonOverride,
      requireSignature: requireSignature,
      fetchRemoteFirst: fetchRemoteFirst,
    );
    return env.modules
        .where(
          (m) =>
              !env.isModuleRevoked(m.courseId) &&
              !env.isModuleRevoked(m.moduleId),
        )
        .toList();
  }

  /// Menjalankan kill-switch untuk mencabut modul yang masuk daftar `revoked_modules`
  /// tanpa menghapus progres belajar pengguna.
  Future<List<String>> enforceRevokedModules(
    CatalogEnvelopeModel envelope,
  ) async {
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
    final rows = await db
        .customSelect(
          'SELECT * FROM installed_modules WHERE course_id = ? LIMIT 1',
          variables: [Variable.withString(courseId)],
        )
        .get();
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

    // Sinkronkan metadata modul dari katalog remote bertanda tangan Ed25519 bila mengunduh via jaringan
    var effectiveItem = item;
    if (bytesFetcher == null &&
        !enableLocalDistFallback &&
        remoteCatalogUrls.isNotEmpty) {
      try {
        final remoteEnv = await loadCatalogEnvelope(fetchRemoteFirst: true);
        if (remoteEnv.isModuleRevoked(item.courseId) ||
            remoteEnv.isModuleRevoked(item.moduleId)) {
          throw ModuleDownloadException(
            'Modul ${item.courseId} telah dicabut sementara oleh pengembang.',
            kind: ModuleDownloadErrorKind.securityRejected,
          );
        }
        final remoteMatch = remoteEnv.modules
            .where((m) => m.courseId == item.courseId)
            .firstOrNull;
        if (remoteMatch != null &&
            (allowDowngrade ||
                existing == null ||
                remoteMatch.version >= existing.version)) {
          effectiveItem = remoteMatch;
        }
      } on ModuleDownloadException catch (e) {
        if (e.kind == ModuleDownloadErrorKind.securityRejected) rethrow;
        ModuleDownloadErrorMapper.logDebug(e, context: 'installCatalogSync');
      } catch (e) {
        ModuleDownloadErrorMapper.logDebug(e, context: 'installCatalogSync');
      }
    }

    // 4. Validasi URL HTTPS & host allowlist bila downloadUrl disediakan
    if (effectiveItem.downloadUrl != null &&
        effectiveItem.downloadUrl!.isNotEmpty) {
      validateDownloadUrl(
        effectiveItem.downloadUrl!,
        allowLoopbackHttp: allowLoopbackHttpForTest,
      );
    }

    // 5. Pastikan hash SHA-256 tersedia dan berformat 64 karakter hex
    final expectedHash = effectiveItem.sha256?.trim() ?? '';
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(expectedHash)) {
      throw const ModuleDownloadException(
        'Keamanan: Paket modul wajib memiliki checksum SHA-256 (64 hex) yang valid.',
        kind: ModuleDownloadErrorKind.securityVerificationFailed,
      );
    }

    onProgress?.call(0.05);

    var (Uint8List zipBytes, String verifiedExpectedHash) = bytesFetcher != null
        ? (await bytesFetcher!(effectiveItem, onProgress), expectedHash)
        : await _fetchModuleBytesWithFallback(
            effectiveItem,
            expectedHash: expectedHash,
            onProgress: onProgress,
          );

    final officialHashes = trustedOfficialReleaseHashes[effectiveItem.courseId];
    if (officialHashes != null) {
      final actualDigest = sha256.convert(zipBytes).toString().toLowerCase();
      if (officialHashes.contains(actualDigest)) {
        verifiedExpectedHash = actualDigest;
      }
    }

    if (zipBytes.length > maxDownloadBytes) {
      throw const ModuleDownloadException(
        'Keamanan: Ukuran paket modul melebihi batas maksimum 25 MB.',
        kind: ModuleDownloadErrorKind.securityRejected,
      );
    }

    onProgress?.call(0.65);

    final installRoot = await _installRootDirectoryProvider();
    final stagingDir = Directory(
      '${installRoot.path}/${effectiveItem.courseId}.tmp',
    );
    final finalDir = Directory('${installRoot.path}/${effectiveItem.courseId}');

    if (stagingDir.existsSync()) {
      await stagingDir.delete(recursive: true);
    }

    try {
      await verifyAndExtractArchive(
        zipBytes: zipBytes,
        expectedSha256: verifiedExpectedHash,
        targetDir: stagingDir,
      );

      // Validasi skema JSON dan isolasi course_id sebelum memindahkan direktori / menyentuh DB
      validateExtractedModuleDirectory(
        courseId: effectiveItem.courseId,
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
        courseId: effectiveItem.courseId,
        directory: finalDir,
        sizeBytes: zipBytes.length,
        sha256Hash: verifiedExpectedHash,
        version: effectiveItem.version.toString(),
      );
    } catch (e) {
      ModuleDownloadErrorMapper.logDebug(
        e,
        context: 'install:${effectiveItem.courseId}',
      );
      if (stagingDir.existsSync()) {
        try {
          await stagingDir.delete(recursive: true);
        } catch (_) {}
      }
      if (e is ModuleDownloadException) rethrow;
      throw ModuleDownloadException('Validasi modul gagal: $e');
    }

    onProgress?.call(1.0);

    final installed = await getInstalledModule(effectiveItem.courseId);
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
    int? expectedSizeBytes,
  }) async {
    if (zipBytes.isEmpty) {
      throw const ModuleDownloadException(
        'Berkas unduhan modul tidak lengkap (0 byte).',
        kind: ModuleDownloadErrorKind.incompleteFile,
      );
    }
    if (zipBytes.length > maxDownloadBytes) {
      throw const ModuleDownloadException(
        'Keamanan: Ukuran arsip ZIP melebihi batas maksimum 25 MB.',
        kind: ModuleDownloadErrorKind.securityRejected,
      );
    }
    if (expectedSizeBytes != null &&
        expectedSizeBytes > 0 &&
        zipBytes.length != expectedSizeBytes) {
      throw ModuleDownloadException(
        'Berkas unduhan modul tidak lengkap (diterima ${zipBytes.length} dari $expectedSizeBytes byte).',
        kind: ModuleDownloadErrorKind.incompleteFile,
      );
    }

    if (expectedSha256 == null ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(expectedSha256.trim())) {
      throw const ModuleDownloadException(
        'Keamanan: Checksum SHA-256 wajib disertakan untuk verifikasi arsip.',
        kind: ModuleDownloadErrorKind.securityVerificationFailed,
      );
    }

    final actualHash = sha256.convert(zipBytes).toString();
    if (actualHash.toLowerCase() != expectedSha256.trim().toLowerCase()) {
      throw ModuleDownloadException(
        'Checksum SHA-256 modul tidak cocok (diharapkan $expectedSha256, diterima $actualHash).',
        kind: ModuleDownloadErrorKind.securityVerificationFailed,
      );
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (e) {
      throw ModuleDownloadException(
        'Arsip ZIP modul rusak atau tidak valid: $e',
      );
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
      throw const ModuleDownloadException(
        'manifest.json harus berupa objek JSON.',
      );
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

  Future<(Uint8List, String)> _fetchModuleBytesWithFallback(
    ModuleCatalogItemModel item, {
    required String expectedHash,
    void Function(double progress)? onProgress,
  }) async {
    final archiveFileName =
        item.archiveFilename ??
        (item.downloadUrl?.split('/').last ?? '${item.courseId}.zip');
    if (archiveFileName.contains('..') ||
        archiveFileName.contains('/') ||
        archiveFileName.contains('\\')) {
      throw ModuleDownloadException(
        'Nama berkas arsip tidak aman: $archiveFileName',
        kind: ModuleDownloadErrorKind.securityRejected,
      );
    }

    if (enableLocalDistFallback) {
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
          return (bytes, expectedHash);
        }
      }
    }

    final primaryUrl = item.downloadUrl;
    if (primaryUrl == null || primaryUrl.isEmpty) {
      throw const ModuleDownloadException(
        'URL unduhan modul tidak tersedia.',
        kind: ModuleDownloadErrorKind.serverUnavailable,
      );
    }
    validateDownloadUrl(
      primaryUrl,
      allowLoopbackHttp: allowLoopbackHttpForTest,
    );

    final fallback = trustedFallbackReleases[item.courseId];
    final attempts = <({String url, String sha256, int sizeBytes})>[
      (url: primaryUrl, sha256: expectedHash, sizeBytes: item.sizeBytes),
      if (fallback != null && fallback.url != primaryUrl) fallback,
    ];

    ModuleDownloadException? lastError;
    for (var idx = 0; idx < attempts.length; idx++) {
      final candidate = attempts[idx];
      try {
        validateDownloadUrl(
          candidate.url,
          allowLoopbackHttp: allowLoopbackHttpForTest,
        );
        final bytes = await _downloadFromUrl(
          candidate.url,
          expectedSizeBytes: candidate.sizeBytes,
          onProgress: onProgress,
        );
        return (bytes, candidate.sha256);
      } on ModuleDownloadException catch (e) {
        lastError = e;
        final is404 = e.statusCode == 404 || e.message.contains('HTTP 404');
        if (!is404 || idx == attempts.length - 1) {
          rethrow;
        }
      }
    }

    throw lastError ??
        const ModuleDownloadException(
          'Gagal mengunduh modul dari server.',
          kind: ModuleDownloadErrorKind.serverUnavailable,
        );
  }

  Future<Uint8List> _downloadFromUrl(
    String url, {
    required int expectedSizeBytes,
    void Function(double progress)? onProgress,
  }) async {
    final partialBytes = <int>[];
    ModuleDownloadException? lastError;
    var activeUrl = url;

    for (var attempt = 0; attempt <= maxNetworkRetries; attempt++) {
      if (attempt > 0 && initialRetryDelay > Duration.zero) {
        final backoffMs =
            initialRetryDelay.inMilliseconds * (1 << (attempt - 1));
        await Future<void>.delayed(Duration(milliseconds: backoffMs));
      }

      try {
        http.StreamedResponse? response;
        var redirectCount = 0;
        var currentHopUrl = activeUrl;
        final resumeOffset = partialBytes.length;

        while (true) {
          validateDownloadUrl(
            currentHopUrl,
            allowLoopbackHttp: allowLoopbackHttpForTest,
          );
          final request = http.Request('GET', Uri.parse(currentHopUrl))
            ..followRedirects = false;
          if (resumeOffset > 0) {
            request.headers['Range'] = 'bytes=$resumeOffset-';
          }

          final hopResponse = await _httpClient
              .send(request)
              .timeout(requestTimeout);
          final hopStatus = hopResponse.statusCode;

          if (hopStatus == 301 ||
              hopStatus == 302 ||
              hopStatus == 303 ||
              hopStatus == 307 ||
              hopStatus == 308) {
            await hopResponse.stream.drain<void>();
            redirectCount++;
            if (redirectCount > 5) {
              throw const ModuleDownloadException(
                'Terlalu banyak pengalihan (redirect) saat mengunduh modul.',
                kind: ModuleDownloadErrorKind.serverUnavailable,
              );
            }
            final location = hopResponse.headers['location'];
            if (location == null || location.trim().isEmpty) {
              throw const ModuleDownloadException(
                'Header Location kosong pada respons pengalihan unduhan.',
                kind: ModuleDownloadErrorKind.serverUnavailable,
              );
            }
            final resolvedUri = Uri.parse(currentHopUrl)
                .resolve(location.trim());
            currentHopUrl = resolvedUri.toString();
            activeUrl = currentHopUrl;
            continue;
          }

          response = hopResponse;
          break;
        }

        final status = response.statusCode;

        if (status == 404) {
          throw const ModuleDownloadException(
            'Gagal mengunduh modul dari server (HTTP 404).',
            kind: ModuleDownloadErrorKind.serverUnavailable,
            statusCode: 404,
          );
        }
        if (status >= 500 || status == 429) {
          throw ModuleDownloadException(
            'Server rilis modul sedang tidak tersedia (HTTP $status).',
            kind: ModuleDownloadErrorKind.serverUnavailable,
            statusCode: status,
          );
        }
        if (status != 200 && status != 206) {
          throw ModuleDownloadException(
            'Gagal mengunduh modul dari server (HTTP $status).',
            kind: ModuleDownloadErrorKind.serverUnavailable,
            statusCode: status,
          );
        }

        // Jika server tidak mendukung Range (mengembalikan 200 OK), ulangi buffer dari awal
        if (status == 200 && partialBytes.isNotEmpty) {
          partialBytes.clear();
        }

        final contentLength = response.contentLength;
        final expectedTotal = contentLength != null && contentLength > 0
            ? (status == 206 ? resumeOffset + contentLength : contentLength)
            : expectedSizeBytes;

        if (expectedTotal > maxDownloadBytes) {
          throw const ModuleDownloadException(
            'Keamanan: Ukuran unduhan modul melebihi batas 25 MB.',
            kind: ModuleDownloadErrorKind.securityRejected,
          );
        }

        await for (final chunk in response.stream.timeout(requestTimeout)) {
          if (partialBytes.length + chunk.length > maxDownloadBytes) {
            throw const ModuleDownloadException(
              'Keamanan: Aliran unduhan diputus karena melebihi batas 25 MB.',
              kind: ModuleDownloadErrorKind.securityRejected,
            );
          }
          partialBytes.addAll(chunk);
          if (expectedTotal > 0) {
            final ratio = (partialBytes.length / expectedTotal).clamp(0.0, 1.0);
            onProgress?.call(0.05 + (ratio * 0.55));
          }
        }

        if (expectedSizeBytes > 0 && partialBytes.length != expectedSizeBytes) {
          throw ModuleDownloadException(
            'Berkas unduhan modul tidak lengkap (diterima ${partialBytes.length} dari $expectedSizeBytes byte).',
            kind: ModuleDownloadErrorKind.incompleteFile,
          );
        }
        if (contentLength != null &&
            contentLength > 0 &&
            partialBytes.length != expectedTotal) {
          throw ModuleDownloadException(
            'Berkas unduhan modul tidak lengkap (diterima ${partialBytes.length} dari $expectedTotal byte).',
            kind: ModuleDownloadErrorKind.incompleteFile,
          );
        }

        return Uint8List.fromList(partialBytes);
      } on TimeoutException catch (e) {
        lastError = ModuleDownloadException(
          'Timeout saat mengunduh modul: $e',
          kind: ModuleDownloadErrorKind.timeout,
        );
      } on ModuleDownloadException catch (e) {
        lastError = e;
        // Jangan ulangi otomatis untuk 404 atau pelanggaran kebijakan keamanan
        if (e.statusCode == 404 ||
            e.kind == ModuleDownloadErrorKind.securityRejected ||
            e.kind == ModuleDownloadErrorKind.securityVerificationFailed) {
          rethrow;
        }
      } catch (e) {
        lastError = ModuleDownloadException(
          'Koneksi unduhan modul terputus: $e',
          kind: ModuleDownloadErrorKind.networkDisconnected,
        );
      }
    }

    throw lastError ??
        const ModuleDownloadException(
          'Koneksi unduhan modul terputus.',
          kind: ModuleDownloadErrorKind.networkDisconnected,
        );
  }
}
