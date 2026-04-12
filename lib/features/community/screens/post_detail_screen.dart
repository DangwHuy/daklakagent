import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/post_card.dart';
import '../services/comment_service.dart';
import '../widgets/comment_item.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final bool openComments;

  const PostDetailScreen({super.key, required this.postId, this.openComments = false});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();
  
  late Stream<DocumentSnapshot> _postStream;
  late Stream<QuerySnapshot> _commentsStream;

  String? _replyToCommentId;
  String? _replyToUserId;
  String? _replyToUserName;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _postStream = FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots();
    _commentsStream = _commentService.getComments(widget.postId);
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chi tiết bài viết",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _postStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.green[700]));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Bài viết này không tồn tại."));
          }

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              PostCard(post: snapshot.data!, isDetail: true),
              
              // Danh sách bình luận tích hợp trực tiếp
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    const Text(
                      "Thảo luận",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: _commentsStream,
                      builder: (context, cmSnapshot) {
                        final count = cmSnapshot.data?.docs.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            "$count",
                            style: TextStyle(color: Colors.green[800], fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: _commentsStream,
                builder: (context, cmSnapshot) {
                  if (cmSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  final docs = cmSnapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.black12),
                          const SizedBox(height: 12),
                          const Text(
                            "Chưa có thảo luận công khai",
                            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Hãy là người đầu tiên chia sẻ ý kiến!",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sắp xếp bình luận mới nhất lên đầu
                  final comments = docs.toList();
                   comments.sort((a, b) {
                    final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                    final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                    if (aTime == null) return -1;
                    if (bTime == null) return 1;
                    return bTime.compareTo(aTime);
                  });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) => CommentItem(
                      postId: widget.postId,
                      commentDoc: comments[index],
                      onReply: _startReply,
                    ),
                  );
                },
              ),
              const SizedBox(height: 100), // Khoảng trống cho input bar
            ],
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              left: 16,
              right: 16,
              top: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -4))
              ],
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
                _isSending 
                ? const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
                : GestureDetector(
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
      ),
    );
  }
}

