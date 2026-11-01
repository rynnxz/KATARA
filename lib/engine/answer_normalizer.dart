/// Normalisasi jawaban ketik sesuai Bagian 13.2:
/// mengabaikan huruf besar, spasi ganda, dan tanda baca akhir.
class AnswerNormalizer {
  const AnswerNormalizer._();

  static String normalize(String input) {
    final trimmed = input.trim().toLowerCase();
    final collapsedSpaces = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    return collapsedSpaces.replaceAll(RegExp(r'[.,!?;:؟]+$'), '').trim();
  }

  static bool isMatch(String expected, String actual) {
    final normExpected = normalize(expected);
    final normActual = normalize(actual);
    if (normExpected == normActual) return true;

    // Jika arti memiliki beberapa alternatif dipisahkan "/", terima salah satu.
    if (normExpected.contains('/')) {
      final parts = normExpected
          .split('/')
          .map((e) => normalize(e))
          .where((e) => e.isNotEmpty);
      if (parts.contains(normActual)) return true;
    }
    return false;
  }
}
