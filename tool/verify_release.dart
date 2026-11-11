import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:katara/services/catalog_signature_verifier.dart';

class ReleaseVerificationResult {
  const ReleaseVerificationResult({
    required this.errors,
    required this.verifiedModules,
  });

  final List<String> errors;
  final Map<String, ({int sizeBytes, String sha256, String downloadUrl})>
  verifiedModules;

  bool get isValid => errors.isEmpty;
}

ReleaseVerificationResult verifyReleaseParity({String rootPath = '.'}) {
  final errors = <String>[];
  final verifiedModules =
      <String, ({int sizeBytes, String sha256, String downloadUrl})>{};

  final catalogPaths = <String>[
    '$rootPath/assets/content/module_catalog.json',
    '$rootPath/dist/releases/v1.1.0/module_catalog.json',
    '$rootPath/dist/releases/v1.1.1/module_catalog.json',
  ];

  String? referenceCatalogRaw;
  Map<String, dynamic>? primaryCatalog;

  for (final path in catalogPaths) {
    final file = File(path);
    if (!file.existsSync()) {
      errors.add('Berkas katalog tidak ditemukan: $path');
      continue;
    }
    final raw = file.readAsStringSync().replaceAll('\r\n', '\n');
    if (referenceCatalogRaw == null) {
      referenceCatalogRaw = raw;
    } else if (raw != referenceCatalogRaw) {
      errors.add(
        'Isi katalog $path berbeda dari assets/content/module_catalog.json.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      errors.add('Format JSON tidak valid pada $path: $e');
      continue;
    }
    if (decoded is! Map<String, dynamic>) {
      errors.add('Root JSON pada $path bukan Map.');
      continue;
    }

    final sigValid = CatalogSignatureVerifier.verifyCatalog(decoded);
    if (!sigValid) {
      errors.add(
        'Tanda tangan digital Ed25519 tidak valid pada katalog: $path',
      );
    }

    primaryCatalog ??= decoded;
  }

  if (primaryCatalog == null) {
    return ReleaseVerificationResult(
      errors: errors,
      verifiedModules: verifiedModules,
    );
  }

  final coursesFile = File('$rootPath/assets/content/courses.json');
  Map<String, Map<String, dynamic>> coursesById = {};
  if (!coursesFile.existsSync()) {
    errors.add('Berkas assets/content/courses.json tidak ditemukan.');
  } else {
    final coursesRoot =
        jsonDecode(coursesFile.readAsStringSync()) as Map<String, dynamic>;
    final coursesList = (coursesRoot['courses'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    coursesById = {for (final c in coursesList) (c['id'] as String): c};
  }

  final modules = (primaryCatalog['modules'] as List<dynamic>? ?? const [])
      .cast<Map<String, dynamic>>();
  if (modules.isEmpty) {
    errors.add('Daftar modules di dalam module_catalog.json kosong.');
  }

  final releaseDirs = <String>[
    '$rootPath/dist/releases/v1.1.0',
    '$rootPath/dist/releases/v1.1.1',
  ];

  for (final mod in modules) {
    final courseId = mod['course_id']?.toString() ?? '';
    final archiveFileName = mod['archive_filename']?.toString() ?? '';
    final catalogSize = (mod['size_bytes'] as num?)?.toInt() ?? -1;
    final catalogSha256 = mod['sha256']?.toString().trim().toLowerCase() ?? '';
    final catalogUrl = mod['download_url']?.toString().trim() ?? '';

    if (courseId.isEmpty || archiveFileName.isEmpty) {
      errors.add('Entri modul tidak memiliki course_id atau archive_filename.');
      continue;
    }

    for (final dir in releaseDirs) {
      final zipFile = File('$dir/$archiveFileName');
      if (!zipFile.existsSync()) {
        errors.add('Berkas ZIP modul tidak ditemukan: ${zipFile.path}');
        continue;
      }
      final bytes = zipFile.readAsBytesSync();
      final actualSize = bytes.length;
      final actualSha256 = sha256.convert(bytes).toString().toLowerCase();

      if (actualSize != catalogSize) {
        errors.add(
          'Ukuran byte ${zipFile.path} ($actualSize) tidak cocok dengan module_catalog.json ($catalogSize).',
        );
      }
      if (actualSha256 != catalogSha256) {
        errors.add(
          'SHA-256 ${zipFile.path} ($actualSha256) tidak cocok dengan module_catalog.json ($catalogSha256).',
        );
      }
    }

    final courseEntry = coursesById[courseId];
    if (courseEntry == null) {
      errors.add(
        'Kursus $courseId tidak ditemukan di assets/content/courses.json.',
      );
    } else {
      final courseSize = (courseEntry['size_bytes'] as num?)?.toInt() ?? -1;
      final courseSha256 =
          courseEntry['sha256']?.toString().trim().toLowerCase() ?? '';
      final courseUrl = courseEntry['download_url']?.toString().trim() ?? '';

      if (courseSize != catalogSize) {
        errors.add(
          'size_bytes untuk $courseId di courses.json ($courseSize) != module_catalog.json ($catalogSize).',
        );
      }
      if (courseSha256 != catalogSha256) {
        errors.add(
          'sha256 untuk $courseId di courses.json ($courseSha256) != module_catalog.json ($catalogSha256).',
        );
      }
      if (courseUrl != catalogUrl) {
        errors.add(
          'download_url untuk $courseId di courses.json ($courseUrl) != module_catalog.json ($catalogUrl).',
        );
      }
    }

    verifiedModules[courseId] = (
      sizeBytes: catalogSize,
      sha256: catalogSha256,
      downloadUrl: catalogUrl,
    );
  }

  return ReleaseVerificationResult(
    errors: errors,
    verifiedModules: verifiedModules,
  );
}

void main() {
  stdout.writeln('=== KATARA Release Artifact & Catalog Parity Verifier ===');
  final result = verifyReleaseParity();
  for (final entry in result.verifiedModules.entries) {
    stdout.writeln(
      '  [MODULE] ${entry.key}: ${entry.value.sizeBytes} bytes | SHA-256: ${entry.value.sha256} | URL: ${entry.value.downloadUrl}',
    );
  }
  if (!result.isValid) {
    stderr.writeln('VERIFIKASI RILIS GAGAL (${result.errors.length} masalah):');
    for (final err in result.errors) {
      stderr.writeln('  - $err');
    }
    exit(1);
  }
  stdout.writeln(
    '=== VERIFIKASI BERHASIL: Katalog APK, Katalog Rilis, dan ZIP Modul 100% Sinkron ===',
  );
}
