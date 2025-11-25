import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpertScreen extends StatefulWidget {
  const ExpertScreen({super.key});

  @override
  State<ExpertScreen> createState() => _ExpertScreenState();
}

class _ExpertScreenState extends State<ExpertScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isLoadingHistory = true;
  late AnimationController _animationController;

  final String geminiApiKey = ''; // API KEY của bạn

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      // Đợi Firebase Auth khởi tạo hoàn tất
      await Future.delayed(const Duration(milliseconds: 500));

      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        final userCredential = await _auth.signInAnonymously();
        currentUser = userCredential.user;
        print('Đã tạo user anonymous mới: ${currentUser?.uid}');
      } else {
        print('Sử dụng user hiện tại: ${currentUser.uid}');
      }

      setState(() {
        _currentUserId = currentUser?.uid;
      });

      await _loadChatHistory();

    } catch (e) {
      print('Lỗi khởi tạo user: $e');
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<String> askAgent(String question) async {
    if (geminiApiKey.isEmpty) {
      return '❌ Lỗi: Chưa cấu hình API Key! Vui lòng liên hệ quản trị viên.';
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''Bạn là "Agent Cho Bà Con" - trợ lý AI thông minh chuyên hỗ trợ bà con nông dân Việt Nam về kỹ thuật trồng sầu riêng.

🌟 Phong cách trả lời:
- Thân thiện, gần gũi như anh em một nhà
- Dùng ngôn ngữ dễ hiểu, tránh thuật ngữ phức tạp
- Đưa ra giải pháp cụ thể, có thể làm ngay
- Kèm theo lời khuyên thực tế từ kinh nghiệm

📝 Câu hỏi của bà con: $question

Hãy trả lời chi tiết, nhiệt tình như một người anh em ruột đang chia sẻ kinh nghiệm với bà con!'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 1200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      return '😔 Xin lỗi bà con, Agent đang bận một chút. Vui lòng thử lại sau nhé!\n\n💡 Mẹo: Bà con có thể xem phần FAQ bên dưới trong lúc chờ đợi.';
    }
  }

  final List<Map<String, dynamic>> faqData = [
    {
      'question': 'Sầu riêng tôi bị vàng lá, phải làm sao?',
      'answer': '🌿 Vàng lá có nhiều nguyên nhân anh em nhé:\n\n'
          '1️⃣ Thiếu dinh dưỡng: Bón NPK 16:16:8, bổ sung sắt (Fe)\n'
          '2️⃣ Ngập úng: Xẻ rãnh thoát nước, rải vôi\n'
          '3️⃣ Nấm bệnh: Dùng Aliette 80WP (2.5g/lít nước)\n'
          '4️⃣ Thiếu nước: Tưới 100-200 lít/gốc/tuần\n\n'
          '⚠️ Lưu ý: Kiểm tra rễ xem có thối không nhé!',
      'category': '🌱 Dinh dưỡng',
      'icon': Icons.eco,
      'color': Colors.green,
    },
    {
      'question': 'Làm sao để sầu riêng ra hoa đều?',
      'answer': '🌸 Bí quyết ra hoa đều:\n\n'
          '1️⃣ Tạo stress nhẹ: Giảm tưới 1-2 tháng trước\n'
          '2️⃣ Bón phân Lân cao: NPK 10:50:7 (2-3kg/gốc)\n'
          '3️⃣ Phun thuốc kìm: Paclobutrazol 2-3g/lít\n'
          '4️⃣ Tỉa cành: Tạo tán thông thoáng\n'
          '5️⃣ Chờ thời tiết lạnh dưới 20°C\n\n'
          '⚠️ Không bón nhiều đạm (N) trước ra hoa!',
      'category': '🛠️ Kỹ thuật',
      'icon': Icons.settings,
      'color': Colors.orange,
    },
    {
      'question': 'Trái sầu riêng bị rụng hàng loạt?',
      'answer': '🍃 Nguyên nhân và cách xử lý:\n\n'
          '1️⃣ Thiếu nước: Tưới 150-300 lít/gốc\n'
          '2️⃣ Thiếu Bo: Phun Boric Acid 0.1-0.2%\n'
          '3️⃣ Nắng nóng >35°C: Phun sương chiều mát\n'
          '4️⃣ Sâu đục trái: Phun thuốc trừ sâu\n'
          '5️⃣ Thụ phấn kém: Thả ong vào vườn\n\n'
          '💊 Giải pháp: Phun Bo + Canxi + Kali khi trái to!',
      'category': '🐛 Sâu bệnh',
      'icon': Icons.bug_report,
      'color': Colors.red,
    },
    {
      'question': 'Khi nào thì thu hoạch sầu riêng?',
      'answer': '📅 Dấu hiệu thu hoạch:\n\n'
          '1️⃣ Thời gian: 90-120 ngày sau đậu trái\n'
          '2️⃣ Gai trái: Từ xanh đậm → xanh nhạt\n'
          '3️⃣ Cuống trái: Khô, nứt vòng quanh\n'
          '4️⃣ Mùi thơm: Nhẹ ở cuống trái\n'
          '5️⃣ Gõ trái: Âm thanh ộp ộp (chín)\n'
          '6️⃣ Rãnh gai: Nông, múi gai phồng\n\n'
          '⏰ Thu hoạch buổi sáng sớm, tránh mưa nhé!',
      'category': '🌾 Thu hoạch',
      'icon': Icons.agriculture,
      'color': Colors.brown,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            // Fixed Header - không bị ảnh hưởng bởi tab
            _buildHeader(),
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: const Color(0xFF6C63FF),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF6C63FF),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.chat_bubble_outline, size: 22),
                    text: 'Trò chuyện',
                  ),
                  Tab(
                    icon: Icon(Icons.help_outline, size: 22),
                    text: 'Câu hỏi thường gặp',
                  ),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildChatTab(),
                  _buildFAQTab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildInputSection(),
      ),
    );
  }
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agent Cho Bà Con',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Đang hoạt động',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Trợ lý AI thông minh - Hỗ trợ 24/7',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    if (_isLoadingHistory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tải lịch sử chat...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: _conversations.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == 0) {
          return _buildTypingIndicator();
        }
        final actualIndex = _isTyping ? index - 1 : index;
        return _buildMessageBubble(
          _conversations[_conversations.length - 1 - actualIndex],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Xin chào bà con! 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Agent sẵn sàng hỗ trợ bà con về\nkỹ thuật trồng sầu riêng',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '💡 Gợi ý câu hỏi:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestedChip('🍃 Cách chữa vàng lá?', Icons.eco),
              _buildSuggestedChip('⏰ Khi nào bón phân?', Icons.schedule),
              _buildSuggestedChip('🐛 Xử lý sâu đục trái?', Icons.bug_report),
              _buildSuggestedChip('🌸 Cách kích hoa?', Icons.local_florist),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedChip(String text, IconData icon) {
    return InkWell(
      onTap: () {
        _questionController.text = text.replaceAll(RegExp(r'[^\w\s?]'), '').trim();
        _sendQuestion();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAgentAvatar(),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 6),
                _buildDot(1),
                const SizedBox(width: 6),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value = (_animationController.value - (index * 0.2)) % 1.0;
        final opacity = (value < 0.5) ? value * 2 : (1 - value) * 2;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.3 + (opacity * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAgentAvatar(),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 20 : 4),
                  topRight: Radius.circular(isUser ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Agent Cho Bà Con',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isUser ? Colors.white : const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message['time'] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAgentAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.support_agent, color: Colors.white, size: 22),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
      ),
      child: const Icon(Icons.person, color: Color(0xFF4CAF50), size: 22),
    );
  }

  Widget _buildFAQTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqData.length,
      itemBuilder: (context, index) => _buildFAQCard(faqData[index]),
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (faq['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              faq['icon'] as IconData,
              color: faq['color'] as Color,
              size: 24,
            ),
          ),
          title: Text(
            faq['question']!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2D3748),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              faq['category']!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (faq['color'] as Color).withOpacity(0.05),
                    (faq['color'] as Color).withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: faq['color'] as Color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Câu trả lời từ Agent',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: faq['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    faq['answer']!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isLoading
                      ? const Color(0xFF6C63FF).withOpacity(0.3)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _questionController,
                maxLines: null,
                enabled: !_isLoading,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: _isLoading
                      ? 'Agent đang suy nghĩ...'
                      : 'Bà con cần hỏi gì không? 😊',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[400]!])
                  : const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
              ),
              shape: BoxShape.circle,
              boxShadow: _isLoading
                  ? null
                  : [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _sendQuestion,
              icon: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _sendQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Bà con vui lòng nhập câu hỏi nhé!'),
            ],
          ),
          backgroundColor: const Color(0xFF6C63FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final question = _questionController.text.trim();
    _questionController.clear();

    setState(() {
      _conversations.add({
        'text': question,
        'isUser': true,
        'time': _getCurrentTime(),
      });
      _isLoading = true;
      _isTyping = true;
    });

    // Save user message
    await _saveMessage(question, true);

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Get AI response
    final answer = await askAgent(question);

    setState(() {
      _isTyping = false;
      _conversations.add({
        'text': answer,
        'isUser': false,
        'time': _getCurrentTime(),
      });
      _isLoading = false;
    });

    // Save AI response
    await _saveMessage(answer, false);

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadChatHistory() async {
    if (_currentUserId == null) {
      print('User ID null, không thể load history');
      return;
    }

    try {
      print('Đang load chat history cho user: $_currentUserId');

      // Lấy chat session mới nhất
      final chatSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('chats')
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();

      if (chatSnapshot.docs.isEmpty) {
        print('Không tìm thấy chat cũ, tạo chat mới');
        // Tạo chat mới
        final newChat = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('chats')
            .add({
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'title': 'Chat với Agent',
          'userId': _currentUserId,
        });
        _currentChatId = newChat.id;
        print('Đã tạo chat mới: $_currentChatId');
      } else {
        _currentChatId = chatSnapshot.docs.first.id;
        print('Tìm thấy chat cũ: $_currentChatId');

        // Load tin nhắn
        final messagesSnapshot = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('chats')
            .doc(_currentChatId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .get();

        print('Tìm thấy ${messagesSnapshot.docs.length} tin nhắn');

        setState(() {
          _conversations.clear();
          for (var doc in messagesSnapshot.docs) {
            final data = doc.data();
            _conversations.add({
              'text': data['text'] ?? '',
              'isUser': data['isUser'] ?? false,
              'time': _formatTimestamp(data['timestamp']),
              'timestamp': data['timestamp'],
            });
          }
        });

        // Scroll xuống tin nhắn mới nhất
        if (_conversations.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      }
    } catch (e) {
      print('Lỗi load chat: $e');
    }
  }

  Future<void> _saveMessage(String text, bool isUser) async {
    if (_currentUserId == null || _currentChatId == null) {
      print('Không thể lưu tin nhắn: UserId=$_currentUserId, ChatId=$_currentChatId');
      return;
    }

    try {
      // Lưu tin nhắn
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .add({
        'text': text,
        'isUser': isUser,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update lastUpdated và lastMessage
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('chats')
          .doc(_currentChatId)
          .update({
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastMessage': text.length > 50 ? '${text.substring(0, 50)}...' : text,
      });

      print('Đã lưu tin nhắn vào Firestore');
    } catch (e) {
      print('Lỗi lưu tin nhắn: $e');
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return _getCurrentTime();
    final date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}