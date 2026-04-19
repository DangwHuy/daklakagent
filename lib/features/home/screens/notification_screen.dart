import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Future<void> _markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final query = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
        
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    if (query.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  void _deleteNotification(String docId) {
    FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 8) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } else if ((difference.inDays / 7).floor() >= 1) {
      return '1 tuần trước';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays >= 1) {
      return 'Hôm qua';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  IconData _getIconForNotification(String title, String? type) {
    String lowerTitle = title.toLowerCase();
    if (type == 'expert_registration' || lowerTitle.contains('chuyên gia')) return Icons.workspace_premium_rounded;
    if (lowerTitle.contains('lịch hẹn') || lowerTitle.contains('tư vấn')) return Icons.event_available_rounded;
    if (lowerTitle.contains('giá') || lowerTitle.contains('thị trường')) return Icons.trending_up_rounded;
    if (lowerTitle.contains('cảnh báo')) return Icons.warning_amber_rounded;
    return Icons.notifications_active_rounded;
  }

  Color _getColorForNotification(String title, String? type) {
    String lowerTitle = title.toLowerCase();
    if (type == 'expert_registration' || lowerTitle.contains('chuyên gia')) return Colors.orange;
    if (lowerTitle.contains('giá') || lowerTitle.contains('thị trường')) return Colors.blue;
    if (lowerTitle.contains('cảnh báo') || lowerTitle.contains('từ chối') || lowerTitle.contains('rất tiếc')) return Colors.red;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Thông báo", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5)),
        backgroundColor: const Color(0xFFF8F9FA),
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Đánh dấu đã đọc tất cả',
            icon: const Icon(Icons.playlist_add_check_rounded, color: Colors.green, size: 28),
            onPressed: () => _markAllAsRead(user.uid),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_off_rounded, size: 80, color: Colors.green[200]),
                  ),
                  const SizedBox(height: 24),
                  const Text("Chưa có thông báo nào", style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Khi có cập nhật mới, hệ thống sẽ gửi\nthông báo cho bạn tại đây.", 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final isRead = data['isRead'] ?? true;
              final title = data['title'] ?? "Thông báo";
              final body = data['body'] ?? "";
              final type = data['type'] as String?;
              final createdAt = data['createdAt'] as Timestamp?;
              
              final timeAgo = createdAt != null ? _getTimeAgo(createdAt.toDate()) : '';
              final notiColor = _getColorForNotification(title, type);
              final notiIcon = _getIconForNotification(title, type);

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                ),
                onDismissed: (_) => _deleteNotification(doc.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isRead ? Colors.transparent : Colors.green[200]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (!isRead) {
                        FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(doc.id)
                            .update({'isRead': true});
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Container
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isRead ? Colors.grey[100] : notiColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(notiIcon, color: isRead ? Colors.grey[400] : notiColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 16,
                                          color: isRead ? Colors.black87 : Colors.black,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8, top: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.red[500],
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)
                                          ]
                                        ),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  body,
                                  style: TextStyle(
                                    color: isRead ? Colors.grey[600] : Colors.black87,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 14, color: isRead ? Colors.grey[400] : Colors.green[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeAgo,
                                      style: TextStyle(
                                        color: isRead ? Colors.grey[500] : Colors.green[700], 
                                        fontSize: 12,
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
