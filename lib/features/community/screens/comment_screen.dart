import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comment_service.dart';
import '../widgets/comment_item.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();
  
  String? _replyToCommentId;
  String? _replyToUserId;
  String? _replyToUserName;
  
  bool _isSending = false;

  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      await _commentService.addComment(
        widget.postId,
        _commentController.text.trim(),
        parentCommentId: _replyToCommentId,
        replyToUserId: _replyToUserId,
        replyToUserName: _replyToUserName,
      );
      
      _commentController.clear();
      _cancelReply();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startReply(String commentId, String userId, String userName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserId = userId;
      _replyToUserName = userName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserId = null;
      _replyToUserName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header BottomSheet sang trọng
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              const Text("Bình luận", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _commentService.getComments(widget.postId),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(fontSize: 12)));
              if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: Colors.green[700]));

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[200]),
                      const SizedBox(height: 12),
                      const Text("Chưa có bình luận nào.\n Hãy là người đầu tiên!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                );
              }

              final comments = docs.toList();
              comments.sort((a, b) {
                final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                if (aTime == null) return -1;
                if (bTime == null) return 1;
                return bTime.compareTo(aTime);
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: comments.length,
                itemBuilder: (context, index) => CommentItem(
                  postId: widget.postId,
                  commentDoc: comments[index],
                  onReply: _startReply,
                ),
              );
            },
          ),
        ),
        
        // Input bar hiện đại
        if (_replyToUserName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(top: BorderSide(color: Colors.green.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Icon(Icons.reply_rounded, size: 16, color: Colors.green[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      children: [
                        const TextSpan(text: "Đang trả lời "),
                        TextSpan(text: _replyToUserName!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
                GestureDetector(onTap: _cancelReply, child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey)),
              ],
            ),
          ),
          
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16, 
            left: 16, right: 16, top: 12
          ),
          decoration: BoxDecoration(
            color: Colors.white, 
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -4))
            ]
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100], 
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: _replyToUserName != null ? "Viết câu trả lời..." : "Viết bình luận...", 
                      hintStyle: const TextStyle(fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_isSending) 
                const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
              else 
                GestureDetector(
                  onTap: _sendComment,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green[700], shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
