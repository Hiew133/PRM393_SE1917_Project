import 'package:flutter/material.dart';

import '../data/lesson_data.dart';
import '../widgets/lesson_card.dart';
import 'listening_detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {

  @override
  Widget build(BuildContext context) {
    final favoriteLessons =
    lessons.where((lesson) => lesson.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorite Lessons"),
      ),
      body: favoriteLessons.isEmpty
          ? const Center(
        child: Text(
          "No favorite lessons yet ❤️",
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: favoriteLessons.length,
        itemBuilder: (context, index) {
          final lesson = favoriteLessons[index];

          return LessonCard(
            lesson: lesson,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListeningDetailScreen(
                    lesson: lesson,
                    lessons: lessons,
                    currentIndex: lessons.indexOf(lesson),
                  ),
                ),
              );

              setState(() {});
            },
          );
        },
      ),
    );
  }
}