import 'package:flutter/material.dart';

class TranscriptCard extends StatelessWidget {
  final String transcript;

  const TranscriptCard({
    super.key,
    required this.transcript,
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
                Icon(Icons.description, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Transcript",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Text(
              transcript,
              style: const TextStyle(
                fontSize: 26,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}