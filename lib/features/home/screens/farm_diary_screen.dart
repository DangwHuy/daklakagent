import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// ============================================================================
// NHẬT KÝ NÔNG HỘ — Farm Diary Screen
// ============================================================================
class FarmDiaryScreen extends StatefulWidget {
  const FarmDiaryScreen({super.key});

  @override
  State<FarmDiaryScreen> createState() => _FarmDiaryScreenState();
}

class _FarmDiaryScreenState extends State<FarmDiaryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  // Danh mục hoạt động
  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Bón phân', 'icon': Icons.science_outlined, 'color': Color(0xFF43A047), 'emoji': '🧪'},
    {'name': 'Tưới nước', 'icon': Icons.water_drop_outlined, 'color': Color(0xFF1E88E5), 'emoji': '💧'},
    {'name': 'Phun thuốc', 'icon': Icons.sanitizer_outlined, 'color': Color(0xFFE53935), 'emoji': '🛡️'},
    {'name': 'Thu hoạch', 'icon': Icons.agriculture_outlined, 'color': Color(0xFFFB8C00), 'emoji': '🌾'},
    {'name': 'Quan sát', 'icon': Icons.visibility_outlined, 'color': Color(0xFF8E24AA), 'emoji': '👁️'},
    {'name': 'Cắt tỉa', 'icon': Icons.content_cut_outlined, 'color': Color(0xFF00897B), 'emoji': '✂️'},
    {'name': 'Khác', 'icon': Icons.more_horiz, 'color': Color(0xFF757575), 'emoji': '📝'},
  ];

  // Stream nhật ký theo tháng
  Stream<QuerySnapshot> _getDiaryStream() {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) {
      // Stream rỗng nếu chưa đăng nhập
      return const Stream.empty();
    }

    final start = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final end = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('farm_diary')
        .doc(currentUid)
        .collection('entries')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          _buildTitleBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getDiaryStream(),
              builder: (context, snapshot) {
                // XỬ LÝ LỖI (Quan trọng để tìm ra lỗi "mất dữ liệu")
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final entries = snapshot.data?.docs ?? [];
                // Tập hợp ngày có nhật ký
                final Set<String> daysWithEntries = {};
                for (var doc in entries) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  daysWithEntries.add('${date.year}-${date.month}-${date.day}');
                }

                // Lọc entries theo ngày đã chọn
                final selectedEntries = entries.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  return date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                }).toList();

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalendar(daysWithEntries),
                      const SizedBox(height: 8),
                      _buildSelectedDateHeader(selectedEntries.length),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF43A047)),
                          ),
                        )
                      else if (selectedEntries.isEmpty)
                        _buildEmptyState()
                      else
                        _buildTimeline(selectedEntries),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(context),
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ghi nhật ký', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 4,
      ),
    );
  }

  // ── Title Bar (đồng bộ) ────────────────────────────────────────────────────
  Widget _buildTitleBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 16),
      color: const Color(0xFFF4F6F8),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
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
            'Nhật Ký Nông Hộ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar ───────────────────────────────────────────────────────────────
  Widget _buildCalendar(Set<String> daysWithEntries) {
    final now = DateTime.now();
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday; // 1=Mon ... 7=Sun

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header tháng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    // Đồng bộ ngày chọn sang tháng mới để tránh bị "lag" không hiện dữ liệu
                    _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
                  });
                },
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                color: Colors.grey[600],
              ),
              Text(
                'Tháng ${_focusedMonth.month}/${_focusedMonth.year}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    // Đồng bộ ngày chọn sang tháng mới
                    _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
                  });
                },
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                color: Colors.grey[600],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Ngày trong tuần header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((d) {
              return SizedBox(
                width: 36,
                child: Text(d,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[500]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Grid ngày
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startWeekday - 1 + lastDay.day,
            itemBuilder: (context, index) {
              if (index < startWeekday - 1) return const SizedBox();

              final day = index - (startWeekday - 1) + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              final hasEntry = daysWithEntries.contains('${date.year}-${date.month}-${date.day}');

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF43A047)
                        : isToday
                            ? const Color(0xFFE8F5E9)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (hasEntry)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF43A047),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tiêu đề ngày chọn ──────────────────────────────────────────────────────
  Widget _buildSelectedDateHeader(int count) {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_note_rounded, color: Color(0xFF43A047), size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            isToday ? 'Hôm nay' : DateFormat('dd/MM/yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  // ── Error state (Hiển thị lỗi truy vấn) ──────────────────────────────────────
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          const Text('Lỗi tải dữ liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit_note_rounded, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có ghi chú ngày này',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500]),
            ),
            const SizedBox(height: 6),
            Text(
              'Bấm nút bên dưới để ghi nhật ký',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timeline ───────────────────────────────────────────────────────────────
  Widget _buildTimeline(List<QueryDocumentSnapshot> entries) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final data = entries[index].data() as Map<String, dynamic>;
        final docId = entries[index].id;
        final date = (data['date'] as Timestamp).toDate();
        final category = data['category'] ?? 'Khác';
        final note = data['note'] ?? '';
        final plot = data['plot'] ?? '';
        final imageUrl = data['imageUrl'] as String?;
        final isLast = index == entries.length - 1;

        // Tìm thông tin category
        final catInfo = _categories.firstWhere(
          (c) => c['name'] == category,
          orElse: () => _categories.last,
        );

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: (catInfo['color'] as Color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (catInfo['color'] as Color).withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              ),
              // Card nội dung
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: category + time + menu
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (catInfo['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(catInfo['icon'] as IconData, color: catInfo['color'] as Color, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: catInfo['color'] as Color,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(date),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          if (plot.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(plot, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[700])),
                            ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                            onSelected: (value) {
                              if (value == 'delete') _deleteEntry(docId);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(note, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                      ],
                      // Ảnh đính kèm
                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(child: CircularProgressIndicator(color: Color(0xFF43A047), strokeWidth: 2)),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey[300], size: 36)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Xóa entry ──────────────────────────────────────────────────────────────
  Future<void> _deleteEntry(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa ghi chú?'),
        content: const Text('Bạn có chắc muốn xóa ghi chú này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('farm_diary').doc(_userId).collection('entries').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa ghi chú'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // ── Bottom Sheet thêm nhật ký ──────────────────────────────────────────────
  void _showAddEntrySheet(BuildContext context) {
    String selectedCategory = 'Bón phân';
    final noteController = TextEditingController();
    final plotController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    File? pickedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_calendar_rounded, color: Color(0xFF43A047), size: 24),
                        const SizedBox(width: 10),
                        const Text('Ghi nhật ký', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM').format(_selectedDate),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category selector
                          const Text('Loại hoạt động', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((cat) {
                              final isActive = selectedCategory == cat['name'];
                              return GestureDetector(
                                onTap: () => setSheetState(() => selectedCategory = cat['name'] as String),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isActive ? (cat['color'] as Color).withOpacity(0.15) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isActive ? (cat['color'] as Color) : Colors.grey[300]!,
                                      width: isActive ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(cat['emoji'] as String, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat['name'] as String,
                                        style: TextStyle(
                                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                          fontSize: 13,
                                          color: isActive ? (cat['color'] as Color) : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // Lô vườn
                          const Text('Lô vườn (tuỳ chọn)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: plotController,
                            decoration: InputDecoration(
                              hintText: 'VD: Lô A, Lô 2...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.map_outlined, color: Colors.grey[500]),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Giờ thực hiện
                          const Text('Giờ thực hiện', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final time = await showTimePicker(context: context, initialTime: selectedTime);
                              if (time != null) setSheetState(() => selectedTime = time);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded, color: Colors.grey[600], size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    selectedTime.format(context),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.edit, color: Colors.grey[400], size: 16),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Ghi chú
                          const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Mô tả chi tiết hoạt động...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Ảnh đính kèm
                          const Text('Ảnh đính kèm (tuỳ chọn)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 8),
                          if (pickedImage != null)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(pickedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setSheetState(() => pickedImage = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                _buildImagePickerButton(
                                  icon: Icons.camera_alt_rounded,
                                  label: 'Chụp ảnh',
                                  onTap: () async {
                                    final picked = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 80);
                                    if (picked != null) setSheetState(() => pickedImage = File(picked.path));
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildImagePickerButton(
                                  icon: Icons.photo_library_rounded,
                                  label: 'Thư viện',
                                  onTap: () async {
                                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
                                    if (picked != null) setSheetState(() => pickedImage = File(picked.path));
                                  },
                                ),
                              ],
                            ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // Nút Lưu
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () async {
                                if (noteController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng nhập ghi chú!'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                setSheetState(() => isUploading = true);

                                try {
                                  String? imageUrl;
                                  if (pickedImage != null) {
                                    final ref = FirebaseStorage.instance.ref().child(
                                      'farm_diary/$_userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
                                    );
                                    await ref.putFile(pickedImage!);
                                    imageUrl = await ref.getDownloadURL();
                                  }

                                  final entryDate = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month,
                                    _selectedDate.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  );

                                  await _firestore
                                      .collection('farm_diary')
                                      .doc(_userId)
                                      .collection('entries')
                                      .add({
                                    'category': selectedCategory,
                                    'note': noteController.text.trim(),
                                    'plot': plotController.text.trim(),
                                    'date': Timestamp.fromDate(entryDate),
                                    'imageUrl': imageUrl ?? '',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('✅ Đã lưu nhật ký!'), backgroundColor: Color(0xFF43A047)),
                                    );
                                  }
                                } catch (e) {
                                  setSheetState(() => isUploading = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isUploading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Lưu nhật ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImagePickerButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.grey[600], size: 28),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }
}
