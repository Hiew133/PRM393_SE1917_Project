import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String translation;

  const TranslationCard({
    super.key,
    required this.translation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.translate, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  "Translation",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Text(
              translation,
              style: TextStyle(
                fontSize: 21,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}