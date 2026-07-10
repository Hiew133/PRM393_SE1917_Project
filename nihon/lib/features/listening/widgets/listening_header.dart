import 'package:flutter/material.dart';

class ListeningHeader extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavoriteTap;

  const ListeningHeader({
    super.key,
    required this.isFavorite,
    required this.onBack,
    required this.onFavoriteTap,
  });

  static const Color primaryOrange = Color(0xFFE8953C);
  static const Color lightOrange = Color(0xFFFFF2DC);
  static const Color textDark = Color(0xFF2D261F);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6EBDD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: onBack,
          ),
        ),

        const SizedBox(width: 12),

        const Text(
          "聴解練習",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),

        const Spacer(),

        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: primaryOrange,
          ),
          onPressed: onFavoriteTap,
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: lightOrange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            "N5",
            style: TextStyle(
              color: primaryOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}