import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/completed_service.dart';
import '../services/favorite_service.dart';
import '../widgets/expandable_info_card.dart';
import '../widgets/listening_audio_card.dart';
import '../widgets/listening_question_card.dart';

class ListeningDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final List<Lesson> lessons;
  final int currentIndex;

  const ListeningDetailScreen({
    super.key,
    required this.lesson,
    required this.lessons,
    required this.currentIndex,
  });

  @override
  State<ListeningDetailScreen> createState() => _ListeningDetailScreenState();
}

class _ListeningDetailScreenState extends State<ListeningDetailScreen> {
  static const Color bgColor = Color(0xFFFDF8EF);
  static const Color primaryOrange = Color(0xFFE8953C);
  static const Color lightOrange = Color(0xFFFFF2DC);
  static const Color textDark = Color(0xFF2D261F);

  final AudioPlayer player = AudioPlayer();
  late Lesson currentLesson;
  late int currentIndex;
  bool isPlaying = false;
  double playbackSpeed = 1.0;

  Duration duration = Duration.zero;

  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();

    currentLesson = widget.lesson;
    currentIndex = widget.currentIndex;
    loadFavorites();
    loadCompleted();

    // Lắng nghe trạng thái Play/Pause
    player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    // Lắng nghe tổng thời lượng bài nghe
    player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() {
        duration = d;
      });
    });

    // Lắng nghe vị trí đang phát
    player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() {
        position = p;
      });
    });

    player.onPlayerComplete.listen((event) async {
      if (!mounted) return;

      setState(() {
        position = Duration.zero;
        duration = Duration.zero;
        isPlaying = false;

        currentLesson.isCompleted = true;
      });

      await saveCompletedLessons();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 Lesson Completed!"),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return "$minutes:$seconds";
  }

  Future<void> saveFavorites() async {
    final favorites = widget.lessons
        .where((lesson) => lesson.isFavorite)
        .map((lesson) => lesson.title)
        .toList();

    await FavoriteService.saveFavorites(favorites);
  }

  Future<void> loadCompleted() async {
    final completed = await CompletedService.getCompleted();

    if (!mounted) return;

    setState(() {
      for (final lesson in widget.lessons) {
        lesson.isCompleted = completed.contains(lesson.title);
      }
    });
  }

  Future<void> saveCompletedLessons() async {
    final completed = widget.lessons
        .where((lesson) => lesson.isCompleted)
        .map((lesson) => lesson.title)
        .toList();

    await CompletedService.saveCompleted(completed);
  }

  Future<void> loadFavorites() async {
    final favorites = await FavoriteService.getFavorites();

    if (!mounted) return;

    setState(() {
      for (final lesson in widget.lessons) {
        lesson.isFavorite = favorites.contains(lesson.title);
      }
    });
  }

  Future<void> playAudio() async {
    await player.stop();

    await player.play(
      AssetSource(currentLesson.audioPath),
    );
  }

  Future<void> pauseAudio() async {
    await player.pause();
  }

  Future<void> replayAudio() async {
    await player.seek(Duration.zero);

    if (!isPlaying) {
      await player.resume();
    }
  }

  Future<void> nextLesson() async {
    if (currentIndex >= widget.lessons.length - 1) return;

    await player.stop();

    setState(() {
      currentIndex++;
      currentLesson = widget.lessons[currentIndex];
      position = Duration.zero;
      duration = Duration.zero;
      isPlaying = false;
    });

    await playAudio();
  }

  Future<void> previousLesson() async {
    if (currentIndex <= 0) return;

    await player.stop();

    setState(() {
      currentIndex--;
      currentLesson = widget.lessons[currentIndex];
      position = Duration.zero;
      duration = Duration.zero;
      isPlaying = false;
    });

    await playAudio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // HEADER
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6EBDD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () {
                          Navigator.pop(context);
                        },
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
                        currentLesson.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: primaryOrange,
                      ),
                      onPressed: () async {
                        setState(() {
                          currentLesson.isFavorite =
                          !currentLesson.isFavorite;
                        });

                        await saveFavorites();
                      },
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
                ),

                const SizedBox(height: 24),

                // AUDIO CARD
                ListeningAudioCard(
                  title: currentLesson.title,
                  translation: currentLesson.translation,
                  isPlaying: isPlaying,
                  duration: duration,
                  position: position,
                  playbackSpeed: playbackSpeed,

                  canPrevious: currentIndex > 0,
                  canNext: currentIndex < widget.lessons.length - 1,

                  formatTime: formatTime,

                  onPrevious: previousLesson,
                  onNext: nextLesson,

                  onPlayPause: () async {
                    if (isPlaying) {
                      await pauseAudio();
                    } else {
                      if (position == Duration.zero) {
                        await playAudio();
                      } else {
                        await player.resume();
                      }
                    }
                  },

                  onSeek: (value) async {
                    await player.seek(
                      Duration(seconds: value.toInt()),
                    );
                  },

                  onSpeedChanged: (value) async {
                    setState(() {
                      playbackSpeed = value;
                    });

                    await player.setPlaybackRate(value);
                  },
                ),

                const SizedBox(height: 24),

                // QUESTION CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE8DCCB),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const ListeningQuestionCard(),
                ),

                const SizedBox(height: 24),

                ExpandableInfoCard(
                  icon: Icons.description,
                  title: "Transcript",
                  content: currentLesson.transcript,
                  iconColor: primaryOrange,
                  contentFontSize: 22,
                ),

                const SizedBox(height: 12),

                ExpandableInfoCard(
                  icon: Icons.translate,
                  title: "Translation",
                  content: currentLesson.translation,
                  iconColor: primaryOrange,
                  contentFontSize: 18,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      currentLesson.isCompleted
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      currentLesson.isCompleted
                          ? "Completed"
                          : "Mark as Completed",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentLesson.isCompleted
                          ? Colors.green
                          : primaryOrange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.green,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: currentLesson.isCompleted
                        ? null
                        : () async {
                      setState(() {
                        currentLesson.isCompleted = true;
                      });

                      await saveCompletedLessons();
                    },
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
