import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExpertAppointmentsScreen extends StatefulWidget {
  const ExpertAppointmentsScreen({super.key});

  @override
  State<ExpertAppointmentsScreen> createState() => _ExpertAppointmentsScreenState();
}

class _ExpertAppointmentsScreenState extends State<ExpertAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Quản Lý Lịch Hẹn"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Chờ Duyệt"),
            Tab(text: "Lịch Sử / Đã Xử Lý"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList(user!.uid, status: 'pending'),
          _buildAppointmentList(user.uid, status: null),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(String expertId, {String? status}) {
    Query query = FirebaseFirestore.instance
        .collection('appointments')
        .where('expertId', isEqualTo: expertId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    } else {
      query = query.where('status', whereIn: ['confirmed', 'cancelled']);
    }

    query = query.orderBy('time', descending: false);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    status == 'pending' ? Icons.mark_email_read_outlined : Icons.history,
                    size: 60, color: Colors.grey[300]
                ),
                const SizedBox(height: 10),
                Text(
                  status == 'pending' ? "Không có yêu cầu mới nào." : "Chưa có lịch sử tư vấn.",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildAppointmentCard(doc, data, isPending: status == 'pending');
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(DocumentSnapshot doc, Map<String, dynamic> data, {required bool isPending}) {
    final DateTime time = (data['time'] as Timestamp).toDate();
    final String farmerName = data['farmerName'] ?? "Nông dân";
    final String farmerId = data['farmerId'] ?? "";
    final String status = data['status'];
    final String note = data['note'] ?? "";
    // Lấy thông tin liên hệ từ dữ liệu lịch hẹn
    final String farmerPhone = data['farmerPhone'] ?? "";
    final String farmerAddress = data['farmerAddress'] ?? "";

    Color cardColor = Colors.white;
    Color statusColor = Colors.orange;
    String statusText = "Chờ duyệt";

    if (status == 'confirmed') {
      statusColor = Colors.green;
      statusText = "Đã nhận";
      cardColor = Colors.green.shade50;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusText = "Đã huỷ";
      cardColor = Colors.red.shade50;
    }

    return Card(
      elevation: 2,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(farmerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(DateFormat('HH:mm - dd/MM/yyyy').format(time), style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),

            // --- LINK XEM CHI TIẾT ---
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: () => _showFarmerDetailDialog(context, farmerId, farmerName, farmerPhone, farmerAddress),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      "Xem thông tin liên hệ & địa chỉ",
                      style: TextStyle(color: Colors.blue[700], fontSize: 13, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ),

            // --- THÔNG TIN LIÊN HỆ TRỰC TIẾP ---
            if (farmerPhone.isNotEmpty || farmerAddress.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (farmerPhone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            SelectableText(farmerPhone, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    if (farmerAddress.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(child: SelectableText(farmerAddress)),
                        ],
                      ),
                  ],
                ),
              ),

            // --- GHI CHÚ ---
            if (note.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.orange[800]),
                        const SizedBox(width: 5),
                        Text("Ghi chú từ nông dân:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange[900])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(note, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87)),
                  ],
                ),
              ),

            // --- LÝ DO HỦY ---
            if (status == 'cancelled' && data['cancelReason'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text("Lý do huỷ: ${data['cancelReason']}", style: TextStyle(color: Colors.red[800], fontStyle: FontStyle.italic)),
              ),

            // --- BUTTONS ---
            if (isPending) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context, doc),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text("Từ chối", style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAccept(doc, time),
                      icon: const Icon(Icons.check),
                      label: const Text("Đồng ý"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  // Cập nhật Dialog để hiển thị thông tin liên hệ (ưu tiên lấy từ appointment nếu có)
  void _showFarmerDetailDialog(BuildContext context, String farmerId, String name, String apptPhone, String apptAddress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Thông tin: $name"),
        content: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(farmerId).get(),
          builder: (context, snapshot) {
            String phone = apptPhone;
            String address = apptAddress;
            String email = "Đang tải...";

            // Nếu có dữ liệu profile, update thêm email hoặc fallback nếu apptPhone rỗng
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              if (phone.isEmpty) phone = data['phoneNumber'] ?? data['phone'] ?? "Chưa cập nhật";
              if (address.isEmpty) address = data['address'] ?? data['location'] ?? "Chưa cập nhật địa chỉ";
              email = data['email'] ?? "Chưa cập nhật";
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              if (phone.isEmpty && address.isEmpty) {
                return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.phone, "Số điện thoại:", phone.isEmpty ? "Chưa cập nhật" : phone),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, "Địa chỉ/Vườn:", address.isEmpty ? "Chưa cập nhật" : address),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.email, "Email:", email),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    "Mẹo: Hãy gọi điện xác nhận trước khi đến vườn.",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              SelectableText(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAccept(DocumentSnapshot currentDoc, DateTime time) async {
    final expertId = FirebaseAuth.instance.currentUser!.uid;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.update(currentDoc.reference, {
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      final conflictQuery = await FirebaseFirestore.instance
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .where('time', isEqualTo: Timestamp.fromDate(time))
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in conflictQuery.docs) {
        if (doc.id != currentDoc.id) {
          batch.update(doc.reference, {
            'status': 'cancelled',
            'cancelReason': 'Chuyên gia đã nhận lịch hẹn khác vào khung giờ này.',
            'cancelledBy': 'system_conflict',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã nhận lịch! Các lịch trùng giờ khác đã được tự động từ chối.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  void _showRejectDialog(BuildContext context, DocumentSnapshot doc) {
    String selectedReason = "Bận đột xuất";
    final TextEditingController noteController = TextEditingController();
    final List<String> reasons = [
      "Bận đột xuất",
      "Sai chuyên môn tư vấn",
      "Đã kín lịch hôm nay",
      "Lý do khác"
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Từ chối lịch hẹn"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Chọn lý do mẫu:", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedReason,
                  isExpanded: true,
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => selectedReason = val!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: "Ghi chú thêm (Tùy chọn)",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              String finalReason = selectedReason;
              if (noteController.text.isNotEmpty) {
                finalReason += ": ${noteController.text}";
              }

              await doc.reference.update({
                'status': 'cancelled',
                'cancelReason': finalReason,
                'cancelledBy': 'expert',
                'cancelledAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã từ chối lịch hẹn.")),
                );
              }
            },
            child: const Text("Xác nhận từ chối"),
          )
        ],
      ),
    );
  }
}