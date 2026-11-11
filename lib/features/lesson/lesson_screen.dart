import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/providers.dart';
import 'package:katara/app/theme/katara_colors.dart';
import 'package:katara/app/widgets/exercise_scaffold.dart';
import 'package:katara/app/widgets/jawi_text.dart';
import 'package:katara/app/widgets/k_button.dart';
import 'package:katara/app/widgets/k_card.dart';
import 'package:katara/app/widgets/k_chip.dart';
import 'package:katara/app/widgets/mascot_view.dart';
import 'package:katara/app/widgets/report_issue_dialog.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/domain/entities/user_progress.dart';
import 'package:katara/domain/rules/gamification_rules.dart';
import 'package:katara/engine/exercise_generator.dart';
import 'package:katara/engine/exercise_models.dart';
import 'package:katara/engine/lesson_session_engine.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _loading = true;
  String? _error;
  LessonModel? _lesson;
  LessonSessionEngine? _engine;

  // Pilihan pengguna untuk soal saat ini
  String? _selectedOption;
  final List<String> _assembledTokens = [];
  final List<int> _usedTokenIndices = [];

  // State untuk matchPairs
  String? _selectedLeftPair;
  String? _selectedRightPair;
  final Set<String> _matchedLeftKeys = {};
  List<String> _shuffledRightValues = [];

  ExerciseFeedbackState _feedbackState = ExerciseFeedbackState.none;
  bool _completingSession = false;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final contentRepo = ref.read(contentRepositoryProvider);
      final progressRepo = ref.read(progressRepositoryProvider);
      final settings = ref.read(appSettingsProvider);

      final lesson = await contentRepo.getLesson(widget.lessonId);
      if (lesson == null) {
        setState(() {
          _loading = false;
          _error = 'Pelajaran tidak ditemukan.';
        });
        return;
      }

      final stats = await progressRepo.getStats();
      final config = await contentRepo.getGameConfig();
      final courseId = stats.activeCourseId ?? 'ms-deli';

      final words = await contentRepo.getWords(courseId);
      final phrases = await contentRepo.getPhrases(courseId);
      final sentences = await contentRepo.getSentences(courseId);
      final letters = await contentRepo.getLetters(courseId);
      final quizBank = await contentRepo.getQuizBank(
        courseId,
        includeUnverified: settings.debugIncludeUnverified,
      );
      final masteryList = await progressRepo.getCourseMastery(courseId);
      final knownItemIds = masteryList.map((m) => m.itemId).toSet();

      const generator = ExerciseGenerator();
      final exercises = generator.generateForLesson(
        lesson: lesson,
        allWords: words,
        allPhrases: phrases,
        allSentences: sentences,
        allLetters: letters,
        quizBank: quizBank,
        knownItemIds: knownItemIds,
        includeUnverified: settings.debugIncludeUnverified,
      );

      final heartsEnabled = GamificationRules.areHeartsEnabled(
        userLevel: stats.level,
        casualMode: stats.casualMode,
        config: config,
      );

      final engine = LessonSessionEngine(
        exercises: exercises,
        initialHearts: stats.hearts,
        heartsEnabled: heartsEnabled,
      );

      _lesson = lesson;
      _engine = engine;
      _prepareCurrentExerciseState();

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat sesi latihan: $e';
        });
      }
    }
  }

  void _prepareCurrentExerciseState() {
    _selectedOption = null;
    _assembledTokens.clear();
    _usedTokenIndices.clear();
    _selectedLeftPair = null;
    _selectedRightPair = null;
    _matchedLeftKeys.clear();
    _shuffledRightValues = [];
    _feedbackState = ExerciseFeedbackState.none;

    final engine = _engine;
    if (engine == null || engine.isFinished) return;
    final current = engine.currentExercise;
    if (current.type == ExerciseType.matchPairs && current.pairs.isNotEmpty) {
      _shuffledRightValues = current.pairs.map((p) => p.right).toList()
        ..shuffle();
    }
  }

  bool get _canCheck {
    final engine = _engine;
    if (engine == null || engine.isFinished) return false;
    final current = engine.currentExercise;
    if (current.isIntro) return true;
    switch (current.type) {
      case ExerciseType.introCard:
        return true;
      case ExerciseType.buildSentence:
        return _assembledTokens.isNotEmpty;
      case ExerciseType.matchPairs:
        return current.pairs.isNotEmpty &&
            _matchedLeftKeys.length == current.pairs.length;
      default:
        return _selectedOption != null && _selectedOption!.isNotEmpty;
    }
  }

  Future<void> _onCheckOrNext() async {
    final engine = _engine;
    if (engine == null || _completingSession) return;

    if (engine.currentExercise.isIntro) {
      engine.submitAnswer('');
      await _advanceOrComplete();
      return;
    }

    if (_feedbackState == ExerciseFeedbackState.none) {
      final current = engine.currentExercise;
      final String submitted;
      if (current.type == ExerciseType.buildSentence) {
        submitted = _assembledTokens.join(' ');
      } else if (current.type == ExerciseType.matchPairs) {
        submitted = 'matched';
      } else {
        submitted = _selectedOption ?? '';
      }

      final isCorrect = engine.submitAnswer(submitted);
      final sfx = ref.read(sfxServiceProvider);
      if (isCorrect) {
        await sfx.playCorrect();
      } else {
        await sfx.playWrong();
        if (engine.heartsEnabled) {
          await ref.read(progressRepositoryProvider).spendHeart();
        }
      }

      setState(() {
        _feedbackState = isCorrect
            ? ExerciseFeedbackState.correct
            : ExerciseFeedbackState.wrong;
      });

      if (engine.isOutOfHearts) {
        if (!mounted) return;
        await _showOutOfHeartsDialog();
      }
      return;
    }

    await _advanceOrComplete();
  }

  Future<void> _advanceOrComplete() async {
    final engine = _engine;
    final lesson = _lesson;
    if (engine == null || lesson == null) return;

    engine.nextStep();
    if (!engine.isFinished) {
      setState(_prepareCurrentExerciseState);
      return;
    }

    setState(() => _completingSession = true);
    try {
      final progressRepo = ref.read(progressRepositoryProvider);
      final stats = await progressRepo.getStats();
      final courseId = stats.activeCourseId ?? 'ms-deli';

      final attempt = LessonAttempt(
        courseId: courseId,
        lessonId: lesson.id,
        unitId: lesson.unitId,
        lessonKind: lesson.kind,
        totalQuestions: engine.initialScoredCount > 0
            ? engine.initialScoredCount
            : engine.totalQueueLength,
        correctFirstTryCount: engine.correctFirstTryCount,
        wrongCount: engine.wrongCount,
        maxCombo: engine.maxCombo,
        itemOutcomes: engine.outcomes,
        jawiPracticedCount: engine.jawiPracticedCount,
      );

      final result = await progressRepo.completeLesson(attempt);
      ref.read(lastLessonResultProvider.notifier).setResult(result);
      await ref.read(sfxServiceProvider).playLessonComplete();

      if (!mounted) return;
      context.pushReplacement('/lesson/${lesson.id}/result');
    } finally {
      if (mounted) {
        setState(() => _completingSession = false);
      }
    }
  }

  Future<void> _showOutOfHeartsDialog() async {
    final palette = context.kataraPalette;
    final progressRepo = ref.read(progressRepositoryProvider);
    final contentRepo = ref.read(contentRepositoryProvider);
    final stats = await progressRepo.getStats();
    final config = await contentRepo.getGameConfig();
    final refillItem = config.shopItems
        .where((i) => i.id == 'heart_refill')
        .firstOrNull;
    final price = refillItem?.priceCoins ?? 40;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: MascotView(state: MascotState.sad, size: 84)),
            const SizedBox(height: 14),
            Text(
              'Nyawa Belajar Habis',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Nyawa pulih otomatis 1 hati setiap 30 menit. Kamu juga bisa mengisi penuh dengan koin atau berlatih di menu Latihan.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: palette.inkMuted),
            ),
            const SizedBox(height: 20),
            if (refillItem != null && stats.coins >= price) ...[
              KButton(
                label: 'Isi Penuh Nyawa ($price Koin)',
                icon: Icons.favorite_rounded,
                onPressed: () async {
                  final ok = await progressRepo.buyShopItem(refillItem);
                  if (ok) {
                    _engine?.restoreFullHearts(config.heartsMax);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 10),
            ],
            KButton(
              label: 'Kembali ke Peta',
              variant: KButtonVariant.outline,
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onTapPair(String key, String value, {required bool isLeft}) {
    final current = _engine?.currentExercise;
    final pairs = current?.pairs;
    if (pairs == null || pairs.isEmpty) return;

    setState(() {
      if (isLeft) {
        _selectedLeftPair = key;
      } else {
        _selectedRightPair = value;
      }

      if (_selectedLeftPair != null && _selectedRightPair != null) {
        final expectedRight = pairs
            .where((p) => p.left == _selectedLeftPair)
            .map((p) => p.right)
            .firstOrNull;
        if (expectedRight == _selectedRightPair) {
          _matchedLeftKeys.add(_selectedLeftPair!);
          ref.read(sfxServiceProvider).playCorrect();
        } else {
          ref.read(sfxServiceProvider).playWrong();
        }
        _selectedLeftPair = null;
        _selectedRightPair = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: palette.primary)),
      );
    }

    if (_error != null || _engine == null || _lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Latihan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'Gagal memuat latihan.'),
                const SizedBox(height: 16),
                KButton(label: 'Coba Lagi', onPressed: _initSession),
              ],
            ),
          ),
        ),
      );
    }

    final engine = _engine!;
    if (engine.isFinished) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: palette.primary)),
      );
    }

    final current = engine.currentExercise;
    final actionLabel = _feedbackState != ExerciseFeedbackState.none
        ? 'Lanjut'
        : (current.isIntro ? 'Mengerti, Lanjut' : 'Periksa');

    return ExerciseScaffold(
      progress: engine.progress,
      hearts: engine.hearts,
      heartsEnabled: engine.heartsEnabled,
      feedbackState: _feedbackState,
      feedbackTitle: _feedbackState == ExerciseFeedbackState.correct
          ? 'Mantap! Jawabanmu tepat.'
          : 'Belum tepat',
      feedbackDetail: _feedbackState == ExerciseFeedbackState.none
          ? null
          : (current.explanation ?? 'Jawaban benar: ${current.correctAnswer}'),
      actionLabel: actionLabel,
      isActionEnabled: _canCheck && !_completingSession,
      onAction: _onCheckOrNext,
      onClose: () => context.pop(),
      onReportIssue: () => showReportIssueSheet(
        context,
        ref,
        courseId: _lesson?.courseId ?? 'ms-deli',
        itemId: current.refItemId ?? current.id,
        itemType: current.refItemType,
        itemTitle: current.subjectDeli ?? current.prompt,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              KChip(
                label: current.isRetry
                    ? 'Ulangan Penguat'
                    : _labelForExerciseType(current.type),
                backgroundColor: current.isRetry
                    ? palette.secondaryContainer
                    : palette.surfaceAlt,
                foregroundColor: current.isRetry
                    ? palette.onSecondaryContainer
                    : palette.ink,
              ),
              ValidationStatusBadge(status: current.validationStatus),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            current.prompt,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          _buildExerciseContent(context, palette, current),
        ],
      ),
    );
  }

  String _labelForExerciseType(ExerciseType type) {
    return switch (type) {
      ExerciseType.introCard => 'Kenalan Kata Baru',
      ExerciseType.mcqTranslate => 'Terjemahkan ke Indonesia',
      ExerciseType.mcqReverse => 'Pilih Bahasa Melayu',
      ExerciseType.matchPairs => 'Pasangkan Kata',
      ExerciseType.fillBlank => 'Lengkapi Kalimat',
      ExerciseType.buildSentence => 'Susun Ungkapan',
      ExerciseType.imageToWord => 'Tebak Gambar',
      ExerciseType.listenChoose => 'Dengar & Pilih',
      ExerciseType.jawiRecognize => 'Kenali Huruf Jawi',
      ExerciseType.jawiRead => 'Baca Aksara Jawi',
      ExerciseType.cultureTf => 'Wawasan Budaya',
      ExerciseType.quizBankItem => 'Kuis Pemahaman',
    };
  }

  Widget _buildExerciseContent(
    BuildContext context,
    KataraPalette palette,
    ExerciseItem current,
  ) {
    final showJawi = ref.watch(appSettingsProvider).showJawiScript;

    if (current.isIntro) {
      return KCard(
        selected: true,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const MascotView(state: MascotState.happy, size: 76),
            const SizedBox(height: 16),
            if (current.subjectJawi != null && showJawi) ...[
              JawiText(
                current.subjectJawi!,
                fontSize: 40,
                color: palette.onPrimaryContainer,
              ),
              const SizedBox(height: 10),
            ],
            if (current.subjectDeli != null)
              Text(
                current.subjectDeli!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: palette.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.outline),
              ),
              child: Text(
                'Arti: ${current.correctAnswer}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: palette.ink, fontWeight: FontWeight.w800),
              ),
            ),
            if (current.explanation != null) ...[
              const SizedBox(height: 12),
              Text(
                current.explanation!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: palette.onPrimaryContainer),
              ),
            ],
            const SizedBox(height: 12),
            ValidationStatusBadge(status: current.validationStatus),
          ],
        ),
      );
    }

    if (current.type == ExerciseType.matchPairs && current.pairs.isNotEmpty) {
      final leftKeys = current.pairs.map((p) => p.left).toList();
      final rightValues = _shuffledRightValues;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ketuk kata di kiri lalu ketuk pasangannya di kanan.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: leftKeys.map((left) {
                    final isMatched = _matchedLeftKeys.contains(left);
                    final isSelected = _selectedLeftPair == left;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: KCard(
                        selected: isSelected,
                        backgroundColor: isMatched
                            ? palette.successContainer
                            : null,
                        onTap:
                            isMatched ||
                                _feedbackState != ExerciseFeedbackState.none
                            ? null
                            : () => _onTapPair(left, '', isLeft: true),
                        child: Center(
                          child: Text(
                            left,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: isMatched
                                      ? palette.onSuccessContainer
                                      : (isSelected
                                            ? palette.onPrimaryContainer
                                            : palette.ink),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: rightValues.map((right) {
                    final isMatched = current.pairs.any(
                      (p) =>
                          _matchedLeftKeys.contains(p.left) && p.right == right,
                    );
                    final isSelected = _selectedRightPair == right;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: KCard(
                        selected: isSelected,
                        backgroundColor: isMatched
                            ? palette.successContainer
                            : null,
                        onTap:
                            isMatched ||
                                _feedbackState != ExerciseFeedbackState.none
                            ? null
                            : () => _onTapPair('', right, isLeft: false),
                        child: Center(
                          child: Text(
                            right,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: isMatched
                                      ? palette.onSuccessContainer
                                      : (isSelected
                                            ? palette.onPrimaryContainer
                                            : palette.ink),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (current.type == ExerciseType.buildSentence) {
      final tokenBank = current.wordBank.isNotEmpty
          ? current.wordBank
          : current.options;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (current.subjectIndonesia != null)
            KCard(
              backgroundColor: palette.surfaceAlt,
              child: Row(
                children: [
                  const MascotView(state: MascotState.idle, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      current.subjectIndonesia!,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.outline, width: 1.5),
            ),
            child: _assembledTokens.isEmpty
                ? Center(
                    child: Text(
                      'Ketuk potongan kata di bawah untuk menyusun kalimat',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.inkMuted),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_assembledTokens.length, (idx) {
                      final word = _assembledTokens[idx];
                      return KChip(
                        label: word,
                        backgroundColor: palette.primaryContainer,
                        textColor: palette.onPrimaryContainer,
                        onTap: _feedbackState == ExerciseFeedbackState.none
                            ? () {
                                setState(() {
                                  _assembledTokens.removeAt(idx);
                                  _usedTokenIndices.removeAt(idx);
                                });
                              }
                            : null,
                      );
                    }),
                  ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(tokenBank.length, (idx) {
              final token = tokenBank[idx];
              final isUsed = _usedTokenIndices.contains(idx);
              return Opacity(
                opacity: isUsed ? 0.35 : 1.0,
                child: KChip(
                  label: token,
                  onTap: isUsed || _feedbackState != ExerciseFeedbackState.none
                      ? null
                      : () {
                          setState(() {
                            _usedTokenIndices.add(idx);
                            _assembledTokens.add(token);
                          });
                        },
                ),
              );
            }),
          ),
        ],
      );
    }

    // Default: MCQ / Fill Blank / Jawi Recognize / Quiz Bank
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (current.subjectDeli != null || current.subjectJawi != null) ...[
          KCard(
            backgroundColor: palette.surfaceAlt,
            child: Column(
              children: [
                if (current.subjectJawi != null &&
                    (showJawi ||
                        current.type == ExerciseType.jawiRecognize ||
                        current.type == ExerciseType.jawiRead))
                  JawiText(
                    current.subjectJawi!,
                    fontSize: 38,
                    color: palette.primary,
                  ),
                if (current.subjectDeli != null) ...[
                  if (current.subjectJawi != null) const SizedBox(height: 6),
                  Text(
                    current.subjectDeli!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: palette.primary),
                  ),
                ],
                if (current.subjectIndonesia != null &&
                    current.type == ExerciseType.fillBlank) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Arti: "${current.subjectIndonesia!}"',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        ...current.options.map((option) {
          final isSelected = _selectedOption == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KCard(
              selected: isSelected,
              onTap: _feedbackState == ExerciseFeedbackState.none
                  ? () => setState(() => _selectedOption = option)
                  : null,
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected
                        ? palette.onPrimaryContainer
                        : palette.inkMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? palette.onPrimaryContainer
                            : palette.ink,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
