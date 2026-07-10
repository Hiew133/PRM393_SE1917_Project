import 'package:flutter/material.dart';
import '../models/lesson.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8DCCB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        splashColor: const Color(0xFFE8953C).withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2DC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.headphones,
                  color: Color(0xFFE8953C),
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D261F),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      lesson.translation,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8C8175),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF8C8175),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "2 min",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8C8175),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (lesson.isCompleted)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Done",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              if (lesson.isFavorite)
                const Icon(
                  Icons.favorite,
                  color: Color(0xFFE8953C),
                  size: 22,
                ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF8C8175),
              ),
            ],
          ),
        ),
      ),
    );
  }
}