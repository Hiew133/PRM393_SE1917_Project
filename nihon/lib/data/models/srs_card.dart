/// Represents a single SRS card (word/kanji to review)
class SrsCard {
  final String word;
  final String furigana;
  final String romaji;
  final String meaning;
  final String category;
  final String exampleJa;
  final String exampleVi;

  const SrsCard({
    required this.word,
    required this.furigana,
    required this.romaji,
    required this.meaning,
    required this.category,
    required this.exampleJa,
    required this.exampleVi,
  });
}

/// Represents the progress state of an SRS card
class CardProgress {
  final SrsCard card;
  final String srsStage;
  final DateTime nextReview;

  CardProgress({
    required this.card,
    required this.srsStage,
    required this.nextReview,
  });
}
