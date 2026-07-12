import 'package:flutter/material.dart';

import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/auth_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final DataRepository _repository = DataRepository();

  @override
  void initState() {
    super.initState();
    _repository.lessonsNotifier.addListener(_refresh);
    _repository.grammarPointsNotifier.addListener(_refresh);
    _repository.srsCardsNotifier.addListener(_refresh);
    _repository.xpHistoryNotifier.addListener(_refresh);
    RoleService().currentRole.addListener(_refresh);
  }

  @override
  void dispose() {
    _repository.lessonsNotifier.removeListener(_refresh);
    _repository.grammarPointsNotifier.removeListener(_refresh);
    _repository.srsCardsNotifier.removeListener(_refresh);
    _repository.xpHistoryNotifier.removeListener(_refresh);
    RoleService().currentRole.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stats = _ProgressStats.fromRepository(_repository);
    final isGuest = RoleService().currentRole.value == AppRole.guest;

    if (isGuest) {
      return const _GuestProgressView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _ProgressHeader(stats: stats),
            const SizedBox(height: 18),
            _HeroProgressCard(stats: stats),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.menu_book_rounded,
                    value: '${stats.lessonCount}',
                    label: 'Bài học',
                    color: AppColors.reading,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.alarm_rounded,
                    value: '${stats.dueCards}',
                    label: 'Đến hạn',
                    color: stats.dueCards > 0
                        ? AppColors.vocab
                        : AppColors.speaking,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Mục tiêu hôm nay'),
            const SizedBox(height: 10),
            _DailyGoalCard(stats: stats),
            const SizedBox(height: 22),
            const _SectionTitle('Hoạt động 7 ngày'),
            const SizedBox(height: 10),
            _ActivityWeeklyChart(stats: stats),
            const SizedBox(height: 22),
            const _SectionTitle('Dữ liệu học tập'),
            const SizedBox(height: 10),
            _LearningDataTile(
              icon: Icons.style_rounded,
              title: 'Từ vựng ôn tập',
              value: '${stats.totalCards}',
              subtitle: '${stats.dueCards} thẻ đang đến hạn',
              color: AppColors.vocab,
            ),
            const SizedBox(height: 10),
            _LearningDataTile(
              icon: Icons.psychology_alt_rounded,
              title: 'Kanji / Từ vựng trong bài',
              value: '${stats.kanjiCount}',
              subtitle: 'Lấy từ dữ liệu bài học hiện có',
              color: AppColors.kanji,
            ),
            const SizedBox(height: 10),
            _LearningDataTile(
              icon: Icons.rule_rounded,
              title: 'Ngữ pháp',
              value: '${stats.grammarCount}',
              subtitle: 'Đồng bộ từ kho ngữ pháp',
              color: AppColors.reading,
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Cấp độ SRS'),
            const SizedBox(height: 10),
            _SrsStageGrid(stats: stats),
            const SizedBox(height: 22),
            const _SectionTitle('Huy hiệu'),
            const SizedBox(height: 10),
            _BadgesGrid(stats: stats),
          ],
        ),
      ),
    );
  }
}

class _GuestProgressView extends StatelessWidget {
  const _GuestProgressView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.brand,
                  size: 46,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Theo dõi tiến độ',
                style: AppTextStyles.latin(size: 21, weight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Đăng nhập để lưu XP, lịch sử ôn tập, cấp độ SRS và huy hiệu học tập của bạn.',
                textAlign: TextAlign.center,
                style: AppTextStyles.latin(
                  size: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AuthScreen(startRegister: false),
                    ),
                  );
                },
                child: const Text('Đăng nhập / Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStats {
  final int lessonCount;
  final int kanjiCount;
  final int grammarCount;
  final int totalCards;
  final int dueCards;
  final int apprenticeCards;
  final int guruCards;
  final int masterCards;
  final int enlightenedCards;
  final int burnedCards;
  final int dailyGoal;
  final int todayXp;
  final Map<String, int> dailyXpHistory;

  const _ProgressStats({
    required this.lessonCount,
    required this.kanjiCount,
    required this.grammarCount,
    required this.totalCards,
    required this.dueCards,
    required this.apprenticeCards,
    required this.guruCards,
    required this.masterCards,
    required this.enlightenedCards,
    required this.burnedCards,
    required this.dailyGoal,
    required this.todayXp,
    required this.dailyXpHistory,
  });

  factory _ProgressStats.fromRepository(DataRepository repository) {
    final now = DateTime.now();
    final cards = repository.srsCards;
    final todayKey = _dateKey(now);

    return _ProgressStats(
      lessonCount: repository.lessons.length,
      kanjiCount: repository.lessons.fold<int>(
        0,
        (total, lesson) => total + lesson.kanjis.length,
      ),
      grammarCount: repository.grammarPoints.length,
      totalCards: cards.length,
      dueCards: cards.where((card) => !card.nextReview.isAfter(now)).length,
      apprenticeCards: _countByStage(cards, '見習い'),
      guruCards: _countByStage(cards, '弟子'),
      masterCards: _countByStage(cards, '達人'),
      enlightenedCards: _countByStage(cards, '悟り'),
      burnedCards: _countByStage(cards, '燃焼'),
      dailyGoal: repository.dailyGoal,
      todayXp: repository.dailyXpHistory[todayKey] ?? 0,
      dailyXpHistory: Map<String, int>.from(repository.dailyXpHistory),
    );
  }

  double get goalPercent {
    if (dailyGoal <= 0) return 0;
    return (todayXp / dailyGoal).clamp(0.0, 1.0);
  }

  int get activeDays =>
      dailyXpHistory.values.where((xp) => xp > 0).length;

  static int _countByStage(List<dynamic> cards, String prefix) {
    return cards.where((card) => card.srsStage.startsWith(prefix)).length;
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ProgressHeader extends StatelessWidget {
  final _ProgressStats stats;

  const _ProgressHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiến độ',
              style: AppTextStyles.latin(size: 24, weight: FontWeight.w800),
            ),
            Text(
              '進捗',
              style: AppTextStyles.jp(size: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        const Spacer(),
        _IconBadge(
          icon: Icons.alarm_rounded,
          label: '${stats.dueCards}',
          color: stats.dueCards > 0 ? AppColors.vocab : AppColors.speaking,
        ),
      ],
    );
  }
}

class _HeroProgressCard extends StatelessWidget {
  final _ProgressStats stats;

  const _HeroProgressCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.resumeCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan học tập',
                  style: AppTextStyles.latin(
                    size: 18,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đang theo dõi ${stats.lessonCount} bài học, ${stats.kanjiCount} mục từ, ${stats.grammarCount} ngữ pháp và ${stats.totalCards} thẻ SRS.',
                  style: AppTextStyles.latin(
                    size: 12,
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniStat(
                      icon: Icons.local_fire_department_rounded,
                      label: '${stats.todayXp} XP hôm nay',
                    ),
                    _MiniStat(
                      icon: Icons.calendar_month_rounded,
                      label: '${stats.activeDays} ngày học',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final _ProgressStats stats;

  const _DailyGoalCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final completed = stats.todayXp >= stats.dailyGoal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: completed ? AppColors.vocab : AppColors.brandDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mục tiêu hằng ngày',
                  style: AppTextStyles.latin(
                    size: 14,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${stats.todayXp} / ${stats.dailyGoal} XP',
                style: AppTextStyles.latin(
                  size: 14,
                  weight: FontWeight.w800,
                  color: completed ? AppColors.brandDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stats.goalPercent,
              minHeight: 10,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(
                completed ? AppColors.speaking : AppColors.listening,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            completed
                ? 'Tuyệt vời! Bạn đã hoàn thành mục tiêu hôm nay.'
                : 'Cần thêm ${stats.dailyGoal - stats.todayXp} XP để đạt mục tiêu hôm nay.',
            style: AppTextStyles.latin(
              size: 11,
              color: completed ? AppColors.speaking : AppColors.textMuted,
              weight: completed ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityWeeklyChart extends StatelessWidget {
  final _ProgressStats stats;

  const _ActivityWeeklyChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final maxValue = days.fold<int>(stats.dailyGoal, (max, day) {
      final xp = stats.dailyXpHistory[_ProgressStats._dateKey(day)] ?? 0;
      return xp > max ? xp : max;
    });
    const weekdayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'XP trong tuần qua',
                style: AppTextStyles.latin(
                  size: 13,
                  color: AppColors.textMuted,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${stats.dailyGoal} XP/ngày',
                style: AppTextStyles.latin(
                  size: 11,
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in days)
                _DayBar(
                  day: day,
                  xp: stats.dailyXpHistory[_ProgressStats._dateKey(day)] ?? 0,
                  maxValue: maxValue,
                  dailyGoal: stats.dailyGoal,
                  label: weekdayLabels[day.weekday % 7],
                  isToday: _ProgressStats._dateKey(day) ==
                      _ProgressStats._dateKey(now),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final DateTime day;
  final int xp;
  final int maxValue;
  final int dailyGoal;
  final String label;
  final bool isToday;

  const _DayBar({
    required this.day,
    required this.xp,
    required this.maxValue,
    required this.dailyGoal,
    required this.label,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : xp / maxValue;
    final height = (ratio * 88).clamp(6.0, 88.0);
    final reachedGoal = xp >= dailyGoal;

    return Column(
      children: [
        SizedBox(
          height: 14,
          child: Text(
            xp > 0 ? '$xp' : '',
            style: AppTextStyles.latin(
              size: 9,
              weight: FontWeight.w800,
              color: reachedGoal ? AppColors.brandDark : AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            color: reachedGoal
                ? AppColors.listening
                : isToday
                    ? AppColors.brand.withValues(alpha: 0.35)
                    : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isToday ? AppColors.brand : Colors.transparent,
              width: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.latin(
            size: 11,
            weight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: isToday ? AppColors.brandDark : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _LearningDataTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _LearningDataTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.latin(size: 15, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.latin(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTextStyles.latin(
              size: 20,
              color: color,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SrsStageGrid extends StatelessWidget {
  final _ProgressStats stats;

  const _SrsStageGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final stages = [
      _StageData('見習い', 'Apprentice', stats.apprenticeCards,
          AppColors.srsApprentice),
      _StageData('弟子', 'Guru', stats.guruCards, AppColors.srsGuru),
      _StageData('達人', 'Master', stats.masterCards, AppColors.srsMaster),
      _StageData('悟り', 'Enlighten', stats.enlightenedCards,
          AppColors.srsEnlightened),
      _StageData('燃焼', 'Burned', stats.burnedCards, AppColors.srsBurned),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.75,
      children: [
        for (final stage in stages) _StageTile(stage: stage),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  final _StageData stage;

  const _StageTile({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: stage.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              stage.jpLabel,
              style: AppTextStyles.jp(
                size: 10,
                color: stage.color,
                weight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stage.enLabel,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.latin(
                    size: 12,
                    color: AppColors.textMuted,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stage.count}',
                  style: AppTextStyles.latin(
                    size: 18,
                    color: stage.color,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  final _ProgressStats stats;

  const _BadgesGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final badges = [
      _BadgeItem(
        title: 'Khởi hành',
        description: 'Có ít nhất 1 bài học',
        icon: Icons.explore_rounded,
        color: AppColors.listening,
        isUnlocked: stats.lessonCount >= 1,
      ),
      _BadgeItem(
        title: 'Chăm chỉ',
        description: 'Có 5 thẻ ôn tập',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.vocab,
        isUnlocked: stats.totalCards >= 5,
      ),
      _BadgeItem(
        title: 'Vượt mục tiêu',
        description: 'Đạt mục tiêu ngày',
        icon: Icons.military_tech_rounded,
        color: AppColors.kanji,
        isUnlocked: stats.todayXp >= stats.dailyGoal,
      ),
      _BadgeItem(
        title: 'Học giả',
        description: 'Có 5 mẫu ngữ pháp',
        icon: Icons.school_rounded,
        color: AppColors.reading,
        isUnlocked: stats.grammarCount >= 5,
      ),
      _BadgeItem(
        title: 'Kỷ luật',
        description: 'Học trong 2 ngày',
        icon: Icons.calendar_month_rounded,
        color: AppColors.srsGuru,
        isUnlocked: stats.activeDays >= 2,
      ),
      _BadgeItem(
        title: 'Ôn tập',
        description: 'Không còn thẻ đến hạn',
        icon: Icons.verified_rounded,
        color: AppColors.speaking,
        isUnlocked: stats.totalCards > 0 && stats.dueCards == 0,
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 10,
      childAspectRatio: 0.8,
      children: [
        for (final badge in badges) _BadgeTile(badge: badge),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final _BadgeItem badge;

  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: badge.isUnlocked
              ? AppColors.border
              : AppColors.border.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badge.isUnlocked
                  ? badge.color.withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge.icon,
              color: badge.isUnlocked ? badge.color : Colors.grey.shade400,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.latin(
              size: 12,
              weight: FontWeight.w800,
              color: badge.isUnlocked
                  ? AppColors.textPrimary
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Text(
              badge.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.latin(
                size: 9,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.latin(
                    size: 18,
                    weight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.latin(
                    size: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.latin(
              size: 11,
              color: Colors.white,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IconBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCD88A)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.latin(
              size: 17,
              weight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.sectionLabel);
  }
}

class _StageData {
  final String jpLabel;
  final String enLabel;
  final int count;
  final Color color;

  const _StageData(this.jpLabel, this.enLabel, this.count, this.color);
}

class _BadgeItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  const _BadgeItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });
}
