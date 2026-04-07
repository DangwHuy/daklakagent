import 'package:flutter/material.dart';

class MoTaScreen extends StatefulWidget {
  const MoTaScreen({super.key});

  @override
  State<MoTaScreen> createState() => _MoTaScreenState();
}

class _MoTaScreenState extends State<MoTaScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Màu nền xanh lá nông nghiệp nhạt cho toàn bộ màn hình
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Mô Tả Sản Phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF388E3C), // Xanh lá đậm nông nghiệp
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Thông tin chi tiết",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 15),

              // Ô nhập liệu to và đẹp
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 12, // Làm cho ô nhập liệu to ra
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Mời bạn nhập mô tả chi tiết tại đây...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.all(20),
                    border: InputBorder.none, // Bỏ viền mặc định để dùng viền Container
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Nút Xong thiết kế to, hiện đại
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  // Trong MoTaScreen.dart, tìm đến nút ElevatedButton
                  onPressed: () {
                    String moTa = _controller.text;
                    // Trả dữ liệu về màn hình trước và đóng màn hình hiện tại
                    Navigator.pop(context, moTa);
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text(
                    'XONG',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50), // Màu xanh lá tươi
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}