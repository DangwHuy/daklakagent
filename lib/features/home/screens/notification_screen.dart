import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Đã có lỗi xảy ra", style: TextStyle(color: Colors.red[400])));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("Bạn chưa có thông báo nào", style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Container(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? true;
              final title = data['title'] ?? "Thông báo";
              final body = data['body'] ?? "";
              final createdAt = data['createdAt'] as Timestamp?;

              return Material(
                color: isRead ? Colors.white : Colors.green[50],
                child: InkWell(
                  onTap: () {
                    // Khi user click vào thông báo -> đánh dấu đã đọc
                    if (!isRead) {
                      FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(docs[index].id)
                          .update({'isRead': true});
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.grey[100] : Colors.green[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: isRead ? Colors.grey[400] : Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: TextStyle(
                                  color: isRead ? Colors.grey[600] : Colors.black87,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (createdAt != null)
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy • HH:mm').format(createdAt.toDate()),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 8, left: 8),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          )
                      ],
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
}
