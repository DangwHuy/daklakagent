// ─────────────────────────────────────────────────────────────────────────────
// expert_home_screen.dart  –  PHIÊN BẢN NÂNG CẤP (CẬP NHẬT LUỒNG DỮ LIỆU)
// Tính năng mới thêm vào:
//   • Kết nối Quick-actions để chuyển tab (Hôm nay, Chờ duyệt).
//   • Popup hiển thị Báo cáo & Hướng dẫn Thu nhập tiền mặt.
//   • Tích hợp Hòm thư Thông báo (Quả chuông góc trên).
//   • KHÔNG LÀM THAY ĐỔI UI HAY LOGIC CŨ.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:daklakagent/features/auth/services/auth_service.dart';
import 'package:daklakagent/features/expret/ExpertProfile.dart';
import 'package:daklakagent/features/expret/ExpertAppointment.dart';
import 'package:daklakagent/features/home/screens/expert_chat_list_screen.dart';
import 'package:daklakagent/features/expret/expert_report_screen.dart';
import 'package:daklakagent/features/expret/expert_today_screen.dart';
import 'package:daklakagent/features/community/screens/posts_screen.dart';
import 'package:daklakagent/features/home/screens/pest_disease_screen.dart';
import 'package:daklakagent/features/home/screens/price_screen.dart';
import 'package:daklakagent/features/expret/expert_help_screen.dart';
// ─── Enum bộ lọc thời gian biểu đồ ──────────────────────────────────────────
enum ChartPeriod { day7, month, quarter, year }

// ─── Model dữ liệu biểu đồ ────────────────────────────────────────────────────
class _ChartData {
  final List<FlSpot> spots;
  final List<FlSpot> cancelledSpots;
  final List<FlSpot> revenueSpots;
  final List<String> labels;
  const _ChartData({
    required this.spots,
    required this.cancelledSpots,
    required this.revenueSpots,
    required this.labels,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. MÀN HÌNH CHÍNH (BOTTOM NAV BAR)
// ═════════════════════════════════════════════════════════════════════════════
class ExpertHomeScreen extends StatefulWidget {
  const ExpertHomeScreen({super.key});

  @override
  State<ExpertHomeScreen> createState() => _ExpertHomeScreenState();
}

class _ExpertHomeScreenState extends State<ExpertHomeScreen> {
  int _selectedIndex = 0;

  // NÂNG CẤP: Chuyển _pages vào initState để có thể truyền hàm _onItemTapped xuống Dashboard
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _DashboardContent(onNavigate: _onItemTapped), // Truyền hàm chuyển tab xuống
      const ExpertAppointmentsScreen(),
      const PostsScreen(),
      const ExpertChatListScreen(),
      const ExpertProfileSetup(),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.green[800],
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.dashboard, size: 24),
                ),
                icon: const Icon(Icons.dashboard_outlined, size: 24),
                label: 'Tổng quan',
              ),
              BottomNavigationBarItem(
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.calendar_month, size: 24),
                ),
                icon: const Icon(Icons.calendar_month_outlined, size: 24),
                label: 'Lịch hẹn',
              ),
              BottomNavigationBarItem(
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.groups, size: 24),
                ),
                icon: const Icon(Icons.groups_outlined, size: 24),
                label: 'Diễn đàn',
              ),
              BottomNavigationBarItem(
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.chat, size: 24),
                ),
                icon: const Icon(Icons.chat_outlined, size: 24),
                label: 'Tin nhắn',
              ),
              BottomNavigationBarItem(
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person, size: 24),
                ),
                icon: const Icon(Icons.person_outline, size: 24),
                label: 'Hồ sơ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. NỘI DUNG BẢNG ĐIỀU KHIỂN
// ═════════════════════════════════════════════════════════════════════════════
class _DashboardContent extends StatefulWidget {
  final Function(int) onNavigate; // NÂNG CẤP: Nhận lệnh chuyển tab từ cha

  const _DashboardContent({required this.onNavigate});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  // Bộ lọc biểu đồ hiện tại
  ChartPeriod _selectedPeriod = ChartPeriod.day7;
  int _chartMode = 0; // 0 = Số ca, 1 = Doanh thu

  // Animation nhấp nháy cho cảnh báo sắp đến giờ
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  // Timer làm mới đếm ngược mỗi phút
  Timer? _countdownTimer;

  // Cached Streams to prevent Page Reloads
  Stream<DocumentSnapshot>? _userProfileStream;
  Stream<QuerySnapshot>? _appointmentsStream;
  Stream<QuerySnapshot>? _confirmedAppointmentsStream;
  Stream<QuerySnapshot>? _unreadNotificationsStream;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _blinkAnimation =
        Tween<double>(begin: 0.25, end: 1.0).animate(_blinkController);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userProfileStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
      _appointmentsStream = FirebaseFirestore.instance.collection('appointments').where('expertId', isEqualTo: user.uid).snapshots();
      _confirmedAppointmentsStream = FirebaseFirestore.instance.collection('appointments').where('expertId', isEqualTo: user.uid).where('status', isEqualTo: 'confirmed').snapshots();
      _unreadNotificationsStream = FirebaseFirestore.instance.collection('notifications').where('receiverId', isEqualTo: user.uid).where('isRead', isEqualTo: false).snapshots();
    }

    // Rebuild mỗi 60 giây để cập nhật đếm ngược
    _countdownTimer = Timer.periodic(
        const Duration(seconds: 60), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ─── Toggle trạng thái ───────────────────────────────────────────────────
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
        content:
        Text(!currentStatus ? "✅ Đã bật: Đang Rảnh" : "⏸️ Đã tắt: Đang Bận"),
        backgroundColor: !currentStatus ? Colors.green[600] : Colors.grey[600],
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Lỗi: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ─── Đăng xuất ──────────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    await FirebaseAuth.instance.signOut();
  }

  // Hàm tính thời gian tương đối
  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "Vừa xong";
    final now = DateTime.now();
    final diff = now.difference(timestamp.toDate());
    if (diff.inDays > 7) return "${timestamp.toDate().day}/${timestamp.toDate().month}";
    if (diff.inDays > 0) return "${diff.inDays} ngày trước";
    if (diff.inHours > 0) return "${diff.inHours} giờ trước";
    if (diff.inMinutes > 0) return "${diff.inMinutes} phút trước";
    return "Vừa xong";
  }

  // ─── NÂNG CẤP: Hàm hiển thị Hòm thư Thông báo ───────────────────────────
  void _showNotificationsDialog(String expertUid) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Thông báo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () async {
                        final batch = FirebaseFirestore.instance.batch();
                        final unreadDocs = await FirebaseFirestore.instance
                            .collection('notifications')
                            .where('receiverId', isEqualTo: expertUid)
                            .where('isRead', isEqualTo: false)
                            .get();
                        for (var doc in unreadDocs.docs) {
                          batch.update(doc.reference, {'isRead': true});
                        }
                        batch.commit();
                      },
                      child: const Text("Đã đọc tất cả", style: TextStyle(color: Colors.green)),
                    )
                  ],
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('notifications')
                          .where('receiverId', isEqualTo: expertUid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.green));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 10),
                                Text("Chưa có thông báo nào.", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs.toList();
                        docs.sort((a, b) {
                          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                          if (aTime == null || bTime == null) return 0;
                          return bTime.compareTo(aTime);
                        });

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final isRead = data['isRead'] ?? false;
                            final timeStr = _formatTimeAgo(data['createdAt'] as Timestamp?);

                            return Dismissible(
                              key: Key(doc.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) {
                                FirebaseFirestore.instance.collection('notifications').doc(doc.id).delete();
                              },
                              child: Container(
                                color: isRead ? Colors.transparent : Colors.green.withOpacity(0.05),
                                child: ListTile(
                                  onTap: () {
                                    if (!isRead) {
                                      FirebaseFirestore.instance.collection('notifications').doc(doc.id).update({'isRead': true});
                                    }
                                    Navigator.pop(context);
                                    widget.onNavigate(1);
                                  },
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isRead ? Colors.grey[200] : Colors.green[100],
                                        child: Icon(
                                          Icons.calendar_month, 
                                          color: isRead ? Colors.grey[600] : Colors.green[700], 
                                          size: 20
                                        )
                                      ),
                                      if (!isRead)
                                        Positioned(
                                          top: 0, right: 0,
                                          child: Container(
                                            width: 10, height: 10,
                                            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                          )
                                        )
                                    ],
                                  ),
                                  title: Text(
                                    data['title'] ?? 'Thông báo mới', 
                                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(data['body'] ?? '', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                      const SizedBox(height: 4),
                                      Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                    ],
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                ),
                              ),
                            );
                          },
                        );
                      }
                  ),
                )
              ],
            ),
          );
        }
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userProfileStream == null) {
      return const Scaffold(
          body: Center(child: Text("Lỗi: Chưa đăng nhập")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Disable material 3 tint
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/images/ai_logo.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Chuyên gia",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _unreadNotificationsStream,
            builder: (context, snapshot) {
              int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.notifications_outlined, color: Colors.grey[800], size: 22),
                      onPressed: () => _showNotificationsDialog(user.uid),
                      tooltip: "Thông báo",
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.red[600], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            }
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: IconButton(
              icon: Icon(Icons.logout_rounded, color: Colors.red[600], size: 20),
              onPressed: _handleLogout,
              tooltip: "Đăng xuất",
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userProfileStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
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
          final String specialty =
              expertInfo['specialty'] ?? "Chưa cập nhật";
          final int bookingCount = expertInfo['bookingCount'] ?? 0;
          final double rating =
          (expertInfo['rating'] ?? 5.0).toDouble();
          final int pendingCount = expertInfo['pendingCount'] ?? 0;
          final double revenue =
          (expertInfo['revenue'] ?? 0.0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thẻ hồ sơ
                _buildProfileCard(
                    name, specialty, email, photoUrl, isOnline),
                const SizedBox(height: 16),

                // ── Nút trạng thái Rảnh / Bận
                _buildStatusControl(isOnline),
                const SizedBox(height: 16),

                // ── Quick-action buttons
                _buildQuickActions(bookingCount, revenue), // NÂNG CẤP: Truyền biến vào hàm
                const SizedBox(height: 24),

                // ── Cảnh báo lịch hẹn sắp tới
                _buildUpcomingAlert(user.uid),

                // ── 4 stat-cards
                _sectionTitle("Tổng quan hiệu suất"),
                const SizedBox(height: 12),
                _buildStatsGrid(
                    bookingCount, rating, pendingCount, revenue),
                const SizedBox(height: 28),

                // ── Biểu đồ đường với bộ lọc
                _sectionTitle("Biểu đồ tư vấn"),
                const SizedBox(height: 12),
                _buildChartPeriodSelector(),
                const SizedBox(height: 12),
                _buildPerformanceChart(user.uid),
                const SizedBox(height: 28),

                // ── Biểu đồ tròn trạng thái
                _sectionTitle("Phân bố trạng thái lịch hẹn"),
                const SizedBox(height: 12),
                _buildAppointmentStatusChart(user.uid),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGETS CON
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Section title ────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );

  // ─── NÂNG CẤP: Quick Actions với logic kết nối ────────────────────────────
  Widget _buildQuickActions(int bookingCount, double revenue) {
    final operationalActions = [
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Hôm nay',
        'color': Colors.blue[600]!,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertTodayScreen())),
      },
      {
        'icon': Icons.pending_actions_rounded,
        'label': 'Chờ duyệt',
        'color': Colors.orange[600]!,
        'onTap': () => widget.onNavigate(1),
      },
      {
        'icon': Icons.bar_chart_rounded,
        'label': 'Báo cáo',
        'color': Colors.purple[600]!,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertReportScreen())),
      },
      {
        'icon': Icons.payments_rounded,
        'label': 'Thu nhập',
        'color': Colors.green[700]!,
        'onTap': () => _showRevenueGuideDialog(),
      },
    ];

    final utilityActions = [
      {
        'icon': Icons.bug_report_rounded,
        'label': 'Tra sâu bệnh',
        'color': Colors.red[600]!,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PestDiseaseScreen())),
      },
      {
        'icon': Icons.trending_up_rounded,
        'label': 'Giá cả',
        'color': Colors.orange[800]!,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgriPriceHome())),
      },
      {
        'icon': Icons.help_outline_rounded,
        'label': 'Trợ giúp',
        'color': Colors.teal[600]!,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertHelpScreen())),
      },
      {
        'icon': Icons.settings_rounded,
        'label': 'Cài đặt',
        'color': Colors.blueGrey[600]!,
        'onTap': () {}, // Placeholder
      },
    ];

    return Column(
      children: [
        _buildActionRow(operationalActions),
        const SizedBox(height: 12),
        _buildActionRow(utilityActions),
      ],
    );
  }

  Widget _buildActionRow(List<Map<String, dynamic>> actions) {
    return Row(
      children: List.generate(actions.length, (i) {
        final a = actions[i];
        final color = a['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: a['onTap'] as VoidCallback,
            child: Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a['icon'] as IconData,
                        color: color, size: 22),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    a['label'] as String,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── NÂNG CẤP: Dialog Báo cáo ─────────────────────────────────────────────
  void _showReportDialog(int totalAppointments, double totalRevenue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: Colors.purple),
            SizedBox(width: 10),
            Text("Báo cáo tổng quan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tổng số ca đã nhận: $totalAppointments ca", style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 10),
            Text("Tổng thu nhập ước tính: ${totalRevenue.toStringAsFixed(0)} VNĐ", style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(10)),
              child: const Text(
                "Tính năng xuất báo cáo chi tiết ra file Excel đang được phát triển.",
                style: TextStyle(color: Colors.purple, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))
        ],
      ),
    );
  }

  // ─── NÂNG CẤP: Dialog Hướng dẫn Thu nhập ──────────────────────────────────
  void _showRevenueGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.monetization_on, color: Colors.green),
            SizedBox(width: 10),
            Text("Quy trình Thu Nhập", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Do đặc thù làm việc tại vườn, ứng dụng sẽ hoạt động như một sổ tay tài chính cá nhân:",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildGuideStep("1", "Đến vườn tư vấn cho bà con nông dân."),
            const SizedBox(height: 10),
            _buildGuideStep("2", "Thu tiền mặt (hoặc chuyển khoản) trực tiếp từ nông dân."),
            const SizedBox(height: 10),
            _buildGuideStep("3", "Vào mục Lịch Hẹn, bấm 'Xác nhận hoàn thành' và nhập số tiền vừa nhận để hệ thống lưu báo cáo."),
          ],
        ),
        actions: [
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text("Đã hiểu")
          )
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 12, backgroundColor: Colors.green[100], child: Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800]))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87))),
      ],
    );
  }


  // ─── Cảnh báo lịch hẹn sắp tới ──────────────────────────────────────────
  Widget _buildUpcomingAlert(String expertUid) {
    final now = DateTime.now();
    final endOfDay =
    DateTime(now.year, now.month, now.day, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: _confirmedAppointmentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Tìm lịch hẹn gần nhất trong ngày hôm nay
        Map<String, dynamic>? soonest;
        DateTime? soonestTime;
        for (var doc in snapshot.data!.docs) {
          final d = doc.data() as Map<String, dynamic>;
          if (d['time'] == null) continue;
          final t = (d['time'] as Timestamp).toDate();
          if (t.isAfter(now) && t.isBefore(endOfDay)) {
            if (soonestTime == null || t.isBefore(soonestTime)) {
              soonestTime = t;
              soonest = d;
            }
          }
        }

        if (soonest == null || soonestTime == null) {
          return const SizedBox.shrink();
        }

        final diff = soonestTime.difference(now);
        final isUrgent = diff.inMinutes <= 120; // ≤ 2 tiếng
        final timeStr =
            '${soonestTime.hour.toString().padLeft(2, '0')}:${soonestTime.minute.toString().padLeft(2, '0')}';

        String countdownStr;
        if (diff.inMinutes < 60) {
          countdownStr = 'Còn ${diff.inMinutes} phút nữa!';
        } else {
          countdownStr =
          'Còn ${diff.inHours} giờ ${diff.inMinutes % 60} phút nữa';
        }

        final Widget card = Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUrgent
                ? Colors.red.withOpacity(0.06)
                : Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUrgent
                  ? Colors.red.withOpacity(0.55)
                  : Colors.blue.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? Colors.red.withOpacity(0.12)
                      : Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUrgent
                      ? Icons.alarm_rounded
                      : Icons.event_available_rounded,
                  color: isUrgent ? Colors.red[700] : Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrgent
                          ? '⚠️  Sắp đến giờ!'
                          : '📅  Lịch hẹn hôm nay',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isUrgent
                            ? Colors.red[700]
                            : Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Lúc $timeStr  •  ${soonest!['patientName'] ?? 'Khách hàng'}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      countdownStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isUrgent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isUrgent
                            ? Colors.red[600]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isUrgent)
                GestureDetector(
                  onTap: () => widget.onNavigate(1), // NÂNG CẤP: Chạm vào đây cũng chuyển sang tab Lịch
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Vào xem',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );

        // Nhấp nháy khi khẩn cấp
        if (isUrgent) {
          return AnimatedBuilder(
            animation: _blinkAnimation,
            builder: (_, child) =>
                Opacity(opacity: _blinkAnimation.value, child: child),
            child: card,
          );
        }
        return card;
      },
    );
  }

  // ─── Bộ lọc kỳ biểu đồ ──────────────────────────────────────────────────
  Widget _buildChartPeriodSelector() {
    const periods = [
      (ChartPeriod.day7, '7 Ngày'),
      (ChartPeriod.month, 'Tháng'),
      (ChartPeriod.quarter, 'Quý'),
      (ChartPeriod.year, 'Năm'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = _selectedPeriod == p.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedPeriod = p.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                    const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 1))
                  ]
                      : null,
                ),
                child: Text(
                  p.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.green[700]
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Biểu đồ đường hiệu suất & Doanh thu ────────────────────────────────
  Widget _buildPerformanceChart(String expertUid) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      height: 330,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Text(
                _periodTitle(),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
              const Spacer(),
              // Tabs gạt đổi chế độ
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _chartMode = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _chartMode == 0
                              ? Colors.green[100]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("Số lượng",
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: _chartMode == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _chartMode == 0
                                    ? Colors.green[800]
                                    : Colors.grey[600])),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _chartMode = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _chartMode == 1
                              ? Colors.orange[100]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("Doanh thu",
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: _chartMode == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _chartMode == 1
                                    ? Colors.orange[800]
                                    : Colors.grey[600])),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _appointmentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.green));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Lỗi tải dữ liệu",
                          style: TextStyle(color: Colors.grey[400])));
                }

                final docs = snapshot.data?.docs ?? [];
                final chartData = _buildChartData(docs);
                
                if (_chartMode == 0) {
                  return _buildLineChart(chartData);
                } else {
                  return _buildBarChart(chartData);
                }
              },
            ),
          ),
          if (_chartMode == 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.green[600],
                          shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Ca tư vấn',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 16),
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.red[400], shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Ca đã hủy',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLineChart(_ChartData chartData) {
    double maxY = 0;
    for (var s in chartData.spots) {
      if (s.y > maxY) maxY = s.y;
    }
    for (var s in chartData.cancelledSpots) {
      if (s.y > maxY) maxY = s.y;
    }
    if (maxY < 4) maxY = 4;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (chartData.spots.length - 1).toDouble(),
        minY: 0,
        maxY: maxY + 1.5,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.grey.withOpacity(0.12),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble())
                  return const SizedBox.shrink();
                final idx = value.toInt();
                if (idx < 0 || idx >= chartData.labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    chartData.labels[idx],
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 9.5),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            tooltipRoundedRadius: 10,
            tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final label = (idx >= 0 && idx < chartData.labels.length)
                    ? chartData.labels[idx].replaceAll('\n', ' ')
                    : '';
                final isCancel = spot.barIndex == 1;
                return LineTooltipItem(
                  '$label\n',
                  const TextStyle(
                      color: Colors.white70, fontSize: 11),
                  children: [
                    TextSpan(
                      text:
                          '${spot.y.toInt()} ${isCancel ? "ca đã hủy" : "ca tư vấn"}',
                      style: TextStyle(
                        color: isCancel
                            ? Colors.red[300]
                            : Colors.green[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: chartData.spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: Colors.green[600],
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.3),
                  Colors.green.withOpacity(0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: chartData.cancelledSpots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: Colors.red[400],
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(_ChartData chartData) {
    double maxY = 0;
    for (var s in chartData.revenueSpots) {
      if (s.y > maxY) maxY = s.y;
    }
    if (maxY == 0) maxY = 100000;

    final double defaultInterval = maxY / 4;

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.grey.withOpacity(0.12),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= chartData.labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    chartData.labels[idx],
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 9.5),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: defaultInterval,
              getTitlesWidget: (value, meta) {
                if (value == 0)
                  return const Text("0",
                      style: TextStyle(color: Colors.grey, fontSize: 10));
                String text = '';
                if (value >= 1000000) {
                  text = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  text = '${(value / 1000).toStringAsFixed(0)}K';
                } else {
                  text = value.toInt().toString();
                }
                return Text(text,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 10));
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.orange[800]!,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = group.x.toInt();
              final label = (idx >= 0 && idx < chartData.labels.length)
                  ? chartData.labels[idx].replaceAll('\n', ' ')
                  : '';
              return BarTooltipItem(
                '$label\n',
                const TextStyle(color: Colors.white70, fontSize: 11),
                children: [
                  TextSpan(
                    text: '${rod.toY.toInt()}đ',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: List.generate(chartData.revenueSpots.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: chartData.revenueSpots[i].y,
                color: Colors.orange[400],
                width: 14,
                borderRadius: BorderRadius.circular(4),
              )
            ],
          );
        }),
      ),
    );
  }

  // ─── Biểu đồ tròn trạng thái lịch hẹn ───────────────────────────────────
  Widget _buildAppointmentStatusChart(String expertUid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      height: 230,
      child: StreamBuilder<QuerySnapshot>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child:
                CircularProgressIndicator(color: Colors.green));
          }

          int confirmed = 0,
              pending = 0,
              cancelled = 0,
              completed = 0;
          for (var doc in snapshot.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            switch (d['status']) {
              case 'confirmed':
                confirmed++;
                break;
              case 'pending':
                pending++;
                break;
              case 'cancelled':
                cancelled++;
                break;
              case 'completed':
                completed++;
                break;
            }
          }

          final total =
              confirmed + pending + cancelled + completed;

          if (total == 0) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pie_chart_outline_rounded,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('Chưa có lịch hẹn',
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            );
          }

          final statusData = [
            _StatusItem(
                label: 'Đã xác nhận',
                count: confirmed,
                color: Colors.green[500]!),
            _StatusItem(
                label: 'Hoàn thành',
                count: completed,
                color: Colors.blue[400]!),
            _StatusItem(
                label: 'Chờ xác nhận',
                count: pending,
                color: Colors.orange[400]!),
            _StatusItem(
                label: 'Đã hủy',
                count: cancelled,
                color: Colors.red[400]!),
          ].where((s) => s.count > 0).toList();

          return Row(
            children: [
              // Pie chart
              Expanded(
                flex: 5,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 38,
                    sections: statusData
                        .map((s) => PieChartSectionData(
                      value: s.count.toDouble(),
                      color: s.color,
                      radius: 44,
                      title: s.count.toString(),
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: statusData
                      .map((s) => Padding(
                    padding:
                    const EdgeInsets.only(bottom: 12),
                    child: _legendItem(
                        s.color, s.label, s.count, total),
                  ))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendItem(
      Color color, String label, int count, int total) {
    final pct = total > 0
        ? (count / total * 100).toStringAsFixed(0)
        : '0';
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black87)),
        ),
        Text('$pct%',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─── Chart data builders ──────────────────────────────────────────────────
  _ChartData _buildChartData(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ChartPeriod.day7:
        return _build7DayData(docs, now);
      case ChartPeriod.month:
        return _buildMonthData(docs, now);
      case ChartPeriod.quarter:
        return _buildQuarterData(docs, now);
      case ChartPeriod.year:
        return _buildYearData(docs, now);
    }
  }

  _ChartData _build7DayData(
      List<QueryDocumentSnapshot> docs, DateTime now) {
    const dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final labels = <String>[];
    final counts = List.filled(7, 0);
    final cancelledCounts = List.filled(7, 0);
    final revenues = List.filled(7, 0.0);

    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      labels.add('${dayNames[d.weekday % 7]}\n${d.day}/${d.month}');
    }
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['time'] == null) continue;
      final t = (data['time'] as Timestamp).toDate();
      final status = data['status'];
      final revenue = (data['earnedRevenue'] ?? 0) as num;

      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        if (t.year == d.year &&
            t.month == d.month &&
            t.day == d.day) {
          if (status == 'cancelled') {
            cancelledCounts[6 - i]++;
          } else if (status == 'confirmed' || status == 'completed') {
            counts[6 - i]++;
            if (status == 'completed') revenues[6 - i] += revenue.toDouble();
          }
        }
      }
    }
    return _ChartData(
      spots: List.generate(7, (i) => FlSpot(i.toDouble(), counts[i].toDouble())),
      cancelledSpots: List.generate(7, (i) => FlSpot(i.toDouble(), cancelledCounts[i].toDouble())),
      revenueSpots: List.generate(7, (i) => FlSpot(i.toDouble(), revenues[i])),
      labels: labels,
    );
  }

  _ChartData _buildMonthData(
      List<QueryDocumentSnapshot> docs, DateTime now) {
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;
    final numWeeks = (daysInMonth / 7).ceil();
    final counts = List.filled(numWeeks, 0);
    final cancelledCounts = List.filled(numWeeks, 0);
    final revenues = List.filled(numWeeks, 0.0);
    final labels =
    List.generate(numWeeks, (i) => 'Tuần\n${i + 1}');

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['time'] == null) continue;
      final t = (data['time'] as Timestamp).toDate();
      final status = data['status'];
      final revenue = (data['earnedRevenue'] ?? 0) as num;
      
      if (t.year == now.year && t.month == now.month) {
        int w = ((t.day - 1) / 7).floor();
        if (w >= numWeeks) w = numWeeks - 1;
        if (status == 'cancelled') {
          cancelledCounts[w]++;
        } else if (status == 'confirmed' || status == 'completed') {
          counts[w]++;
          if (status == 'completed') revenues[w] += revenue.toDouble();
        }
      }
    }
    return _ChartData(
      spots: List.generate(numWeeks, (i) => FlSpot(i.toDouble(), counts[i].toDouble())),
      cancelledSpots: List.generate(numWeeks, (i) => FlSpot(i.toDouble(), cancelledCounts[i].toDouble())),
      revenueSpots: List.generate(numWeeks, (i) => FlSpot(i.toDouble(), revenues[i])),
      labels: labels,
    );
  }

  _ChartData _buildQuarterData(
      List<QueryDocumentSnapshot> docs, DateTime now) {
    final labels = <String>[];
    final counts = List.filled(3, 0);
    final cancelledCounts = List.filled(3, 0);
    final revenues = List.filled(3, 0.0);

    for (int i = 2; i >= 0; i--) {
      int month = now.month - i;
      int year = now.year;
      while (month < 1) {
        month += 12;
        year--;
      }
      labels.add('T$month');
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['time'] == null) continue;
        final t = (data['time'] as Timestamp).toDate();
        final status = data['status'];
        final revenue = (data['earnedRevenue'] ?? 0) as num;
        
        if (t.year == year && t.month == month) {
          if (status == 'cancelled') {
            cancelledCounts[2 - i]++;
          } else if (status == 'confirmed' || status == 'completed') {
            counts[2 - i]++;
            if (status == 'completed') revenues[2 - i] += revenue.toDouble();
          }
        }
      }
    }
    return _ChartData(
      spots: List.generate(3, (i) => FlSpot(i.toDouble(), counts[i].toDouble())),
      cancelledSpots: List.generate(3, (i) => FlSpot(i.toDouble(), cancelledCounts[i].toDouble())),
      revenueSpots: List.generate(3, (i) => FlSpot(i.toDouble(), revenues[i])),
      labels: labels,
    );
  }

  _ChartData _buildYearData(
      List<QueryDocumentSnapshot> docs, DateTime now) {
    final counts = List.filled(12, 0);
    final cancelledCounts = List.filled(12, 0);
    final revenues = List.filled(12, 0.0);
    final labels =
    List.generate(12, (i) => 'T${i + 1}');

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['time'] == null) continue;
      final t = (data['time'] as Timestamp).toDate();
      final status = data['status'];
      final revenue = (data['earnedRevenue'] ?? 0) as num;

      if (t.year == now.year) {
        final idx = t.month - 1;
        if (status == 'cancelled') {
          cancelledCounts[idx]++;
        } else if (status == 'confirmed' || status == 'completed') {
          counts[idx]++;
          if (status == 'completed') revenues[idx] += revenue.toDouble();
        }
      }
    }
    return _ChartData(
      spots: List.generate(12, (i) => FlSpot(i.toDouble(), counts[i].toDouble())),
      cancelledSpots: List.generate(12, (i) => FlSpot(i.toDouble(), cancelledCounts[i].toDouble())),
      revenueSpots: List.generate(12, (i) => FlSpot(i.toDouble(), revenues[i])),
      labels: labels,
    );
  }

  String _periodTitle() {
    switch (_selectedPeriod) {
      case ChartPeriod.day7:
        return '7 ngày gần nhất';
      case ChartPeriod.month:
        return 'Tháng ${DateTime.now().month} / ${DateTime.now().year}';
      case ChartPeriod.quarter:
        return '3 tháng gần nhất';
      case ChartPeriod.year:
        return 'Cả năm ${DateTime.now().year}';
    }
  }

  // ─── Thẻ hồ sơ ────────────────────────────────────────────────────────────
  Widget _buildProfileCard(String name, String specialty,
      String email, String photoUrl, bool isOnline) {
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
                  border:
                  Border.all(color: Colors.white, width: 2.5),
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
                      border: Border.all(
                          color: Colors.white, width: 2),
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

  // ─── Nút Rảnh / Bận ──────────────────────────────────────────────────────
  Widget _buildStatusControl(bool isOnline) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
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

  // ─── 4 stat-cards ────────────────────────────────────────────────────────
  Widget _buildStatsGrid(int bookingCount, double rating,
      int pendingCount, double revenue) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                label: 'Tổng ca đã nhận',
                value: bookingCount.toString(),
                icon: Icons.people_alt_rounded,
                color: Colors.blue[600]!,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatBox(
                label: 'Đánh giá TB',
                value: rating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: Colors.amber[600]!,
                suffix: '★',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                label: 'Chờ xác nhận',
                value: pendingCount.toString(),
                icon: Icons.pending_actions_rounded,
                color: Colors.orange[600]!,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatBox(
                label: 'Thu nhập (k)',
                value: (revenue / 1000).toStringAsFixed(0),
                icon: Icons.payments_rounded,
                color: Colors.green[700]!,
                suffix: 'k',
              ),
            ),
          ],
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
      padding:
      const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2))
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (suffix != null)
                Text(
                  ' $suffix',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Helper model ──────────────────────────────────────────────────────────────
class _StatusItem {
  final String label;
  final int count;
  final Color color;
  const _StatusItem(
      {required this.label,
        required this.count,
        required this.color});
}