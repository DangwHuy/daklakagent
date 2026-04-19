import 'package:flutter/material.dart';

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Điều khoản & Chính sách",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              "1. Giới thiệu",
              "Chào mừng bạn đến với DaklakAgent. Bằng việc sử dụng ứng dụng của chúng tôi, bạn đồng ý tuân thủ các điều khoản và điều kiện được nêu dưới đây. Ứng dụng cung cấp các công cụ hỗ trợ nông nghiệp, kết nối chuyên gia và quản lý nhật ký nông hộ.",
            ),
            _buildSection(
              "2. Quyền sở hữu trí tuệ",
              "Tất cả nội dung, hình ảnh, mã nguồn và dữ liệu trên DaklakAgent đều thuộc sở hữu của đội ngũ phát triển hoặc được cấp phép sử dụng hợp pháp. Bạn không được sao chép, phân phối hoặc sử dụng cho mục đích thương mại mà không có sự đồng ý bằng văn bản.",
            ),
            _buildSection(
              "3. Chính sách bảo mật",
              "Chúng tôi cam kết bảo mật thông tin cá nhân của bạn. Dữ liệu như tên, email và vị trí địa lý chỉ được sử dụng để cải thiện trải nghiệm dịch vụ và hỗ trợ tư vấn nông sản. Chúng tôi không chia sẻ thông tin này cho bên thứ ba vì mục đích quảng cáo trái phép.",
            ),
            _buildSection(
              "4. Trách nhiệm người dùng",
              "Người dùng cam kết cung cấp thông tin chính xác khi đăng ký tài khoản và chịu trách nhiệm bảo mật mật khẩu của mình. Bạn không được sử dụng ứng dụng vào các mục đích vi phạm pháp luật hoặc gây hại cho cộng đồng nông nghiệp.",
            ),
            _buildSection(
              "5. Thay đổi điều khoản",
              "Chúng tôi có quyền cập nhật các điều khoản này bất kỳ lúc nào để phù hợp với sự phát triển của dịch vụ. Các thay đổi sẽ có hiệu lực ngay khi được đăng tải trên ứng dụng.",
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text(
                    "Phiên bản 1.0.0",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Cập nhật lần cuối: 15/04/2026",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
