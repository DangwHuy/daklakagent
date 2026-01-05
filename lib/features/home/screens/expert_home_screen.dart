import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- SỬA LỖI IMPORT (DÙNG TƯƠNG ĐỐI) ---
// Giả định: file này nằm trong thư mục lib/screens/
// File auth_service.dart nằm trong thư mục lib/services/
import 'package:daklakagent/features/auth/screens/login_screen.dart';
// File login_screen.dart nằm cùng thư mục lib/screens/
import 'package:daklakagent/features/auth/services/auth_service.dart';

class ExpertHomeScreen extends StatefulWidget {
  const ExpertHomeScreen({super.key});

  @override
  State<ExpertHomeScreen> createState() => _ExpertHomeScreenState();
}

class _ExpertHomeScreenState extends State<ExpertHomeScreen> {
  final AuthService _authService = AuthService();

  // Hàm bật/tắt trạng thái Rảnh/Bận
  Future<void> _toggleStatus(bool currentStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'expertInfo.isOnline': !currentStatus,
        'lastActive': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus ? "Đã bật: Đang Rảnh" : "Đã tắt: Đang Bận"),
          backgroundColor: !currentStatus ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Hàm đăng xuất
  Future<void> _handleLogout() async {
    await _authService.signOut();

    if (!mounted) return;

    // Sửa lỗi context: Dùng pushAndRemoveUntil để xóa lịch sử về Login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Lỗi: Chưa đăng nhập")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Bảng Điều Khiển"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: "Đăng xuất",
          ),
        ],
      ),
      // --- SỬA LỖI TYPE STREAM BUILDER ---
      // Bỏ <Map<String, dynamic>> ở đây để tránh lỗi xung đột kiểu
      // Chúng ta sẽ ép kiểu thủ công bên trong builder
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Không tìm thấy hồ sơ"));
          }

          // --- ÉP KIỂU AN TOÀN NHẤT ---
          // Chuyển data sang Object rồi sang Map để tránh mọi lỗi type
          final rawData = snapshot.data!.data();
          if (rawData == null) return const Center(child: Text("Hồ sơ trống"));

          final Map<String, dynamic> data = rawData as Map<String, dynamic>;

          // Lấy thông tin
          final String name = data['displayName'] ?? "Chuyên gia";
          final String email = data['email'] ?? "";

          final Map<String, dynamic> expertInfo =
              (data['expertInfo'] as Map<String, dynamic>?) ?? {};

          final bool isOnline = expertInfo['isOnline'] ?? false;
          final String specialty = expertInfo['specialty'] ?? "Chưa cập nhật";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileCard(name, specialty, email),
                const SizedBox(height: 20),
                _buildStatusControl(isOnline),
                const SizedBox(height: 20),
                _buildStatsGrid(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget con: Thông tin cá nhân
  Widget _buildProfileCard(String name, String specialty, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[100],
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : "E",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(specialty, style: TextStyle(color: Colors.blue[700])),
                Text(email, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget con: Điều khiển trạng thái
  Widget _buildStatusControl(bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isOnline ? Icons.check_circle : Icons.remove_circle_outline,
                color: isOnline ? Colors.green : Colors.grey,
                size: 30,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? "Đang Rảnh" : "Đang Bận",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                  Text(isOnline ? "Sẵn sàng nhận việc" : "Không nhận cuộc gọi",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          Switch(
            value: isOnline,
            activeColor: Colors.green,
            onChanged: (val) => _toggleStatus(isOnline),
          ),
        ],
      ),
    );
  }

  // Widget con: Thống kê giả lập
  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildBox("Tư vấn", "0", Icons.phone)),
        const SizedBox(width: 10),
        Expanded(child: _buildBox("Đánh giá", "5.0", Icons.star)),
      ],
    );
  }

  Widget _buildBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}