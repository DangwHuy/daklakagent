import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:daklakagent/features/home/screens/chat_screen.dart';

class ExpertTodayScreen extends StatefulWidget {
  const ExpertTodayScreen({super.key});

  @override
  State<ExpertTodayScreen> createState() => _ExpertTodayScreenState();
}

class _ExpertTodayScreenState extends State<ExpertTodayScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _openMap(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể mở ứng dụng Bản đồ")));
      }
    }
  }

  void _callPhone(String phone) async {
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể thực hiện cuộc gọi")));
      }
    }
  }

  // ─── UPLOAD NHIỀU ẢNH LÊN FIREBASE STORAGE ───────────────────────────
  Future<List<String>> _uploadConfirmImages(List<File> images, String appointmentId) async {
    List<String> urls = [];
    for (int i = 0; i < images.length; i++) {
      final ref = FirebaseStorage.instance.ref().child(
        'confirmations/$appointmentId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
      );
      await ref.putFile(images[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // ─── CẬP NHẬT TRẠNG THÁI (DUYỆT/TỪ CHỐI) ───────────────────────────────
  Future<void> _updateStatus(String appointmentId, String newStatus) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(newStatus == 'confirmed' ? 'Chấp nhận lịch hẹn?' : 'Từ chối lịch hẹn?'),
        content: Text(newStatus == 'confirmed' 
          ? 'Bạn đồng ý tiếp nhận ca tư vấn này?' 
          : 'Bạn chắc chắn muốn từ chối ca tư vấn này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'confirmed' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': newStatus,
        if (newStatus == 'confirmed') 'acceptedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'cancelled') 'cancelledAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newStatus == 'confirmed' ? "✅ Đã chấp nhận lịch hẹn!" : "❌ Đã từ chối lịch hẹn."),
          backgroundColor: newStatus == 'confirmed' ? Colors.green[700] : Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  // ─── NÂNG CẤP: Đánh dấu hoàn thành & Nhập Doanh thu + Ảnh xác nhận (ĐỒNG NHẤT VỚI QUẢN LÝ LỊCH HẸN) ───────
  Future<void> _markAsCompleted(String appointmentId) async {
    final TextEditingController revenueController = TextEditingController();
    List<File> pickedImages = [];
    bool isUploading = false;
    final ImagePicker picker = ImagePicker();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified_rounded, color: Colors.green[700], size: 32),
              ),
              const SizedBox(height: 12),
              const Text('Xác nhận hoàn thành?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Số tiền
                const Text('Số tiền thực nhận (VNĐ):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: revenueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'VD: 500000',
                    suffixText: 'VNĐ',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Ảnh xác nhận (3-5 ảnh bắt buộc)
                Row(
                  children: [
                    Icon(Icons.camera_alt_rounded, size: 18, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    const Text('Ảnh xác nhận công việc:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Bắt buộc 3-5 ảnh minh chứng (đã chọn ${pickedImages.length}/5)',
                  style: TextStyle(
                    fontSize: 12,
                    color: pickedImages.length < 3 ? Colors.red[600] : Colors.green[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                // Hiển thị ảnh đã chọn
                if (pickedImages.isNotEmpty)
                  SizedBox(
                    height: 90,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: pickedImages.asMap().entries.map((entry) {
                          final i = entry.key;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(pickedImages[i], width: 90, height: 90, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4, right: 4,
                                  child: GestureDetector(
                                    onTap: () => setDialogState(() => pickedImages.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickedImages.length >= 5 ? null : () async {
                          final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 80);
                          if (picked != null && pickedImages.length < 5) {
                            setDialogState(() => pickedImages.add(File(picked.path)));
                          }
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text("Chụp ảnh", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[700],
                          side: BorderSide(color: Colors.green[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickedImages.length >= 5 ? null : () async {
                          final remaining = 5 - pickedImages.length;
                          final results = await picker.pickMultiImage(maxWidth: 1024, imageQuality: 80);
                          if (results.isNotEmpty) {
                            setDialogState(() {
                              pickedImages.addAll(results.take(remaining).map((f) => File(f.path)));
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text("Thư viện", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),

                if (isUploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.green),
                          SizedBox(height: 8),
                          Text("Đang tải ảnh lên...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: isUploading ? [] : [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Hủy', style: TextStyle(color: Colors.grey[600]))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: pickedImages.length >= 3 ? Colors.green[600] : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: pickedImages.length < 3 ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vui lòng chọn ít nhất 3 ảnh minh chứng (đã chọn ${pickedImages.length})'),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } : () => Navigator.pop(ctx, true),
              child: const Text('Hoàn thành', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    // Lấy số tiền người dùng đã nhập (Nếu để trống thì mặc định là 0)
    final double earnedAmount = double.tryParse(revenueController.text.trim().replaceAll(',', '')) ?? 0.0;

    try {
      // Upload ảnh xác nhận
      List<String> imageUrls = [];
      if (pickedImages.isNotEmpty) {
        imageUrls = await _uploadConfirmImages(pickedImages, appointmentId);
      }

      final batch = FirebaseFirestore.instance.batch();
      final appRef = FirebaseFirestore.instance.collection('appointments').doc(appointmentId);
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);

      // 1. Cập nhật trạng thái lịch hẹn & lưu lịch sử số tiền kiếm được
      batch.update(appRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'earnedRevenue': earnedAmount,
        'confirmImages': imageUrls,
      });

      // 2. Cộng dồn số tiền vào tổng thu nhập của Chuyên gia
      batch.update(userRef, {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Cần đăng nhập")));

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Lịch trình Hôm nay", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lọc tất cả lịch hẹn của chuyên gia và sắp xếp bên client để tránh lỗi Index
        stream: FirebaseFirestore.instance.collection('appointments').where('expertId', isEqualTo: currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Đã có lỗi xảy ra: ${snapshot.error}"));
          }

          // Lọc thủ công các ca chỉ trong ngày hôm nay
          final allDocs = snapshot.data?.docs ?? [];
          final todayDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['time'] == null) return false;
            final t = (data['time'] as Timestamp).toDate();
            return t.isAfter(startOfDay) && t.isBefore(endOfDay);
          }).toList();

          todayDocs.sort((a, b) {
            final timeA = ((a.data() as Map<String, dynamic>)['time'] as Timestamp).toDate();
            final timeB = ((b.data() as Map<String, dynamic>)['time'] as Timestamp).toDate();
            return timeA.compareTo(timeB);
          });

          int total = todayDocs.length;
          int completed = todayDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'completed').length;
          int active = todayDocs.where((d) {
            final s = (d.data() as Map<String, dynamic>)['status'];
            return s != 'completed' && s != 'cancelled';
          }).length;

          return Column(
            children: [
               _buildHeaderPanel(now, total, completed, active),
               Expanded(
                 child: todayDocs.isEmpty 
                  ? _buildEmptyState() 
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 20, right: 16, bottom: 40),
                      itemCount: todayDocs.length,
                      itemBuilder: (context, index) {
                         return _buildTimelineItem(
                            todayDocs[index].id, 
                            todayDocs[index].data() as Map<String, dynamic>, 
                            index == todayDocs.length - 1
                         );
                      }
                  ),
               )
            ],
          );
        }
      )
    );
  }

  Widget _buildEmptyState() {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.free_breakfast_outlined, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text("Lịch trống", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text("Tuyệt vời! Bạn không có ca tư vấn nào hôm nay.", style: TextStyle(color: Colors.grey[600])),
         ],
       ),
     );
  }

  Widget _buildHeaderPanel(DateTime date, int total, int completed, int active) {
    String formattedDate = DateFormat('EEEE, dd MMMM, yyyy', 'vi').format(date);
    // Vi hoá EEEE (Thứ) vì hệ thống đôi khi trả tiếng Anh nếu locale chưa chuẩn
    formattedDate = formattedDate.replaceAll('Monday', 'Thứ 2')
                                 .replaceAll('Tuesday', 'Thứ 3')
                                 .replaceAll('Wednesday', 'Thứ 4')
                                 .replaceAll('Thursday', 'Thứ 5')
                                 .replaceAll('Friday', 'Thứ 6')
                                 .replaceAll('Saturday', 'Thứ 7')
                                 .replaceAll('Sunday', 'Chủ nhật');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Lịch làm việc", style: TextStyle(color: Colors.green[100], fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(formattedDate, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox(total.toString(), "Tổng ca", Icons.event_note),
              _buildStatBox(completed.toString(), "Đã xong", Icons.check_circle_outline),
              _buildStatBox(active.toString(), "Chưa xong", Icons.access_time),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatBox(String count, String label, IconData icon) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.15),
         borderRadius: BorderRadius.circular(15)
       ),
       child: Column(
         children: [
           Icon(icon, color: Colors.white, size: 24),
           const SizedBox(height: 8),
           Text(count, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
           Text(label, style: TextStyle(color: Colors.green[50], fontSize: 12)),
         ],
       ),
     );
  }

  Widget _buildTimelineItem(String docId, Map<String, dynamic> data, bool isLast) {
    final t = (data['time'] as Timestamp).toDate();
    final timeStr = DateFormat('HH:mm').format(t);
    final status = data['status'] ?? 'pending';

    final now = DateTime.now();
    final diff = t.difference(now);
    final isUrgent = (status == 'confirmed' || status == 'accepted') && diff.inMinutes > 0 && diff.inMinutes <= 120;
    
    // Màu sắc theo trạng thái
    Color dotColor = Colors.orange;
    Color bgColor = Colors.white;
    String statusText = "Chờ duyệt";

    final isDone = status == 'completed' || status == 'cancelled';
    final isTimePassed = t.isBefore(now) && !isDone;

    if (status == 'confirmed' || status == 'accepted') {
      dotColor = isUrgent ? Colors.red : (isTimePassed ? Colors.orange : Colors.blue);
      statusText = isUrgent ? "Sắp diễn ra!" : (isTimePassed ? "Chưa hoàn thành" : "Sắp tới");
    } else if (status == 'completed') {
      dotColor = Colors.green;
      bgColor = Colors.green[50]!;
      statusText = "Hoàn thành";
    } else if (status == 'cancelled') {
        dotColor = Colors.red;
        bgColor = Colors.red[50]!;
        statusText = "Đã hủy";
    } else if (status == 'pending' && isTimePassed) {
        dotColor = Colors.red[300]!;
        statusText = "Quá hạn duyệt";
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bên trái: Thời gian & Trục chỉ thị
          SizedBox(
            width: 70,
            child: Column(
              children: [
                Text(timeStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDone ? Colors.grey : Colors.black87)),
                const SizedBox(height: 6),
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: dotColor.withOpacity(0.4), blurRadius: 4)]
                  ),
                ),
                Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : Colors.grey[300])),
              ],
            ),
          ),

          // Bên phải: Thẻ nội dung
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isUrgent ? Colors.red.withOpacity(0.3) : Colors.grey[200]!),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header của thẻ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: dotColor.withOpacity(isDone ? 0.05 : 0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                               decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(10)),
                               child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            if (!isDone && (status == 'confirmed' || status == 'accepted')) 
                            InkWell(
                              onTap: () => _markAsCompleted(docId),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                child: const Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                            )
                          ],
                        ),
                      ),
                      
                      // Thân thẻ
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Countdown
                            if ((status == 'confirmed' || status == 'accepted') && diff.inMinutes > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isUrgent ? Colors.red.withOpacity(0.06) : Colors.blue.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_rounded, size: 15, color: isUrgent ? Colors.red[700] : Colors.blue[700]),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatCountdown(diff),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUrgent ? Colors.red[700] : Colors.blue[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            Row(
                              children: [
                                CircleAvatar(backgroundColor: Colors.blue[100], child: Text((data['farmerName']?[0] ?? "N").toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['farmerName'] ?? "Nhà nông", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      GestureDetector(
                                        onTap: () => _showFarmerDetailDialog(context, data['farmerId'], data['farmerName'] ?? "Nông dân", data['farmerPhone'] ?? "", data['farmerAddress'] ?? ""),
                                        child: Text("Xem thông tin liên hệ →", style: TextStyle(color: Colors.green[600], fontSize: 12, fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.note_alt_outlined, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(child: Text(data['note'] ?? "Không có mô tả.", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(child: Text(data['farmerAddress'] ?? "Không có địa chỉ.", style: const TextStyle(fontSize: 13, color: Colors.black87))),
                              ],
                            ),
                            
                            // NÂNG CẤP: Hiển thị doanh thu thực nhận
                            if (status == 'completed' && data['earnedRevenue'] != null)
                              _revenueBox(data['earnedRevenue'].toDouble()),

                            // NÂNG CẤP: Hiển thị ảnh xác nhận của chuyên gia
                            if (status == 'completed' && data['confirmImages'] != null)
                              _confirmImagesBox(data['confirmImages'] as List<dynamic>),

                            // NÂNG CẤP: Hiển thị đánh giá của nông dân
                            if (status == 'completed' && (data['isRated'] ?? false))
                              _farmerReviewBox(data['ratingValue'], data['reviewComment'] ?? '', data['reviewImages'] ?? []),

                            const SizedBox(height: 16),
                            
                            // MENU HÀNH ĐỘNG
                            if (!isDone)
                            Column(
                              children: [
                                // Case 1: Appointment is Pending -> Show Accept/Reject
                                if (status == 'pending') ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _updateStatus(docId, 'confirmed'),
                                          icon: const Icon(Icons.check_circle_outline, size: 18),
                                          label: const Text("Chấp nhận", style: TextStyle(fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[600],
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _updateStatus(docId, 'cancelled'),
                                          icon: const Icon(Icons.cancel_outlined, size: 18),
                                          label: const Text("Từ chối"),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red[700],
                                            side: BorderSide(color: Colors.red[200]!),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Case 2: Appointment is Confirmed/Accepted -> Show Confirm Completed
                                if (status == 'confirmed' || status == 'accepted')
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _markAsCompleted(docId),
                                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                        label: const Text("Xác nhận đã hoàn thành", style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          backgroundColor: Colors.green[600],
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Chat, Call, Map
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          final String chatRoomId = "${data['farmerId']}_${currentUser!.uid}";
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChatScreen(
                                                chatRoomId: chatRoomId,
                                                peerId: data['farmerId'],
                                                peerName: data['farmerName'] ?? "Nông dân",
                                                peerAvatar: "",
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.chat, size: 16),
                                        label: const Text("Chat"),
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue[700], side: BorderSide(color: Colors.blue[200]!),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                        ),
                                      )
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _callPhone(data['farmerPhone'] ?? ""),
                                        icon: const Icon(Icons.phone, size: 16),
                                        label: const Text("Gọi"),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[600], foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0
                                        ),
                                      )
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _openMap(data['farmerAddress'] ?? ""),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
                                        child: Icon(Icons.directions, color: Colors.orange[700], size: 20),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      )
    );
  }

  // ─── CÁC UI HELPER MỚI (ĐỒNG NHẤT VỚI QUẢN LÝ LỊCH HẸN) ────────────────────
  
  String _formatCountdown(Duration diff) {
    if (diff.inMinutes < 60) return 'Còn ${diff.inMinutes} phút nữa';
    return 'Còn ${diff.inHours} giờ ${diff.inMinutes % 60} phút nữa';
  }

  Widget _revenueBox(double amount) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, size: 16, color: Colors.green[800]),
          const SizedBox(width: 6),
          Text(
            "Thực nhận: ${NumberFormat("#,##0", "vi_VN").format(amount)} VNĐ",
            style: TextStyle(color: Colors.green[800], fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _confirmImagesBox(List<dynamic> images) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text("Ảnh xác nhận (${images.length})", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue[700])),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: images.map<Widget>((url) {
                  return GestureDetector(
                    onTap: () => _showFullImageDialog(context, url),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, width: 70, height: 70, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey[200], child: Icon(Icons.broken_image, size: 20, color: Colors.grey[400])),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _farmerReviewBox(int? rating, String comment, List<dynamic> images) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_rounded, size: 16, color: Colors.amber[700]),
              const SizedBox(width: 6),
              Text("Đánh giá từ khách hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber[800])),
              const Spacer(),
              ...List.generate(5, (i) => Icon(i < (rating ?? 5) ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 16)),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"$comment"', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[800], height: 1.3)),
          ],
          if (images.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: images.map<Widget>((url) {
                    return GestureDetector(
                      onTap: () => _showFullImageDialog(context, url),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(url, width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey[200], child: Icon(Icons.broken_image, size: 16, color: Colors.grey[400])),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, size: 48))),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFarmerDetailDialog(BuildContext context, String farmerId, String name, String phone, String address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text(phone),
              onTap: () => _callPhone(phone),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.orange),
              title: Text(address),
              onTap: () => _openMap(address),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng")),
        ],
      ),
    );
  }

}
