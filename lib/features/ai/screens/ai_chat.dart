//Ai Chat
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daklakagent/features/ai/services/ai_service.dart';

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
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    "Giá cà phê hôm nay?",
    "Lịch tưới cho sầu riêng",
    "Tìm chuyên gia tư vấn",
    "Tra cứu bệnh nấm hồng",
  ];

  // --- HÀM ĐIỀU HƯỚNG TỪ MÃ ACTION ---
  void _performAction(String actionCode) {
    Widget? targetScreen;
    String actionName = "";

    switch (actionCode) {
      case 'OPEN_PRICE':
        targetScreen = const AgriPriceHome();
        actionName = "Bảng Giá";
        break;
      case 'OPEN_WATER':
        targetScreen = const IrrigationScreen();
        actionName = "Lịch Tưới";
        break;
      case 'OPEN_PEST':
        targetScreen = const PestDiseaseScreen();
        actionName = "Sâu Bệnh";
        break;
      case 'OPEN_FORUM':
        targetScreen = const ExpertScreen();
        actionName = "Hỏi Đáp";
        break;
      case 'OPEN_BOOKING':
        targetScreen = const FindExpertScreen();
        actionName = "Đặt Lịch";
        break;
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen!),
      );
    }
  }

  // --- HÀM GỬI TIN NHẮN ---
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    _controller.clear();
    _scrollToBottom();

    try {
      // 1. Lưu tin nhắn User
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_chat_history')
          .add({
        'text': text,
        'isUser': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Gửi lên AI
      String responseRaw = await _aiService.sendMessage(text);

      // 3. Phân tích Action Tag
      String cleanResponse = responseRaw;
      String? actionCode;

      if (responseRaw.contains('[ACTION:OPEN_PRICE]')) {
        cleanResponse = responseRaw.replaceAll('[ACTION:OPEN_PRICE]', '');
        actionCode = 'OPEN_PRICE';
      } else if (responseRaw.contains('[ACTION:OPEN_WATER]')) {
        cleanResponse = responseRaw.replaceAll('[ACTION:OPEN_WATER]', '');
        actionCode = 'OPEN_WATER';
      } else if (responseRaw.contains('[ACTION:OPEN_PEST]')) {
        cleanResponse = responseRaw.replaceAll('[ACTION:OPEN_PEST]', '');
        actionCode = 'OPEN_PEST';
      } else if (responseRaw.contains('[ACTION:OPEN_FORUM]')) {
        cleanResponse = responseRaw.replaceAll('[ACTION:OPEN_FORUM]', '');
        actionCode = 'OPEN_FORUM';
      } else if (responseRaw.contains('[ACTION:OPEN_BOOKING]')) {
        cleanResponse = responseRaw.replaceAll('[ACTION:OPEN_BOOKING]', '');
        actionCode = 'OPEN_BOOKING';
      }

      // 4. Lưu tin nhắn AI (kèm action nếu có)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_chat_history')
          .add({
        'text': cleanResponse.trim(),
        'isUser': false,
        'action': actionCode, // Lưu mã hành động vào DB
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      print("Lỗi chat AI: $e");
    }
  }

  void _scrollToBottom() {
    // Delay nhẹ để list kịp render item mới
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Vì reverse: true, 0.0 là đáy (mới nhất)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final batch = FirebaseFirestore.instance.batch();
    var snapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_chat_history')
        .get();
    for (var doc in snapshots.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.smart_toy), SizedBox(width: 10), Text("Trợ Lý AI")]),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearHistory,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('ai_chat_history')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.spa, size: 60, color: Colors.green[200]),
                        const SizedBox(height: 10),
                        const Text("Chào bác! Tôi có thể giúp gì hôm nay?", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isUser = data['isUser'] ?? false;
                    final text = data['text'] ?? "";
                    final String? action = data['action']; // Lấy action từ DB

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // Bong bóng chat
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.green[600] : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(15),
                                  topRight: const Radius.circular(15),
                                  bottomLeft: isUser ? const Radius.circular(15) : const Radius.circular(0),
                                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(15),
                                ),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16),
                              ),
                            ),

                            // Nút hành động (Nếu có action và là tin nhắn AI)
                            if (!isUser && action != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: ElevatedButton.icon(
                                  onPressed: () => _performAction(action),
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: Text(_getActionLabel(action)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[50],
                                    foregroundColor: Colors.blue[800],
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    elevation: 0,
                                    side: BorderSide(color: Colors.blue.withOpacity(0.3)),
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
            ),
          ),

          if (_isLoading)
            const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator(color: Colors.green)),

          if (!_isLoading)
            SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (c, i) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  label: Text(_suggestions[index]),
                  onPressed: () => _sendMessage(_suggestions[index]),
                  backgroundColor: Colors.green[50],
                  labelStyle: TextStyle(color: Colors.green[800]),
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Nhập câu hỏi...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(_controller.text)
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper để lấy tên nút hiển thị
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