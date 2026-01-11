import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FindExpertScreen extends StatefulWidget {
  const FindExpertScreen({super.key});

  @override
  State<FindExpertScreen> createState() => _FindExpertScreenState();
}

class _FindExpertScreenState extends State<FindExpertScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Tìm Chuyên Gia Tư Vấn", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // NÚT XEM LỊCH ĐÃ ĐẶT
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FarmerAppointmentsScreen()),
              );
            },
            icon: const Icon(Icons.calendar_month),
            tooltip: "Lịch đã đặt",
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Tìm theo tên hoặc chuyên môn...",
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      // --- STREAM 1: LẤY DANH SÁCH LỊCH ĐÃ ĐẶT CỦA NÔNG DÂN ---
      // Mục đích: Để biết giờ nào đã đặt rồi thì ẩn đi, tránh spam
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('farmerId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, appointmentSnapshot) {
            // Tạo một Set chứa các key "expertId_timestamp" đã đặt
            Set<String> bookedSlots = {};

            if (appointmentSnapshot.hasData) {
              for (var doc in appointmentSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final String expertId = data['expertId'];
                final Timestamp time = data['time'];
                // Key duy nhất để nhận diện lịch trùng
                bookedSlots.add("${expertId}_${time.seconds}");
              }
            }

            // --- STREAM 2: LẤY DANH SÁCH CHUYÊN GIA ---
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'expert')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }

                final now = DateTime.now();

                var experts = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final expertInfo = data['expertInfo'] as Map<String, dynamic>? ?? {};

                  List<dynamic> rawSlots = expertInfo['availableSlots'] ?? [];

                  // LỌC SLOT:
                  // 1. Phải là tương lai (isAfter now)
                  // 2. Chưa bị đặt (không nằm trong bookedSlots)
                  List<DateTime> validSlots = rawSlots
                      .map((e) => (e as Timestamp).toDate())
                      .where((date) {
                    // Kiểm tra trùng lịch
                    final String key = "${doc.id}_${(date.millisecondsSinceEpoch / 1000).floor()}";
                    bool isBooked = bookedSlots.contains(key);

                    return date.isAfter(now) && !isBooked; // Chỉ lấy nếu chưa đặt
                  })
                      .toList();

                  validSlots.sort();

                  return {
                    'id': doc.id,
                    'name': data['displayName'] ?? "Chuyên gia",
                    'photoUrl': data['photoUrl'] ?? "",
                    'specialty': expertInfo['specialty'] ?? "Nông nghiệp",
                    'bio': expertInfo['bio'] ?? "",
                    'isOnline': expertInfo['isOnline'] ?? false,
                    'validSlots': validSlots,
                  };
                }).toList();

                // Lọc chuyên gia (Logic cũ)
                experts = experts.where((e) {
                  final bool isOnline = e['isOnline'] as bool;
                  final List slots = e['validSlots'] as List;
                  final String name = (e['name'] as String).toLowerCase();
                  final String specialty = (e['specialty'] as String).toLowerCase();

                  bool passStatus = isOnline && slots.isNotEmpty;
                  bool passSearch = _searchText.isEmpty || name.contains(_searchText) || specialty.contains(_searchText);

                  return passStatus && passSearch;
                }).toList();

                experts.sort((a, b) {
                  DateTime firstSlotA = (a['validSlots'] as List<DateTime>).first;
                  DateTime firstSlotB = (b['validSlots'] as List<DateTime>).first;
                  return firstSlotA.compareTo(firstSlotB);
                });

                if (experts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                          bookedSlots.isNotEmpty
                              ? "Bạn đã đặt hết lịch rảnh hiện có!"
                              : "Hiện không có chuyên gia nào rảnh.",
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: experts.length,
                  itemBuilder: (context, index) {
                    final expert = experts[index];
                    return _buildExpertCard(context, expert);
                  },
                );
              },
            );
          }
      ),
    );
  }

  Widget _buildExpertCard(BuildContext context, Map<String, dynamic> expert) {
    final List<DateTime> slots = expert['validSlots'] as List<DateTime>;
    final displaySlots = slots.take(4).toList();
    final int remainingSlots = slots.length - 4;
    final String expertId = expert['id'];

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Phần Header: Avatar + Tên
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue[50],
                      backgroundImage: expert['photoUrl'] != ""
                          ? NetworkImage(expert['photoUrl'])
                          : null,
                      child: expert['photoUrl'] == ""
                          ? Text((expert['name'] as String)[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14, height: 14,
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
                      Text(
                        expert['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          expert['specialty'],
                          style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expert['bio'].toString().isNotEmpty ? expert['bio'] : "Sẵn sàng tư vấn hỗ trợ bà con.",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Phần Lịch: Hiển thị ngang
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_filled, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      "Lịch rảnh sắp tới:",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...displaySlots.map((time) => _buildTimeChip(context, time, expert['name'], expertId)),
                    if (remainingSlots > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("+$remainingSlots", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeChip(BuildContext context, DateTime time, String expertName, String expertId) {
    final timeStr = DateFormat('HH:mm').format(time);
    String dateStr;
    final now = DateTime.now();
    if (time.day == now.day && time.month == now.month && time.year == now.year) {
      dateStr = "Hôm nay";
    } else {
      dateStr = DateFormat('dd/MM').format(time);
    }

    return InkWell(
      onTap: () => _showBookingDialog(context, expertName, time, expertId),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Text(
              timeStr,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
            ),
            Text(
              dateStr,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // --- HÀM ĐẶT LỊCH (ĐÃ THÊM SĐT VÀ ĐỊA CHỈ CHO CHUYÊN GIA THẤY) ---
  void _showBookingDialog(BuildContext context, String expertName, DateTime time, String expertId) {
    final TextEditingController noteController = TextEditingController();
    // 2 Controller mới để nhận thông tin liên hệ của nông dân
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("Xác nhận đặt lịch"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Chuyên gia: $expertName", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Thời gian: ${DateFormat('HH:mm - dd/MM/yyyy').format(time)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const Divider(height: 20),

                    // --- PHẦN NHẬP THÔNG TIN LIÊN HỆ (QUAN TRỌNG) ---
                    const Text("Thông tin liên hệ của bạn:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Số điện thoại (*)",
                        hintText: "Để chuyên gia gọi lại",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: "Địa chỉ / Khu vực",
                        hintText: "VD: Thôn 3, Cư M'gar",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),

                    const SizedBox(height: 15),
                    const Text("Mô tả vấn đề:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: "VD: Cây bị vàng lá...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),

                    if (_isBooking)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              actions: _isBooking ? [] : [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Huỷ")),
                ElevatedButton(
                  onPressed: () async {
                    if (phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập số điện thoại!"), backgroundColor: Colors.red));
                      return;
                    }

                    setDialogState(() => _isBooking = true);
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) throw Exception("Bạn chưa đăng nhập!");

                      // Lưu lịch hẹn kèm SĐT và Địa chỉ để chuyên gia thấy
                      await FirebaseFirestore.instance.collection('appointments').add({
                        'farmerId': user.uid,
                        'farmerName': user.displayName ?? "Nông dân",
                        'expertId': expertId,
                        'expertName': expertName,
                        'time': Timestamp.fromDate(time),
                        'status': 'pending',
                        'note': noteController.text.trim(),
                        'farmerPhone': phoneController.text.trim(), // Lưu SĐT
                        'farmerAddress': addressController.text.trim(), // Lưu Địa chỉ
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã gửi yêu cầu thành công!"), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => _isBooking = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text("Gửi Yêu Cầu"),
                ),
              ],
            );
          }
      ),
    );
  }
}
class FarmerAppointmentsScreen extends StatelessWidget {
  const FarmerAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Lịch Đã Đặt"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('farmerId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true) // Mới nhất lên đầu
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Bạn chưa đặt lịch hẹn nào.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              // Thêm ID để sau này có thể dùng nếu cần
              data['id'] = docs[index].id;

              final DateTime time = (data['time'] as Timestamp).toDate();
              final String expertName = data['expertName'] ?? "Chuyên gia";
              final String status = data['status'] ?? "pending";

              Color statusColor = Colors.orange;
              String statusText = "Chờ xác nhận";
              if (status == 'confirmed') {
                statusColor = Colors.green;
                statusText = "Đã xác nhận";
              } else if (status == 'cancelled') {
                statusColor = Colors.red;
                statusText = "Đã huỷ";
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => _showAppointmentDetails(context, data),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(
                        status == 'confirmed' ? Icons.check_circle : (status == 'cancelled' ? Icons.cancel : Icons.access_time),
                        color: statusColor
                    ),
                  ),
                  title: Text(expertName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Thời gian: ${DateFormat('HH:mm - dd/MM/yyyy').format(time)}"),
                      if (status == 'cancelled')
                        Text("Đã bị hủy", style: TextStyle(color: Colors.red[300], fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- HÀM HIỂN THỊ CHI TIẾT LỊCH HẸN ---
  void _showAppointmentDetails(BuildContext context, Map<String, dynamic> data) {
    final String status = data['status'] ?? 'pending';
    final String expertName = data['expertName'] ?? 'Chuyên gia';
    final String expertId = data['expertId'];
    final DateTime time = (data['time'] as Timestamp).toDate();
    final String? cancelReason = data['cancelReason'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 10),
              const Text("Chi tiết lịch hẹn"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thông tin chung
                _buildDetailRow("Chuyên gia:", expertName),
                const SizedBox(height: 8),
                _buildDetailRow("Thời gian:", DateFormat('HH:mm - dd/MM/yyyy').format(time)),
                const SizedBox(height: 8),
                _buildDetailRow("Ghi chú của bạn:", data['note'] ?? "Không có"),
                const Divider(height: 20),

                // XỬ LÝ THEO TRẠNG THÁI
                if (status == 'cancelled') ...[
                  // 1. Trường hợp bị HỦY
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Lịch hẹn đã bị hủy!",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Lý do: ${cancelReason ?? 'Không có lý do cụ thể'}",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  )
                ] else if (status == 'confirmed') ...[
                  // 2. Trường hợp ĐÃ XÁC NHẬN -> Hiện thông tin chuyên gia
                  const Text("Thông tin liên hệ chuyên gia:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 10),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(expertId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text("Không tải được thông tin chuyên gia.");
                      }

                      final expertData = snapshot.data!.data() as Map<String, dynamic>;
                      final phone = expertData['phoneNumber'] ?? expertData['phone'] ?? "Chưa cập nhật";
                      final email = expertData['email'] ?? "Chưa cập nhật";
                      final address = expertData['address'] ?? expertData['location'] ?? "Chưa cập nhật";

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContactRow(Icons.phone, phone),
                          const SizedBox(height: 8),
                          _buildContactRow(Icons.email, email),
                          const SizedBox(height: 8),
                          _buildContactRow(Icons.location_on, address),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                            child: const Text(
                              "Bạn có thể đến địa chỉ trên hoặc gọi điện để được tư vấn.",
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          )
                        ],
                      );
                    },
                  )
                ] else ...[
                  // 3. Trường hợp ĐANG CHỜ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_empty, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(child: Text("Đang chờ chuyên gia xác nhận. Vui lòng quay lại sau.")),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}