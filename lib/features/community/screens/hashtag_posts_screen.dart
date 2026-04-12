import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/post_card.dart';

class HashtagPostsScreen extends StatelessWidget {
  final String hashtag;

  const HashtagPostsScreen({super.key, required this.hashtag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "#$hashtag",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('hashtags', arrayContains: hashtag.toLowerCase())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.green[700]));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          
          final posts = snapshot.data?.docs ?? [];
          final sortedPosts = List<DocumentSnapshot>.from(posts);
          sortedPosts.sort((a, b) {
            final aTimestamp = (a.data() as Map)['timestamp'] as Timestamp?;
            final bTimestamp = (b.data() as Map)['timestamp'] as Timestamp?;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            return bTimestamp.compareTo(aTimestamp);
          });

          if (sortedPosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tag_faces_rounded, size: 80, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  Text(
                    "Chưa có bài viết nào với #$hashtag",
                    style: TextStyle(fontSize: 16, color: Colors.grey[400], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sortedPosts.length,
            itemBuilder: (context, index) => PostCard(post: sortedPosts[index]),
          );
        },
      ),
    );
  }
}
