import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daklakagent/features/auth/screens/login_screen.dart';
import 'package:daklakagent/features/auth/services/auth_service.dart';
// Import trang cài đặt hồ sơ vừa tạo
import 'package:daklakagent/features/expret/ExpertProfile.dart';
import 'package:daklakagent/features/expret/ExpertAppointment.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    }
  }

  // Hàm đăng xuất
  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Lỗi: Chưa đăng nhập")));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Bảng Điều Khiển"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout, tooltip: "Đăng xuất"),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Không tìm thấy hồ sơ"));

          final rawData = snapshot.data!.data();
          if (rawData == null) return const Center(child: Text("Hồ sơ trống"));
          final Map<String, dynamic> data = rawData as Map<String, dynamic>;

          final String name = data['displayName'] ?? "Chuyên gia";
          final String email = data['email'] ?? "";
          final Map<String, dynamic> expertInfo = (data['expertInfo'] as Map<String, dynamic>?) ?? {};
          final bool isOnline = expertInfo['isOnline'] ?? false;
          final String specialty = expertInfo['specialty'] ?? "Chưa cập nhật";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(name, specialty, email),
                const SizedBox(height: 20),

                _buildStatusControl(isOnline),
                const SizedBox(height: 20),

                // --- PHẦN MỚI THÊM: Menu Chức Năng ---
                const Text("Chức năng quản lý", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                _buildActionGrid(context),

                const SizedBox(height: 20),
                const Text("Thống kê nhanh", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                _buildStatsGrid(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget Thẻ thông tin cá nhân
  Widget _buildProfileCard(String name, String specialty, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[100],
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : "E",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800], fontSize: 24)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(specialty, style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                Text(email, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Điều khiển trạng thái Online/Offline
  Widget _buildStatusControl(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isOnline ? Icons.circle : Icons.circle_outlined, color: isOnline ? Colors.green : Colors.grey, size: 16),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isOnline ? "Đang Rảnh" : "Đang Bận", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOnline ? Colors.green : Colors.grey)),
                  Text(isOnline ? "Sẵn sàng nhận lịch" : "Tạm ngưng nhận lịch", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          Switch(value: isOnline, activeColor: Colors.green, onChanged: (val) => _toggleStatus(isOnline)),
        ],
      ),
    );
  }

  // Widget Menu Chức năng (Grid)
  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          icon: Icons.edit_calendar,
          title: "Hồ sơ & Lịch",
          color: Colors.orange,
          onTap: () {
            // Điều hướng sang trang cài đặt hồ sơ
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpertProfileSetup()));
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.question_answer,
          title: "Yêu cầu Tư vấn", // Hoặc "Quản lý Lịch hẹn"
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExpertAppointmentsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // Widget Thống kê (Giữ nguyên)
  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildBox("Lượt tư vấn", "0", Icons.phone_in_talk, Colors.purple)),
        const SizedBox(width: 15),
        Expanded(child: _buildBox("Đánh giá", "5.0", Icons.star, Colors.amber)),
      ],
    );
  }

  Widget _buildBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}