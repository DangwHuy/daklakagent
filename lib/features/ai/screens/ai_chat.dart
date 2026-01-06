import 'package:flutter/material.dart';
import 'package:daklakagent/features/ai/services/ai_service.dart';

// --- IMPORT CÁC MÀN HÌNH CHỨC NĂNG (Dựa trên HomeScreen của bạn) ---
// Đảm bảo đường dẫn import chính xác với cấu trúc thư mục của bạn
import 'package:daklakagent/features/home/screens/price_screen.dart';        // Giá Nông Sản
import 'package:daklakagent/features/home/screens/irrigation_screen.dart';   // Lịch Tưới
import 'package:daklakagent/features/home/screens/pest_disease_screen.dart'; // Tra cứu sâu bệnh
import 'package:daklakagent/features/home/screens/expert_screen.dart';       // Hỏi đáp chuyên gia (Forum)
import 'package:daklakagent/features/home/screens/FarmerView.dart';        // Đặt lịch Chuyên gia (FindExpertScreen)

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final AiService _aiService = AiService();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // Các câu hỏi gợi ý bám sát 5 chức năng chính
  final List<String> _suggestions = [
    "Giá cà phê hôm nay?",
    "Lịch tưới cho sầu riêng",
    "Tìm chuyên gia tư vấn",
    "Tra cứu bệnh nấm hồng",
  ];

  @override
  void initState() {
    super.initState();
    _addBotMessage("Chào bác! Tôi là trợ lý AI. Bác cần tra cứu giá, xem lịch tưới hay đặt lịch chuyên gia?");
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({"isUser": false, "text": text});
    });
    _scrollToBottom();
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

  // --- XỬ LÝ GỬI TIN NHẮN & ĐIỀU HƯỚNG ---
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"isUser": true, "text": text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // 1. Gửi lên AI
    String responseRaw = await _aiService.sendMessage(text);

    // 2. Phân tích Action Tag để điều hướng
    String cleanResponse = responseRaw;
    Widget? targetScreen;
    String actionName = "";

    if (responseRaw.contains('[ACTION:OPEN_PRICE]')) {
      cleanResponse = responseRaw.replaceAll('[ACTION:OPEN_PRICE]', '');
      targetScreen = const PriceScreen();
      actionName = "Bảng Giá Nông Sản";
    }
    else if (responseRaw.contains('[ACTION:OPEN_WATER]')) {
      cleanResponse = responseRaw.replaceAll('[ACTION:OPEN_WATER]', '');
      targetScreen = const IrrigationScreen();
      actionName = "Lịch Tưới Tiêu";
    }
    else if (responseRaw.contains('[ACTION:OPEN_PEST]')) {
      cleanResponse = responseRaw.replaceAll('[ACTION:OPEN_PEST]', '');
      targetScreen = const PestDiseaseScreen();
      actionName = "Tra Cứu Sâu Bệnh";
    }
    else if (responseRaw.contains('[ACTION:OPEN_FORUM]')) {
      cleanResponse = responseRaw.replaceAll('[ACTION:OPEN_FORUM]', '');
      targetScreen = const ExpertScreen();
      actionName = "Hỏi Đáp Chuyên Gia";
    }
    else if (responseRaw.contains('[ACTION:OPEN_BOOKING]')) {
      cleanResponse = responseRaw.replaceAll('[ACTION:OPEN_BOOKING]', '');
      targetScreen = const FindExpertScreen(); // Màn hình FarmerView
      actionName = "Đặt Lịch Chuyên Gia";
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // Hiện câu trả lời (đã xóa tag)
      _addBotMessage(cleanResponse.trim());

      // 3. Thực hiện chuyển trang tự động (nếu có tag)
      if (targetScreen != null) {
        // Delay nhẹ để người dùng kịp đọc tin nhắn trả lời của AI
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text("Đang mở: $actionName..."),
                  ],
                ),
                backgroundColor: Colors.green[700],
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );

            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => targetScreen!)
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.smart_toy), SizedBox(width: 10), Text("Trợ Lý AI")]),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'];
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green[600] : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: isUser ? const Radius.circular(15) : const Radius.circular(0),
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(15),
                      ),
                    ),
                    child: Text(msg['text'], style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16)),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator(color: Colors.green)),

          // Gợi ý nhanh
          if (!_isLoading && _messages.length < 5)
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
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => _sendMessage(_controller.text)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}