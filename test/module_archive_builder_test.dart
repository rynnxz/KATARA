import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bundled Content & Standalone ZIP Module Archive Builder Tests', () {
    test('assets/content/courses.json defines ms-deli (bundled), ms-langkat, and ms-palembang (downloadable)', () {
      final coursesFile = File('assets/content/courses.json');
      expect(coursesFile.existsSync(), isTrue);

      final decoded =
          jsonDecode(coursesFile.readAsStringSync()) as Map<String, dynamic>;
      final courses = (decoded['courses'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final ids = courses.map((c) => c['id']).toSet();
      expect(ids, containsAll(['ms-deli', 'ms-langkat', 'ms-palembang']));

      final deli = courses.firstWhere((c) => c['id'] == 'ms-deli');
      final langkat = courses.firstWhere((c) => c['id'] == 'ms-langkat');
      final palembang = courses.firstWhere((c) => c['id'] == 'ms-palembang');

      expect(deli['is_bundled'], isTrue);
      expect(langkat['is_bundled'], isFalse);
      expect(palembang['is_bundled'], isFalse);
    });

    test('Bundled ms-deli assets contain >= 300 words, >= 15 lessons, >= 10 conversations, and references.json', () {
      final wordsFile = File('assets/content/ms-deli/words.json');
      final lessonsFile = File('assets/content/ms-deli/lessons.json');
      final convFile = File('assets/content/ms-deli/conversations.json');
      final refsFile = File('assets/content/ms-deli/references.json');

      expect(wordsFile.existsSync(), isTrue);
      expect(lessonsFile.existsSync(), isTrue);
      expect(convFile.existsSync(), isTrue);
      expect(refsFile.existsSync(), isTrue);

      final words = (jsonDecode(wordsFile.readAsStringSync()) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final lessons = (jsonDecode(
        lessonsFile.readAsStringSync(),
      ) as List<dynamic>).cast<Map<String, dynamic>>();
      final convs = (jsonDecode(convFile.readAsStringSync()) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final refs = (jsonDecode(refsFile.readAsStringSync()) as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(words.length, greaterThanOrEqualTo(300));
      expect(lessons.length, greaterThanOrEqualTo(15));
      expect(convs.length, greaterThanOrEqualTo(10));
      expect(refs.length, greaterThanOrEqualTo(5));

      // Check v2 provenance fields on words
      final sample = words.first;
      expect(sample['pronunciation'], isNotNull);
      expect(sample['example_sentence'], isNotNull);
      expect(sample['sources'], isNotNull);
    });

    test('Standalone module_langkat.zip and module_palembang.zip match module_catalog.json SHA-256 and structure', () {
      final catalogFile = File('dist/releases/v1.1.0/module_catalog.json');
      expect(
        catalogFile.existsSync(),
        isTrue,
        reason: 'Missing dist/releases/v1.1.0/module_catalog.json',
      );

      final catalog =
          jsonDecode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
      final modules = (catalog['modules'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(modules.length, greaterThanOrEqualTo(2));

      for (final courseId in ['ms-langkat', 'ms-palembang']) {
        final item = modules.firstWhere((m) => m['course_id'] == courseId);
        final archiveName = item['archive_filename'] as String;
        final zipFile = File('dist/releases/v1.1.0/$archiveName');
        expect(zipFile.existsSync(), isTrue, reason: 'Missing $archiveName');

        final bytes = zipFile.readAsBytesSync();
        final actualSha256 = sha256.convert(bytes).toString();
        expect(
          item['sha256'],
          equals(actualSha256),
          reason: 'SHA-256 mismatch for $archiveName',
        );
        expect(
          item['size_bytes'],
          equals(bytes.length),
          reason: 'Size mismatch for $archiveName',
        );
        expect(
          (item['download_url'] as String).startsWith(
            'https://github.com/rynnxz/KATARA/releases/download/',
          ),
          isTrue,
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        final fileNames = archive.files.map((f) => f.name).toSet();

        for (final name in fileNames) {
          expect(
            name.contains('..'),
            isFalse,
            reason: 'Path traversal in archive entry $name',
          );
          expect(
            name.startsWith('/'),
            isFalse,
            reason: 'Leading slash in archive entry $name',
          );
        }

        expect(
          fileNames,
          containsAll([
            'manifest.json',
            'words.json',
            'phrases.json',
            'sentences.json',
            'units.json',
            'lessons.json',
            'conversations.json',
            'cultural_cards.json',
            'articles.json',
            'references.json',
          ]),
        );

        final wordsEntry = archive.files.firstWhere(
          (f) => f.name == 'words.json',
        );
        final wordsJson = utf8.decode(wordsEntry.content as List<int>);
        final wordsList = jsonDecode(wordsJson) as List<dynamic>;
        expect(wordsList.length, greaterThanOrEqualTo(300));

        final lessonsEntry = archive.files.firstWhere(
          (f) => f.name == 'lessons.json',
        );
        final lessonsJson = utf8.decode(lessonsEntry.content as List<int>);
        final lessonsList = jsonDecode(lessonsJson) as List<dynamic>;
        expect(lessonsList.length, greaterThanOrEqualTo(15));
      }
    });
  });
}
