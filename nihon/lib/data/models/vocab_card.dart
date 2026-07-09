import 'srs_stage.dart';

/// Một thẻ từ vựng trong phiên SRS.
class VocabCard {
  final String? id; // Firestore document ID
  final String reading; // hiragana / katakana
  final String word; // kanji + kana
  final String romaji;
  final String meaning;
  final String exampleJp;
  final String exampleVi;
  final String wordTypeJp;
  final String wordTypeVi;
  SrsStage stage;

  VocabCard({
    this.id,
    required this.reading,
    required this.word,
    required this.romaji,
    required this.meaning,
    required this.exampleJp,
    required this.exampleVi,
    required this.wordTypeJp,
    required this.wordTypeVi,
    this.stage = SrsStage.apprentice1,
  });

  String get wordTypeLabel => '$wordTypeJp — $wordTypeVi';
}
