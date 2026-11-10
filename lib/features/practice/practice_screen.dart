import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/k_progress_bar.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/pattern_background.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/domain/entities/user_progress.dart';
import 'package:katara/engine/exercise_generator.dart';
import 'package:katara/engine/exercise_models.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  List<ExerciseItem>? _activeDrill;
  String _activeDrillTitle = '';
  int _drillIndex = 0;
  String? _selectedOption;
  bool? _lastCorrect;
  int _correctCount = 0;
  final List<ItemAttemptOutcome> _outcomes = [];

  // Kuis cepat 30 detik
  Timer? _speedTimer;
  int _secondsRemaining = 0;
  bool _isSpeedQuiz = false;

  @override
  void dispose() {
    _speedTimer?.cancel();
    super.dispose();
  }

  Future<void> _startWeakWordsDrill(String courseId) async {
    final contentRepo = ref.read(contentRepositoryProvider);
    final progressRepo = ref.read(progressRepositoryProvider);

    final dueList = await progressRepo.dueForReview(courseId, limit: 15);
    final allWords = await contentRepo.getWords(courseId);
    final allPhrases = await contentRepo.getPhrases(courseId);

    final List<String> itemRefs;
    if (dueList.isNotEmpty) {
      itemRefs = dueList.map((d) => d.itemId).toList();
    } else {
      itemRefs = allWords.take(8).map((w) => w.id).toList();
    }

    final syntheticLesson = LessonModel(
      id: 'practice:srs',
      courseId: courseId,
      unitId: 'practice',
      order: 1,
      kind: 'review',
      xpReward: 10,
      itemRefs: itemRefs,
    );

    const generator = ExerciseGenerator();
    final exercises = generator
        .generateForLesson(
          lesson: syntheticLesson,
          allWords: allWords,
          allPhrases: allPhrases,
          allSentences: const [],
          allLetters: const [],
          quizBank: const [],
          knownItemIds: allWords.map((w) => w.id).toSet(),
        )
        .where((e) => !e.isIntro && e.options.isNotEmpty)
        .toList();

    _beginDrill(
      title: 'Latihan Kata Lemah (SRS)',
      exercises: exercises,
      isSpeed: false,
    );
  }

  Future<void> _startSpeedQuiz(String courseId) async {
    final contentRepo = ref.read(contentRepositoryProvider);
    final allWords = await contentRepo.getWords(courseId);
    final allPhrases = await contentRepo.getPhrases(courseId);

    final syntheticLesson = LessonModel(
      id: 'practice:speed',
      courseId: courseId,
      unitId: 'practice',
      order: 1,
      kind: 'review',
      xpReward: 10,
      itemRefs: allWords.take(15).map((w) => w.id).toList(),
    );

    const generator = ExerciseGenerator();
    final exercises = generator
        .generateForLesson(
          lesson: syntheticLesson,
          allWords: allWords,
          allPhrases: allPhrases,
          allSentences: const [],
          allLetters: const [],
          quizBank: const [],
          knownItemIds: allWords.map((w) => w.id).toSet(),
        )
        .where((e) =>
            e.type == ExerciseType.mcqTranslate ||
            e.type == ExerciseType.mcqReverse)
        .toList();

    _beginDrill(
      title: 'Kuis Cepat 30 Detik',
      exercises: exercises,
      isSpeed: true,
    );
  }

  Future<void> _startCategoryDrill(String courseId, String category) async {
    final contentRepo = ref.read(contentRepositoryProvider);
    final allWords = await contentRepo.getWords(courseId);
    final catWords = allWords.where((w) => w.category == category).toList();

    final syntheticLesson = LessonModel(
      id: 'practice:cat:$category',
      courseId: courseId,
      unitId: 'practice',
      order: 1,
      kind: 'vocab',
      xpReward: 8,
      itemRefs: (catWords.isNotEmpty ? catWords : allWords.take(6))
          .map((w) => w.id)
          .toList(),
    );

    const generator = ExerciseGenerator();
    final exercises = generator
        .generateForLesson(
          lesson: syntheticLesson,
          allWords: allWords,
          allPhrases: const [],
          allSentences: const [],
          allLetters: const [],
          quizBank: const [],
          knownItemIds: allWords.map((w) => w.id).toSet(),
        )
        .where((e) => !e.isIntro && e.options.isNotEmpty)
        .toList();

    _beginDrill(
      title: 'Kategori: ${category.replaceAll('_', ' ')}',
      exercises: exercises,
      isSpeed: false,
    );
  }

  void _beginDrill({
    required String title,
    required List<ExerciseItem> exercises,
    required bool isSpeed,
  }) {
    _speedTimer?.cancel();
    setState(() {
      _activeDrillTitle = title;
      _activeDrill = exercises;
      _drillIndex = 0;
      _selectedOption = null;
      _lastCorrect = null;
      _correctCount = 0;
      _outcomes.clear();
      _isSpeedQuiz = isSpeed;
      _secondsRemaining = isSpeed ? 30 : 0;
    });

    if (isSpeed) {
      _speedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_secondsRemaining <= 1) {
          timer.cancel();
          _finishDrill();
        } else {
          setState(() => _secondsRemaining--);
        }
      });
    }
  }

  Future<void> _submitDrillAnswer(String option) async {
    final drill = _activeDrill;
    if (drill == null || _drillIndex >= drill.length) return;
    final current = drill[_drillIndex];
    final isCorrect = option == current.correctAnswer;

    final sfx = ref.read(sfxServiceProvider);
    if (isCorrect) {
      await sfx.playCorrect();
      _correctCount++;
    } else {
      await sfx.playWrong();
    }

    if (current.refItemId != null) {
      _outcomes.add(
        ItemAttemptOutcome(
          itemId: current.refItemId!,
          itemType: current.refItemType,
          isCorrect: isCorrect,
        ),
      );
    }

    setState(() {
      _selectedOption = option;
      _lastCorrect = isCorrect;
    });

    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    if (_drillIndex + 1 < drill.length) {
      setState(() {
        _drillIndex++;
        _selectedOption = null;
        _lastCorrect = null;
      });
    } else {
      await _finishDrill();
    }
  }

  Future<void> _finishDrill() async {
    _speedTimer?.cancel();
    final xp = _correctCount > 0 ? 8 : 5;
    final stats = await ref.read(progressRepositoryProvider).getStats();
    final courseId = stats.activeCourseId ?? 'ms-deli';

    await ref.read(progressRepositoryProvider).recordPracticeReview(
          courseId: courseId,
          outcomes: _outcomes,
          xpEarned: xp,
        );

    if (!mounted) return;
    setState(() {
      _activeDrill = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Latihan selesai! $_correctCount jawaban benar • +$xp XP diperoleh.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final statsAsync = ref.watch(userStatsStreamProvider);

    if (_activeDrill != null && _activeDrill!.isNotEmpty) {
      return _buildActiveDrillView(context, palette);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruang Latihan & Penguatan'),
      ),
      body: PatternBackground(
        opacity: 0.05,
        child: statsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: palette.primary),
          ),
          error: (err, _) => Center(child: Text('Gagal memuat latihan: $err')),
          data: (stats) {
            final courseId = stats.activeCourseId ?? 'ms-deli';
            return FutureBuilder<List<WordMastery>>(
              future: ref
                  .read(progressRepositoryProvider)
                  .dueForReview(courseId, limit: 20),
              builder: (context, snapshot) {
                final dueCount = snapshot.data?.length ?? 0;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    KCard(
                      selected: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const MascotView(
                                state: MascotState.happy,
                                size: 68,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Latihan Kata Lemah (SRS)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dueCount > 0
                                          ? 'Ada $dueCount kata yang sudah waktunya diulang hari ini agar tidak lupa.'
                                          : 'Semua kata sudah kuat! Kamu tetap bisa mengulang kosakata untuk bonus XP.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: palette.inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          KButton(
                            label: dueCount > 0
                                ? 'Ulangi $dueCount Kata Sekarang (+10 XP)'
                                : 'Mulai Latihan Penguat (+8 XP)',
                            icon: Icons.psychology_rounded,
                            onPressed: () => _startWeakWordsDrill(courseId),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: KCard(
                            onTap: () => _startSpeedQuiz(courseId),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.timer_rounded,
                                    color: palette.streak, size: 32),
                                const SizedBox(height: 10),
                                Text(
                                  'Kuis Cepat 30 Detik',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Jawab sebanyak mungkin sebelum waktu habis.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KCard(
                            onTap: () => context.push('/jawi'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.auto_stories_rounded,
                                    color: palette.primary, size: 32),
                                const SizedBox(height: 10),
                                Text(
                                  'Latihan Aksara Jawi',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kenali 6 huruf Jawi khas Melayu & bentuknya.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: KCard(
                            onTap: () => context.push('/practice/conversation'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.forum_rounded,
                                    color: palette.primary, size: 30),
                                const SizedBox(height: 10),
                                Text(
                                  'Latihan Percakapan',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Simulasi dialog pasar, keluarga, dan adab.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KCard(
                            onTap: () => context.push('/practice/pronunciation'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.record_voice_over_rounded,
                                    color: palette.secondary, size: 30),
                                const SizedBox(height: 10),
                                Text(
                                  'Panduan Lafal & Fonologi',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kaidah vokal akhir [-e] vs [-o] & glotal.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    KCard(
                      onTap: () => context.push('/dialect-comparison'),
                      child: Row(
                        children: [
                          Icon(Icons.compare_arrows_rounded,
                              color: palette.primary, size: 30),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Perbandingan Dialek Melayu',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bandingkan kosakata & fonetik Melayu Deli, Langkat, dan Palembang secara berdampingan.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.inkMuted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Latihan Acak per Kategori',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final cat in const [
                          ('sapaan', 'Sapaan & Adab'),
                          ('keluarga', 'Keluarga & Silsilah'),
                          ('angka', 'Hitungan & Angka'),
                          ('makanan', 'Kuliner & Pekan'),
                          ('sifat', 'Kata Sifat'),
                          ('kerja', 'Aktivitas Harian'),
                          ('pronomina_tanya', 'Kata Ganti & Tanya'),
                        ])
                          KChip(
                            label: cat.$2,
                            icon: Icons.play_circle_outline_rounded,
                            onTap: () => _startCategoryDrill(courseId, cat.$1),
                          ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveDrillView(BuildContext context, KataraPalette palette) {
    final drill = _activeDrill!;
    final current = drill[_drillIndex];
    final progress = (_drillIndex + 1) / drill.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_activeDrillTitle),
        leading: IconButton(
          tooltip: 'Tutup Latihan',
          onPressed: () {
            _speedTimer?.cancel();
            setState(() => _activeDrill = null);
          },
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          if (_isSpeedQuiz)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: KChip(
                  label: '$_secondsRemaining dtk',
                  icon: Icons.timer_rounded,
                  backgroundColor: palette.streak.withValues(alpha: 0.2),
                  textColor: palette.ink,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KProgressBar(
              value: progress,
              height: 12,
              semanticLabel: 'Progres latihan',
            ),
            const SizedBox(height: 20),
            Text(
              current.prompt,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (current.subjectDeli != null) ...[
              const SizedBox(height: 14),
              KCard(
                backgroundColor: palette.surfaceAlt,
                child: Text(
                  current.subjectDeli!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: palette.primary,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: current.options.map((opt) {
                  final isSelected = _selectedOption == opt;
                  Color? bg;
                  if (isSelected && _lastCorrect != null) {
                    bg = _lastCorrect!
                        ? palette.success.withValues(alpha: 0.2)
                        : palette.error.withValues(alpha: 0.2);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: KCard(
                      selected: isSelected,
                      backgroundColor: bg,
                      onTap: _selectedOption == null
                          ? () => _submitDrillAnswer(opt)
                          : null,
                      child: Text(
                        opt,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
