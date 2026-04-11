// ─────────────────────────────────────────────────────────────────────────────
// ExpertAppointment.dart  –  PHIÊN BẢN NÂNG CẤP
// Cải tiến:
//   • 3 tab: Chờ Duyệt | Đã Nhận | Lịch Sử
//   • Badge đếm số lượng trên từng tab
//   • Tab "Đã Nhận" chia nhóm: Hôm nay / Sắp tới / Chờ hoàn thành
//   • Countdown "Còn X phút" cho lịch hẹn hôm nay
//   • Viền đỏ + nhãn "Sắp đến giờ!" nhấp nháy khi còn ≤ 2 tiếng
//   • Nút "Đánh dấu Hoàn thành" cho ca đã qua chưa xử lý
//   • Empty state đẹp hơn cho từng tab
//   • (NÂNG CẤP) Dialog xác nhận hoàn thành cho phép nhập doanh thu
//   • (NÂNG CẤP) Hiển thị doanh thu thực nhận ở Tab Lịch sử
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExpertAppointmentsScreen extends StatefulWidget {
  const ExpertAppointmentsScreen({super.key});

  @override
  State<ExpertAppointmentsScreen> createState() =>
      _ExpertAppointmentsScreenState();
}

class _ExpertAppointmentsScreenState
    extends State<ExpertAppointmentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Animation nhấp nháy cho lịch hẹn sắp đến giờ
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  // Timer làm mới đếm ngược mỗi phút
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _blinkAnimation =
        Tween<double>(begin: 0.25, end: 1.0).animate(_blinkController);

    _refreshTimer = Timer.periodic(
        const Duration(seconds: 60), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _blinkController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Chưa đăng nhập")));
    }
    final expertId = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          "Quản Lý Lịch Hẹn",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            _badgeTab("Chờ Duyệt", expertId, ['pending']),
            _badgeTab("Đã Nhận", expertId, ['confirmed']),
            const Tab(text: "Lịch Sử"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(expertId),
          _buildConfirmedTab(expertId),
          _buildHistoryTab(expertId),
        ],
      ),
    );
  }

  // ─── Tab với badge đếm số ─────────────────────────────────────────────────
  Widget _badgeTab(
      String label, String expertId, List<String> statuses) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .where('status', whereIn: statuses)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 – CHỜ DUYỆT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPendingTab(String expertId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .where('status', isEqualTo: 'pending')
          .orderBy('time', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorView(snapshot.error.toString());
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.green));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _emptyView(
            icon: Icons.mark_email_read_rounded,
            message: 'Chưa có yêu cầu đặt lịch mới',
            sub: 'Bật trạng thái "Đang Rảnh" để nhận lịch',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            return _buildPendingCard(
                doc, doc.data() as Map<String, dynamic>);
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 – ĐÃ NHẬN (CONFIRMED)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildConfirmedTab(String expertId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd =
    DateTime(now.year, now.month, now.day, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .where('status', isEqualTo: 'confirmed')
          .orderBy('time', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorView(snapshot.error.toString());
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.green));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _emptyView(
            icon: Icons.event_available_rounded,
            message: 'Chưa có lịch hẹn đã xác nhận',
            sub: 'Chấp nhận yêu cầu trong tab "Chờ Duyệt"',
          );
        }

        // Phân nhóm: hôm nay / sắp tới / đã qua chưa đánh dấu
        final todayDocs = <QueryDocumentSnapshot>[];
        final upcomingDocs = <QueryDocumentSnapshot>[];
        final pastDocs = <QueryDocumentSnapshot>[];

        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final t = (d['time'] as Timestamp?)?.toDate();
          if (t == null) continue;
          if (t.isAfter(todayStart) && t.isBefore(todayEnd)) {
            todayDocs.add(doc);
          } else if (t.isAfter(todayEnd)) {
            upcomingDocs.add(doc);
          } else {
            pastDocs.add(doc);
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (todayDocs.isNotEmpty) ...[
              _sectionHeader('📅  Hôm nay', Colors.blue[700]!),
              ...todayDocs.map((doc) => _buildConfirmedCard(
                  doc, doc.data() as Map<String, dynamic>,
                  isToday: true)),
            ],
            if (upcomingDocs.isNotEmpty) ...[
              _sectionHeader('🗓️  Sắp tới', Colors.green[700]!),
              ...upcomingDocs.map((doc) => _buildConfirmedCard(
                  doc, doc.data() as Map<String, dynamic>)),
            ],
            if (pastDocs.isNotEmpty) ...[
              _sectionHeader(
                  '⏰  Chờ đánh dấu hoàn thành',
                  Colors.orange[700]!),
              ...pastDocs.map((doc) => _buildConfirmedCard(
                  doc, doc.data() as Map<String, dynamic>,
                  isPast: true)),
            ],
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 – LỊCH SỬ (COMPLETED + CANCELLED)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHistoryTab(String expertId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorView(snapshot.error.toString());
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.green));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _emptyView(
            icon: Icons.history_rounded,
            message: 'Chưa có lịch sử tư vấn',
            sub:
            'Các ca hoàn thành hoặc đã hủy sẽ xuất hiện tại đây',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            return _buildHistoryCard(
                doc, doc.data() as Map<String, dynamic>);
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CARDS
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Card: Chờ duyệt ──────────────────────────────────────────────────────
  Widget _buildPendingCard(
      DocumentSnapshot doc, Map<String, dynamic> data) {
    final time = (data['time'] as Timestamp).toDate();
    final farmerName = data['farmerName'] ?? "Nông dân";
    final farmerId = data['farmerId'] ?? "";
    final note = data['note'] ?? "";
    final phone = data['farmerPhone'] ?? "";
    final address = data['farmerAddress'] ?? "";

    return _cardShell(
      borderColor: Colors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(time,
              badgeColor: Colors.orange[50]!,
              textColor: Colors.orange[700]!,
              icon: Icons.pending_actions_rounded,
              label: 'Chờ duyệt'),
          _divider(),
          _farmerRow(farmerName, farmerId, phone, address),
          if (phone.isNotEmpty || address.isNotEmpty)
            _contactBox(phone, address),
          if (note.isNotEmpty) _noteBox(note),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(context, doc),
                  style: OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Từ chối",
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAccept(doc, time),
                  style: ElevatedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("✓  Đồng ý nhận",
                      style:
                      TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Card: Đã nhận ────────────────────────────────────────────────────────
  Widget _buildConfirmedCard(
      DocumentSnapshot doc, Map<String, dynamic> data,
      {bool isToday = false, bool isPast = false}) {
    final time = (data['time'] as Timestamp).toDate();
    final farmerName = data['farmerName'] ?? "Nông dân";
    final farmerId = data['farmerId'] ?? "";
    final note = data['note'] ?? "";
    final phone = data['farmerPhone'] ?? "";
    final address = data['farmerAddress'] ?? "";

    final now = DateTime.now();
    final diff = time.difference(now);
    final isUrgent =
        isToday && diff.inMinutes > 0 && diff.inMinutes <= 120;

    // THÊM: Kiểm tra xem đã qua giờ hẹn hay chưa
    final isTimePassed = time.isBefore(now);

    String headerLabel = 'Đã nhận';
    if (isUrgent) headerLabel = 'Sắp đến giờ!';
    if (isTimePassed || isPast) headerLabel = 'Chờ hoàn thành';

    Widget card = _cardShell(
      borderColor: isUrgent ? Colors.red : (isTimePassed || isPast ? Colors.orange : Colors.green[600]!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(time,
              badgeColor: isUrgent
                  ? Colors.red[50]!
                  : (isTimePassed || isPast ? Colors.orange[50]! : Colors.green[50]!),
              textColor: isUrgent
                  ? Colors.red[700]!
                  : (isTimePassed || isPast ? Colors.orange[700]! : Colors.green[700]!),
              icon: isUrgent
                  ? Icons.alarm_rounded
                  : (isTimePassed || isPast ? Icons.assignment_late_rounded : Icons.check_circle_rounded),
              label: headerLabel),

          // Countdown
          if (isToday && diff.inMinutes > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isUrgent
                    ? Colors.red.withOpacity(0.06)
                    : Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_rounded,
                      size: 15,
                      color: isUrgent
                          ? Colors.red[700]
                          : Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text(
                    _formatCountdown(diff),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUrgent
                          ? Colors.red[700]
                          : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],

          _divider(),
          _farmerRow(farmerName, farmerId, phone, address),
          if (phone.isNotEmpty || address.isNotEmpty)
            _contactBox(phone, address),
          if (note.isNotEmpty) _noteBox(note),

          // Nút hoàn thành cho ca đã qua
          if (isPast || isTimePassed) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleComplete(doc),
                icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18),
                label: const Text("Đánh dấu Hoàn thành",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // Nhấp nháy nếu khẩn cấp
    if (isUrgent) {
      return AnimatedBuilder(
        animation: _blinkAnimation,
        builder: (_, child) =>
            Opacity(opacity: 0.65 + 0.35 * _blinkAnimation.value, child: child),
        child: card,
      );
    }
    return card;
  }

  // ─── Card: Lịch sử (completed / cancelled) ───────────────────────────────
  Widget _buildHistoryCard(
      DocumentSnapshot doc, Map<String, dynamic> data) {
    final time = (data['time'] as Timestamp).toDate();
    final farmerName = data['farmerName'] ?? "Nông dân";
    final farmerId = data['farmerId'] ?? "";
    final status = data['status'] ?? '';
    final note = data['note'] ?? "";
    final phone = data['farmerPhone'] ?? "";
    final address = data['farmerAddress'] ?? "";

    // NÂNG CẤP: Lấy số tiền thực nhận để hiển thị trong lịch sử
    final double earned = (data['earnedRevenue'] ?? 0.0).toDouble();

    final isCompleted = status == 'completed';
    final borderColor =
    isCompleted ? Colors.blue[500]! : Colors.red[400]!;
    final badgeColor =
    isCompleted ? Colors.blue[50]! : Colors.red[50]!;
    final textColor =
    isCompleted ? Colors.blue[700]! : Colors.red[700]!;
    final icon = isCompleted
        ? Icons.verified_rounded
        : Icons.cancel_rounded;
    final label = isCompleted ? 'Hoàn thành' : 'Đã hủy';

    return _cardShell(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(time,
              badgeColor: badgeColor,
              textColor: textColor,
              icon: icon,
              label: label),
          _divider(),
          _farmerRow(farmerName, farmerId, phone, address),
          if (note.isNotEmpty) _noteBox(note),

          // NÂNG CẤP: Hiện hộp tiền thu được nếu ca hoàn thành
          if (isCompleted && earned > 0)
            _revenueBox(earned),

          if (status == 'cancelled' && data['cancelReason'] != null)
            _cancelBox(data['cancelReason']),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED SUB-WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _cardShell(
      {required Color borderColor, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border:
        Border(left: BorderSide(color: borderColor, width: 5)),
      ),
      child: Padding(
          padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _cardHeader(DateTime time,
      {required Color badgeColor,
        required Color textColor,
        required IconData icon,
        required String label}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd/MM/yyyy  •  HH:mm').format(time),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey[800]),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
  );

  Widget _farmerRow(
      String name, String farmerId, String phone, String address) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
              color: Colors.green[50], shape: BoxShape.circle),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "N",
              style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87)),
              const SizedBox(height: 3),
              GestureDetector(
                onTap: () => _showFarmerDetailDialog(
                    context, farmerId, name, phone, address),
                child: Text(
                  "Xem thông tin liên hệ →",
                  style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactBox(String phone, String address) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (phone.isNotEmpty)
            Row(
              children: [
                Icon(Icons.phone_rounded,
                    size: 15, color: Colors.grey[600]),
                const SizedBox(width: 8),
                SelectableText(phone,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          if (phone.isNotEmpty && address.isNotEmpty)
            const SizedBox(height: 8),
          if (address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded,
                    size: 15, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(address,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[800])),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _noteBox(String note) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  size: 16, color: Colors.orange[800]),
              const SizedBox(width: 6),
              Text("Vấn đề cần hỗ trợ:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.orange[900])),
            ],
          ),
          const SizedBox(height: 5),
          Text(note,
              style:
              TextStyle(fontSize: 13, color: Colors.orange[900])),
        ],
      ),
    );
  }

  // NÂNG CẤP: Box hiển thị tiền trong lịch sử
  Widget _revenueBox(double amount) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, size: 16, color: Colors.green[800]),
          const SizedBox(width: 6),
          Text(
            "Thực nhận: ${NumberFormat("#,##0", "vi_VN").format(amount)} VNĐ",
            style: TextStyle(
                color: Colors.green[800],
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _cancelBox(String reason) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10)),
      child: Text("Lý do huỷ: $reason",
          style: TextStyle(
              color: Colors.red[800],
              fontSize: 13,
              fontStyle: FontStyle.italic)),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color)),
        ],
      ),
    );
  }

  Widget _emptyView(
      {required IconData icon,
        required String message,
        required String sub}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(sub,
                style:
                TextStyle(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String error) => Center(
    child: Text("Lỗi: $error",
        style: const TextStyle(color: Colors.red)),
  );

  String _formatCountdown(Duration diff) {
    if (diff.inMinutes < 60) return 'Còn ${diff.inMinutes} phút nữa';
    return 'Còn ${diff.inHours} giờ ${diff.inMinutes % 60} phút nữa';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Chấp nhận lịch ──────────────────────────────────────────────────────
  Future<void> _handleAccept(
      DocumentSnapshot doc, DateTime time) async {
    final expertId = FirebaseAuth.instance.currentUser!.uid;
    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(doc.reference, {
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      final expertRef = FirebaseFirestore.instance
          .collection('users')
          .doc(expertId);
      batch.update(expertRef, {
        'expertInfo.bookingCount': FieldValue.increment(1),
        'expertInfo.pendingCount': FieldValue.increment(-1),
      });

      // Tạo thông báo cho nông dân
      final appointmentData = doc.data() as Map<String, dynamic>?;
      final farmerId = appointmentData?['farmerId'];
      if (farmerId != null && farmerId.toString().isNotEmpty) {
        final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifRef, {
          'appointmentId': doc.id,
          'body': 'Chuyên gia đã xác nhận lịch hẹn của bạn vào lúc ${DateFormat('HH:mm - dd/MM/yyyy').format(time)}.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'receiverId': farmerId,
          'title': 'Xác nhận lịch hẹn',
        });
      }

      // Hủy các lịch trùng giờ
      final conflicts = await FirebaseFirestore.instance
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .where('time', isEqualTo: Timestamp.fromDate(time))
          .where('status', isEqualTo: 'pending')
          .get();

      for (var d in conflicts.docs) {
        if (d.id != doc.id) {
          batch.update(d.reference, {
            'status': 'cancelled',
            'cancelReason':
            'Chuyên gia đã nhận lịch hẹn khác vào khung giờ này.',
            'cancelledBy': 'system_conflict',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("✅  Đã nhận lịch thành công!"),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  // ─── NÂNG CẤP: Đánh dấu hoàn thành & Nhập Doanh thu ──────────────────────
  Future<void> _handleComplete(DocumentSnapshot doc) async {
    final TextEditingController revenueController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận hoàn thành?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đánh dấu ca tư vấn này là đã hoàn thành?'),
            const SizedBox(height: 16),
            const Text('Số tiền thực nhận (VNĐ):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: revenueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'VD: 500000',
                suffixText: 'VNĐ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hủy',
                  style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Lấy số tiền người dùng đã nhập (Nếu để trống thì mặc định là 0)
    final double earnedAmount = double.tryParse(revenueController.text.trim()) ?? 0.0;
    final String expertId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Cập nhật trạng thái lịch hẹn & lưu lịch sử số tiền kiếm được
      batch.update(doc.reference, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'earnedRevenue': earnedAmount, // Lưu để xem lại trong tab Lịch sử
      });

      // 2. Cộng dồn số tiền vào tổng thu nhập của Chuyên gia
      final expertRef = FirebaseFirestore.instance.collection('users').doc(expertId);
      batch.update(expertRef, {
        'expertInfo.revenue': FieldValue.increment(earnedAmount),
      });

      // Thực thi cùng lúc 2 lệnh trên
      await batch.commit();

      if (mounted) {
        String message = "🎉 Ca tư vấn đã hoàn thành!";
        if (earnedAmount > 0) {
          message = "🎉 Hoàn thành! Đã cộng ${NumberFormat("#,##0", "vi_VN").format(earnedAmount)} VNĐ vào báo cáo.";
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  // ─── Dialog từ chối ──────────────────────────────────────────────────────
  void _showRejectDialog(
      BuildContext context, DocumentSnapshot doc) {
    String selectedReason = "Bận đột xuất";
    final noteController = TextEditingController();
    final reasons = [
      "Bận đột xuất",
      "Sai chuyên môn tư vấn",
      "Đã kín lịch hôm nay",
      "Lý do khác",
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Từ chối lịch hẹn",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (ctx2, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chọn lý do mẫu:",
                  style:
                  TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border:
                  Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: selectedReason,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: reasons
                      .map((r) => DropdownMenuItem(
                      value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) =>
                      setS(() => selectedReason = v!),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: "Ghi chú thêm (Tùy chọn)",
                  labelStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.green.shade600, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Hủy",
                  style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              String reason = selectedReason;
              if (noteController.text.isNotEmpty) {
                reason += ": ${noteController.text}";
              }
              final batch = FirebaseFirestore.instance.batch();
              batch.update(doc.reference, {
                'status': 'cancelled',
                'cancelReason': reason,
                'cancelledBy': 'expert',
                'cancelledAt': FieldValue.serverTimestamp(),
              });

              final appointmentData = doc.data() as Map<String, dynamic>?;
              final farmerId = appointmentData?['farmerId'];
              if (farmerId != null && farmerId.toString().isNotEmpty) {
                final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
                batch.set(notifRef, {
                  'appointmentId': doc.id,
                  'body': 'Chuyên gia hẹn dịp khác với lý do: $reason',
                  'createdAt': FieldValue.serverTimestamp(),
                  'isRead': false,
                  'receiverId': farmerId,
                  'title': 'Lịch hẹn thay đổi',
                });
              }
              await batch.commit();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                    const Text("Đã từ chối lịch hẹn."),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text("Xác nhận từ chối",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Dialog thông tin nông dân ────────────────────────────────────────────
  void _showFarmerDetailDialog(BuildContext context,
      String farmerId, String name, String phone, String address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(farmerId)
              .get(),
          builder: (_, snapshot) {
            String p = phone, a = address, email = "Đang tải...";

            if (snapshot.hasData && snapshot.data!.exists) {
              final d =
              snapshot.data!.data() as Map<String, dynamic>;
              if (p.isEmpty) {
                p = d['phoneNumber'] ?? d['phone'] ?? "Chưa cập nhật";
              }
              if (a.isEmpty) {
                a = d['address'] ??
                    d['location'] ??
                    "Chưa cập nhật địa chỉ";
              }
              email = d['email'] ?? "Chưa cập nhật";
            } else if (snapshot.connectionState ==
                ConnectionState.waiting) {
              if (p.isEmpty && a.isEmpty) {
                return const SizedBox(
                    height: 100,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Colors.green)));
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.phone_rounded, "Số điện thoại:",
                    p.isEmpty ? "Chưa cập nhật" : p),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.location_on_rounded,
                    "Địa chỉ/Vườn:", a.isEmpty ? "Chưa cập nhật" : a),
                const SizedBox(height: 16),
                _buildInfoRow(
                    Icons.email_rounded, "Email:", email),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Nên gọi điện xác nhận trước khi đến vườn.",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Đóng",
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.grey[100], shape: BoxShape.circle),
          child:
          Icon(icon, size: 18, color: Colors.green[700]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const SizedBox(height: 2),
              SelectableText(value,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}