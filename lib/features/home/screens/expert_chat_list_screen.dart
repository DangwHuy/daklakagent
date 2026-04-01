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
        title: const Text("Tin nhắn của bà con", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // SỬA ĐỔI: Dùng hàm where chuẩn của Firebase dựa vào cấu trúc mảng users bạn cung cấp
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

          // Lấy danh sách doc
          var docs = snapshot.data!.docs.toList();

          // Thực hiện sắp xếp (Sort) bằng Dart để đẩy tin nhắn mới nhất lên đầu, không cần index server
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final Timestamp? timeA = dataA['lastMessageTime'];
            final Timestamp? timeB = dataB['lastMessageTime'];

            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;

            return timeB.compareTo(timeA); // Sắp xếp giảm dần
          });

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final roomId = docs[index].id;

              // Cố gắng tìm ID người kia (Nông dân) từ mảng
              List<dynamic> users = data['users'] ?? [];
              String peerId = users.firstWhere((id) => id != currentUserId, orElse: () => "");

              if (peerId.isEmpty) return const SizedBox.shrink();

              // Dùng FutureBuilder để lấy tên/avatar nông dân từ bảng users
              return FutureBuilder<DocumentSnapshot>(
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

                  return Card(
                    elevation: 2,
                    shadowColor: Colors.black12,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.green[50],
                        backgroundImage: peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                        child: peerAvatar.isEmpty
                            ? Text(peerName[0], style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 20))
                            : null,
                      ),
                      title: Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          data['lastMessage'] ?? "Đã gửi hình ảnh/file...",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      trailing: time != null
                          ? Text(DateFormat('HH:mm').format(time), style: TextStyle(color: Colors.grey[500], fontSize: 12))
                          : null,
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
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