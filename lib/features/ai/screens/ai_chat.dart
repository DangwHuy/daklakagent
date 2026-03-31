import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Để bắt sự kiện cuộn
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daklakagent/features/ai/services/ai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// --- IMPORT CÁC MÀN HÌNH CHỨC NĂNG (Giữ nguyên của bác) ---
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

  bool _isLoading = false; // Trạng thái đang gửi tin
  bool _isRecommendationVisible = true; // Trạng thái hiện menu gợi ý

  // Dữ liệu menu nông nghiệp (Giao diện mới)
  final List<Map<String, dynamic>> _recommendations = [
    {"icon": Icons.price_change, "color": Colors.orange, "title": "Giá nông sản", "subtitle": "Cập nhật giá sầu riêng, cà phê.", "query": "Giá nông sản hôm nay"},
    {"icon": Icons.water_drop, "color": Colors.blue, "title": "Lịch Tưới", "subtitle": "Tra cứu lịch tưới nước.", "query": "Lịch tưới nước cho cây"},
    {"icon": Icons.bug_report, "color": Colors.redAccent, "title": "Tra cứu sâu bệnh", "subtitle": "Nhận diện bệnh và cách phòng trừ.", "query": "Cách trị sâu bệnh"},
    {"icon": Icons.support_agent, "color": Colors.green, "title": "Hỏi đáp chuyên gia", "subtitle": "Tham gia diễn đàn kỹ thuật.", "query": "Tôi muốn hỏi chuyên gia"},
    {"icon": Icons.calendar_month, "color": Colors.purple, "title": "Đặt lịch chuyên gia", "subtitle": "Hẹn gặp kỹ sư tại vườn.", "query": "Đặt lịch hẹn kỹ sư"},
  ];

  // --- 1. LOGIC ĐIỀU HƯỚNG (Giữ nguyên) ---
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

  // --- 2. LOGIC GỬI TIN NHẮN (Giữ nguyên logic, thêm xử lý UI) ---
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Cập nhật UI ngay lập tức
    setState(() {
      _isLoading = true;
      _isRecommendationVisible = false; // Ẩn gợi ý khi bắt đầu chat
    });
    _controller.clear();

    // Cuộn xuống dưới cùng
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    try {
      // A. Lưu tin nhắn User
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('ai_chat_history').add({
        'text': text,
        'isUser': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // B. Gọi AI
      // Thêm dấu phẩy và ngoặc vuông [] vào sau biến text
      String responseRaw = await _aiService.sendMessage(text, []);

      // C. Xử lý Action Tag
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

      // D. Lưu tin nhắn AI
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('ai_chat_history').add({
        'text': cleanResponse.trim(),
        'isUser': false,
        'action': actionCode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi chat AI: $e");
    }
  }

  // --- 3. LOGIC XÓA LỊCH SỬ (TẠO CHAT MỚI) ---
  // Hàm xử lý khi bấm nút Cây bút (Tạo đoạn chat mới)
  void _startNewChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. CẬP NHẬT GIAO DIỆN NGAY LẬP TỨC
    setState(() {
      _isRecommendationVisible = true; // <--- DÒNG QUAN TRỌNG NHẤT: Bắt buộc phải là true để hiện lại menu
      _isLoading = false;              // Tắt xoay vòng nếu đang treo
      _controller.clear();             // Xóa chữ đang nhập dở
    });

    // 2. Xóa dữ liệu trên Firestore (chạy ngầm)
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
// KIỂM TRA BÀN PHÍM CÓ ĐANG MỞ HAY KHÔNG
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F9FF), // Màu nền xanh nhạt chuẩn Mimo

      // --- APP BAR ---
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
          // --- PHẦN 1: HEADER & GỢI Ý (Đã sửa để tự động giãn Full màn hình) ---
          if (_isRecommendationVisible)
            Expanded( // <--- Dùng Expanded để chiếm trọn không gian khi không có chat
              flex: isKeyboardOpen ? 0 : 1, // Nếu mở phím thì không chiếm ưu tiên, đóng phím thì chiếm hết
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    // Lời chào
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

                    // Khung Menu Gợi ý - Tự động giãn nở
                    Expanded(
                      flex: isKeyboardOpen ? 0 : 1,
                      child: Container(
                        constraints: BoxConstraints(
                          // Khi mở bàn phím thì giới hạn lại, khi đóng thì cho phép cao tối đa
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
                            // Danh sách có thể cuộn
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

          // --- PHẦN 2: DANH SÁCH CHAT (Chỉ hiện khi có dữ liệu) ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('ai_chat_history')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              // Nếu đã có tin nhắn, phần này sẽ chiếm không gian để hiển thị chat
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
              // Nếu chưa có tin nhắn, trả về SizedBox trống để Khuyến nghị chiếm Full
              return const SizedBox.shrink();
            },
          ),

          if (_isLoading)
            const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)),

          // --- PHẦN 3: INPUT VIÊN THUỐC ---
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

  // --- WIDGET CON: ITEM GỢI Ý ---
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
        onTap: () => _sendMessage(item['query']), // Tự động gửi câu hỏi mẫu
      ),
    );
  }

  // --- WIDGET CON: BONG BÓNG CHAT ---
  // --- WIDGET CON: BONG BÓNG CHAT (ĐÃ SỬA ĐỂ HIỂN THỊ MARKDOWN) ---
  Widget _buildChatBubble(String text, bool isUser, String? action) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.white, // User: Xanh, AI: Trắng
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
            // --- THAY ĐỔI Ở ĐÂY: DÙNG MARKDOWN BODY ---
            MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                // Chỉnh màu chữ: User màu trắng, AI màu đen
                p: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4, // Giãn dòng cho dễ đọc
                ),
                // Chỉnh in đậm (**text**)
                strong: TextStyle(
                    color: isUser ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold
                ),
                // Chỉnh tiêu đề (# Title) - làm cho giá tiền to rõ hơn
                h1: TextStyle(
                    color: isUser ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18
                ),
                h2: TextStyle(
                    color: isUser ? Colors.white : Colors.blue[800], // Tiêu đề con màu xanh đậm cho đẹp
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                ),
                // Chỉnh list (gạch đầu dòng)
                listBullet: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),

            // Nút hành động (Giữ nguyên code cũ)
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