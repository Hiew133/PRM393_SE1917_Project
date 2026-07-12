import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../lessons/kanji_data.dart';
import '../welcome/welcome_screen.dart';

class CrudManagementScreen extends StatefulWidget {
  const CrudManagementScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CrudManagementScreen> createState() => _CrudManagementScreenState();
}

class _CrudManagementScreenState extends State<CrudManagementScreen> with SingleTickerProviderStateMixin {
  static const int _tabCount = 3;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab.clamp(0, _tabCount - 1).toInt();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureTabControllerLength();

    if (!RoleService().currentRole.value.canManageContent) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Bạn không có quyền truy cập khu vực quản lý.',
              textAlign: TextAlign.center,
              style: AppTextStyles.latin(size: 14, color: AppColors.textMuted, weight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Quản trị Hệ thống',
          style: AppTextStyles.latin(size: 20, weight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              RoleService().useGuestRole();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.brand,
          labelColor: AppColors.brand,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTextStyles.latin(size: 14, weight: FontWeight.bold),
          unselectedLabelStyle: AppTextStyles.latin(size: 14, weight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Tài khoản'),
            Tab(text: 'Bài học & Kanji'),
            Tab(text: 'Ngữ pháp'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AccountsManagerTab(),
          _LessonsManagerTab(),
          _GrammarManagerTab(),
        ],
      ),
    );
  }

  void _ensureTabControllerLength() {
    if (_tabController.length == _tabCount) return;

    final nextIndex = _tabController.index >= _tabCount ? _tabCount - 1 : _tabController.index;
    _tabController.dispose();
    _tabController = TabController(length: _tabCount, vsync: this, initialIndex: nextIndex);
  }
}

class AdminContentManagerScreen extends StatelessWidget {
  const AdminContentManagerScreen({super.key, required this.section});

  final int section;

  @override
  Widget build(BuildContext context) {
    final safeSection = section.clamp(0, 2).toInt();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(context, safeSection),
            Expanded(child: _body(safeSection)),
          ],
        ),
      ),
    );
  }

  Widget _body(int section) {
    return switch (section) {
      0 => const _AccountsManagerTab(),
      1 => const _LessonsManagerTab(),
      _ => const _GrammarManagerTab(),
    };
  }

  Widget _header(BuildContext context, int section) {
    final meta = switch (section) {
      0 => (
          title: 'Quản lý tài khoản',
          jp: '人',
          subtitle: 'Phân quyền admin/customer',
          color: AppColors.brandDark,
        ),
      1 => (
          title: 'Quản lý Kanji',
          jp: '漢字',
          subtitle: 'Bài học và danh sách Kanji',
          color: AppColors.vocab,
        ),
      _ => (
          title: 'Quản lý ngữ pháp',
          jp: '文法',
          subtitle: 'Mẫu câu, ghi chú và ví dụ',
          color: AppColors.reading,
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        meta.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.latin(
                          size: 20,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meta.jp,
                      style: AppTextStyles.jp(size: 18, color: meta.color),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'ADMIN',
                        style: AppTextStyles.latin(
                          size: 9,
                          weight: FontWeight.w800,
                          color: const Color(0xFFF7C547),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  meta.subtitle,
                  style: AppTextStyles.latin(
                    size: 12,
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

class _AccountsManagerTab extends StatelessWidget {
  const _AccountsManagerTab();

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  Future<void> _updateRole(String userId, AppRole role) {
    return _firestore.collection('users').doc(userId).set({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _toggleLock(String userId, bool currentLockStatus) {
    return _firestore.collection('users').doc(userId).set({
      'isLocked': !currentLockStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('users').limit(100).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brand));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tải được tài khoản từ Firebase:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.latin(
                    size: 13,
                    color: AppColors.textMuted,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }
          final users = snapshot.data?.docs ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('Chưa có tài khoản nào.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data();
              final email = data['email'] as String? ?? 'Không có email';
              final role = _roleFromString(data['role'] as String?);
              final isLocked = data['isLocked'] as bool? ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isLocked ? Colors.red.shade100 : AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isLocked ? AppColors.surfaceAlt.withOpacity(0.5) : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLocked ? Colors.red.shade200 : const Color(0xFFFCD88A),
                        ),
                      ),
                      child: Icon(
                        role == AppRole.admin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                        color: isLocked
                            ? Colors.red.shade300
                            : (role == AppRole.admin ? AppColors.kanji : AppColors.brandDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  email,
                                  style: AppTextStyles.latin(
                                    size: 14,
                                    weight: FontWeight.bold,
                                    color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLocked) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.shade100),
                                  ),
                                  child: Text(
                                    'ĐÃ KHÓA',
                                    style: AppTextStyles.latin(
                                      size: 8,
                                      weight: FontWeight.w800,
                                      color: Colors.red.shade700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(doc.id, style: AppTextStyles.latin(size: 11, color: AppColors.textFaint)),
                        ],
                      ),
                    ),
                    DropdownButton<AppRole>(
                      value: role,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: AppRole.customer, child: Text('Customer')),
                        DropdownMenuItem(value: AppRole.admin, child: Text('Admin')),
                      ],
                      onChanged: (nextRole) {
                        if (nextRole != null) _updateRole(doc.id, nextRole);
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        isLocked ? Icons.lock : Icons.lock_open,
                        color: isLocked ? Colors.red : Colors.green,
                      ),
                      tooltip: isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
                      onPressed: () => _toggleLock(doc.id, isLocked),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  AppRole _roleFromString(String? role) {
    switch (role) {
      case 'admin':
        return AppRole.admin;
      default:
        return AppRole.customer;
    }
  }
}

// ── TAB 1: QUẢN LÝ BÀI HỌC ──────────────────────────────────────────────────
class _LessonsManagerTab extends StatelessWidget {
  const _LessonsManagerTab();

  void _showLessonDialog(BuildContext context, {LessonData? lesson, int? index}) {
    final titleController = TextEditingController(text: lesson?.title ?? '');
    final jpTitleController = TextEditingController(text: lesson?.jpTitle ?? '');
    final descController = TextEditingController(text: lesson?.description ?? '');
    List<KanjiData> kanjisList = lesson != null ? List.from(lesson.kanjis) : [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: AppColors.surface,
              title: Text(
                lesson == null ? 'Thêm Bài Học Mới' : 'Sửa Bài Học',
                style: AppTextStyles.latin(size: 18, weight: FontWeight.bold),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(titleController, 'Tiêu đề tiếng Việt', 'Ví dụ: Hán tự bài 1...'),
                      const SizedBox(height: 12),
                      _buildTextField(jpTitleController, 'Tiêu đề tiếng Nhật', 'Ví dụ: 漢字 第1課...'),
                      const SizedBox(height: 12),
                      _buildTextField(descController, 'Mô tả bài học', 'Ví dụ: Học các chữ Kanji/chữ Hán cơ bản...', maxLines: 2),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kanji trong bài (${kanjisList.length})',
                            style: AppTextStyles.latin(size: 14, weight: FontWeight.bold, color: AppColors.brandDark),
                          ),
                          TextButton.icon(
                            onPressed: () => _showKanjiDialog(context, onSave: (newKanji) {
                              setDialogState(() {
                                kanjisList.add(newKanji);
                              });
                            }),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Thêm Kanji'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (kanjisList.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          alignment: Alignment.center,
                          child: Text(
                            'Chưa có Kanji nào trong bài học này.',
                            style: AppTextStyles.latin(size: 12, color: AppColors.textMuted),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: kanjisList.length,
                          itemBuilder: (context, kIdx) {
                            final k = kanjisList[kIdx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              elevation: 0,
                              color: AppColors.surfaceAlt,
                              child: ListTile(
                                dense: true,
                                title: Text('${k.character} (${k.hanViet})', style: AppTextStyles.jp(size: 13, weight: FontWeight.bold)),
                                subtitle: Text(k.meaning, style: AppTextStyles.latin(size: 11, color: AppColors.textSecondary)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                  onPressed: () {
                                    setDialogState(() {
                                      kanjisList.removeAt(kIdx);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy', style: AppTextStyles.latin(size: 14, color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final newLesson = LessonData(
                      title: titleController.text.trim(),
                      jpTitle: jpTitleController.text.trim(),
                      description: descController.text.trim(),
                      kanjis: kanjisList,
                    );
                    try {
                      if (lesson == null) {
                        await DataRepository().addLesson(newLesson);
                      } else {
                        await DataRepository().updateLesson(index!, newLesson, lesson.title);
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Không lưu được lên Firebase: $e')),
                      );
                    }
                  },
                  child: Text('Lưu', style: AppTextStyles.latin(size: 14, weight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showKanjiDialog(BuildContext context, {required Function(KanjiData) onSave}) {
    final charController = TextEditingController();
    final hanVietController = TextEditingController();
    final onyomiController = TextEditingController();
    final kunyomiController = TextEditingController();
    final meaningController = TextEditingController();
    final exampleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surface,
          title: const Text('Thêm Kanji vào bài học'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(charController, 'Chữ Kanji / Hán tự', 'Ví dụ: 私'),
                const SizedBox(height: 10),
                _buildTextField(hanVietController, 'Âm Hán Việt', 'Ví dụ: TƯ'),
                const SizedBox(height: 10),
                _buildTextField(onyomiController, 'Onyomi (Âm ôn)', 'Ví dụ: し'),
                const SizedBox(height: 10),
                _buildTextField(kunyomiController, 'Kunyomi (Âm huấn)', 'Ví dụ: わたし'),
                const SizedBox(height: 10),
                _buildTextField(meaningController, 'Ý nghĩa', 'Ví dụ: Tôi, bản thân'),
                const SizedBox(height: 10),
                _buildTextField(exampleController, 'Ví dụ (Cách nhau bởi dấu xuống dòng)', 'Ví dụ:\n私 (わたし): Tôi\n私立 (しりつ): Tư nhân', maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (charController.text.trim().isEmpty) return;
                final lines = exampleController.text.split('\n').where((line) => line.trim().isNotEmpty).toList();
                final kanji = KanjiData(
                  character: charController.text.trim(),
                  hanViet: hanVietController.text.trim(),
                  onyomi: onyomiController.text.trim(),
                  kunyomi: kunyomiController.text.trim(),
                  meaning: meaningController.text.trim(),
                  examples: lines,
                  strokes: const [
                    KanjiStroke(points: [Offset(0.2, 0.5), Offset(0.8, 0.5)]), // Default horizontal stroke
                  ],
                );
                onSave(kanji);
                Navigator.pop(context);
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surfaceAlt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder<List<LessonData>>(
        valueListenable: DataRepository().lessonsNotifier,
        builder: (context, lessons, child) {
          if (lessons.isEmpty) {
            return const Center(child: Text('Danh sách bài học trống.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lesson.title, style: AppTextStyles.latin(size: 15, weight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(lesson.jpTitle, style: AppTextStyles.jp(size: 13, color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          Text('${lesson.kanjis.length} Kanji trong bài', style: AppTextStyles.latin(size: 12, color: AppColors.brand)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.brand),
                      onPressed: () => _showLessonDialog(context, lesson: lesson, index: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, () {
                        DataRepository().deleteLesson(index, lesson.title);
                      }),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLessonDialog(context),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm bài học'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa bài học này không? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                onDelete();
                Navigator.pop(context);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class _GrammarManagerTab extends StatelessWidget {
  const _GrammarManagerTab();

  void _showGrammarDialog(BuildContext context, {GrammarPoint? grammarPoint, int? index}) {
    final titleController = TextEditingController(text: grammarPoint?.title ?? '');
    final subTitleController = TextEditingController(text: grammarPoint?.subTitle ?? '');
    final patternController = TextEditingController(text: grammarPoint?.pattern ?? '');
    final noteController = TextEditingController(text: grammarPoint?.note ?? '');
    final examplesController = TextEditingController(
      text: grammarPoint?.examples.map((example) => '${example.exampleJa} | ${example.exampleVi}').join('\n') ?? '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.surface,
          title: Text(
            grammarPoint == null ? 'Thêm ngữ pháp mới' : 'Sửa ngữ pháp',
            style: AppTextStyles.latin(size: 18, weight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(titleController, 'Tiêu đề', 'Ví dụ: A は B です'),
                  const SizedBox(height: 10),
                  _buildTextField(subTitleController, 'Mô tả ngắn', 'Ví dụ: Câu khẳng định với danh từ'),
                  const SizedBox(height: 10),
                  _buildTextField(patternController, 'Mẫu câu', 'Ví dụ: A は B です'),
                  const SizedBox(height: 10),
                  _buildTextField(noteController, 'Ghi chú', 'Giải thích cách dùng...', maxLines: 3),
                  const SizedBox(height: 10),
                  _buildTextField(
                    examplesController,
                    'Ví dụ',
                    'Mỗi dòng: câu tiếng Nhật | nghĩa tiếng Việt',
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: AppTextStyles.latin(size: 14, color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final examples = examplesController.text
                    .split('\n')
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty)
                    .map((line) {
                  final parts = line.split('|');
                  return GrammarExample(
                    exampleJa: parts.first.trim(),
                    exampleVi: parts.length > 1 ? parts.sublist(1).join('|').trim() : '',
                  );
                }).toList();
                final nextGrammarPoint = GrammarPoint(
                  title: titleController.text.trim(),
                  subTitle: subTitleController.text.trim(),
                  pattern: patternController.text.trim(),
                  note: noteController.text.trim(),
                  examples: examples,
                );
                try {
                  if (grammarPoint == null) {
                    await DataRepository().addGrammarPoint(nextGrammarPoint);
                  } else {
                    await DataRepository().updateGrammarPoint(index!, nextGrammarPoint, grammarPoint.title);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không lưu được lên Firebase: $e')),
                  );
                }
              },
              child: Text('Lưu', style: AppTextStyles.latin(size: 14, weight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surfaceAlt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder<List<GrammarPoint>>(
        valueListenable: DataRepository().grammarPointsNotifier,
        builder: (context, grammarPoints, child) {
          if (grammarPoints.isEmpty) {
            return const Center(child: Text('Danh sách ngữ pháp trống.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grammarPoints.length,
            itemBuilder: (context, index) {
              final grammarPoint = grammarPoints[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(grammarPoint.title, style: AppTextStyles.latin(size: 15, weight: FontWeight.bold, color: AppColors.kanji)),
                          const SizedBox(height: 4),
                          Text(grammarPoint.subTitle, style: AppTextStyles.latin(size: 13, color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          Text(grammarPoint.pattern, style: AppTextStyles.latin(size: 12, color: AppColors.textPrimary, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.brand),
                      onPressed: () => _showGrammarDialog(context, grammarPoint: grammarPoint, index: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => DataRepository().deleteGrammarPoint(index, grammarPoint.title),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGrammarDialog(context),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm ngữ pháp'),
      ),
    );
  }
}
