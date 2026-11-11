enum ExerciseType {
  introCard('intro_card'),
  mcqTranslate('mcq_translate'),
  mcqReverse('mcq_reverse'),
  matchPairs('match_pairs'),
  fillBlank('fill_blank'),
  buildSentence('build_sentence'),
  imageToWord('image_to_word'),
  listenChoose('listen_choose'),
  jawiRecognize('jawi_recognize'),
  jawiRead('jawi_read'),
  cultureTf('culture_tf'),
  quizBankItem('quiz_bank_item');

  const ExerciseType(this.code);
  final String code;
}

class MatchPairItem {
  const MatchPairItem({required this.left, required this.right, this.itemId});

  final String left;
  final String right;
  final String? itemId;
}

class ExerciseItem {
  const ExerciseItem({
    required this.id,
    required this.type,
    required this.prompt,
    required this.correctAnswer,
    this.subtitle,
    this.jawiText,
    this.options = const [],
    this.pairs = const [],
    this.wordBank = const [],
    this.refItemId,
    this.refItemType = 'word',
    this.explanation,
    this.validationStatus = 'draft',
    this.audioPath,
    this.imagePath,
    this.isRetry = false,
  });

  final String id;
  final ExerciseType type;
  final String prompt;
  final String? subtitle;
  final String? jawiText;
  final String correctAnswer;
  final List<String> options;
  final List<MatchPairItem> pairs;
  final List<String> wordBank;
  final String? refItemId;
  final String refItemType;
  final String? explanation;
  final String validationStatus;
  final String? audioPath;
  final String? imagePath;
  final bool isRetry;

  bool get isIntro => type == ExerciseType.introCard;
  String? get subjectDeli => subtitle;
  String? get subjectIndonesia => subtitle;
  String? get subjectJawi => jawiText;

  ExerciseItem asRetry() => ExerciseItem(
    id: id,
    type: type,
    prompt: prompt,
    subtitle: subtitle,
    jawiText: jawiText,
    correctAnswer: correctAnswer,
    options: options,
    pairs: pairs,
    wordBank: wordBank,
    refItemId: refItemId,
    refItemType: refItemType,
    explanation: explanation,
    validationStatus: validationStatus,
    audioPath: audioPath,
    imagePath: imagePath,
    isRetry: true,
  );
}
