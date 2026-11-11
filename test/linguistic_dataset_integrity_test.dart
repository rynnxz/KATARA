import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-Dialect Linguistic Dataset Integrity & Provenance Tests', () {
    final dialectConfigs = [
      {
        'dialect_id': 'melayu_deli',
        'master_path': 'melayu-deli-dataset/curated/melayu_deli_master.json',
        'raw_path': 'melayu-deli-dataset/raw/vocabulary.json',
        'sources_path': 'melayu-deli-dataset/references/sources.json',
        'report_path': 'docs/reports/research_report_deli.md',
      },
      {
        'dialect_id': 'melayu_langkat',
        'master_path':
            'melayu-langkat-dataset/curated/melayu_langkat_master.json',
        'raw_path': 'melayu-langkat-dataset/raw/langkat_research_corpus.json',
        'sources_path': 'melayu-langkat-dataset/references/sources.json',
        'report_path': 'docs/reports/research_report_langkat.md',
      },
      {
        'dialect_id': 'melayu_palembang',
        'master_path':
            'melayu-palembang-dataset/curated/melayu_palembang_master.json',
        'raw_path':
            'melayu-palembang-dataset/raw/palembang_research_corpus.json',
        'sources_path': 'melayu-palembang-dataset/references/sources.json',
        'report_path': 'docs/reports/research_report_palembang.md',
      },
    ];

    for (final cfg in dialectConfigs) {
      final dialectId = cfg['dialect_id']!;

      test(
        '$dialectId curated dataset meets target counts, provenance, and validation rules',
        () {
          final masterFile = File(cfg['master_path']!);
          expect(
            masterFile.existsSync(),
            isTrue,
            reason: 'Missing ${cfg['master_path']}',
          );

          final sourcesFile = File(cfg['sources_path']!);
          expect(
            sourcesFile.existsSync(),
            isTrue,
            reason: 'Missing ${cfg['sources_path']}',
          );

          final reportFile = File(cfg['report_path']!);
          expect(
            reportFile.existsSync(),
            isTrue,
            reason: 'Missing ${cfg['report_path']}',
          );
          expect(reportFile.readAsStringSync().length, greaterThan(500));

          final sources = (jsonDecode(
            sourcesFile.readAsStringSync(),
          ) as List<dynamic>).cast<Map<String, dynamic>>();
          expect(
            sources.length,
            greaterThanOrEqualTo(5),
            reason: '$dialectId must have at least 5 documented references',
          );

          final sourceIds = <String>{};
          for (final src in sources) {
            final id = src['id'] as String?;
            final url = src['url'] as String?;
            expect(id, isNotNull);
            expect(
              sourceIds.add(id!),
              isTrue,
              reason: 'Duplicate source ID $id',
            );
            expect(url, isNotNull);
            expect(
              url!.startsWith('https://'),
              isTrue,
              reason: 'Source $id must have a valid https URL',
            );
            expect(
              url.contains('example.com'),
              isFalse,
              reason: 'Source $id must not use fake example.com URL',
            );
          }

          final master =
              jsonDecode(masterFile.readAsStringSync()) as Map<String, dynamic>;
          final vocab = (master['vocabulary'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
          final expressions =
              (master['expressions'] as List<dynamic>? ?? const [])
                  .cast<Map<String, dynamic>>();
          final sentences = (master['sentences'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
          final conversations =
              (master['conversations'] as List<dynamic>? ?? const [])
                  .cast<Map<String, dynamic>>();
          final quizzes = (master['quizzes'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();

          // Measurable dataset targets (Section 4)
          expect(
            vocab.length,
            greaterThanOrEqualTo(300),
            reason: '$dialectId must have >= 300 curated vocabulary entries',
          );

          final categories = vocab
              .map((w) => (w['category'] ?? '').toString())
              .where((c) => c.isNotEmpty)
              .toSet();
          expect(
            categories.length,
            greaterThanOrEqualTo(10),
            reason: '$dialectId must have >= 10 vocabulary categories',
          );

          final lexicalExamplesCount = vocab
              .where(
                (w) =>
                    (w['example_sentence']?.toString().trim().isNotEmpty ??
                    false),
              )
              .length;
          expect(
            sentences.length + lexicalExamplesCount,
            greaterThanOrEqualTo(100),
            reason: '$dialectId must have >= 100 example sentences',
          );

          expect(
            conversations.length,
            greaterThanOrEqualTo(10),
            reason: '$dialectId must have >= 10 conversations',
          );

          expect(
            quizzes.length,
            greaterThanOrEqualTo(100),
            reason: '$dialectId must have >= 100 quiz questions',
          );

          // Provenance & validation checks
          final seenIds = <String>{};
          var verifiedCount = 0;

          for (final entry in vocab) {
            final id = entry['id'] as String?;
            expect(id, isNotNull);
            expect(
              seenIds.add(id!),
              isTrue,
              reason: 'Duplicate vocab ID $id in $dialectId',
            );

            final entryDialect = (entry['dialect_id'] ?? entry['dialect'] ?? '')
                .toString();
            expect(
              entryDialect,
              isNotEmpty,
              reason: 'Missing dialect_id on $id',
            );

            final status = (entry['verification_status'] ?? '').toString();
            expect(
              ['verified', 'needs_review'].contains(status),
              isTrue,
              reason:
                  'Curated vocab $id must not contain rejected/disputed status ($status)',
            );
            if (status == 'verified') verifiedCount++;

            final confidence = (entry['confidence'] ?? '').toString();
            expect(['high', 'medium', 'low'].contains(confidence), isTrue);

            final entrySources = entry['sources'] as List<dynamic>? ?? const [];
            expect(
              entrySources,
              isNotEmpty,
              reason: 'Entry $id must reference at least one documented source',
            );
          }

          final verifiedRatio = verifiedCount / vocab.length;
          expect(
            verifiedRatio,
            greaterThanOrEqualTo(0.70),
            reason:
                '$dialectId must have >= 70% verified entries (got $verifiedRatio)',
          );
          expect(expressions, isNotEmpty);
        },
      );
    }

    test('Langkat dataset records distinct sub-regional variation (Stabat, Tanjung Pura, Secanggang)', () {
      final master = jsonDecode(
        File('melayu-langkat-dataset/curated/melayu_langkat_master.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final vocab = (master['vocabulary'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final regions = vocab
          .map((e) => (e['region'] ?? '').toString())
          .toSet()
          .join(' | ');
      expect(regions.contains('Stabat'), isTrue);
      expect(regions.contains('Tanjung Pura'), isTrue);
      expect(regions.contains('Secanggang'), isTrue);
    });

    test('Palembang dataset records Sari-sari and Bebaso registers and urban/surrounding variation', () {
      final master = jsonDecode(
        File('melayu-palembang-dataset/curated/melayu_palembang_master.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final vocab = (master['vocabulary'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final contexts = vocab
          .map(
            (e) =>
                '${e['usage_context'] ?? ''} ${e['notes'] ?? ''} ${e['region'] ?? ''}',
          )
          .join(' ');
      expect(
        contexts.contains('Sari-sari') || contexts.contains('sari-sari'),
        isTrue,
      );
      expect(
        contexts.contains('Bebaso') || contexts.contains('bebaso'),
        isTrue,
      );
    });
  });
}
