import 'package:flutter/material.dart';

class ListeningOption extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;

  const ListeningOption({
    super.key,
    required this.label,
    required this.text,
    this.isSelected = false,
    this.onTap,
  });

  static const Color primaryOrange = Color(0xFFE8953C);
  static const Color borderColor = Color(0xFFE8DCCB);
  static const Color textDark = Color(0xFF2D261F);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFFF4E7)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? primaryOrange
              : borderColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          child: Row(
            children: [

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? primaryOrange
                      : Colors.transparent,
                  border: Border.all(
                    color: primaryOrange,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : primaryOrange,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: textDark,
                  ),
                ),
              ),

              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: primaryOrange,
                ),
            ],
          ),
        ),
      ),
    );
  }
}