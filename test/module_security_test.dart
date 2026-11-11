import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/services/catalog_signature_verifier.dart';
import 'package:katara/services/module_download_service.dart';

Uint8List _encodeZip(Map<String, String> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    final bytes = utf8.encode(entry.value);
    archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ContentSeeder seeder;
  late Directory tempInstallRoot;
  late ModuleDownloadService downloadService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    seeder = ContentSeeder(
      db: db,
      loadAsset: (assetPath) async => File(assetPath).readAsStringSync(),
    );
    await seeder.seedIfNeeded();
    tempInstallRoot = await Directory.systemTemp.createTemp('katara_mod_sec_');
    downloadService = ModuleDownloadService(
      db: db,
      seeder: seeder,
      installRootDirectoryProvider: () async => tempInstallRoot,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempInstallRoot.existsSync()) {
      await tempInstallRoot.delete(recursive: true);
    }
  });

  test('1. Ed25519 signature verification accepts official catalog and rejects tampered catalog', () async {
    final rawOfficial = File('assets/content/module_catalog.json')
        .readAsStringSync();
    expect(
      CatalogSignatureVerifier.verifyCatalog(
        jsonDecode(rawOfficial) as Map<String, dynamic>,
      ),
      isTrue,
    );
    final envelope = await downloadService.loadCatalogEnvelope(
      rawJsonOverride: rawOfficial,
      requireSignature: true,
    );
    expect(envelope.signatureVerified, isTrue);
    expect(envelope.modules.length, greaterThanOrEqualTo(2));

    // Tamper with download_url in catalog JSON while keeping old signature
    final tamperedMap = jsonDecode(rawOfficial) as Map<String, dynamic>;
    final modules = (tamperedMap['modules'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    modules.first['download_url'] =
        'https://github.com/evil/repo/releases/download/v1/evil.zip';

    await expectLater(
      () => downloadService.loadCatalogEnvelope(
        rawJsonOverride: jsonEncode(tamperedMap),
        requireSignature: true,
      ),
      throwsA(isA<ModuleDownloadException>()),
    );
  });

  test('2. HTTPS and GitHub host allowlist enforcement', () {
    expect(
      () => ModuleDownloadService.validateDownloadUrl(
        'http://github.com/rynnxz/KATARA/releases/download/v1.1.1/module_langkat.zip',
      ),
      throwsA(isA<ModuleDownloadException>()),
    );

    expect(
      () => ModuleDownloadService.validateDownloadUrl(
        'https://evil.example.com/module_langkat.zip',
      ),
      throwsA(isA<ModuleDownloadException>()),
    );

    expect(
      () => ModuleDownloadService.validateDownloadUrl(
        'https://github.com/rynnxz/KATARA/releases/download/v1.1.1/module_langkat.zip',
      ),
      returnsNormally,
    );
  });

  test(
    '3. SHA-256 mismatch, Zip-Slip, and non-allowlisted files are rejected',
    () async {
      final targetDir = Directory('${tempInstallRoot.path}/test_extract');

      // Valid zip bytes but wrong SHA-256
      final validZip = _encodeZip({
        'manifest.json': jsonEncode({
          'course_id': 'ms-langkat',
          'content_version': 1,
        }),
        'words.json': jsonEncode([]),
      });
      await expectLater(
        () => downloadService.verifyAndExtractArchive(
          zipBytes: validZip,
          expectedSha256: '0' * 64,
          targetDir: targetDir,
        ),
        throwsA(isA<ModuleDownloadException>()),
      );

      // Zip-Slip path traversal entry
      final zipSlipBytes = _encodeZip({'../evil.json': '{}'});
      final zipSlipSha = sha256.convert(zipSlipBytes).toString();
      await expectLater(
        () => downloadService.verifyAndExtractArchive(
          zipBytes: zipSlipBytes,
          expectedSha256: zipSlipSha,
          targetDir: targetDir,
        ),
        throwsA(isA<ModuleDownloadException>()),
      );

      // Unexpected executable/script file inside archive
      final evilScriptZip = _encodeZip({
        'manifest.json': '{}',
        'evil.sh': '#!/bin/sh\necho pwned',
      });
      final evilScriptSha = sha256.convert(evilScriptZip).toString();
      await expectLater(
        () => downloadService.verifyAndExtractArchive(
          zipBytes: evilScriptZip,
          expectedSha256: evilScriptSha,
          targetDir: targetDir,
        ),
        throwsA(isA<ModuleDownloadException>()),
      );
    },
  );

  test('4. Anti-Zip-Bomb compression ratio guard rejects highly compressed payload', () async {
    final targetDir = Directory('${tempInstallRoot.path}/bomb_test');
    // Create a repetitive payload > 512 bytes compressed that expands > 30:1
    final hugeRepeated = 'A' * 400000;
    final archive = Archive();
    final contentBytes = utf8.encode(hugeRepeated);
    archive.addFile(
      ArchiveFile('words.json', contentBytes.length, contentBytes),
    );
    // Pad with pseudo-random comment/file so compressed size >= 512 bytes while ratio > 30:1
    final noise = List<int>.generate(600, (i) => (i * 73 + 19) & 0xFF);
    archive.addFile(ArchiveFile('manifest.json', noise.length, noise));
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final zipSha = sha256.convert(zipBytes).toString();

    expect(zipBytes.length, greaterThanOrEqualTo(512));
    expect(
      (contentBytes.length + noise.length) / zipBytes.length,
      greaterThan(30.0),
    );

    await expectLater(
      () => downloadService.verifyAndExtractArchive(
        zipBytes: zipBytes,
        expectedSha256: zipSha,
        targetDir: targetDir,
      ),
      throwsA(isA<ModuleDownloadException>()),
    );
  });

  test('5. Blocks overwriting bundled ms-deli or injecting ms-deli IDs from another module', () async {
    // Attempt to install a module claiming to be ms-deli
    final deliItem = ModuleCatalogItemModel(
      id: 'ms-deli',
      courseId: 'ms-deli',
      name: 'Fake Deli',
      regionLabel: 'Medan',
      version: 99,
      isBundled: false,
      accentHex: '#F5B700',
      sha256: 'a' * 64,
    );
    await expectLater(
      () => downloadService.installModule(deliItem),
      throwsA(isA<ModuleDownloadException>()),
    );

    // Attempt to inject an ms-deli word ID inside ms-langkat package
    final crossCourseZip = _encodeZip({
      'manifest.json': jsonEncode({
        'course_id': 'ms-langkat',
        'content_version': 2,
      }),
      'words.json': jsonEncode([
        {
          'id': 'ms-deli:w:0001',
          'course_id': 'ms-langkat',
          'deli': 'bajakan',
          'indonesia': 'palsu',
        },
      ]),
    });
    final crossSha = sha256.convert(crossCourseZip).toString();
    final langkatEvilItem = ModuleCatalogItemModel(
      id: 'melayu_langkat',
      courseId: 'ms-langkat',
      name: 'Melayu Langkat',
      regionLabel: 'Langkat',
      version: 2,
      isBundled: false,
      accentHex: '#1E7F5C',
      sha256: crossSha,
      downloadUrl: 'https://github.com/rynnxz/KATARA/releases/download/v1.1.1/module_langkat.zip',
    );

    final customService = ModuleDownloadService(
      db: db,
      seeder: seeder,
      installRootDirectoryProvider: () async => tempInstallRoot,
      bytesFetcher: (_, _) async => crossCourseZip,
    );

    await expectLater(
      () => customService.installModule(langkatEvilItem),
      throwsA(isA<ModuleDownloadException>()),
    );

    // Ensure staging .tmp directory was cleaned up after failure
    expect(
      Directory('${tempInstallRoot.path}/ms-langkat.tmp').existsSync(),
      isFalse,
    );
  });

  test(
    '6. Anti-downgrade protection, kill-switch revocation, and .tmp cleanup',
    () async {
      // Cleanup stale staging directories on startup
      final staleTmp = Directory('${tempInstallRoot.path}/ms-langkat.tmp')
        ..createSync(recursive: true);
      final staleStage = Directory(
        '${tempInstallRoot.path}/.staging_ms-palembang',
      )..createSync(recursive: true);
      expect(staleTmp.existsSync(), isTrue);
      expect(staleStage.existsSync(), isTrue);

      final cleaned = await downloadService.cleanupStaleStagingDirectories();
      expect(cleaned, equals(2));
      expect(staleTmp.existsSync(), isFalse);
      expect(staleStage.existsSync(), isFalse);

      // Install v2 module, then verify v1 downgrade is blocked
      final v2Zip = _encodeZip({
        'manifest.json': jsonEncode({
          'course_id': 'ms-langkat',
          'content_version': 2,
        }),
        'words.json': jsonEncode([
          {
            'id': 'ms-langkat:w:0001',
            'course_id': 'ms-langkat',
            'deli': 'encik',
            'indonesia': 'tuan/puan',
          },
        ]),
      });
      final v2Sha = sha256.convert(v2Zip).toString();
      final serviceWithV2 = ModuleDownloadService(
        db: db,
        seeder: seeder,
        installRootDirectoryProvider: () async => tempInstallRoot,
        bytesFetcher: (_, _) async => v2Zip,
      );

      final installedV2 = await serviceWithV2.installModule(
        ModuleCatalogItemModel(
          id: 'melayu_langkat',
          courseId: 'ms-langkat',
          name: 'Melayu Langkat',
          regionLabel: 'Langkat',
          version: 2,
          isBundled: false,
          accentHex: '#1E7F5C',
          sha256: v2Sha,
          downloadUrl: 'https://github.com/rynnxz/KATARA/releases/download/v1.1.1/module_langkat.zip',
        ),
      );
      expect(installedV2.version, equals(2));

      // Attempt to downgrade to v1
      await expectLater(
        () => serviceWithV2.installModule(
          ModuleCatalogItemModel(
            id: 'melayu_langkat',
            courseId: 'ms-langkat',
            name: 'Melayu Langkat',
            regionLabel: 'Langkat',
            version: 1,
            isBundled: false,
            accentHex: '#1E7F5C',
            sha256: v2Sha,
            downloadUrl: 'https://github.com/rynnxz/KATARA/releases/download/v1.1.1/module_langkat.zip',
          ),
        ),
        throwsA(isA<ModuleDownloadException>()),
      );

      // Kill-switch revokes ms-langkat
      const revokedEnvelope = CatalogEnvelopeModel(
        catalogVersion: 3,
        minAppVersion: '1.2.0',
        revokedModules: ['ms-langkat', 'ms-deli'],
        modules: [],
        signatureVerified: true,
      );
      expect(
        ModuleDownloadService.isAppUpdateRequired(
          currentVersion: '1.1.1',
          minAppVersion: revokedEnvelope.minAppVersion,
        ),
        isTrue,
      );
      final removed = await serviceWithV2.enforceRevokedModules(
        revokedEnvelope,
      );
      expect(removed, equals(['ms-langkat']));
      expect(await serviceWithV2.getInstalledModule('ms-langkat'), isNull);
    },
  );
}
