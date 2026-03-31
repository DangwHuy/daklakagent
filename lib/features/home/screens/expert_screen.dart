/*
⚠️ HƯỚNG DẪN CẤU HÌNH QUYỀN MICRO (BẮT BUỘC ĐỂ DÙNG GIỌNG NÓI):

1. Android (android/app/src/main/AndroidManifest.xml):
   Thêm các dòng sau vào trước thẻ <application>:

   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.BLUETOOTH"/>
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>

   Và thêm vào trong thẻ <manifest> (quan trọng cho Android 11+):
   <queries>
       <intent>
           <action android:name="android.speech.RecognitionService" />
       </intent>
       <!-- QUERIES CHO TEXT-TO-SPEECH (QUAN TRỌNG ĐỂ ĐỌC ĐƯỢC) -->
       <intent>
           <action android:name="android.intent.action.TTS_SERVICE" />
       </intent>
   </queries>

2. iOS (ios/Runner/Info.plist):
   Thêm các dòng sau vào trong thẻ <dict>:

   <key>NSSpeechRecognitionUsageDescription</key>
   <string>Ứng dụng cần quyền này để chuyển giọng nói thành văn bản cho việc nhập câu hỏi.</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Ứng dụng cần quyền truy cập microphone để nghe câu hỏi của bạn.</string>
*/

// AI phân tích CHuyên sâu
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter_markdown/flutter_markdown.dart'; // FEATURE 2: Hiển thị Markdown đẹp
import 'package:speech_to_text/speech_to_text.dart' as stt; // FEATURE 3: Giọng nói
import 'package:flutter_tts/flutter_tts.dart'; // đọc kết quả trả về

class ExpertScreen extends StatefulWidget {
  final String? initialQuestion;

  const ExpertScreen({super.key, this.initialQuestion});

  @override
  State<ExpertScreen> createState() => _ExpertScreenState();
}

class _ExpertScreenState extends State<ExpertScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Dữ liệu hội thoại sẽ được đồng bộ từ Firestore
  List<Map<String, dynamic>> _conversations = [];

  bool _isLoading = false;
  bool _isTyping = false;
  late AnimationController _animationController;

  // Cấu hình Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Trong thực tế, bạn nên lấy User ID từ FirebaseAuth.
  // Ở đây mình dùng ID cố định để demo cho bà con.
  final String _userId = 'ba_con_nong_dan_01';

  // UPDATE: Địa chỉ Server Python (Ngrok) của bạn
  // Lưu ý: Mỗi lần chạy lại ngrok sẽ có link mới, nhớ cập nhật vào đây nhé!
  final String serverUrl = 'https://dann-uncoincidental-katheleen.ngrok-free.dev/chat';

  // --- BIẾN CHO FEATURE 3 (GIỌNG NÓI) ---
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _speechError = ''; // Biến lưu lỗi cụ thể để hiển thị

  // --- BIẾN CHO TEXT TO SPEECH (ĐỌC VĂN BẢN) ---
  late FlutterTts _flutterTts;
  String? _currentReadingText; // Biến để kiểm soát đoạn đang đọc

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Khởi tạo Speech to Text
    _speech = stt.SpeechToText();
    _initSpeech();

    // Khởi tạo Text to Speech
    _initTts();

    // 1. Lắng nghe dữ liệu từ Firestore theo thời gian thực (Real-time)
    _listenToChatHistory();

    if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
      _questionController.text = widget.initialQuestion!;
    }
  }

  // Khởi tạo quyền truy cập Micro
  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          } else if (status == 'listening') {
            if (mounted) setState(() => _isListening = true);
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _speechError = errorNotification.errorMsg; // Lưu thông báo lỗi
            });
            print('Lỗi giọng nói: ${errorNotification.errorMsg}');
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      setState(() {
        _speechError = e.toString();
        _speechEnabled = false;
      });
      print("Không khởi tạo được SpeechToText: $e");
    }
  }

  // Hàm bắt đầu nghe
  void _startListening() async {
    if (!_speechEnabled) {
      // HIỂN THỊ LỖI CỤ THỂ CHO NGƯỜI DÙNG
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_speechError.isNotEmpty
              ? 'Lỗi: $_speechError'
              : '⚠️ Lỗi: Không tìm thấy dịch vụ Google Speech hoặc chưa cấp quyền Micro!'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: _initSpeech,
          ),
        ),
      );
      // Cố gắng khởi tạo lại
      _initSpeech();
      return;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _questionController.text = result.recognizedWords;
            if (_questionController.text.isNotEmpty) {
              _questionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _questionController.text.length),
              );
            }
          });
        },
        localeId: 'vi_VN', // Cấu hình tiếng Việt
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      );
      setState(() => _isListening = true);
    } catch (e) {
      print("Lỗi khi bắt đầu nghe: $e");
      setState(() => _isListening = false);
    }
  }

  // Hàm dừng nghe
  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  // Hàm cấu hình TTS (Copy hàm này vào trong class)
  void _initTts() async { // Thêm async để chờ cấu hình
    _flutterTts = FlutterTts();

    // Cấu hình tiếng Việt - Quan trọng: Chờ setLanguage xong mới chạy tiếp
    // Nếu máy chưa có tiếng Việt, nó sẽ dùng tiếng Anh mặc định gây lỗi đọc không dấu
    await _flutterTts.setLanguage("vi-VN");

    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); // Tốc độ vừa phải

    // Khi đọc xong hoặc hủy thì reset icon
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _currentReadingText = null);
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _currentReadingText = null);
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _currentReadingText = null);
    });
  }

  // Hàm xử lý việc Đọc/Dừng (Copy hàm này vào trong class)
  Future<void> _speak(String text) async {
    // Đảm bảo set lại ngôn ngữ trước mỗi lần đọc để tránh bị reset về mặc định
    await _flutterTts.setLanguage("vi-VN");

    if (_currentReadingText == text) {
      // Nếu đang đọc chính đoạn này thì DỪNG
      await _flutterTts.stop();
      if (mounted) setState(() => _currentReadingText = null);
    } else {
      // Nếu đang đọc đoạn khác hoặc chưa đọc thì ĐỌC MỚI
      await _flutterTts.stop();
      if (mounted) setState(() => _currentReadingText = text);
      await _flutterTts.speak(text);
    }
  }

  // --- LOGIC FIRESTORE (MỚI) ---

  void _listenToChatHistory() {
    // Lắng nghe thay đổi trong collection messages
    _firestore
        .collection('chat_history')
        .doc(_userId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Sắp xếp tin nhắn cũ -> mới
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _conversations = snapshot.docs.map((doc) => doc.data()).toList();
        });

        // Tự động cuộn xuống cuối khi có tin nhắn mới
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }, onError: (e) {
      print("Lỗi tải chat: $e");
    });
  }

  // Hàm thêm tin nhắn vào Firestore
  Future<void> _addMessageToFirestore(String text, bool isUser) async {
    await _firestore
        .collection('chat_history')
        .doc(_userId)
        .collection('messages')
        .add({
      'text': text,
      'isUser': isUser,
      'time': _getCurrentTime(), // Lưu chuỗi giờ hiển thị
      'timestamp': FieldValue.serverTimestamp(), // Lưu thời gian server để sắp xếp
    });
  }

  // Hàm xóa lịch sử trên Firestore
  Future<void> _clearHistory() async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('chat_history')
        .doc(_userId)
        .collection('messages')
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ---------------------------

  // UPDATE: Hàm gọi Server Python (RAG) thay vì gọi trực tiếp Gemini
  Future<String> askAgent(String question) async {
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question, // Gửi key 'question' đúng như server Python yêu cầu
        }),
      );

      if (response.statusCode == 200) {
        // Server Python trả về JSON dạng: {"answer": "...", "context_used": "..."}
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'] ?? 'Lỗi: Server không trả về câu trả lời.';
      } else {
        return '❌ Lỗi kết nối Server: ${response.statusCode}. Bà con kiểm tra lại Server Python nhé!';
      }
    } catch (e) {
      return '😔 Không kết nối được với Server chuyên gia. \nLỗi: $e \n\n💡 Mẹo: Bà con kiểm tra xem link Ngrok có bị đổi không nhé!';
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
        // resizeToAvoidBottomInset: true giúp đẩy giao diện lên khi có bàn phím
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            _buildHeader(),
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
            Expanded(
              child: TabBarView(
                children: [
                  _buildChatTab(),
                  _buildFAQTab(),
                ],
              ),
            ),
            // UPDATE: Đưa thanh nhập liệu vào Column chính để nó tự động đẩy lên theo bàn phím
            _buildInputSection(),
          ],
        ),
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
                      'Chuyên Gia Sầu Riêng',
                      style: TextStyle(
                        fontSize: 20,
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
                          'Trực tuyến',
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
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.white70),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xóa lịch sử trên Mây?'),
                      content: const Text('Hành động này sẽ xóa vĩnh viễn tin nhắn đã lưu.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Thôi'),
                        ),
                        TextButton(
                          onPressed: () {
                            _clearHistory();
                            Navigator.pop(context);
                          },
                          child: const Text('Xóa hết', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              )
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
                Icon(Icons.cloud_done, color: Colors.lightBlueAccent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đã đồng bộ dữ liệu',
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
    if (_conversations.isEmpty && !_isTyping) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _conversations.length) {
          return _buildTypingIndicator();
        }
        if (index < _conversations.length) {
          return _buildMessageBubble(_conversations[index]);
        }
        return const SizedBox.shrink();
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
            'Quy trình chuẩn VietGAP.\nBà con cứ yên tâm hỏi nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
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
    final text = message['text'] ?? '';
    final bool isReadingThis = _currentReadingText == text; // Kiểm tra trạng thái đọc

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
                maxWidth: MediaQuery.of(context).size.width * 0.85,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Chuyên Gia Sầu Riêng AI',
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
                          // Nút Loa (Đọc/Dừng)
                          InkWell(
                            onTap: () => _speak(text),
                            child: Row(
                              children: [
                                Icon(
                                  isReadingThis ? Icons.stop_circle : Icons.volume_up,
                                  size: 20,
                                  color: isReadingThis ? Colors.red : Colors.grey[600],
                                ),
                                if (isReadingThis) ...[
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Dừng',
                                    style: TextStyle(fontSize: 12, color: Colors.red),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // FEATURE 2: SỬ DỤNG MARKDOWN BODY
                  MarkdownBody(
                    data: text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: isUser ? Colors.white : const Color(0xFF2D3748),
                      ),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : const Color(0xFF2D3748),
                      ),
                      listBullet: TextStyle(
                        color: isUser ? Colors.white70 : const Color(0xFF6C63FF),
                      ),
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
      child: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16,
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
                      color: _isListening
                          ? Colors.redAccent
                          : (_isLoading ? const Color(0xFF6C63FF).withOpacity(0.3) : Colors.transparent),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _questionController,
                          maxLines: null,
                          enabled: !_isLoading,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: _isListening
                                ? 'Đang nghe bà con nói...'
                                : (_isLoading ? 'Đang suy nghĩ...' : 'Hỏi gì không bà con?'),
                            hintStyle: TextStyle(
                              color: _isListening ? Colors.redAccent : Colors.grey[400],
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
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            if (_isListening) {
                              _stopListening();
                            } else {
                              _startListening();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isListening ? Colors.redAccent.withOpacity(0.1) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? Colors.red : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
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
        ),
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

    await _addMessageToFirestore(question, true);

    setState(() {
      _isLoading = true;
      _isTyping = true;
    });

    final answer = await askAgent(question);

    await _addMessageToFirestore(answer, false);

    setState(() {
      _isTyping = false;
      _isLoading = false;
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _flutterTts.stop(); // Tắt loa khi thoát
    super.dispose();
  }
}