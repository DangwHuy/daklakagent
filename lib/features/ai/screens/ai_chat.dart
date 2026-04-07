import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daklakagent/features/ai/services/ai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// --- IMPORT CÁC MÀN HÌNH CHỨC NĂNG ---
import 'package:daklakagent/features/home/screens/price_screen.dart';
import 'package:daklakagent/features/home/screens/irrigation_screen.dart';
import 'package:daklakagent/features/home/screens/pest_disease_screen.dart';
import 'package:daklakagent/features/home/screens/expert_screen.dart';
import 'package:daklakagent/features/home/screens/farmerView.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final AiService _aiService = AiService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isRecommendationVisible = true;

  final List<Map<String, dynamic>> _recommendations = [
    {"icon": Icons.price_change, "color": Colors.orange, "title": "Giá nông sản", "subtitle": "Cập nhật giá sầu riêng, cà phê.", "query": "Giá nông sản hôm nay"},
    {"icon": Icons.water_drop, "color": Colors.blue, "title": "Lịch Tưới", "subtitle": "Tra cứu lịch tưới nước.", "query": "Lịch tưới nước cho cây"},
    {"icon": Icons.bug_report, "color": Colors.redAccent, "title": "Tra cứu sâu bệnh", "subtitle": "Nhận diện bệnh và cách phòng trừ.", "query": "Cách trị sâu bệnh"},
    {"icon": Icons.support_agent, "color": Colors.green, "title": "Hỏi đáp chuyên gia", "subtitle": "Tham gia diễn đàn kỹ thuật.", "query": "Tôi muốn hỏi chuyên gia"},
    {"icon": Icons.calendar_month, "color": Colors.purple, "title": "Đặt lịch chuyên gia", "subtitle": "Hẹn gặp kỹ sư tại vườn.", "query": "Đặt lịch hẹn kỹ sư"},
  ];

  void _performAction(String actionCode) {
    Widget? targetScreen;
    switch (actionCode) {
      case 'OPEN_PRICE': targetScreen = const AgriPriceHome(); break;
      case 'OPEN_WATER': targetScreen = const IrrigationScreen(); break;
      case 'OPEN_PEST': targetScreen = const PestDiseaseScreen(); break;
      case 'OPEN_FORUM': targetScreen = const ExpertScreen(); break;
      case 'OPEN_BOOKING': targetScreen = const FindExpertScreen(); break;
    }
    if (targetScreen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen!));
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _isRecommendationVisible = false;
    });
    _controller.clear();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('ai_chat_history').add({
        'text': text,
        'isUser': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      String responseRaw = await _aiService.sendMessage(text, []);

      String cleanResponse = responseRaw;
      String? actionCode;

      final actions = ['OPEN_PRICE', 'OPEN_WATER', 'OPEN_PEST', 'OPEN_FORUM', 'OPEN_BOOKING'];
      for (var act in actions) {
        if (responseRaw.contains('[ACTION:$act]')) {
          cleanResponse = responseRaw.replaceAll('[ACTION:$act]', '');
          actionCode = act;
          break;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('ai_chat_history').add({
        'text': cleanResponse.trim(),
        'isUser': false,
        'action': actionCode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      String textLower = text.toLowerCase();
      String category = 'Khác';
      if (textLower.contains('giá') || textLower.contains('tiền')) category = 'Giá nông sản';
      else if (textLower.contains('sâu') || textLower.contains('bệnh') || textLower.contains('thuốc')) category = 'Sâu bệnh';
      else if (textLower.contains('tưới') || textLower.contains('nước')) category = 'Lịch tưới';
      else if (textLower.contains('chuyên gia') || textLower.contains('kỹ sư')) category = 'Chuyên gia';

      await FirebaseFirestore.instance.collection('ai_chat_logs').add({
        'userId': user.uid,
        'userEmail': user.email ?? 'Khách',
        'prompt': text,
        'response': cleanResponse.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': cleanResponse.isEmpty ? 'error' : 'success',
        'category_tag': category,
        'action_triggered': actionCode ?? 'NONE',
        'isFlagged': false,
      });

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi chat AI: $e");

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        FirebaseFirestore.instance.collection('ai_chat_logs').add({
          'userId': currentUser.uid,
          'userEmail': currentUser.email ?? 'Khách',
          'prompt': text,
          'response': 'Lỗi hệ thống: $e',
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'error',
          'category_tag': 'Lỗi',
          'action_triggered': 'NONE',
          'isFlagged': true,
        });
      }
    }
  }

  void _startNewChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isRecommendationVisible = true;
      _isLoading = false;
      _controller.clear();
    });

    final batch = FirebaseFirestore.instance.batch();
    var snapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_chat_history')
        .get();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F9FF),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: !_isRecommendationVisible
            ? const Text("Trợ lý Nông nghiệp", style: TextStyle(color: Colors.black87, fontSize: 16))
            : null,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Tạo trò chuyện mới",
            icon: const Icon(Icons.edit_square, color: Colors.blue),
            onPressed: _startNewChat,
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          if (_isRecommendationVisible)
            Expanded(
              flex: isKeyboardOpen ? 0 : 1,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    if (!isKeyboardOpen)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Chào, tôi là Trợ lý Nông nghiệp",
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                      ),

                    Expanded(
                      flex: isKeyboardOpen ? 0 : 1,
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: isKeyboardOpen ? 250 : MediaQuery.of(context).size.height,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF5FF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8, left: 4),
                              child: Text("Khuyến nghị 👍", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  children: _recommendations.map((item) => _buildRecommendationItem(item)).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('ai_chat_history')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              if (docs.isNotEmpty) {
                return Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildChatBubble(data['text'] ?? "", data['isUser'] ?? false, data['action']);
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          if (_isLoading)
            const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF5F9FF),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: "Hỏi tôi bất cứ gì...",
                              hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _sendMessage(_controller.text),
                          child: const Icon(Icons.send_rounded, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text("Nội dung tạo bởi AI. Vui lòng sử dụng chỉ để tham khảo.",
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 2, blurRadius: 5)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: item['color'].withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(item['icon'], color: item['color']),
        ),
        title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(item['subtitle'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
        onTap: () => _sendMessage(item['query']),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser, String? action) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
                strong: TextStyle(
                    color: isUser ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold
                ),
                h1: TextStyle(
                    color: isUser ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18
                ),
                h2: TextStyle(
                    color: isUser ? Colors.white : Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                ),
                listBullet: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (!isUser && action != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: () => _performAction(action),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(_getActionLabel(action), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'OPEN_PRICE': return "Xem Bảng Giá";
      case 'OPEN_WATER': return "Xem Lịch Tưới";
      case 'OPEN_PEST': return "Tra Cứu Sâu Bệnh";
      case 'OPEN_FORUM': return "Vào Diễn Đàn";
      case 'OPEN_BOOKING': return "Đặt Lịch Ngay";
      default: return "Xem chi tiết";
    }
  }
}