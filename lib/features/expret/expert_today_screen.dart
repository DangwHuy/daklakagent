import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  void _markAsCompleted(String appointmentId) async {
    // Hiện popup nhập số tiền doanh thu nếu muốn giống chuẩn cũ. 
    // Tuy nhiên ở màn này ta đơn giản hóa, chỉ đổi trạng thái là 'completed'. Doanh thu tính sau hoặc nhập nhanh.
    showDialog(
      context: context,
      builder: (ctx) {
        final TextEditingController _amountController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Xác nhận hoàn thành"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Vuốt xác nhận đã tư vấn xong & Nhập thu nhập (tùy chọn):"),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Thu nhập (VNĐ)",
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                ),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("Xác nhận"),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  double amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
                  
                  final batch = FirebaseFirestore.instance.batch();
                  final appRef = FirebaseFirestore.instance.collection('appointments').doc(appointmentId);
                  final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);

                  batch.update(appRef, {
                    'status': 'completed',
                    'earnedRevenue': amount,
                    'completedAt': FieldValue.serverTimestamp(),
                    'confirmedAt': FieldValue.serverTimestamp(), // Đảm bảo luôn có mốc xác nhận để tính Radar
                  });
                  batch.update(userRef, {
                    'expertInfo.revenue': FieldValue.increment(amount),
                  });
                  
                  await batch.commit();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu hoàn thành ca tư vấn!"), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                  }
                }
              }
            )
          ],
        );
      }
    );
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
          int pending = todayDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'pending' || (d.data() as Map<String, dynamic>)['status'] == 'confirmed').length;

          return Column(
            children: [
               _buildHeaderPanel(now, total, completed, pending),
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

  Widget _buildHeaderPanel(DateTime date, int total, int completed, int pending) {
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
              _buildStatBox(pending.toString(), "Sắp diễn ra", Icons.access_time),
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
    
    // Màu sắc theo trạng thái
    Color dotColor = Colors.orange;
    Color bgColor = Colors.white;
    String statusText = "Chờ duyệt";

    if (status == 'confirmed' || status == 'accepted') {
      dotColor = Colors.blue;
      statusText = "Sắp tới";
    } else if (status == 'completed') {
      dotColor = Colors.green;
      bgColor = Colors.green[50]!;
      statusText = "Hoàn thành";
    } else if (status == 'cancelled') {
        dotColor = Colors.red;
        bgColor = Colors.red[50]!;
        statusText = "Đã hủy";
    }

    final isDone = status == 'completed' || status == 'cancelled';

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
                  border: Border.all(color: Colors.grey[200]!),
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
                            if (!isDone) 
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
                            Row(
                              children: [
                                CircleAvatar(backgroundColor: Colors.blue[100], child: Text((data['farmerName']?[0] ?? "N").toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['farmerName'] ?? "Nhà nông", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text(data['farmerPhone'] ?? "Không có SĐT", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
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
                            
                            const SizedBox(height: 16),
                            // Menu hành động nhanh
                            if (!isDone)
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
                                              peerAvatar: "", // Add default generic
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
                                    onPressed: () {
                                      _callPhone(data['farmerPhone'] ?? "");
                                    },
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
                                  onTap: () {
                                    _openMap(data['farmerAddress'] ?? "");
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
                                    child: Icon(Icons.directions, color: Colors.orange[700], size: 20),
                                  ),
                                )
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
}
