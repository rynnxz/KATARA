import 'dart:math' as math;

import 'package:katara/domain/entities/user_progress.dart';
import 'package:katara/engine/answer_normalizer.dart';
import 'package:katara/engine/exercise_models.dart';

/// Mesin pengelola sesi pelajaran murni Dart (Bagian 13.2 & 13.3):
/// mengelola indeks soal, nyawa, combo, skor, dan antrean ulang soal salah (maks 1 kali ulang per soal).
class LessonSessionEngine {
  LessonSessionEngine({
    required List<ExerciseItem> exercises,
    required int initialHearts,
    required this.heartsEnabled,
  }) : _queue = List<ExerciseItem>.from(exercises),
       _hearts = initialHearts,
       _initialScoredCount = exercises.where((e) => !e.isIntro).length;

  final List<ExerciseItem> _queue;
  final int _initialScoredCount;
  final bool heartsEnabled;

  final Set<String> _retriedExerciseIds = <String>{};
  final List<ItemAttemptOutcome> _outcomes = <ItemAttemptOutcome>[];

  int _currentIndex = 0;
  int _hearts;
  int _currentCombo = 0;
  int _maxCombo = 0;
  int _correctFirstTryCount = 0;
  int _wrongCount = 0;
  int _jawiPracticedCount = 0;
  bool? _lastSubmissionCorrect;

  int get currentIndex => _currentIndex;
  int get totalQueueLength => _queue.length;
  int get initialScoredCount => _initialScoredCount;
  int get hearts => _hearts;
  int get currentCombo => _currentCombo;
  int get maxCombo => _maxCombo;
  int get correctFirstTryCount => _correctFirstTryCount;
  int get wrongCount => _wrongCount;
  int get jawiPracticedCount => _jawiPracticedCount;
  bool? get lastSubmissionCorrect => _lastSubmissionCorrect;
  List<ItemAttemptOutcome> get outcomes => List.unmodifiable(_outcomes);

  bool get isFinished => _currentIndex >= _queue.length;
  bool get isOutOfHearts => heartsEnabled && _hearts <= 0;

  ExerciseItem get currentExercise => _queue[_currentIndex];

  double get progress {
    if (_queue.isEmpty) return 1.0;
    return (_currentIndex / _queue.length).clamp(0.0, 1.0);
  }

  /// Memeriksa jawaban untuk soal saat ini.
  /// Mengembalikan `true` bila benar, `false` bila salah.
  bool submitAnswer(String answer) {
    if (isFinished) return true;
    final current = currentExercise;
    if (current.isIntro) {
      _lastSubmissionCorrect = true;
      return true;
    }

    final isCorrect = current.type == ExerciseType.matchPairs
        ? answer == 'matched'
        : AnswerNormalizer.isMatch(current.correctAnswer, answer);

    _lastSubmissionCorrect = isCorrect;

    if (current.type == ExerciseType.jawiRecognize ||
        current.type == ExerciseType.jawiRead) {
      _jawiPracticedCount++;
    }

    if (isCorrect) {
      _currentCombo++;
      _maxCombo = math.max(_maxCombo, _currentCombo);
      if (!current.isRetry) {
        _correctFirstTryCount++;
        if (current.refItemId != null) {
          _outcomes.add(
            ItemAttemptOutcome(
              itemId: current.refItemId!,
              itemType: current.refItemType,
              isCorrect: true,
            ),
          );
        }
      }
    } else {
      _currentCombo = 0;
      _wrongCount++;
      if (heartsEnabled && _hearts > 0) {
        _hearts--;
      }
      if (!current.isRetry) {
        if (current.refItemId != null) {
          _outcomes.add(
            ItemAttemptOutcome(
              itemId: current.refItemId!,
              itemType: current.refItemType,
              isCorrect: false,
            ),
          );
        }
        // Antrekan ulang di akhir sesi maksimal 1 kali per soal (Bagian 13.2).
        if (!_retriedExerciseIds.contains(current.id)) {
          _retriedExerciseIds.add(current.id);
          _queue.add(current.asRetry());
        }
      }
    }

    return isCorrect;
  }

  void restoreFullHearts(int maxHearts) {
    _hearts = maxHearts;
  }

  void nextStep() {
    if (!isFinished) {
      _currentIndex++;
      _lastSubmissionCorrect = null;
    }
  }
}
