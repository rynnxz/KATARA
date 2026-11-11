import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_theme.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/features/region_picker/region_picker_screen.dart';
import 'package:katara/services/catalog_signature_verifier.dart';
import 'package:katara/services/module_download_service.dart';

import '../tool/verify_release.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Module Download Error Classification, Mock HttpServer & Parity Tests', () {
    test('ModuleDownloadErrorMapper distinguishes network, timeout, 404/5xx, incomplete file, and SHA-256 security failure honestly', () {
      const err404 = ModuleDownloadException(
        'Gagal mengunduh modul Melayu Langkat (HTTP 404).',
        kind: ModuleDownloadErrorKind.serverUnavailable,
        statusCode: 404,
      );
      const errTimeout = ModuleDownloadException(
        'Timeout 25s saat mengunduh modul',
        kind: ModuleDownloadErrorKind.timeout,
      );
      const errNetwork = ModuleDownloadException(
        'SocketException: Failed host lookup',
        kind: ModuleDownloadErrorKind.networkDisconnected,
      );
      const errIncomplete = ModuleDownloadException(
        'Berkas unduhan modul tidak lengkap (diterima 4000 dari 71391 byte).',
        kind: ModuleDownloadErrorKind.incompleteFile,
      );
      const errHash = ModuleDownloadException(
        'Checksum SHA-256 modul tidak cocok',
        kind: ModuleDownloadErrorKind.securityVerificationFailed,
      );

      for (final err in [
        err404,
        errTimeout,
        errNetwork,
        errIncomplete,
        errHash,
      ]) {
        final msg = ModuleDownloadErrorMapper.toUserMessage(
          err,
          courseName: 'Melayu Palembang',
        );
        expect(msg, isNot(contains('ModuleDownloadException')));
        expect(msg, isNot(contains('HTTP 404')));
        expect(msg, isNot(contains('SocketException')));
        expect(msg.length, greaterThan(20));
      }

      // SHA-256 mismatch must NEVER blame the user's network
      final hashMsg1 = ModuleDownloadErrorMapper.toUserMessage(
        errHash,
        courseName: 'Melayu Palembang',
        attemptCount: 1,
      );
      expect(hashMsg1, contains('verifikasi keamanan'));
      expect(hashMsg1, isNot(contains('gangguan jaringan')));
      expect(
        ModuleDownloadErrorMapper.canRetry(errHash, attemptCount: 1),
        isTrue,
      );

      // On 2nd SHA-256 failure, retry is capped and user is advised to update the app
      final hashMsg2 = ModuleDownloadErrorMapper.toUserMessage(
        errHash,
        courseName: 'Melayu Palembang',
        attemptCount: 2,
      );
      expect(hashMsg2, contains('perbarui aplikasi KATARA'));
      expect(
        ModuleDownloadErrorMapper.canRetry(errHash, attemptCount: 2),
        isFalse,
      );

      // Incomplete file message specifically mentions incomplete/terpotong and allows retry
      final incMsg = ModuleDownloadErrorMapper.toUserMessage(
        errIncomplete,
        courseName: 'Melayu Palembang',
      );
      expect(incMsg, contains('tidak lengkap'));
      expect(
        ModuleDownloadErrorMapper.canRetry(errIncomplete, attemptCount: 3),
        isTrue,
      );
    });

    test('Release artifact & catalog parity verifier confirms 100% match across bundled catalog, release catalogs, courses.json, and ZIP files', () {
      final result = verifyReleaseParity();
      expect(
        result.errors,
        isEmpty,
        reason: 'Parity errors: ${result.errors.join("; ")}',
      );
      expect(result.isValid, isTrue);
      expect(result.verifiedModules.containsKey('ms-langkat'), isTrue);
      expect(result.verifiedModules.containsKey('ms-palembang'), isTrue);
    });

    test('Local HttpServer: 200 OK with remote signed module_catalog.json sync, 302 redirect + 206 Range resume, 404, truncated body, wrong SHA-256, timeout, and anti-downgrade', () async {
      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousOverrides);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.ensureInitialized();

      final seeder = ContentSeeder(
        db: db,
        loadAsset: (assetPath) async => File(assetPath).readAsStringSync(),
      );
      await seeder.seedIfNeeded(force: true);

      final tempRoot = await Directory.systemTemp.createTemp(
        'katara_http_srv_test_',
      );
      addTearDown(() async {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      });

      final langkatZipBytes = await File(
        'dist/releases/v1.1.0/module_langkat.zip',
      ).readAsBytes();
      final langkatSha = sha256.convert(langkatZipBytes).toString();
      final palembangZipBytes = await File(
        'dist/releases/v1.1.0/module_palembang.zip',
      ).readAsBytes();
      final palembangSha = sha256.convert(palembangZipBytes).toString();

      final seedHex = File('.keys/catalog_ed25519.seed')
          .readAsStringSync()
          .trim();
      final seed = Ed25519Crypto.hexToBytes(seedHex);
      final pubKeyHex = Ed25519Crypto.bytesToHex(
        Ed25519Crypto.publicKeyFromSeed(seed),
      );

      var rangeResumeAttempts = 0;

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final baseUrl = 'http://127.0.0.1:${server.port}';

      Map<String, dynamic> buildSignedCatalog({required int catalogVersion}) {
        final map = <String, dynamic>{
          'catalog_version': catalogVersion,
          'min_app_version': '1.1.0',
          'revoked_modules': <String>[],
          'generated_at': '2026-11-11T00:00:00Z',
          'github_release_tag': 'v1.1.1',
          'repository_url': 'https://github.com/rynnxz/KATARA',
          'modules': [
            {
              'course_id': 'ms-langkat',
              'dialect_id': 'melayu_langkat',
              'name': 'Melayu Langkat',
              'region_label': 'Langkat',
              'version': 3,
              'content_version': 1,
              'archive_filename': 'module_langkat.zip',
              'download_url': '$baseUrl/ok/module_langkat.zip',
              'size_bytes': langkatZipBytes.length,
              'sha256': langkatSha,
              'word_count': 308,
              'lesson_count': 64,
              'quiz_count': 110,
              'is_bundled': false,
              'accent_hex': '#1E7F5C',
            },
            {
              'course_id': 'ms-palembang',
              'dialect_id': 'melayu_palembang',
              'name': 'Melayu Palembang',
              'region_label': 'Palembang',
              'version': 3,
              'content_version': 1,
              'archive_filename': 'module_palembang.zip',
              'download_url': '$baseUrl/redirect/module_palembang.zip',
              'size_bytes': palembangZipBytes.length,
              'sha256': palembangSha,
              'word_count': 308,
              'lesson_count': 64,
              'quiz_count': 110,
              'is_bundled': false,
              'accent_hex': '#8B1E24',
            },
          ],
        };
        final payload = CatalogSignatureVerifier.canonicalCatalogPayload(map);
        final sig = Ed25519Crypto.sign(payload, seed);
        map['signature_ed25519'] = Ed25519Crypto.bytesToHex(sig);
        map['public_key_ed25519'] = pubKeyHex;
        return map;
      }

      server.listen((HttpRequest req) async {
        req.response.persistentConnection = false;
        final path = req.uri.path;
        if (path == '/catalog/valid.json') {
          final body = jsonEncode(buildSignedCatalog(catalogVersion: 3));
          req.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(body);
          await req.response.close();
        } else if (path == '/catalog/downgraded.json') {
          final body = jsonEncode(buildSignedCatalog(catalogVersion: 1));
          req.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(body);
          await req.response.close();
        } else if (path == '/ok/module_langkat.zip') {
          req.response
            ..statusCode = HttpStatus.ok
            ..contentLength = langkatZipBytes.length
            ..add(langkatZipBytes);
          await req.response.close();
        } else if (path == '/redirect/module_palembang.zip') {
          req.response
            ..statusCode = HttpStatus.found
            ..contentLength = 0
            ..headers.set(
              HttpHeaders.locationHeader,
              '$baseUrl/resume/module_palembang.zip',
            );
          await req.response.close();
        } else if (path == '/resume/module_palembang.zip') {
          rangeResumeAttempts++;
          final rangeHeader = req.headers.value('range');
          final splitOffset = palembangZipBytes.length ~/ 2;
          if (rangeResumeAttempts == 1) {
            // Simulate premature stream completion halfway through file
            final firstHalf = palembangZipBytes.sublist(0, splitOffset);
            req.response
              ..statusCode = HttpStatus.ok
              ..contentLength = firstHalf.length
              ..add(firstHalf);
            await req.response.close();
          } else if (rangeHeader != null &&
              rangeHeader.startsWith('bytes=$splitOffset-')) {
            final remaining = palembangZipBytes.sublist(splitOffset);
            req.response
              ..statusCode = HttpStatus.partialContent
              ..contentLength = remaining.length
              ..add(remaining);
            await req.response.close();
          } else {
            req.response
              ..statusCode = HttpStatus.ok
              ..contentLength = palembangZipBytes.length
              ..add(palembangZipBytes);
            await req.response.close();
          }
        } else if (path == '/truncated/module_langkat.zip') {
          final half = langkatZipBytes.sublist(0, 1024);
          req.response
            ..statusCode = HttpStatus.ok
            ..contentLength = half.length
            ..add(half);
          await req.response.close();
        } else if (path == '/bad_hash/module_langkat.zip') {
          final mutated = Uint8List.fromList(langkatZipBytes);
          mutated[mutated.length - 10] ^= 0xFF;
          req.response
            ..statusCode = HttpStatus.ok
            ..contentLength = mutated.length
            ..add(mutated);
          await req.response.close();
        } else if (path == '/slow/module_langkat.zip') {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          req.response
            ..statusCode = HttpStatus.ok
            ..add(langkatZipBytes);
          await req.response.close();
        } else {
          req.response.statusCode = HttpStatus.notFound;
          await req.response.close();
        }
      });

      final service = ModuleDownloadService(
        db: db,
        seeder: seeder,
        installRootDirectoryProvider: () async => tempRoot,
        remoteCatalogUrls: ['$baseUrl/catalog/valid.json'],
        allowLoopbackHttpForTest: true,
        enableLocalDistFallback: false,
        requestTimeout: const Duration(seconds: 3),
        maxNetworkRetries: 1,
        initialRetryDelay: const Duration(milliseconds: 20),
      );

      // 1. Anti-downgrade check on remote catalog (version 1 < minCatalogVersion 2)
      await expectLater(
        () => service.fetchVerifiedRemoteCatalog(
          '$baseUrl/catalog/downgraded.json',
          minCatalogVersion: 2,
        ),
        throwsA(
          isA<ModuleDownloadException>().having(
            (e) => e.kind,
            'kind',
            ModuleDownloadErrorKind.securityRejected,
          ),
        ),
      );

      // 2. Remote signed catalog sync overrides stale APK hash & URL and installs 200 OK
      const staleLangkatItem = ModuleCatalogItemModel(
        id: 'melayu_langkat',
        courseId: 'ms-langkat',
        name: 'Melayu Langkat',
        regionLabel: 'Langkat',
        version: 2,
        isBundled: false,
        accentHex: '#1E7F5C',
        archiveFilename: 'module_langkat.zip',
        downloadUrl: 'http://127.0.0.1:1/stale_url.zip',
        sha256:
            '0000000000000000000000000000000000000000000000000000000000000000',
        sizeBytes: 99999,
      );
      final installedLangkat = await service.installModule(staleLangkatItem);
      expect(installedLangkat.courseId, equals('ms-langkat'));
      expect(installedLangkat.wordCount, greaterThanOrEqualTo(300));

      // 3. 302 Redirect + 206 Partial Content Range Resume installs Palembang cleanly
      const palembangItem = ModuleCatalogItemModel(
        id: 'melayu_palembang',
        courseId: 'ms-palembang',
        name: 'Melayu Palembang',
        regionLabel: 'Palembang',
        version: 2,
        isBundled: false,
        accentHex: '#8B1E24',
        archiveFilename: 'module_palembang.zip',
        downloadUrl: 'http://127.0.0.1:1/stale_palembang.zip',
        sha256:
            '0000000000000000000000000000000000000000000000000000000000000000',
        sizeBytes: 99999,
      );
      final installedPalembang = await service.installModule(palembangItem);
      expect(installedPalembang.courseId, equals('ms-palembang'));
      expect(rangeResumeAttempts, equals(2));

      // Service without remoteCatalogUrls to test direct HTTP error scenarios
      final directService = ModuleDownloadService(
        db: db,
        seeder: seeder,
        installRootDirectoryProvider: () async => tempRoot,
        remoteCatalogUrls: const [],
        allowLoopbackHttpForTest: true,
        enableLocalDistFallback: false,
        requestTimeout: const Duration(milliseconds: 120),
        maxNetworkRetries: 1,
        initialRetryDelay: const Duration(milliseconds: 10),
      );

      // 4. 404 Not Found -> serverUnavailable
      final item404 = ModuleCatalogItemModel(
        id: 'melayu_langkat',
        courseId: 'ms-langkat-404',
        name: 'Melayu Langkat',
        regionLabel: 'Langkat',
        version: 3,
        isBundled: false,
        accentHex: '#1E7F5C',
        downloadUrl: '$baseUrl/missing/module_langkat.zip',
        sha256: langkatSha,
        sizeBytes: langkatZipBytes.length,
      );
      await expectLater(
        () => directService.installModule(item404),
        throwsA(
          isA<ModuleDownloadException>().having(
            (e) => e.kind,
            'kind',
            ModuleDownloadErrorKind.serverUnavailable,
          ),
        ),
      );

      // 5. Truncated body (size_bytes mismatch) -> incompleteFile
      final itemTruncated = ModuleCatalogItemModel(
        id: 'melayu_langkat',
        courseId: 'ms-langkat-trunc',
        name: 'Melayu Langkat',
        regionLabel: 'Langkat',
        version: 3,
        isBundled: false,
        accentHex: '#1E7F5C',
        downloadUrl: '$baseUrl/truncated/module_langkat.zip',
        sha256: langkatSha,
        sizeBytes: langkatZipBytes.length,
      );
      await expectLater(
        () => directService.installModule(itemTruncated),
        throwsA(
          isA<ModuleDownloadException>().having(
            (e) => e.kind,
            'kind',
            ModuleDownloadErrorKind.incompleteFile,
          ),
        ),
      );

      // 6. Wrong SHA-256 (exact size_bytes, mutated byte) -> securityVerificationFailed
      final itemBadHash = ModuleCatalogItemModel(
        id: 'melayu_langkat',
        courseId: 'ms-langkat-badhash',
        name: 'Melayu Langkat',
        regionLabel: 'Langkat',
        version: 3,
        isBundled: false,
        accentHex: '#1E7F5C',
        downloadUrl: '$baseUrl/bad_hash/module_langkat.zip',
        sha256: langkatSha,
        sizeBytes: langkatZipBytes.length,
      );
      await expectLater(
        () => directService.installModule(itemBadHash),
        throwsA(
          isA<ModuleDownloadException>().having(
            (e) => e.kind,
            'kind',
            ModuleDownloadErrorKind.securityVerificationFailed,
          ),
        ),
      );

      // 7. Slow server -> timeout
      final itemSlow = ModuleCatalogItemModel(
        id: 'melayu_langkat',
        courseId: 'ms-langkat-slow',
        name: 'Melayu Langkat',
        regionLabel: 'Langkat',
        version: 3,
        isBundled: false,
        accentHex: '#1E7F5C',
        downloadUrl: '$baseUrl/slow/module_langkat.zip',
        sha256: langkatSha,
        sizeBytes: langkatZipBytes.length,
      );
      await expectLater(
        () => directService.installModule(itemSlow),
        throwsA(
          isA<ModuleDownloadException>().having(
            (e) => e.kind,
            'kind',
            ModuleDownloadErrorKind.timeout,
          ),
        ),
      );
    });

    testWidgets(
      'RegionPickerScreen caps retry after 2 consecutive SHA-256 security verification failures and advises app update',
      (tester) async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        late ContentSeeder seeder;
        late Directory tempRoot;
        await tester.runAsync(() async {
          await db.ensureInitialized();
          seeder = ContentSeeder(db: db);
          await seeder.seedIfNeeded(force: true);
          tempRoot = await Directory.systemTemp.createTemp('katara_region_ux_');
        });
        addTearDown(() async {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        });

        final hashFailingService = ModuleDownloadService(
          db: db,
          seeder: seeder,
          installRootDirectoryProvider: () async => tempRoot,
          bytesFetcher: (item, onProgress) async {
            throw const ModuleDownloadException(
              'Checksum SHA-256 modul tidak cocok.',
              kind: ModuleDownloadErrorKind.securityVerificationFailed,
            );
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              moduleDownloadServiceProvider.overrideWithValue(
                hashFailingService,
              ),
            ],
            child: MaterialApp(
              theme: KataraTheme.light(),
              home: const RegionPickerScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Melayu lainnya'), findsNothing);
        expect(find.text('Cek SHA-256 saat pasang'), findsWidgets);

        // 1st attempt -> fails SHA-256 -> shows security message + Coba Lagi
        final downloadBtn = find.textContaining('Unduh Modul').first;
        await tester.ensureVisible(downloadBtn);
        await tester.pump();
        await tester.tap(downloadBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          find.textContaining('tidak lolos verifikasi keamanan (SHA-256)'),
          findsOneWidget,
        );
        expect(find.text('Coba Lagi'), findsOneWidget);

        // 2nd attempt via Coba Lagi -> fails SHA-256 again -> Coba Lagi hidden, advises app update
        await tester.tap(find.text('Coba Lagi'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          find.textContaining('Silakan perbarui aplikasi KATARA'),
          findsOneWidget,
        );
        expect(find.text('Coba Lagi'), findsNothing);
      },
    );

    test('Branding assets and Android launcher/notification/splash resources exist and have valid PNG dimensions', () {
      final icon1024 = File('assets/branding/app_icon_1024.png');
      final fg1024 = File('assets/branding/app_icon_foreground.png');
      final mono1024 = File('assets/branding/app_icon_monochrome.png');
      final splash512 = File('assets/branding/splash_mascot.png');
      final notifIcon = File(
        'android/app/src/main/res/drawable/ic_stat_katara.png',
      );
      final adaptiveXml = File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      );
      final splashV31Xml = File(
        'android/app/src/main/res/values-v31/styles.xml',
      );

      for (final f in [
        icon1024,
        fg1024,
        mono1024,
        splash512,
        notifIcon,
        adaptiveXml,
        splashV31Xml,
      ]) {
        expect(f.existsSync(), isTrue, reason: 'Missing ${f.path}');
        expect(f.lengthSync(), greaterThan(100));
      }

      final bytes = icon1024.readAsBytesSync();
      final bd = ByteData.sublistView(Uint8List.fromList(bytes));
      expect(bd.getUint32(16), equals(1024));
      expect(bd.getUint32(20), equals(1024));
    });
  });
}
