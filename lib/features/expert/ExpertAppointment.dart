import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExpertAppointmentsScreen extends StatefulWidget {
  const ExpertAppointmentsScreen({super.key});

  @override
  State<ExpertAppointmentsScreen> createState() => _ExpertAppointmentsScreenState();
}

class _ExpertAppointmentsScreenState extends State<ExpertAppointmentsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // Function to handle appointment status update
  Future<void> _updateStatus(String docId, String newStatus, {String? reason}) async {
    try {
      Map<String, dynamic> updateData = {'status': newStatus};
      if (reason != null) {
        updateData['cancelReason'] = reason;
      }
      
      await FirebaseFirestore.instance.collection('appointments').doc(docId).update(updateData);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'confirmed' ? "Đã xác nhận lịch hẹn!" : "Đã từ chối lịch hẹn."),
          backgroundColor: newStatus == 'confirmed' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  // Show dialog to enter cancellation reason
  void _showCancelDialog(String docId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Từ chối lịch hẹn"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Nhập lý do (ví dụ: Trùng lịch, bận việc đột xuất...)",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(docId, 'cancelled', reason: controller.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Xác nhận từ chối"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Cần đăng nhập")));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Quản lý Lịch hẹn"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('expertId', isEqualTo: user!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Chưa có yêu cầu tư vấn nào.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String docId = doc.id;
              
              final DateTime time = (data['time'] as Timestamp).toDate();
              final String farmerName = data['farmerName'] ?? "Nông dân";
              final String status = data['status'] ?? "pending";
              final String note = data['note'] ?? "";
              final String phone = data['farmerPhone'] ?? "Không có SĐT";
              final String address = data['farmerAddress'] ?? "Không có địa chỉ";

              Color statusColor = Colors.orange;
              String statusText = "Đang chờ";
              if (status == 'confirmed') {
                statusColor = Colors.green;
                statusText = "Đã xác nhận";
              } else if (status == 'cancelled') {
                statusColor = Colors.red;
                statusText = "Đã từ chối";
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                shadowColor: Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(farmerName[0].toUpperCase(), style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(farmerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(DateFormat('dd/MM/yyyy - HH:mm').format(time), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
                            child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Divider(height: 25),
                      
                      _buildInfoRow(Icons.phone, "Số điện thoại:", phone),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.location_on, "Địa chỉ:", address),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.description, "Nội dung:", note.isNotEmpty ? note : "Không có ghi chú"),
                      
                      if (status == 'pending') ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showCancelDialog(docId),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text("Từ chối"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus(docId, 'confirmed'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text("Xác nhận"),
                              ),
                            ),
                          ],
                        )
                      ] else if (status == 'cancelled' && data.containsKey('cancelReason')) ...[
                         const SizedBox(height: 12),
                         Container(
                           padding: const EdgeInsets.all(12),
                           width: double.infinity,
                           decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                           child: Text("Lý do từ chối: ${data['cancelReason']}", style: TextStyle(color: Colors.red[800], fontSize: 13, fontStyle: FontStyle.italic)),
                         )
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blue[800]),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(width: 5),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}