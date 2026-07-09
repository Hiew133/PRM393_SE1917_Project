import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Cấp độ SRS (Spaced Repetition System) của một thẻ từ vựng.
enum SrsStage {
  apprentice1,
  apprentice2,
  apprentice3,
  apprentice4,
  guru1,
  guru2,
  master,
  enlightened,
  burned,
}

extension SrsStageX on SrsStage {
  String get label {
    switch (this) {
      case SrsStage.apprentice1:
        return '見習い I';
      case SrsStage.apprentice2:
        return '見習い II';
      case SrsStage.apprentice3:
        return '見習い III';
      case SrsStage.apprentice4:
        return '見習い IV';
      case SrsStage.guru1:
        return '弟子 I';
      case SrsStage.guru2:
        return '弟子 II';
      case SrsStage.master:
        return '達人';
      case SrsStage.enlightened:
        return '悟り';
      case SrsStage.burned:
        return '燃焼済';
    }
  }

  Color get color {
    switch (this) {
      case SrsStage.apprentice1:
      case SrsStage.apprentice2:
      case SrsStage.apprentice3:
      case SrsStage.apprentice4:
        return AppColors.srsApprentice;
      case SrsStage.guru1:
      case SrsStage.guru2:
        return AppColors.srsGuru;
      case SrsStage.master:
        return AppColors.srsMaster;
      case SrsStage.enlightened:
        return AppColors.srsEnlightened;
      case SrsStage.burned:
        return AppColors.srsBurned;
    }
  }

  /// Tiến lên một bậc khi trả lời đúng.
  SrsStage advance() {
    const order = SrsStage.values;
    final idx = order.indexOf(this);
    if (idx >= order.length - 1) return this;
    return order[idx + 1];
  }

  /// Lùi về bậc thấp hơn khi trả lời sai.
  SrsStage regress() {
    const order = SrsStage.values;
    final idx = order.indexOf(this);
    if (idx <= 0) return SrsStage.apprentice1;
    return order[idx - 1];
  }
}

/// Mức đánh giá SRS khi ôn flashcard.
enum SrsRating {
  again,
  hard,
  good,
  easy,
}

extension SrsRatingX on SrsRating {
  String get emoji {
    switch (this) {
      case SrsRating.again:
        return '❌';
      case SrsRating.hard:
        return '😓';
      case SrsRating.good:
        return '👍';
      case SrsRating.easy:
        return '⭐';
    }
  }

  String get label {
    switch (this) {
      case SrsRating.again:
        return 'Lại';
      case SrsRating.hard:
        return 'Khó';
      case SrsRating.good:
        return 'Tốt';
      case SrsRating.easy:
        return 'Dễ';
    }
  }

  String get interval {
    switch (this) {
      case SrsRating.again:
        return '1 giờ';
      case SrsRating.hard:
        return '1 ngày';
      case SrsRating.good:
        return '4 ngày';
      case SrsRating.easy:
        return '1 tuần';
    }
  }

  Color get textColor {
    switch (this) {
      case SrsRating.again:
        return AppColors.vocab;
      case SrsRating.hard:
        return AppColors.listening;
      case SrsRating.good:
        return AppColors.speaking;
      case SrsRating.easy:
        return AppColors.brand;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case SrsRating.again:
        return const Color(0xFFFEE2E2);
      case SrsRating.hard:
        return const Color(0xFFFFF7ED);
      case SrsRating.good:
        return const Color(0xFFF0FDF4);
      case SrsRating.easy:
        return const Color(0xFFFFFBEB);
    }
  }

  Color get borderColor {
    switch (this) {
      case SrsRating.again:
        return const Color(0xFFFECACA);
      case SrsRating.hard:
        return const Color(0xFFFED7AA);
      case SrsRating.good:
        return const Color(0xFFBBF7D0);
      case SrsRating.easy:
        return const Color(0xFFFDE68A);
    }
  }

  int get xpReward {
    switch (this) {
      case SrsRating.again:
        return 2;
      case SrsRating.hard:
        return 4;
      case SrsRating.good:
        return 6;
      case SrsRating.easy:
        return 8;
    }
  }

  SrsStage applyTo(SrsStage current) {
    switch (this) {
      case SrsRating.again:
        return current.regress();
      case SrsRating.hard:
        return current;
      case SrsRating.good:
        return current.advance();
      case SrsRating.easy:
        return current.advance().advance();
    }
  }
}
