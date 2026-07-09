class Lesson {
  final String title;
  final String audioPath;
  final String transcript;
  final String translation;

  bool isFavorite;
  bool isCompleted;

  Lesson({
    required this.title,
    required this.audioPath,
    required this.transcript,
    required this.translation,
    this.isFavorite = false,
    this.isCompleted = false,
  });
}