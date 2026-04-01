import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daklakagent/features/auth/screens/login_screen.dart';
import 'package:daklakagent/features/auth/services/auth_service.dart';
// Import trang cài đặt hồ sơ vừa tạo
import 'package:daklakagent/features/expret/ExpertProfile.dart';
import 'package:daklakagent/features/expret/ExpertAppointment.dart';
// LƯU Ý: Import thêm trang ChatList vừa tạo để nút tin nhắn hoạt động
import 'package:daklakagent/features/home/screens/expert_chat_list_screen.dart';
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
      backgroundColor: Colors.grey[100], // UPDATED: Đổi background cho đồng nhất
      appBar: AppBar(
        title: const Text("Bảng Điều Khiển", style: TextStyle(fontWeight: FontWeight.bold)), // UPDATED: Chữ đậm
        backgroundColor: Colors.green[700], // UPDATED: Đổi từ blue sang green theo concept nông nghiệp
        foregroundColor: Colors.white,
        elevation: 0, // UPDATED: Xóa bóng mờ của AppBar để phẳng hơn
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout, tooltip: "Đăng xuất"),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Không tìm thấy hồ sơ"));

          final rawData = snapshot.data!.data();
          if (rawData == null) return const Center(child: Text("Hồ sơ trống"));
          final Map<String, dynamic> data = rawData as Map<String, dynamic>;

          final String name = data['displayName'] ?? "Chuyên gia";
          final String email = data['email'] ?? "";
          final String photoUrl = data['photoUrl'] ?? ""; // NEW: Lấy thêm avatar

          final Map<String, dynamic> expertInfo = (data['expertInfo'] as Map<String, dynamic>?) ?? {};
          final bool isOnline = expertInfo['isOnline'] ?? false;
          final String specialty = expertInfo['specialty'] ?? "Chưa cập nhật";

          // NEW: Lấy data thống kê từ DB (thay vì fix cứng)
          final int bookingCount = expertInfo['bookingCount'] ?? 0;
          final double rating = expertInfo['rating']?.toDouble() ?? 5.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(name, specialty, email, photoUrl, isOnline),
                const SizedBox(height: 16),

                _buildStatusControl(isOnline),
                const SizedBox(height: 24),

                const Text("Chức năng quản lý", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                _buildActionGrid(context),

                const SizedBox(height: 24),
                const Text("Thống kê cá nhân", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                _buildStatsGrid(bookingCount, rating), // UPDATED: Truyền data thật
              ],
            ),
          );
        },
      ),
    );
  }

  // UPDATED: Widget Thẻ thông tin cá nhân đồng bộ với Card FindExpertScreen
  Widget _buildProfileCard(String name, String specialty, String email, String photoUrl, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Nâng bo góc lên 20
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))], // Mềm bóng đổ
      ),
      child: Row(
        children: [
          // UPDATED: Cấu trúc Avatar giống hệt FindExpertScreen có chấm online
          Stack(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.green[50], // Đổi sang tone xanh
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : "E",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800], fontSize: 28))
                    : null,
              ),
              if (isOnline) // Chỉ hiện chấm xanh nếu đang rảnh
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 6),

                // UPDATED: Trình bày chức danh dưới dạng tag/chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    specialty,
                    style: TextStyle(fontSize: 13, color: Colors.green[800], fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Điều khiển trạng thái làm mềm UI hơn
  Widget _buildStatusControl(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOnline ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isOnline ? Icons.check_circle : Icons.pause_circle_filled,
                  color: isOnline ? Colors.green : Colors.grey, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isOnline ? "Đang Rảnh" : "Đang Bận",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOnline ? Colors.green[700] : Colors.grey[700])),
                  Text(isOnline ? "Sẵn sàng nhận lịch tư vấn" : "Tạm ngưng nhận lịch mới",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          Switch(
              value: isOnline,
              activeColor: Colors.white,
              activeTrackColor: Colors.green,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
              onChanged: (val) => _toggleStatus(isOnline)
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16, // Nới rộng xíu cho thoáng
      mainAxisSpacing: 16,
      childAspectRatio: 1.3, // UPDATED: Cho khối hình chữ nhật hơn chút
      children: [
        _buildActionCard(
          context,
          icon: Icons.edit_calendar,
          title: "Hồ sơ & Lịch",
          subtitle: "Quản lý lịch rảnh",
          color: Colors.green[600]!, // Đồng bộ xanh
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpertProfileSetup()));
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.question_answer,
          title: "Yêu cầu Tư vấn",
          subtitle: "Danh sách lịch đặt",
          color: Colors.orange[600]!, // Nổi bật
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExpertAppointmentsScreen()),
            );
          },
        ),
        // NEW: ĐÃ THÊM THẺ TIN NHẮN TẠI ĐÂY
        _buildActionCard(
          context,
          icon: Icons.chat,
          title: "Tin nhắn",
          subtitle: "Trò chuyện với bà con",
          color: Colors.blue[600]!, // Nổi bật với màu xanh lam
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExpertChatListScreen()),
            );
          },
        ),
      ],
    );
  }

  // UPDATED: Làm đẹp nút Action
  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])), // Mới thêm subtitle
          ],
        ),
      ),
    );
  }

  // UPDATED: Thống kê động (thay vì số cứng 0 và 5.0)
  Widget _buildStatsGrid(int bookingCount, double rating) {
    return Row(
      children: [
        Expanded(child: _buildBox("Lượt tư vấn", bookingCount.toString(), Icons.people_alt, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildBox("Đánh giá", rating.toStringAsFixed(1), Icons.star_rounded, Colors.amber)),
      ],
    );
  }

  // UPDATED: Cải thiện UI Box Thống kê
  Widget _buildBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}