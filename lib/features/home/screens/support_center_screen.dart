import 'package:flutter/material.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Trung tâm hỗ trợ",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: const [
                  Text(
                    "Chúng tôi có thể giúp gì cho bạn?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Tìm kiếm câu trả lời nhanh chóng hoặc liên hệ trực tiếp với chúng tôi",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FAQs Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Câu hỏi thường gặp",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFaqItem(
                    context,
                    "Làm thế nào để kết nối với chuyên gia?",
                    "Bạn chỉ cần vào mục 'Chuyên gia' ở màn hình chính, lựa chọn lĩnh vực cần tư vấn và nhấn nút 'Nhắn tin' hoặc 'Đặt lịch'.",
                  ),
                  _buildFaqItem(
                    context,
                    "Tôi có thể đăng ký làm chuyên gia được không?",
                    "Hoàn toàn được! Bạn hãy vào trang Tài khoản -> Trở thành Chuyên gia và điền đầy đủ thông tin hồ sơ để chúng tôi xét duyệt.",
                  ),
                  _buildFaqItem(
                    context,
                    "Cách sử dụng nhật ký nông hộ?",
                    "Mục Nhật ký nông hộ giúp bạn ghi lại quá trình chăm sóc cây trồng. Bạn có thể thêm ghi chú, hình ảnh và nhắc lịch bón phân.",
                  ),
                  _buildFaqItem(
                    context,
                    "Dữ liệu thời tiết lấy từ đâu?",
                    "Chúng tôi sử dụng dữ liệu thời tiết thời gian thực từ các trạm quan trắc uy tín nhất để cung cấp dự báo chính xác cho vùng của bạn.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Contact Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Liên hệ với chúng tôi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    Icons.email_outlined,
                    "Email hỗ trợ",
                    "support@daklakagent.vn",
                    Colors.blue,
                  ),
                  _buildContactCard(
                    Icons.phone_outlined,
                    "Hotline 24/7",
                    "1900 1234 (Miễn phí)",
                    Colors.orange,
                  ),
                  _buildContactCard(
                    Icons.language_outlined,
                    "Website",
                    "www.daklakagent.vn",
                    Colors.teal,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
        shape: const RoundedRectangleBorder(side: BorderSide.none),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
