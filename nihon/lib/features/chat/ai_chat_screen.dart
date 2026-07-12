import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/services/role_service.dart';
import '../../core/services/speech_assessment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/tts_helper.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

const List<List<Color>> kAvatarGradients = [
  [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
  [Color(0xFFA1C4FD), Color(0xFFC2E9FB)],
  [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
  [Color(0xFFFAD0C4), Color(0xFFFFD1FF)],
  [Color(0xFFF6D365), Color(0xFFFDA085)],
  [Color(0xFFA6C0FE), Color(0xFFF1EEFD)],
];

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _suggestions = [
    'Giải thích cấu trúc 〜てください',
    'Phân biệt Onyomi và Kunyomi là gì',
    '3 cách chào hỏi buổi sáng trong tiếng Nhật',
    'Viết đoạn hội thoại ngắn giới thiệu bản thân',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'Xin chào! Tôi là Trợ lý Học tập Nihon của bạn. Bạn muốn tôi giải thích ngữ pháp, từ vựng hay luyện giao tiếp tiếng Nhật hôm nay?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    final apiKey = SpeechAssessmentService().apiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Vui lòng cấu hình Gemini API Key trước khi sử dụng trợ lý học tập Nihon! Bạn có thể dán key ở tab Học Kanji hoặc cấu hình trực tiếp.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
      );

      final historyList = _messages.take(_messages.length - 1).map((msg) {
        return {
          'role': msg.isUser ? 'user' : 'model',
          'parts': [{'text': msg.text}]
        };
      }).toList();

      historyList.add({
        'role': 'user',
        'parts': [{'text': text}]
      });

      final systemInstruction = 'Bạn là một trợ lý học tiếng Nhật thông minh, vui vẻ và thân thiện tên là Nihon. Hãy trả lời câu hỏi của học sinh bằng Tiếng Việt ngắn gọn, dễ hiểu, sử dụng các ký tự Markdown để in đậm, tạo danh sách rõ ràng, kèm icon sinh động.';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': historyList,
          'systemInstruction': {
            'parts': [{'text': systemInstruction}]
          }
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final String textContent = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        
        setState(() {
          _messages.add(ChatMessage(
            text: textContent.trim(),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Gọi Gemini API thất bại. Mã lỗi: ${response.statusCode}',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Có lỗi xảy ra: $e. Hãy kiểm tra kết nối mạng của bạn!',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                '🤖',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý học tập Nihon',
                  style: AppTextStyles.latin(size: 16, weight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Đồng hành cùng bạn học tiếng Nhật',
                  style: AppTextStyles.latin(size: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.textSecondary),
            tooltip: 'Xóa lịch sử chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    text: 'Lịch sử chat đã được làm mới. Hãy bắt đầu cuộc hội thoại mới nhé!',
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Nihon đang tìm câu trả lời...',
                    style: AppTextStyles.latin(size: 12, color: AppColors.textMuted, weight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          if (!_isLoading && _messages.length <= 2)
            Container(
              height: 48,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final sug = _suggestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      label: Text(
                        sug,
                        style: AppTextStyles.latin(size: 12, color: AppColors.textSecondary, weight: FontWeight.w500),
                      ),
                      onPressed: () => _sendMessage(sug),
                    ),
                  );
                },
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: AppTextStyles.latin(size: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi ngữ pháp, dịch thuật...',
                      hintStyle: AppTextStyles.latin(size: 14, color: AppColors.textFaint),
                      filled: true,
                      fillColor: AppColors.surfaceAlt.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (val) => _sendMessage(val),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                '🤖',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: isUser
                  ? const EdgeInsets.symmetric(horizontal: 18, vertical: 14)
                  : const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.brandGradient : null,
                color: isUser ? null : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: AppColors.brand.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'NIHON TUTOR',
                          style: AppTextStyles.latin(
                            size: 10,
                            color: AppColors.brandDark,
                            weight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép phản hồi vào bộ nhớ tạm!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.copy_rounded,
                            color: AppColors.textFaint,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildStructuredContent(message.text, context),
                  ] else ...[
                    _buildRichText(message.text, Colors.white),
                  ]
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                final user = FirebaseAuth.instance.currentUser;
                final isGuest = RoleService().currentRole.value == AppRole.guest || user == null;
                final email = user?.email ?? 'Khách';
                final initial = email.isNotEmpty ? email[0].toUpperCase() : 'G';
                final firestore = FirebaseFirestore.instanceFor(
                  app: Firebase.app(),
                  databaseId: 'default',
                );

                if (isGuest) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: firestore.collection('users').doc(user.uid).snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data();
                    final String avatarEmoji = data?['avatarEmoji'] as String? ?? '';
                    final int avatarColorIndex = data?['avatarColorIndex'] as int? ?? 0;

                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: avatarEmoji.isNotEmpty
                              ? kAvatarGradients[avatarColorIndex.clamp(0, kAvatarGradients.length - 1)]
                              : [AppColors.brand, AppColors.vocab],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        avatarEmoji.isNotEmpty ? avatarEmoji : initial,
                        style: TextStyle(
                          fontSize: avatarEmoji.isNotEmpty ? 18 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  bool _isJapaneseExampleLine(String line) {
    final clean = line.replaceFirst(RegExp(r'^[\*\-\d\.\s]+'), '').trim();
    if (clean.isEmpty) return false;

    final firstJaIndex = clean.indexOf(RegExp(r'[\u3040-\u30ff\u4e00-\u9faf]'));
    if (firstJaIndex == -1) return false;

    final textBeforeJa = clean.substring(0, firstJaIndex).trim();
    final cleanBefore = textBeforeJa
        .replaceAll(RegExp(r'[vV]í\s+dụ(\s+như)?|VD|vd|[\s\d\.\:\-\,\?\!\(\)]+'), '')
        .trim();

    return cleanBefore.isEmpty;
  }

  String _extractJapaneseOnly(String text) {
    final RegExp jaRegex = RegExp(r'[\u3040-\u30ff\u4e00-\u9faf\u3000-\u303f]+');
    final matches = jaRegex.allMatches(text);
    if (matches.isEmpty) return '';
    return matches.map((m) => m.group(0)).join(' ');
  }

  Widget _buildStructuredContent(String text, BuildContext context) {
    final lines = text.split('\n');
    final List<Widget> children = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      // Check if it's a header
      if (trimmed.startsWith('###')) {
        children.add(_buildHeader(trimmed.substring(3).trim(), 15, AppColors.brandDark));
        continue;
      } else if (trimmed.startsWith('##')) {
        children.add(_buildHeader(trimmed.substring(2).trim(), 16, AppColors.kanji));
        continue;
      } else if (trimmed.startsWith('#')) {
        children.add(_buildHeader(trimmed.substring(1).trim(), 18, AppColors.kanji));
        continue;
      }

      // Check if it's a Japanese example line
      final isBulletOrExample = trimmed.startsWith('*') || trimmed.startsWith('-') || RegExp(r'^\d+\.').hasMatch(trimmed);

      if (isBulletOrExample && _isJapaneseExampleLine(trimmed)) {
        children.add(_buildExampleCard(trimmed));
      } else if (trimmed.startsWith('*') || trimmed.startsWith('-')) {
        final content = trimmed.substring(1).trim();
        // Render horizontal separator rules as real Dividers
        if (content.replaceAll('-', '').trim().isEmpty) {
          children.add(const Divider(height: 16, color: AppColors.border));
          continue;
        }
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 8),
                child: Icon(Icons.circle, size: 6, color: AppColors.brandDark),
              ),
              Expanded(child: _buildRichText(content, AppColors.textPrimary)),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: _buildRichText(trimmed, AppColors.textPrimary),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildHeader(String text, double size, Color color) {
    final cleanedText = text.replaceAll('**', '');
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: size,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              cleanedText,
              style: AppTextStyles.latin(
                size: size,
                color: color,
                weight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(String lineText) {
    var clean = lineText.replaceFirst(RegExp(r'^[\*\-\d\.\s]+'), '').trim();

    String japanese = clean;
    String romaji = '';
    String translation = '';

    final openParen = clean.indexOf('(');
    final closeParen = clean.indexOf(')');

    if (openParen != -1 && closeParen != -1 && closeParen > openParen) {
      japanese = clean.substring(0, openParen).trim();
      romaji = clean.substring(openParen + 1, closeParen).trim();
      
      final rest = clean.substring(closeParen + 1).trim();
      if (rest.startsWith('👉')) {
        translation = rest.substring(1).trim();
      } else if (rest.startsWith('-')) {
        translation = rest.substring(1).trim();
      } else {
        translation = rest;
      }
    } else {
      final arrow = clean.indexOf('👉');
      if (arrow != -1) {
        japanese = clean.substring(0, arrow).trim();
        translation = clean.substring(arrow + 1).trim();
      }
    }

    final speechText = _extractJapaneseOnly(japanese);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRichText(japanese, AppColors.textPrimary, size: 15, isBold: true),
                if (romaji.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    romaji,
                    style: AppTextStyles.latin(
                      size: 12,
                      color: AppColors.textMuted,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                if (translation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('👉 ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: _buildRichText(translation, AppColors.textSecondary, size: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(8),
              shape: const CircleBorder(),
              shadowColor: Colors.black12,
              elevation: 1,
            ),
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.brand, size: 18),
            onPressed: () {
              if (speechText.isNotEmpty) {
                speakJapanese(speechText);
              }
            },
            tooltip: 'Nghe phát âm',
          ),
        ],
      ),
    );
  }

  Widget _buildRichText(String text, Color baseColor, {double size = 14, bool isBold = false}) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final Match match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start).replaceAll('*', ''),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1)?.replaceAll('*', ''),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: baseColor == Colors.white ? Colors.white : AppColors.brandDark,
        ),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start).replaceAll('*', ''),
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: AppTextStyles.latin(
          size: size,
          color: baseColor,
          weight: isBold ? FontWeight.bold : FontWeight.normal,
          height: 1.45,
        ),
      ),
    );
  }
}
