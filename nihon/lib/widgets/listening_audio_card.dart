import 'package:flutter/material.dart';

class ListeningAudioCard extends StatelessWidget {
  final String title;
  final String translation;
  final bool isPlaying;
  final Duration duration;
  final Duration position;
  final double playbackSpeed;

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSpeedChanged;

  final bool canPrevious;
  final bool canNext;
  final String Function(Duration) formatTime;

  const ListeningAudioCard({
    super.key,
    required this.title,
    required this.translation,
    required this.isPlaying,
    required this.duration,
    required this.position,
    required this.playbackSpeed,
    required this.onPrevious,
    required this.onNext,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeedChanged,
    required this.canPrevious,
    required this.canNext,
    required this.formatTime,
  });

  static const Color primaryOrange = Color(0xFFE8953C);
  static const Color textDark = Color(0xFF2D261F);
  static const Color textGrey = Color(0xFF8C8175);
  static const Color borderColor = Color(0xFFE8DCCB);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.headphones, size: 18, color: primaryOrange),
              SizedBox(width: 6),
              Text(
                "HỘI THOẠI",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textGrey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            translation,
            style: const TextStyle(
              fontSize: 14,
              color: textGrey,
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(28, (index) {
                final heights = [18.0, 28.0, 14.0, 36.0, 22.0, 44.0, 30.0];

                return Container(
                  width: 4,
                  height: heights[index % heights.length],
                  decoration: BoxDecoration(
                    color: primaryOrange.withValues(
                      alpha: index < 12 ? 1.0 : 0.25,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 18),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryOrange,
              inactiveTrackColor: borderColor,
              thumbColor: primaryOrange,
              overlayColor: primaryOrange.withValues(alpha: 0.2),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              min: 0,
              max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1,
              value: position.inSeconds
                  .clamp(0, duration.inSeconds > 0 ? duration.inSeconds : 1)
                  .toDouble(),
              onChanged: onSeek,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatTime(position),
                  style: const TextStyle(color: textGrey, fontSize: 13)),
              Text(formatTime(duration),
                  style: const TextStyle(color: textGrey, fontSize: 13)),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 36,
                color: textGrey,
                onPressed: canPrevious ? onPrevious : null,
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: onPlayPause,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(24),
                  backgroundColor: primaryOrange,
                  elevation: 4,
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 36,
                color: textGrey,
                onPressed: canNext ? onNext : null,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildSpeedButton(0.75),
              buildSpeedButton(1.0),
              buildSpeedButton(1.25),
              buildSpeedButton(1.5),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSpeedButton(double speed) {
    final bool selected = playbackSpeed == speed;

    return GestureDetector(
      onTap: () => onSpeedChanged(speed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primaryOrange : const Color(0xFFF1E7D8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "${speed}x",
          style: TextStyle(
            color: selected ? Colors.white : textDark,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}