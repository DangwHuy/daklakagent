// File này chỉ làm nhiệm vụ hiển thị thống kê. Logic lấy dữ liệu đã CỰC KỲ CHUẨN,
// tuyệt đối không cần thay đổi gì thêm.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daklakagent/features/auth/screens/login_screen.dart';
import 'package:daklakagent/features/auth/services/auth_service.dart';
import 'package:daklakagent/features/expret/ExpertProfile.dart';
import 'package:daklakagent/features/expret/ExpertAppointment.dart';
import 'package:daklakagent/features/home/screens/expert_chat_list_screen.dart';

class ExpertHomeScreen extends StatefulWidget {
  const ExpertHomeScreen({super.key});

  @override
  State<ExpertHomeScreen> createState() => _ExpertHomeScreenState();
}

class _ExpertHomeScreenState extends State<ExpertHomeScreen> {
  final AuthService _authService = AuthService();

  // ─── Toggle trạng thái Rảnh / Bận ─────────────────────────────────────────
  Future<void> _toggleStatus(bool currentStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'expertInfo.isOnline': !currentStatus,
        'lastActive': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(!currentStatus ? "Đã bật: Đang Rảnh" : "Đã tắt: Đang Bận"),
        backgroundColor: !currentStatus ? Colors.green : Colors.grey,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Lỗi: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ─── Đăng xuất ─────────────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    // 1. Tắt các hộp thoại đang mở (nếu có) để tránh lỗi kẹt màn hình
    Navigator.of(context).popUntil((route) => route.isFirst);

    // 2. Gọi lệnh đăng xuất Firebase. AuthGate sẽ TỰ ĐỘNG đưa bạn về Login!
    await FirebaseAuth.instance.signOut();
  }
  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Lỗi: Chưa đăng nhập")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          "Bảng Điều Khiển",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
            tooltip: "Đăng xuất",
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Không tìm thấy hồ sơ"));
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String name = data['displayName'] ?? "Chuyên gia";
          final String email = data['email'] ?? "";
          final String photoUrl = data['photoUrl'] ?? "";
          final Map<String, dynamic> expertInfo =
              (data['expertInfo'] as Map<String, dynamic>?) ?? {};
          final bool isOnline = expertInfo['isOnline'] ?? false;
          final String specialty = expertInfo['specialty'] ?? "Chưa cập nhật";

          // Lấy dữ liệu thống kê từ Firestore cực chuẩn tại đây:
          final int bookingCount = expertInfo['bookingCount'] ?? 0;
          final double rating = (expertInfo['rating'] ?? 5.0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(
                    name, specialty, email, photoUrl, isOnline),
                const SizedBox(height: 16),
                _buildStatusControl(isOnline),
                const SizedBox(height: 28),
                _sectionTitle("Chức năng quản lý"),
                const SizedBox(height: 12),
                // Truyền uid xuống để mỗi thẻ tự lắng nghe badge
                _buildActionGrid(context, user.uid),
                const SizedBox(height: 28),
                _sectionTitle("Thống kê cá nhân"),
                const SizedBox(height: 12),
                _buildStatsGrid(bookingCount, rating),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Section Title ──────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
  );

  // ─── Profile Card ───────────────────────────────────────────────────────────
  Widget _buildProfileCard(String name, String specialty, String email,
      String photoUrl, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white24,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? Text(
                    name.isNotEmpty
                        ? name[0].toUpperCase()
                        : "E",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 26,
                    ),
                  )
                      : null,
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    specialty,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status Control ─────────────────────────────────────────────────────────
  Widget _buildStatusControl(bool isOnline) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withOpacity(0.06)
            : Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? Colors.green.withOpacity(0.35)
              : Colors.grey.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isOnline
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_filled_rounded,
                color: isOnline ? Colors.green : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? "Đang Rảnh" : "Đang Bận",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isOnline
                          ? Colors.green[700]
                          : Colors.grey[700],
                    ),
                  ),
                  Text(
                    isOnline
                        ? "Sẵn sàng nhận lịch tư vấn"
                        : "Tạm ngưng nhận lịch mới",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
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
            onChanged: (_) => _toggleStatus(isOnline),
          ),
        ],
      ),
    );
  }

  // ─── Action Grid với Badge ──────────────────────────────────────────────────
  Widget _buildActionGrid(BuildContext context, String uid) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.2,
      children: [
        // ── Hồ sơ & Lịch (không cần badge) ──
        _buildActionCard(
          context,
          icon: Icons.edit_calendar_rounded,
          title: "Hồ sơ & Lịch",
          subtitle: "Quản lý lịch rảnh",
          color: Colors.green[600]!,
          badgeCount: 0,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ExpertProfileSetup()),
          ),
        ),

        // ── Yêu cầu Tư vấn – badge từ appointments pending ──
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('expertId', isEqualTo: uid)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snap) {
            final int pendingCount = snap.data?.docs.length ?? 0;
            return _buildActionCard(
              context,
              icon: Icons.event_note_rounded,
              title: "Yêu cầu Tư vấn",
              subtitle: "Danh sách lịch đặt",
              color: Colors.orange[600]!,
              badgeCount: pendingCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                    const ExpertAppointmentsScreen()),
              ),
            );
          },
        ),

        // ── Tin nhắn – badge từ chats có unreadCountExpert > 0 ──
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('expertId', isEqualTo: uid)
              .where('unreadCountExpert', isGreaterThan: 0)
              .snapshots(),
          builder: (context, snap) {
            final int unreadCount = snap.data?.docs.length ?? 0;
            return _buildActionCard(
              context,
              icon: Icons.chat_rounded,
              title: "Tin nhắn",
              subtitle: "Trò chuyện với bà con",
              color: Colors.blue[600]!,
              badgeCount: unreadCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExpertChatListScreen()),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Action Card với Badge overlay ─────────────────────────────────────────
  Widget _buildActionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required int badgeCount,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Nội dung thẻ ──
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 18, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style:
                    TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // ── Badge đỏ (chỉ hiển thị khi có thông báo) ──
            if (badgeCount > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 22,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeCount > 99 ? "99+" : badgeCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Stats Grid ─────────────────────────────────────────────────────────────
  Widget _buildStatsGrid(int bookingCount, double rating) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            label: "Lượt tư vấn",
            value: bookingCount.toString(),
            icon: Icons.people_alt_rounded,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatBox(
            label: "Đánh giá TB",
            value: rating.toStringAsFixed(1),
            icon: Icons.star_rounded,
            color: Colors.amber,
            suffix: "★",
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}