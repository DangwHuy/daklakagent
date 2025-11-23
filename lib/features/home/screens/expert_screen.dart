import 'package:flutter/material.dart';
import 'home_screen.dart';

class ExpertScreen extends StatefulWidget {
  const ExpertScreen({super.key});

  @override
  State<ExpertScreen> createState() => _ExpertScreenState();
}

class _ExpertScreenState extends State<ExpertScreen> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, dynamic>> _conversations = [];

  // Dữ liệu câu hỏi thường gặp
  final List<Map<String, String>> faqData = [
    {
      'question': 'Sầu riêng tôi bị vàng lá, phải làm sao?',
      'answer': 'Vàng lá có nhiều nguyên nhân:\n\n'
          '1. Thiếu dinh dưỡng: Bón phân NPK 16:16:8, bổ sung sắt (Fe)\n'
          '2. Ngập úng: Xẻ rãnh thoát nước, rải vôi khử trùng\n'
          '3. Nấm Phytophthora: Tưới thuốc Aliette 80WP (2.5g/lít)\n'
          '4. Thiếu nước: Tưới đủ 100-200 lít/gốc/tuần\n\n'
          'Kiểm tra rễ xem có thối không, nếu thối → xử lý nấm ngay!',
      'category': 'Dinh dưỡng',
    },
    {
      'question': 'Làm sao để sầu riêng ra hoa đều?',
      'answer': 'Để ra hoa đều, cần:\n\n'
          '1. Tạo stress nhẹ: Giảm tưới 1-2 tháng trước kỳ ra hoa mong muốn\n'
          '2. Bón phân cao Lân: NPK 10:50:7 (2-3kg/gốc) trước ra hoa 30-40 ngày\n'
          '3. Phun Paclobutrazol: 2-3g/lít, phun tán lá 2-3 tháng trước\n'
          '4. Tỉa cành: Tỉa cành già, tạo tán thông thoáng\n'
          '5. Thời tiết: Cần có đợt lạnh (dưới 20°C) để kích thích ra hoa\n\n'
          'Lưu ý: Không bón nhiều đạm (N) trước ra hoa!',
      'category': 'Kỹ thuật',
    },
    {
      'question': 'Trái sầu riêng bị rụng hàng loạt?',
      'answer': 'Nguyên nhân rụng trái:\n\n'
          '1. Thiếu nước: Tưới đủ 150-300 lít/gốc khi trái còn nhỏ\n'
          '2. Thiếu Bo (붕 붕소): Phun lá Boric Acid 0.1-0.2%\n'
          '3. Stress nhiệt: Nhiệt độ > 35°C → Tưới phun sương chiều mát\n'
          '4. Sâu đục trái: Kiểm tra và phun thuốc trừ sâu\n'
          '5. Thụ phấn kém: Thả ong bầu trong vườn\n\n'
          'Giải pháp: Phun Bo + Canxi + Kali khi trái to bằng nắm tay',
      'category': 'Sâu bệnh',
    },
    {
      'question': 'Khi nào thì thu hoạch sầu riêng?',
      'answer': 'Dấu hiệu thu hoạch sầu riêng:\n\n'
          '1. Thời gian: 90-120 ngày sau khi đậu trái (tùy giống)\n'
          '2. Gai trái: Gai cách xa, màu xanh đậm → xanh nhạt\n'
          '3. Cuống trái: Cuống khô, nứt vòng quanh\n'
          '4. Mùi: Có mùi thơm nhẹ ở cuống\n'
          '5. Gõ trái: Âm thanh ộp ộp (chín), không giòn (còn sống)\n'
          '6. Rãnh giữa múi gai: Rãnh nông, múi gai phồng\n\n'
          'Lưu ý: Thu hoạch buổi sáng sớm, tránh mưa!',
      'category': 'Thu hoạch',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Hỏi Đáp Chuyên Gia'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[700]!, Colors.purple[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💬 Tư Vấn Miễn Phí',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đặt câu hỏi hoặc xem câu hỏi thường gặp',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Trả lời trong vòng 24h',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: DefaultTabController.of(context),
              labelColor: Colors.purple[700],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.purple[700],
              tabs: const [
                Tab(text: 'Hỏi đáp'),
                Tab(text: 'FAQ'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: TabBarView(
                children: [
                  _buildQATab(),
                  _buildFAQTab(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildInputSection(),
    );
  }

  Widget _buildQATab() {
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.question_answer_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có câu hỏi nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy đặt câu hỏi đầu tiên của bạn!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        return _buildConversationCard(_conversations[index]);
      },
    );
  }

  Widget _buildFAQTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqData.length,
      itemBuilder: (context, index) {
        return _buildFAQCard(faqData[index]);
      },
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.purple[700], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Câu hỏi của bạn',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      conversation['time'],
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: conversation['answered'] ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  conversation['answered'] ? 'Đã trả lời' : 'Chờ trả lời',
                  style: TextStyle(
                    fontSize: 11,
                    color: conversation['answered'] ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            conversation['question'],
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          if (conversation['answered']) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.green[700], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Trả lời từ chuyên gia',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    conversation['answer'],
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFAQCard(Map<String, String> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.help_outline, color: Colors.purple[700], size: 24),
          ),
          title: Text(
            faq['question']!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            faq['category']!,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.green[700], size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Câu trả lời',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      faq['answer']!,
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
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
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi của bạn...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[700]!, Colors.purple[500]!],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendQuestion,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sendQuestion() {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập câu hỏi')),
      );
      return;
    }

    setState(() {
      _conversations.insert(0, {
        'question': _questionController.text,
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} - ${DateTime.now().day}/${DateTime.now().month}',
        'answered': false,
        'answer': '',
      });
    });

    _questionController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Câu hỏi đã được gửi! Chuyên gia sẽ trả lời trong 24h'),
        backgroundColor: Colors.green[700],
      ),
    );

    // Giả lập trả lời sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _conversations[0]['answered'] = true;
          _conversations[0]['answer'] =
          'Cảm ơn bạn đã đặt câu hỏi! Đây là câu trả lời mẫu từ hệ thống.\n\n'
              'Để được tư vấn chi tiết hơn, vui lòng:\n'
              '• Cung cấp hình ảnh rõ nét\n'
              '• Mô tả cụ thể triệu chứng\n'
              '• Cho biết tuổi cây, giống cây\n'
              '• Thời tiết và điều kiện canh tác\n\n'
              'Chuyên gia sẽ hỗ trợ bạn sớm nhất!';
        });
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}