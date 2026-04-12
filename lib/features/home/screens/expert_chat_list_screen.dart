import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart'; // Đảm bảo bạn đã import đúng

class ExpertChatListScreen extends StatelessWidget {
  const ExpertChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Disable material 3 tint
        titleSpacing: 16,
        title: Row(
          children: [
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
              "Tin nhắn của bà con",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Lọc các bản ghi đã bị ẩn bởi người dùng hiện tại
          var allDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final List<dynamic> hiddenBy = data['hiddenBy'] ?? [];
            return !hiddenBy.contains(currentUserId);
          }).toList();

          if (allDocs.isEmpty) return _buildEmptyState();

          // Sắp xếp: Ưu tiên Ghim lên đầu, sau đó đến thời gian tin nhắn mới nhất
          allDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            
            final List<dynamic> pinnedByA = dataA['pinnedBy'] ?? [];
            final List<dynamic> pinnedByB = dataB['pinnedBy'] ?? [];
            final bool isPinnedA = pinnedByA.contains(currentUserId);
            final bool isPinnedB = pinnedByB.contains(currentUserId);

            if (isPinnedA != isPinnedB) {
              return isPinnedA ? -1 : 1;
            }

            final Timestamp? timeA = dataA['lastMessageTime'];
            final Timestamp? timeB = dataB['lastMessageTime'];

            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;

            return timeB.compareTo(timeA);
          });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            itemCount: allDocs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 84),
            itemBuilder: (context, index) {
              final doc = allDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final roomId = doc.id;

              List<dynamic> users = data['users'] ?? [];
              String peerId = users.firstWhere((id) => id != currentUserId, orElse: () => "");
              if (peerId.isEmpty) return const SizedBox.shrink();

              final List<dynamic> pinnedBy = data['pinnedBy'] ?? [];
              final bool isPinned = pinnedBy.contains(currentUserId);

              return Dismissible(
                key: Key(roomId),
                background: Container(
                  color: Colors.blue[400],
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: Colors.white),
                      Text(isPinned ? "Bỏ ghim" : "Ghim", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.red[400],
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: Colors.white),
                      Text("Xóa", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    // Xử lý GHIM
                    if (isPinned) {
                      await doc.reference.update({
                        'pinnedBy': FieldValue.arrayRemove([currentUserId])
                      });
                    } else {
                      await doc.reference.update({
                        'pinnedBy': FieldValue.arrayUnion([currentUserId])
                      });
                    }
                    return false; // Không xóa widget, chỉ cập nhật data
                  } else {
                    // Xử lý XÓA (ẨN)
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Xóa cuộc trò chuyện?"),
                        content: const Text("Cuộc trò chuyện này sẽ bị ẩn khỏi danh sách của bạn."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await doc.reference.update({
                        'hiddenBy': FieldValue.arrayUnion([currentUserId])
                      });
                      return true;
                    }
                    return false;
                  }
                },
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(peerId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const SizedBox.shrink();
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData == null) return const SizedBox.shrink();

                    final peerName = userData['displayName'] ?? "Nông dân";
                    final peerAvatar = userData['photoUrl'] ?? "";

                    DateTime? time;
                    if (data['lastMessageTime'] != null) {
                      time = (data['lastMessageTime'] as Timestamp).toDate();
                    }

                    return Container(
                      color: isPinned ? Colors.blue.withOpacity(0.02) : Colors.transparent,
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatRoomId: roomId,
                                peerId: peerId,
                                peerName: peerName,
                                peerAvatar: peerAvatar,
                              ),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.green.withOpacity(0.2), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                backgroundImage: peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                                child: peerAvatar.isEmpty
                                    ? Text(peerName[0], style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 20))
                                    : null,
                              ),
                            ),
                            if (isPinned)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                  child: const Icon(Icons.push_pin, color: Colors.white, size: 10),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87))),
                            if (time != null)
                              Text(
                                _formatTime(time),
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['lastMessage'] ?? "Đã gửi hình ảnh/file...",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ),
                              // (Tùy chọn) Thêm badge cho tin nhắn chưa đọc nếu có field unreadCount
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays < 7) {
      return DateFormat('E').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  // Widget hiển thị khi không có tin nhắn
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("Chưa có tin nhắn nào.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Danh sách sẽ hiện khi có nông dân nhắn tin.", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}