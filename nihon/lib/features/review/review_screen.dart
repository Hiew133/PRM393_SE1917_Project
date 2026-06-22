import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/placeholder_screen.dart';

/// Màn "Ôn tập" – phiên ôn SRS (flashcard từ vựng, kanji...).
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Ôn tập',
      jpTitle: '復習',
      icon: Icons.autorenew,
      color: AppColors.vocab,
      description: 'Ôn tập theo phương pháp SRS – 8 thẻ đang chờ.',
    );
  }
}
