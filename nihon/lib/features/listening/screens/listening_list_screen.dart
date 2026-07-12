import 'package:flutter/material.dart';
import '../../../core/services/role_service.dart';
import '../../../core/widgets/guest_lock_dialog.dart';
import '../data/lesson_data.dart';
import '../models/lesson.dart';
import '../services/completed_service.dart';
import '../services/favorite_service.dart';
import '../widgets/lesson_card.dart';
import 'listening_detail_screen.dart';

class ListeningListScreen extends StatefulWidget {
  const ListeningListScreen({super.key});

  @override
  State<ListeningListScreen> createState() =>
      _ListeningListScreenState();
}

class _ListeningListScreenState
    extends State<ListeningListScreen> {

  String searchText = "";

  late List<Lesson> filteredLessons;

  @override
  void initState() {
    super.initState();

    filteredLessons = lessons;

    loadFavorites();
    loadCompleted();
  }

  Future<void> loadFavorites() async {
    final favorites =
    await FavoriteService.getFavorites();

    setState(() {
      for (final lesson in lessons) {
        lesson.isFavorite =
            favorites.contains(lesson.title);
      }
    });
  }

  Future<void> loadCompleted() async {
    final completed =
    await CompletedService.getCompleted();

    setState(() {
      for (final lesson in lessons) {
        lesson.isCompleted =
            completed.contains(lesson.title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    final completedCount =
        lessons.where((lesson) => lesson.isCompleted).length;

    final progress =
    lessons.isEmpty ? 0.0 : completedCount / lessons.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8EF),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Listening",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D261F),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "👋 Welcome Back",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  "Japanese Listening",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(height: 20),

          /// Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search lesson...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFE8953C),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;

                  filteredLessons = lessons.where((lesson) {
                    return lesson.title
                        .toLowerCase()
                        .contains(searchText.toLowerCase());
                  }).toList();
                });
              },
            ),
          ),

          /// Learning Progress
          /// Learning Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(
                  color: Color(0xFFE8DCCB),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_stories,
                          color: Color(0xFFE8953C),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Continue Learning",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D261F),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE8953C),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: const Color(0xFFF1E7D8),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE8953C),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        "$completedCount of ${lessons.length} lessons completed",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF8C8175),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// Lesson List
          Expanded(
            child: ListView.builder(
              itemCount: filteredLessons.length,
              itemBuilder: (context, index) {

                final lesson =
                filteredLessons[index];

                // Khách chỉ được nghe thử bài đầu tiên; các bài sau khóa.
                final isGuest =
                    RoleService().currentRole.value == AppRole.guest;
                final isLocked =
                    isGuest && lessons.indexOf(lesson) > 0;

                final card = LessonCard(
                  lesson: lesson,
                  onTap: () async {
                    if (isLocked) {
                      showGuestLockDialog(context);
                      return;
                    }

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ListeningDetailScreen(
                              lesson: lesson,
                              lessons: lessons,
                              currentIndex:
                              lessons.indexOf(lesson),
                            ),
                      ),
                    );

                    setState(() {});
                  },
                );

                if (!isLocked) return card;
                return Stack(
                  children: [
                    Opacity(opacity: 0.55, child: card),
                    const Positioned(
                      top: 12,
                      right: 28,
                      child: Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: Color(0xFF8C8175),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}