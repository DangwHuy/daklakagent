import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/comment_service.dart';
import 'comment_bubble.dart';

class CommentItem extends StatefulWidget {
  final String postId;
  final DocumentSnapshot commentDoc;
  final Function(String commentId, String userId, String userName) onReply;

  const CommentItem({
    super.key, 
    required this.postId, 
    required this.commentDoc, 
    required this.onReply,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  final CommentService _commentService = CommentService();
  bool _showAllReplies = false;
  late Stream<QuerySnapshot> _repliesStream; 
  int _prevReplyCount = -1;

  @override
  void initState() {
    super.initState();
    _repliesStream = _commentService.getReplies(widget.postId, widget.commentDoc.id);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.commentDoc.data() as Map<String, dynamic>;
    final commentId = widget.commentDoc.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentBubble(
            postId: widget.postId,
            commentId: commentId,
            data: data,
            isReply: false, 
            onReply: () {
               widget.onReply(commentId, data['userId'] ?? '', data['userName'] ?? 'Người dùng');
            },
          ),
          
          StreamBuilder<QuerySnapshot>(
            stream: _repliesStream, 
            builder: (context, snapshot) {
              // Bỏ báo lỗi Index vì giờ đã dùng sorting thủ công
              if (!snapshot.hasData) return const SizedBox.shrink();

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const SizedBox.shrink();

              // SẮP XẾP THỦ CÔNG CÁC CÂU TRẢ LỜI (Từ cũ đến mới)
              final replies = docs.toList();
              replies.sort((a, b) {
                final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return aTime.compareTo(bTime);
              });

              if (_prevReplyCount != -1 && replies.length > _prevReplyCount) {
                 final lastReply = replies.last.data() as Map<String, dynamic>;
                 if (lastReply['userId'] == FirebaseAuth.instance.currentUser?.uid && !_showAllReplies) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _showAllReplies = true);
                    });
                 }
              }
              _prevReplyCount = replies.length;

              final displayedReplies = _showAllReplies ? replies : [replies.first];
              final hasMoreReplies = replies.length > displayedReplies.length;

              return Padding(
                padding: const EdgeInsets.only(left: 44.0), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedReplies.length,
                      itemBuilder: (context, i) {
                        final replyData = displayedReplies[i].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: CommentBubble(
                            postId: widget.postId,
                            commentId: displayedReplies[i].id,
                            data: replyData,
                            isReply: true,
                            isLastReply: i == displayedReplies.length - 1 && !hasMoreReplies,
                            onReply: () {
                              widget.onReply(commentId, replyData['userId'] ?? '', replyData['userName'] ?? 'Người dùng');
                            },
                          ),
                        );
                      },
                    ),
                    if (hasMoreReplies)
                      GestureDetector(
                        onTap: () => setState(() => _showAllReplies = true),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, top: 4),
                          child: Text(
                            'Xem thêm ${replies.length - 1} phản hồi...', 
                            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
