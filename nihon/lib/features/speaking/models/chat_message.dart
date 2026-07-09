/// Một bong bóng hội thoại trong màn luyện nói.
class ChatMessage {
  final bool fromUser; // true = người học, false = AI
  final String japanese; // câu tiếng Nhật (kanji + kana)
  final String? reading; // cách đọc (hiragana) – furigana toàn câu
  final String? translation; // bản dịch tiếng Việt

  /// Điểm phát âm 0–100 (chỉ có ở lượt của người học).
  ///
  /// Lưu ý: STT chỉ trả về *văn bản*, không phải âm thanh thô, nên điểm này là
  /// ước lượng dựa trên độ chính xác của câu được nhận diện — không phải chấm
  /// phát âm thật. Muốn chấm phát âm thật cần phân tích tín hiệu âm thanh.
  final int? pronunciationScore;

  /// Nhận xét phát âm/ngữ pháp bằng tiếng Việt (do AI đưa ra).
  final String? feedback;

  /// Đánh dấu bong bóng AI đang được tạo (hiện trạng thái "đang nghĩ").
  final bool isPending;

  const ChatMessage({
    required this.fromUser,
    required this.japanese,
    this.reading,
    this.translation,
    this.pronunciationScore,
    this.feedback,
    this.isPending = false,
  });

  factory ChatMessage.pendingAi() =>
      const ChatMessage(fromUser: false, japanese: '', isPending: true);

  ChatMessage copyWith({
    String? japanese,
    String? reading,
    String? translation,
    int? pronunciationScore,
    String? feedback,
    bool? isPending,
  }) {
    return ChatMessage(
      fromUser: fromUser,
      japanese: japanese ?? this.japanese,
      reading: reading ?? this.reading,
      translation: translation ?? this.translation,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      feedback: feedback ?? this.feedback,
      isPending: isPending ?? this.isPending,
    );
  }
}
