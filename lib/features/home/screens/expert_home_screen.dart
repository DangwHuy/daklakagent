// ─────────────────────────────────────────────────────────────────────────────
// expert_home_screen.dart  –  PHIÊN BẢN NÂNG CẤP
// Tính năng mới:
//   • Quick-action buttons (hôm nay / chờ duyệt / báo cáo / thu nhập)
//   • "Lịch hẹn sắp tới" với đếm ngược + cảnh báo nhấp nháy khi < 2 tiếng
//   • 4 stat-card (tổng ca / đánh giá / chờ xác nhận / thu nhập)
//   • Bộ lọc biểu đồ: 7 Ngày | Tháng | Quý | Năm
//   • Biểu đồ đường với gradient, dot trắng, tooltip thông minh
//   • Biểu đồ tròn trạng thái lịch hẹn (confirmed / completed / pending / cancelled)
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

// ─── Enum bộ lọc thời gian biểu đồ ──────────────────────────────────────────
enum ChartPeriod { day7, month, quarter, year }

// ─── Model dữ liệu biểu đồ ────────────────────────────────────────────────────
class _ChartData {
  final List<FlSpot> spots;
  final List<String> labels;
  const _ChartData({required this.spots, required this.labels});
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

  final List<Widget> _pages = [
    const _DashboardContent(),
    const ExpertAppointmentsScreen(),
    const ExpertChatListScreen(),
    const ExpertProfileSetup(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green[700],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, size: 28),
              label: 'Tổng quan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              activeIcon: Icon(Icons.calendar_month_rounded, size: 28),
              label: 'Lịch hẹn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_rounded),
              activeIcon: Icon(Icons.chat_rounded, size: 28),
              label: 'Tin nhắn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded, size: 28),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. NỘI DUNG BẢNG ĐIỀU KHIỂN
// ═════════════════════════════════════════════════════════════════════════════
class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  // Bộ lọc biểu đồ hiện tại
  ChartPeriod _selectedPeriod = ChartPeriod.day7;

  // Animation nhấp nháy cho cảnh báo sắp đến giờ
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  // Timer làm mới đếm ngược mỗi phút
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _blinkAnimation =
        Tween<double>(begin: 0.25, end: 1.0).animate(_blinkController);

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

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
          body: Center(child: Text("Lỗi: Chưa đăng nhập")));
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
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: "Thông báo",
          ),
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

                // ── Quick-action buttons  ← MỚI
                _buildQuickActions(),
                const SizedBox(height: 24),

                // ── Cảnh báo lịch hẹn sắp tới  ← MỚI
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

                // ── Biểu đồ tròn trạng thái  ← MỚI
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

  // ─── Quick Actions ────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Hôm nay',
        'color': Colors.blue[600]!,
      },
      {
        'icon': Icons.pending_actions_rounded,
        'label': 'Chờ duyệt',
        'color': Colors.orange[600]!,
      },
      {
        'icon': Icons.bar_chart_rounded,
        'label': 'Báo cáo',
        'color': Colors.purple[600]!,
      },
      {
        'icon': Icons.payments_rounded,
        'label': 'Thu nhập',
        'color': Colors.green[700]!,
      },
    ];

    return Row(
      children: List.generate(actions.length, (i) {
        final a = actions[i];
        final color = a['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${a['label']} – Đang phát triển 🚧'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
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

  // ─── Cảnh báo lịch hẹn sắp tới ──────────────────────────────────────────
  Widget _buildUpcomingAlert(String expertUid) {
    final now = DateTime.now();
    final endOfDay =
    DateTime(now.year, now.month, now.day, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('expertId', isEqualTo: expertUid)
          .where('status', isEqualTo: 'confirmed')
          .snapshots(),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Vào ngay',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
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

  // ─── Biểu đồ đường hiệu suất ─────────────────────────────────────────────
  Widget _buildPerformanceChart(String expertUid) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
      height: 290,
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 14,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(2),
                        )),
                    const SizedBox(width: 5),
                    Text('Ca tư vấn',
                        style: TextStyle(
                            fontSize: 11, color: Colors.green[700])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('expertId', isEqualTo: expertUid)
              // ĐÃ SỬA: Đếm cả ca đang nhận và đã hoàn thành
                  .where('status', whereIn: ['confirmed', 'completed'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi tải dữ liệu", style: TextStyle(color: Colors.grey[400])));
                }

                final docs = snapshot.data?.docs ?? [];
                final chartData = _buildChartData(docs);
                final allZero = chartData.spots.every((s) => s.y == 0);

                if (allZero) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insert_chart_outlined_rounded, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text('Chưa có dữ liệu', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  );
                }

                double maxY = chartData.spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
                if (maxY < 4) maxY = 4;

                return LineChart(
                  LineChartData(
                    minX: 0, // ĐÃ THÊM: Khóa trục X
                    maxX: (chartData.spots.length - 1).toDouble(), // ĐÃ THÊM: Khóa trục X
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
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _selectedPeriod == ChartPeriod.year ? 1 : 1,
                          getTitlesWidget: (value, meta) {
                            // ĐÃ THÊM: Fix lỗi lặp nhãn và giãn đồ thị
                            if (value != value.roundToDouble()) return const SizedBox.shrink();

                            final idx = value.toInt();
                            if (idx < 0 || idx >= chartData.labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                chartData.labels[idx],
                                style: const TextStyle(color: Colors.grey, fontSize: 9.5),
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
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    // ── Tooltip thông minh
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.green[800]!,
                        tooltipRoundedRadius: 10,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.toInt();
                            final label = (idx >= 0 && idx < chartData.labels.length)
                                ? chartData.labels[idx].replaceAll('\n', ' ')
                                : '';
                            return LineTooltipItem(
                              '$label\n',
                              const TextStyle(color: Colors.white70, fontSize: 11),
                              children: [
                                TextSpan(
                                  text: '${spot.y.toInt()} ca tư vấn',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                        preventCurveOverShooting: true, // ĐÃ THÊM: Ngăn đường cong võng xuống âm
                        curveSmoothness: 0.3,
                        color: Colors.green[600],
                        barWidth: 3,
                        isStrokeCapRound: true,
                        // Dot trắng viền xanh
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeColor: Colors.green[600]!,
                          ),
                        ),
                        // ── Gradient bóng đổ dưới đường
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withOpacity(0.38),
                              Colors.green.withOpacity(0.08),
                              Colors.green.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('expertId', isEqualTo: expertUid)
            .snapshots(),
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

  /// 7 ngày gần nhất – trục X: "CN\n5/4" "T2\n6/4" ...
  _ChartData _build7DayData(
      List<QueryDocumentSnapshot> docs, DateTime now) {
    const dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final labels = <String>[];
    final counts = List.filled(7, 0);

    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      labels.add('${dayNames[d.weekday % 7]}\n${d.day}/${d.month}');
    }
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['time'] == null) continue;
      final t = (data['time'] as Timestamp).toDate();
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        if (t.year == d.year &&
            t.month == d.month &&
            t.day == d.day) {
          counts[6 - i]++;
        }
      }
    }
    return _ChartData(
      spots: List.generate(
          7, (i) => FlSpot(i.toDouble(), counts[i].toDouble())),
      labels: labels,
    );
  }

  /// Tháng này – chia theo tuần trong tháng
  _ChartData _buildMonthData(
      List<QueryDocumentSnapshot> docs, DateTime now) {
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;
    final numWeeks = (daysInMonth / 7).ceil();
    final counts = List.filled(numWeeks, 0);
    final labels =
    List.generate(numWeeks, (i) => 'Tuần\n${i + 1}');

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['time'] == null) continue;
      final t = (data['time'] as Timestamp).toDate();
      if (t.year == now.year && t.month == now.month) {
        int w = ((t.day - 1) / 7).floor();
        if (w >= numWeeks) w = numWeeks - 1;
        counts[w]++;
      }
    }
    return _ChartData(
      spots: List.generate(
          numWeeks,
              (i) => FlSpot(i.toDouble(), counts[i].toDouble())),
      labels: labels,
    );
  }

  /// Quý (3 tháng gần nhất)
  _ChartData _buildQuarterData(
      List<QueryDocumentSnapshot> docs, DateTime now) {
    final labels = <String>[];
    final counts = List.filled(3, 0);

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
        if (t.year == year && t.month == month) counts[2 - i]++;
      }
    }
    return _ChartData(
      spots: List.generate(
          3, (i) => FlSpot(i.toDouble(), counts[i].toDouble())),
      labels: labels,
    );
  }

  /// Năm – 12 tháng
  _ChartData _buildYearData(
      List<QueryDocumentSnapshot> docs, DateTime now) {
    final counts = List.filled(12, 0);
    final labels =
    List.generate(12, (i) => 'T${i + 1}');

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['time'] == null) continue;
      final t = (data['time'] as Timestamp).toDate();
      if (t.year == now.year) counts[t.month - 1]++;
    }
    return _ChartData(
      spots: List.generate(
          12,
              (i) => FlSpot(i.toDouble(), counts[i].toDouble())),
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