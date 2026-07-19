import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/guest_lock_dialog.dart';
import '../../data/models/skill.dart';
import '../games/football_quiz/football_quiz_screen.dart';
import '../kana_quiz/kana_quiz_screen.dart';
import '../lessons/grammar_lessons_screen.dart';
import '../lessons/kanji_lessons_screen.dart';
import '../listening/screens/listening_list_screen.dart';
import '../speaking/level_select_screen.dart';
import '../welcome/welcome_screen.dart';
import 'widgets/skill_card.dart';

/// Màn 02 – Dashboard / Trang chủ.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onStartVocabReview});

  final VoidCallback? onStartVocabReview;

  @override
  Widget build(BuildContext context) {
    void openSpeaking() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
      );
    }

    void openListening() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ListeningListScreen()),
      );
    }

    void openKanji() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const KanjiLessonsScreen()),
      );
    }

    void openGrammar() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GrammarLessonsScreen()),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const _UserHeader(),
        const SizedBox(height: 18),
        // Bảng chữ cái Kana — giữ Ở TRÊN CÙNG theo yêu cầu.
        _KanaBanner(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KanaQuizScreen()),
            );
          },
        ),
        const SizedBox(height: 20),
        Text('Các kỹ năng', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 12),
        // Lưới 2 cột cho 4 kỹ năng đầu + 1 hàng full-width cho kỹ năng cuối.
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            for (final skill in kSampleSkills.take(4))
              SkillCard(
                skill: skill,
                onTap: switch (skill.jpLabel) {
                  '語彙' => onStartVocabReview,
                  '漢字' => openKanji,
                  '文法' => openGrammar,
                  '聴く' => openListening,
                  _ => null,
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Luyện nói với AI — chỗ vào phần Nói (giữ DUY NHẤT một lối vào ở đây).
        _SpeakingButton(onTap: openSpeaking),
        // Trò chơi bóng đá — nằm DƯỚI phần Luyện nói.
        const SizedBox(height: 20),
        Text('Trò chơi', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 12),
        ValueListenableBuilder<AppRole>(
          valueListenable: RoleService().currentRole,
          builder: (context, role, _) {
            final isGuest = role == AppRole.guest;
            return _GameBanner(
              locked: isGuest,
              onPlay: () {
                // Khách chỉ được xem — muốn chơi phải đăng nhập.
                if (isGuest) {
                  showGuestLockDialog(context);
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FootballQuizScreen()),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Nút nổi bật dẫn tới phần Luyện nói với AI.
class _SpeakingButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SpeakingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.speaking,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Luyện nói với AI',
                      style: AppTextStyles.latin(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '話す · Hội thoại tiếng Nhật cùng 田中先生',
                      style: AppTextStyles.jp(
                        size: 12,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

const List<List<Color>> kAvatarGradients = [
  [Color(0xFFFF9A9E), Color(0xFFFECFEF)], // Soft Pink
  [Color(0xFFA1C4FD), Color(0xFFC2E9FB)], // Sky Blue
  [Color(0xFF84FAB0), Color(0xFF8FD3F4)], // Mint Green
  [Color(0xFFFAD0C4), Color(0xFFFFD1FF)], // Peach Pink
  [Color(0xFFF6D365), Color(0xFFFDA085)], // Sunset Orange
  [Color(0xFFA6C0FE), Color(0xFFF1EEFD)], // Lavender Purple
];

/// Banner mở trò chơi "Thủ môn bắt bóng" (thay cho thẻ Tiếp tục học).
class _GameBanner extends StatelessWidget {
  const _GameBanner({required this.onPlay, this.locked = false});

  final VoidCallback onPlay;

  /// Chế độ Khách: hiển thị ổ khóa, bấm vào mời đăng nhập.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E8B57), Color(0xFF3BAD6C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.speaking.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('⚽', style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRÒ CHƠI',
                    style: AppTextStyles.latin(
                      size: 10,
                      weight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thủ môn bắt bóng',
                    style: AppTextStyles.latin(size: 16, weight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ôn Hiragana theo kiểu đá bóng — sút tung lưới!',
                    style: AppTextStyles.latin(
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (locked)
                    const Icon(Icons.lock_outline, size: 15, color: Colors.white)
                  else ...[
                    Text(
                      'Chơi',
                      style: AppTextStyles.latin(size: 13, weight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Text('→', style: TextStyle(color: Colors.white)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ mở "Ôn bảng chữ cái Kana" (Hiragana + Katakana).
class _KanaBanner extends StatelessWidget {
  const _KanaBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF9B4FCC)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.kanji.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('あ',
                  style: AppTextStyles.jp(size: 26, weight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BẢNG CHỮ CÁI',
                    style: AppTextStyles.latin(
                      size: 10,
                      weight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Học Hiragana & Katakana',
                    style: AppTextStyles.latin(size: 16, weight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chọn hàng rồi gõ romaji — luyện đến khi thuộc',
                    style: AppTextStyles.latin(size: 12, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Học',
                      style: AppTextStyles.latin(size: 13, weight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 6),
                  const Text('→', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final role = RoleService().currentRole.value;

    final String displayName;
    if (role == AppRole.guest) {
      displayName = 'Guest';
    } else if (user != null && user.email != null) {
      displayName = user.email!;
    } else {
      displayName = 'Guest';
    }

    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G';
    final isGuest = role == AppRole.guest || user == null;

    final firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );

    return Row(
      children: [
        isGuest
            ? Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.brand, AppColors.vocab],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTextStyles.latin(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: firestore.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final String avatarEmoji = data?['avatarEmoji'] as String? ?? '';
                  final int avatarColorIndex = data?['avatarColorIndex'] as int? ?? 0;

                  return Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: avatarEmoji.isNotEmpty
                            ? kAvatarGradients[avatarColorIndex.clamp(0, kAvatarGradients.length - 1)]
                            : [AppColors.brand, AppColors.vocab],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      avatarEmoji.isNotEmpty ? avatarEmoji : initial,
                      style: TextStyle(
                        fontSize: avatarEmoji.isNotEmpty ? 24 : 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'おはよう 🌸',
                style: AppTextStyles.latin(size: 12, color: AppColors.textMuted),
              ),
              Text(
                displayName,
                style: AppTextStyles.latin(size: 17, weight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Streak
        ValueListenableBuilder<Map<String, int>>(
          valueListenable: DataRepository().xpHistoryNotifier,
          builder: (context, _, child) {
            final streakCount = DataRepository().streak;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFCD88A)),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    '$streakCount',
                    style: AppTextStyles.latin(
                      size: 18,
                      weight: FontWeight.w800,
                      color: AppColors.listening,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        // Nút về trang đầu (đăng nhập / Welcome).
        GestureDetector(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.logout,
                size: 20, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}