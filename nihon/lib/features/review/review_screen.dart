import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_config.dart';
import '../../core/widgets/guest_lock_dialog.dart';
import '../home/main_navigation.dart';
import 'vocabulary_review_screen.dart';

/// Màn "Ôn tập" – cho phép chọn Giáo trình và Bài học trước khi ôn.
/// Hỗ trợ chế độ Admin với các chức năng CRUD được liên kết trực tiếp với Firebase Firestore.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String _selectedBook = 'Nhật 1';
  List<String> _books = ['Nhật 1', 'Nhật 2'];
  Map<String, dynamic> _booksMetadata = {
    'Nhật 1': {'title': 'Nhật 1', 'desc': 'N5 - N4 (Cơ bản)'},
    'Nhật 2': {'title': 'Nhật 2', 'desc': 'N5 - N4 (Trung cấp)'},
  };
  Map<String, List<int>> _bookLessons = {};

  // Cấu hình giao diện lấy từ Firestore
  String _screenTitle = 'Luyện Tập Từ Vựng';
  Map<String, String> _lessonTitles = {};
  bool _isLoadingSettings = true;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Tải cấu hình tiêu đề và mô tả giáo trình từ Firestore settings/review_screen
  Future<void> _loadSettings() async {
    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );
      DocumentSnapshot doc = await firestore
          .collection('settings')
          .doc('review_screen')
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            _screenTitle =
                data['screenTitle'] as String? ?? 'Luyện Tập Từ Vựng';

            if (data['books'] != null) {
              _books = List<String>.from(data['books']);
            } else {
              _books = ['Nhật 1', 'Nhật 2'];
            }

            if (data['booksMetadata'] != null) {
              _booksMetadata = Map<String, dynamic>.from(data['booksMetadata']);
              if (_booksMetadata['Nhật 2'] != null &&
                  _booksMetadata['Nhật 2']['desc'] == 'N3 - N2 (Trung cấp)') {
                _booksMetadata['Nhật 2']['desc'] = 'N5 - N4 (Trung cấp)';
                firestore.collection('settings').doc('review_screen').update({
                  'booksMetadata': _booksMetadata,
                }).catchError((e) => print("Lỗi khi tự động cập nhật mô tả Nhật 2: $e"));
              }
            } else {
              // Hỗ trợ tương thích ngược
              _booksMetadata = {
                'Nhật 1': {
                  'title': data['nhat1Title'] as String? ?? 'Nhật 1',
                  'desc': data['nhat1Desc'] as String? ?? 'N5 - N4 (Cơ bản)',
                },
                'Nhật 2': {
                  'title': data['nhat2Title'] as String? ?? 'Nhật 2',
                  'desc': data['nhat2Desc'] as String? ?? 'N5 - N4 (Trung cấp)',
                },
              };
            }

            if (data['lessons'] != null) {
              final Map<String, dynamic> rawLessons =
                  data['lessons'] as Map<String, dynamic>;
              _bookLessons = rawLessons.map((key, value) {
                return MapEntry(key, List<int>.from(value as List));
              });
            } else {
              _bookLessons = {};
            }

            if (data['lessonTitles'] != null) {
              _lessonTitles = Map<String, String>.from(data['lessonTitles']);
            } else {
              _lessonTitles = {};
            }
          });
        }
      } else {
        // Khởi tạo mặc định nếu chưa tồn tại
        await firestore.collection('settings').doc('review_screen').set({
          'screenTitle': 'Luyện Tập Từ Vựng',
          'books': ['Nhật 1', 'Nhật 2'],
          'booksMetadata': {
            'Nhật 1': {'title': 'Nhật 1', 'desc': 'N5 - N4 (Cơ bản)'},
            'Nhật 2': {'title': 'Nhật 2', 'desc': 'N5 - N4 (Trung cấp)'},
          },
          'lessons': {},
          'lessonTitles': {},
        });
      }
    } catch (e) {
      print("Lỗi khi tải cấu hình settings: $e");
    } finally {
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  /// Cập nhật cấu hình settings lên Firestore
  Future<void> _updateSettings({String? screenTitle}) async {
    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );
      final updateData = <String, dynamic>{};
      if (screenTitle != null) updateData['screenTitle'] = screenTitle;

      await firestore
          .collection('settings')
          .doc('review_screen')
          .update(updateData);
      await _loadSettings();
    } catch (e) {
      print("Lỗi khi cập nhật cấu hình: $e");
    }
  }

  /// Cập nhật tiêu đề tùy chỉnh của bài học lên Firestore
  Future<void> _updateLessonTitle(int lessonNumber, String newTitle) async {
    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );
      final key = "${_selectedBook}_$lessonNumber";
      _lessonTitles[key] = newTitle;

      await firestore.collection('settings').doc('review_screen').update({
        'lessonTitles': _lessonTitles,
      });
      await _loadSettings();
    } catch (e) {
      print("Lỗi khi cập nhật tiêu đề bài học: $e");
    }
  }

  /// Hộp thoại sửa tiêu đề bài học
  void _showEditLessonTitleDialog(
    int lessonNumber,
    String currentTitle,
    StateSetter dialogSetState,
  ) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sửa Tiêu Đề Bài Học',
          style: TextStyle(fontFamily: 'Lexend',fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Tiêu đề bài học',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vocab,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _updateLessonTitle(lessonNumber, controller.text.trim());
                dialogSetState(() {}); // Vẽ lại dialog chính
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Lấy danh sách các bài học hiện có của giáo trình được chọn từ settings hoặc quét cơ sở dữ liệu
  Future<List<int>> _getAvailableLessons(String book) async {
    // 1. Nếu đã có danh sách bài học lưu trong settings doc, trả về ngay lập tức!
    if (_bookLessons.containsKey(book)) {
      final list = _bookLessons[book] ?? [];
      list.sort();
      return list;
    }

    // 2. Nếu chưa có, ta quét từ bộ sưu tập 'vocabulary' một lần để khởi tạo
    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

      final QuerySnapshot snapshot = await firestore
          .collection('vocabulary')
          .where('book', isEqualTo: book)
          .get();

      final Set<int> uniqueLessons = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['lesson'] != null) {
          uniqueLessons.add(data['lesson'] as int);
        }
      }

      final List<int> sortedLessons = uniqueLessons.toList();
      sortedLessons.sort();

      // Cập nhật lại vào Firestore settings để dùng cho lần sau
      setState(() {
        _bookLessons[book] = sortedLessons;
      });
      await firestore.collection('settings').doc('review_screen').update({
        'lessons': _bookLessons,
      });

      return sortedLessons;
    } catch (e) {
      print("Lỗi khi tải bài học dự phòng: $e");
      return [];
    }
  }

  /// Hộp thoại thêm giáo trình mới ở chế độ Admin
  void _showAddBookDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Thêm Giáo Trình Mới',
          style: TextStyle(fontFamily: 'Lexend',fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Tên giáo trình (Ví dụ: Nhật 3)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mô tả (Ví dụ: N1 - Cao cấp)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vocab,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng điền đầy đủ Tên giáo trình!'),
                  ),
                );
                return;
              }

              if (_books.contains(name)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Giáo trình này đã tồn tại!')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final updatedBooks = List<String>.from(_books)..add(name);
                final updatedMeta = Map<String, dynamic>.from(_booksMetadata);
                updatedMeta[name] = {'title': name, 'desc': desc};

                final firestore = FirebaseFirestore.instanceFor(
                  app: Firebase.app(),
                  databaseId: 'default',
                );

                await firestore.collection('settings').doc('review_screen').set(
                  {'books': updatedBooks, 'booksMetadata': updatedMeta},
                  SetOptions(merge: true),
                );

                await _loadSettings();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm giáo trình "$name" thành công!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi thêm giáo trình: $e')),
                  );
                }
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại thêm bài học mới ở chế độ Admin (không cần nhập từ vựng trước)
  void _showAddLessonDialog() {
    final lessonController = TextEditingController();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Thêm Bài Học Mới',
          style: TextStyle(fontFamily: 'Lexend',fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: lessonController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Bài số (Ví dụ: 1, 2, 3...)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Tiêu đề bài học (Ví dụ: Chào hỏi - Tùy chọn)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vocab,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final lessonStr = lessonController.text.trim();
              final lesson = int.tryParse(lessonStr);

              if (lesson == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập số bài hợp lệ!')),
                );
                return;
              }

              final currentLessons = List<int>.from(
                _bookLessons[_selectedBook] ?? [],
              );
              if (currentLessons.contains(lesson)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bài học này đã tồn tại!')),
                );
                return;
              }

              Navigator.pop(context);

              currentLessons.add(lesson);
              currentLessons.sort();
              _bookLessons[_selectedBook] = currentLessons;

              final firestore = FirebaseFirestore.instanceFor(
                app: Firebase.app(),
                databaseId: 'default',
              );

              final Map<String, dynamic> updateData = {'lessons': _bookLessons};

              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final key = "${_selectedBook}_$lesson";
                _lessonTitles[key] = title;
                updateData['lessonTitles'] = _lessonTitles;
              }

              await firestore
                  .collection('settings')
                  .doc('review_screen')
                  .update(updateData);
              await _loadSettings();
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại sửa tên và mô tả giáo trình
  void _showEditBookDialog(String bookKey) {
    final metadata = _booksMetadata[bookKey] as Map<String, dynamic>? ?? {};
    final titleController = TextEditingController(
      text: metadata['title'] ?? bookKey,
    );
    final descController = TextEditingController(text: metadata['desc'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sửa Giáo Trình',
          style: TextStyle(fontFamily: 'Lexend',fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Tên hiển thị',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mô tả',
              ),
            ),
          ],
        ),
        actions: [
          if (_books.length > 1)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xóa giáo trình?'),
                    content: Text(
                      'Bạn có chắc chắn muốn xóa giáo trình "$bookKey" cùng toàn bộ từ vựng thuộc giáo trình này?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  Navigator.pop(context); // Đóng Dialog sửa giáo trình

                  try {
                    final updatedBooks = List<String>.from(_books)
                      ..remove(bookKey);
                    final updatedMeta = Map<String, dynamic>.from(
                      _booksMetadata,
                    )..remove(bookKey);
                    final updatedLessons = Map<String, dynamic>.from(
                      _bookLessons,
                    )..remove(bookKey);

                    final firestore = FirebaseFirestore.instanceFor(
                      app: Firebase.app(),
                      databaseId: 'default',
                    );

                    await firestore
                        .collection('settings')
                        .doc('review_screen')
                        .set({
                          'books': updatedBooks,
                          'booksMetadata': updatedMeta,
                          'lessons': updatedLessons,
                        }, SetOptions(merge: true));

                    // Xóa tất cả từ vựng thuộc sách này
                    final QuerySnapshot vocabDocs = await firestore
                        .collection('vocabulary')
                        .where('book', isEqualTo: bookKey)
                        .get();

                    final batch = firestore.batch();
                    for (final doc in vocabDocs.docs) {
                      batch.delete(doc.reference);
                    }
                    await batch.commit();

                    setState(() {
                      _selectedBook = updatedBooks.first;
                    });
                    await _loadSettings();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã xóa giáo trình "$bookKey" thành công!',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi xóa giáo trình: $e')),
                      );
                    }
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text(
                'Xóa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vocab,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final newTitle = titleController.text.trim();
              final newDesc = descController.text.trim();
              if (newTitle.isNotEmpty) {
                Navigator.pop(context);

                try {
                  final updatedMeta = Map<String, dynamic>.from(_booksMetadata);
                  updatedMeta[bookKey] = {'title': newTitle, 'desc': newDesc};

                  final firestore = FirebaseFirestore.instanceFor(
                    app: Firebase.app(),
                    databaseId: 'default',
                  );

                  await firestore
                      .collection('settings')
                      .doc('review_screen')
                      .set({
                        'booksMetadata': updatedMeta,
                      }, SetOptions(merge: true));

                  await _loadSettings();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã cập nhật giáo trình thành công!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi cập nhật giáo trình: $e'),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại sửa tiêu đề màn hình
  void _showEditScreenTitleDialog() {
    final controller = TextEditingController(text: _screenTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sửa Tiêu Đề',
          style: TextStyle(fontFamily: 'Lexend',fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Tiêu đề màn hình',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vocab,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _updateSettings(screenTitle: controller.text.trim());
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại thêm/sửa từ vựng
  void _showAddEditWordDialog({
    Map<String, dynamic>? initialWordData,
    String? prefilledBook,
    int? prefilledLesson,
  }) {
    final jpController = TextEditingController(
      text: initialWordData?['jp'] ?? '',
    );
    final readingController = TextEditingController(
      text: initialWordData?['reading'] ?? '',
    );
    final viController = TextEditingController(
      text: initialWordData?['vi'] ?? '',
    );
    final lessonController = TextEditingController(
      text: initialWordData != null
          ? initialWordData['lesson'].toString()
          : (prefilledLesson?.toString() ?? ''),
    );

    String selectedBookForWord =
        initialWordData?['book'] ?? (prefilledBook ?? _selectedBook);
    final isNew = initialWordData == null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isNew ? 'Thêm Từ Vựng Mới' : 'Sửa Từ Vựng',
            style: TextStyle(fontFamily: 'Lexend',fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNew && prefilledBook == null) ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedBookForWord,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Giáo trình',
                    ),
                    items: _books.map((book) {
                      final metadata =
                          _booksMetadata[book] as Map<String, dynamic>? ?? {};
                      final title = metadata['title'] ?? book;
                      return DropdownMenuItem<String>(
                        value: book,
                        child: Text(title),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedBookForWord = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: lessonController,
                  keyboardType: TextInputType.number,
                  enabled: isNew && prefilledLesson == null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Bài số (Ví dụ: 1, 2, 3...)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jpController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Từ vựng (Kanji / Kana)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: readingController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Cách đọc (Hiragana / Katakana - Tùy chọn)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: viController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Ý nghĩa (Tiếng Việt)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vocab,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final jp = jpController.text.trim();
                final reading = readingController.text.trim();
                final vi = viController.text.trim();
                final lessonStr = lessonController.text.trim();
                final lesson = int.tryParse(lessonStr);

                if (jp.isEmpty || vi.isEmpty || lesson == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin hợp lệ!'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  final firestore = FirebaseFirestore.instanceFor(
                    app: Firebase.app(),
                    databaseId: 'default',
                  );

                  if (isNew) {
                    final Map<String, dynamic> data = {
                      'book': selectedBookForWord,
                      'lesson': lesson,
                      'jp': jp,
                      'vi': vi,
                      'createdAt': FieldValue.serverTimestamp(),
                    };
                    if (reading.isNotEmpty) {
                      data['reading'] = reading;
                    }
                    await firestore.collection('vocabulary').add(data);

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Đã thêm từ mới vào Bài $lesson!'),
                      ),
                    );
                  } else {
                    final docId = initialWordData['id'] as String;
                    final Map<String, dynamic> data = {'jp': jp, 'vi': vi};
                    if (reading.isNotEmpty) {
                      data['reading'] = reading;
                    } else {
                      data['reading'] = FieldValue.delete();
                    }
                    await firestore
                        .collection('vocabulary')
                        .doc(docId)
                        .update(data);

                    messenger.showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật từ vựng!')),
                    );
                  }

                  setState(() {});
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Hộp thoại hiển thị và quản lý danh sách từ vựng thuộc Bài học (CRUD)
  void _showManageVocabularyDialog(int lessonNumber) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final firestore = FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'default',
          );

          return StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('vocabulary')
                .where('book', isEqualTo: _selectedBook)
                .where('lesson', isEqualTo: lessonNumber)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AlertDialog(
                  content: SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.vocab),
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              final key = "${_selectedBook}_$lessonNumber";
              final currentTitle =
                  _lessonTitles[key] ?? 'Từ vựng Bài $lessonNumber';

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _showEditLessonTitleDialog(
                            lessonNumber,
                            currentTitle,
                            setDialogState,
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                currentTitle,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: 'Lexend',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.vocab,
                      ),
                      onPressed: () {
                        _showAddEditWordDialog(
                          prefilledBook: _selectedBook,
                          prefilledLesson: lessonNumber,
                        );
                      },
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 350,
                  child: docs.isEmpty
                      ? const Center(
                          child: Text('Không có từ vựng nào trong bài này.'),
                        )
                      : ScrollConfiguration(
                          behavior: ScrollConfiguration.of(
                            context,
                          ).copyWith(scrollbars: false),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: docs.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final jp = data['jp'] as String? ?? '';
                              final vi = data['vi'] as String? ?? '';
                              final reading = data['reading'] as String? ?? '';

                              return ListTile(
                                contentPadding: const EdgeInsets.only(
                                  right: 8,
                                ), // Thêm khoảng đệm bên phải để tránh sát viền
                                title: Text(
                                  jp,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  reading.isNotEmpty ? '$reading • $vi' : vi,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        final wordData =
                                            Map<String, dynamic>.from(data);
                                        wordData['id'] = doc.id;
                                        _showAddEditWordDialog(
                                          initialWordData: wordData,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Xác nhận xóa'),
                                            content: Text(
                                              'Bạn có chắc muốn xóa từ "$jp" không?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Hủy'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text(
                                                  'Xóa',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await firestore
                                              .collection('vocabulary')
                                              .doc(doc.id)
                                              .delete();
                                          setDialogState(() {});
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xóa bài học?'),
                          content: Text(
                            'Bạn có chắc chắn muốn xóa Bài $lessonNumber cùng toàn bộ từ vựng trong bài này?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        Navigator.pop(context); // Đóng Dialog quản lý từ vựng

                        try {
                          final firestore = FirebaseFirestore.instanceFor(
                            app: Firebase.app(),
                            databaseId: 'default',
                          );

                          // 1. Cập nhật danh sách bài học của giáo trình
                          final List<int> updatedLessons = List<int>.from(
                            _bookLessons[_selectedBook] ?? [],
                          )..remove(lessonNumber);
                          final Map<String, dynamic> newLessonsMap =
                              Map<String, dynamic>.from(_bookLessons);
                          newLessonsMap[_selectedBook] = updatedLessons;

                          // 2. Xóa tiêu đề bài học nếu có
                          final Map<String, dynamic> newLessonTitles =
                              Map<String, dynamic>.from(_lessonTitles);
                          newLessonTitles.remove(
                            "${_selectedBook}_$lessonNumber",
                          );

                          await firestore
                              .collection('settings')
                              .doc('review_screen')
                              .set({
                                'lessons': newLessonsMap,
                                'lessonTitles': newLessonTitles,
                              }, SetOptions(merge: true));

                          // 3. Xóa toàn bộ từ vựng thuộc giáo trình này và bài học này
                          final vocabDocs = await firestore
                              .collection('vocabulary')
                              .where('book', isEqualTo: _selectedBook)
                              .where('lesson', isEqualTo: lessonNumber)
                              .get();

                          final batch = firestore.batch();
                          for (final doc in vocabDocs.docs) {
                            batch.delete(doc.reference);
                          }
                          await batch.commit();

                          await _loadSettings();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã xóa Bài $lessonNumber thành công!',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi khi xóa bài học: $e'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text(
                      'Xóa bài học',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('Đóng'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.vocab)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề có thể click đổi tên ở chế độ Admin, hoặc bấm 5 lần để kích hoạt Admin
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        // Trong tab chính: về Trang chủ. Khi được push riêng
                        // (vd. từ trang Admin): pop về màn trước.
                        final nav = context
                            .findAncestorStateOfType<MainNavigationState>();
                        if (nav != null) {
                          nav.goToTab(0);
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x05000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: AppConfig.isAdmin,
                    builder: (context, isAdmin, child) {
                      return Padding(
                        // Chừa chỗ cho nút back bên trái (và cân đối bên
                        // phải) để tiêu đề dài không đè lên nút.
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  if (isAdmin) {
                                    _showEditScreenTitleDialog();
                                  } else {
                                    setState(() {
                                      _tapCount++;
                                    });
                                    if (_tapCount >= 5) {
                                      _tapCount = 0;
                                      AppConfig.isAdmin.value = true;
                                    }
                                  }
                                },
                                child: Text(
                                  _screenTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: 'Lexend',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: AppColors.vocab,
                                ),
                                onPressed: _showEditScreenTitleDialog,
                              ),
                              const SizedBox(width: 8),
                              // Nút để tắt nhanh chế độ admin
                              GestureDetector(
                                onTap: () {
                                  AppConfig.isAdmin.value = false;
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Tắt Admin',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Phần Chọn Giáo trình
              Text('CHỌN GIÁO TRÌNH', style: AppTextStyles.overline),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._books.map((book) {
                    final isSelected = _selectedBook == book;
                    final metadata =
                        _booksMetadata[book] as Map<String, dynamic>? ?? {};
                    final displayDesc = metadata['desc'] ?? '';
                    final double cardWidth =
                        (MediaQuery.of(context).size.width - 52) / 2;
                    // Khách chỉ được học thử giáo trình đầu tiên.
                    final isGuest =
                        RoleService().currentRole.value == AppRole.guest;
                    final isBookLocked =
                        isGuest && _books.isNotEmpty && book != _books.first;
                    final displayTitle =
                        '${metadata['title'] ?? book}${isBookLocked ? ' 🔒' : ''}';

                    return SizedBox(
                      width: cardWidth,
                      child: GestureDetector(
                        onTap: () {
                          if (isBookLocked) {
                            showGuestLockDialog(context);
                            return;
                          }
                          setState(() {
                            _selectedBook = book;
                          });
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.vocab
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.vocab
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.vocab.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : [
                                        const BoxShadow(
                                          color: Color(0x052D1F0E),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    displayTitle,
                                    style: AppTextStyles.latin(
                                      size: 16,
                                      weight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    displayDesc,
                                    style: AppTextStyles.latin(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white70
                                          : AppColors.textFaint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Biểu tượng chỉnh sửa giáo trình ở chế độ Admin
                            ValueListenableBuilder<bool>(
                              valueListenable: AppConfig.isAdmin,
                              builder: (context, isAdmin, child) {
                                if (!isAdmin) return const SizedBox.shrink();
                                return Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _showEditBookDialog(book),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Nút thêm giáo trình mới ở chế độ Admin
                  ValueListenableBuilder<bool>(
                    valueListenable: AppConfig.isAdmin,
                    builder: (context, isAdmin, child) {
                      if (!isAdmin) return const SizedBox.shrink();
                      final double cardWidth =
                          (MediaQuery.of(context).size.width - 52) / 2;
                      return SizedBox(
                        width: cardWidth,
                        child: GestureDetector(
                          onTap: _showAddBookDialog,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add,
                                  color: AppColors.vocab,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Thêm giáo trình',
                                  style: AppTextStyles.latin(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: AppColors.vocab,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Phần Chọn Bài học
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CHỌN BÀI HỌC', style: AppTextStyles.overline),
                  ValueListenableBuilder<bool>(
                    valueListenable: AppConfig.isAdmin,
                    builder: (context, isAdmin, child) {
                      if (!isAdmin) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () {
                          _showAddLessonDialog();
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              size: 16,
                              color: AppColors.vocab,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Thêm bài mới',
                              style: AppTextStyles.latin(
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppColors.vocab,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<int>>(
                  future: _getAvailableLessons(_selectedBook),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.vocab,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Lỗi tải danh sách bài học: ${snapshot.error}',
                          style: AppTextStyles.latin(color: Colors.red),
                        ),
                      );
                    }

                    final availableLessons = snapshot.data ?? [];

                    if (availableLessons.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'Không có bài học nào của $_selectedBook trên Firebase.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.latin(
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: availableLessons.length,
                      itemBuilder: (context, index) {
                        final lessonNumber = availableLessons[index];
                        // Khách chỉ được ôn thử bài đầu tiên của giáo trình đầu.
                        final isGuest = RoleService().currentRole.value ==
                            AppRole.guest;
                        final isLessonLocked = isGuest &&
                            (index > 0 ||
                                (_books.isNotEmpty &&
                                    _selectedBook != _books.first));
                        return ValueListenableBuilder<bool>(
                          valueListenable: AppConfig.isAdmin,
                          builder: (context, isAdmin, child) {
                            return GestureDetector(
                              onTap: () async {
                                if (isLessonLocked) {
                                  showGuestLockDialog(context);
                                  return;
                                }
                                if (isAdmin) {
                                  final firestore =
                                      FirebaseFirestore.instanceFor(
                                        app: Firebase.app(),
                                        databaseId: 'default',
                                      );
                                  final QuerySnapshot
                                  checkSnapshot = await firestore
                                      .collection('vocabulary')
                                      .where('book', isEqualTo: _selectedBook)
                                      .where('lesson', isEqualTo: lessonNumber)
                                      .limit(1)
                                      .get();

                                  if (!context.mounted) return;

                                  if (checkSnapshot.docs.isEmpty) {
                                    _showManageVocabularyDialog(lessonNumber);
                                    return;
                                  }
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VocabularyReviewScreen(
                                          book: _selectedBook,
                                          lesson: lessonNumber,
                                        ),
                                  ),
                                ).then((_) {
                                  setState(() {});
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isLessonLocked
                                      ? AppColors.surface.withValues(alpha: 0.7)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x032D1F0E),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            (_lessonTitles["${_selectedBook}_$lessonNumber"] ??
                                                    'Bài $lessonNumber') +
                                                (isLessonLocked ? ' 🔒' : ''),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.latin(
                                              size:
                                                  _lessonTitles.containsKey(
                                                    "${_selectedBook}_$lessonNumber",
                                                  )
                                                  ? 13
                                                  : 15,
                                              weight: FontWeight.w700,
                                              color: isLessonLocked
                                                  ? AppColors.textMuted
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isLessonLocked
                                                  ? Colors.grey.withValues(
                                                      alpha: 0.15)
                                                  : AppColors.speaking
                                                      .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isLessonLocked
                                                  ? 'Đăng nhập'
                                                  : isAdmin
                                                      ? 'Quản lý'
                                                      : 'Sẵn sàng',
                                              style: AppTextStyles.latin(
                                                size: 10,
                                                weight: FontWeight.w800,
                                                color: isLessonLocked
                                                    ? AppColors.textMuted
                                                    : isAdmin
                                                        ? Colors.blue
                                                        : AppColors.speaking,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isAdmin)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: GestureDetector(
                                          onTap: () {
                                            _showManageVocabularyDialog(
                                              lessonNumber,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(
                                                alpha: 0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              size: 14,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


