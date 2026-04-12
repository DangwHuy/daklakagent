import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/time_ago.dart';
import '../screens/post_detail_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/comment_screen.dart';
import '../screens/hashtag_posts_screen.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot post;
  final bool isDetail;
  final bool openCommentsOnInit;

  const PostCard({
    super.key, 
    required this.post, 
    this.isDetail = false, 
    this.openCommentsOnInit = false
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isExpanded = false;
  bool _isHidden = false;
  OverlayEntry? _overlayEntry;

  final List<Map<String, dynamic>> _reactionTypes = [
    {'value': 'like', 'label': 'Thích', 'icon': '👍', 'color': Colors.blue},
    {'value': 'love', 'label': 'Yêu thích', 'icon': '❤️', 'color': Colors.red},
    {'value': 'haha', 'label': 'Haha', 'icon': '😆', 'color': Colors.amber},
    {'value': 'wow', 'label': 'Wow', 'icon': '😮', 'color': Colors.orange},
    {'value': 'sad', 'label': 'Buồn', 'icon': '😢', 'color': Colors.amber},
    {'value': 'angry', 'label': 'Phẫn nộ', 'icon': '😡', 'color': Colors.deepOrange},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.openCommentsOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openCommentSheet();
        }
      });
    }
  }

  void _showReactionMenu(BuildContext context, Offset position) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: position.dy - 60,
            left: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _reactionTypes.map((reaction) {
                    return GestureDetector(
                      onTap: () => _handleReaction(reaction['value']),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(reaction['icon'], style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _handleReaction(String reactionType) async {
    _removeOverlay();
    if (currentUser == null) return;
    
    final data = widget.post.data() as Map<String, dynamic>;
    final Map reactions = data['reactions'] ?? {};
    final String? currentReaction = reactions[currentUser!.uid];

    if (currentReaction == reactionType) {
      await widget.post.reference.update({
        'reactions.${currentUser!.uid}': FieldValue.delete(),
        'likes': FieldValue.arrayRemove([currentUser!.uid])
      });
    } else {
      await widget.post.reference.update({
        'reactions.${currentUser!.uid}': reactionType,
        'likes': FieldValue.arrayUnion([currentUser!.uid])
      });
    }
  }

  void _openCommentSheet() {
    if (!widget.isDetail) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(postId: widget.post.id),
        ),
      );
    }
  }

  void _showReactionDetails(Map reactions) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Người đã bày tỏ cảm xúc", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: reactions.length,
                itemBuilder: (context, index) {
                  String userId = reactions.keys.elementAt(index);
                  String reactionType = reactions[userId];
                  var config = _reactionTypes.firstWhere((e) => e['value'] == reactionType, orElse: () => _reactionTypes[0]);
                  
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: (userData?['photoUrl'] != null && userData?['photoUrl'].isNotEmpty) ? NetworkImage(userData?['photoUrl']) : null,
                              child: (userData?['photoUrl'] == null || userData?['photoUrl'].isEmpty) ? const Icon(Icons.person) : null,
                            ),
                            Positioned(right: 0, bottom: 0, child: Text(config['icon'], style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                        title: Text(userData?['displayName'] ?? 'Người dùng'),
                        trailing: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          child: const Text("Nhắn tin"),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(String content) {
    final List<TextSpan> spans = [];
    final RegExp hashtagRegex = RegExp(r"\#\w+");
    
    content.splitMapJoin(
      hashtagRegex,
      onMatch: (Match match) {
        final String hashtag = match.group(0)!;
        spans.add(
          TextSpan(
            text: hashtag,
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HashtagPostsScreen(hashtag: hashtag.substring(1)),
                  ),
                );
              },
          ),
        );
        return '';
      },
      onNonMatch: (String text) {
        spans.add(TextSpan(text: text, style: const TextStyle(color: Colors.black87)));
        return '';
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          style: const TextStyle(fontSize: 16, height: 1.4),
          children: spans,
        );

        // Tạo TextPainter để kiểm tra xem văn bản có bị cắt (overflow) hay không
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final bool hasOverflow = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: textSpan,
              maxLines: _isExpanded ? null : 3,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (hasOverflow && !widget.isDetail)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _isExpanded ? "THU GỌN ▲" : "XEM THÊM ▼",
                    style: TextStyle(
                      color: Colors.green[700], 
                      fontWeight: FontWeight.w900, 
                      fontSize: 12, 
                      letterSpacing: 0.5
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReactionSummary(Map reactions, List likes) {
    if (likes.isEmpty) return const SizedBox.shrink();

    Map<String, int> counts = {};
    reactions.forEach((key, value) {
      counts[value] = (counts[value] ?? 0) + 1;
    });

    var sortedReactions = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    var topReactions = sortedReactions.take(3).map((e) => e.key).toList();

    return GestureDetector(
      onTap: () => _showReactionDetails(reactions),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18.0 + (topReactions.length > 1 ? (topReactions.length - 1) * 12 : 0),
              height: 20,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: topReactions.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String type = entry.value;
                  var config = _reactionTypes.firstWhere((e) => e['value'] == type, orElse: () => _reactionTypes[0]);
                  return Positioned(
                    left: idx * 12.0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.0),
                      ),
                      child: Text(config['icon'], style: const TextStyle(fontSize: 11)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 4),
            Text("${likes.length}", style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_off_outlined, color: Colors.grey),
            const SizedBox(width: 12),
            const Expanded(child: Text("Bài viết này đã bị ẩn", style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () => setState(() => _isHidden = false),
              child: const Text("Hoàn tác"),
            ),
          ],
        ),
      );
    }

    final data = widget.post.data() as Map<String, dynamic>;
    final bool isOwner = currentUser?.uid == data['userId'];
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final String content = data['content'] ?? '';
    
    final Map reactions = data['reactions'] ?? {};
    final List likes = data['likes'] ?? [];
    String? myReaction = reactions[currentUser?.uid];
    
    final currentReactionConfig = myReaction != null 
        ? _reactionTypes.firstWhere((e) => e['value'] == myReaction, orElse: () => _reactionTypes[0])
        : null;

    final Color themeColor = Colors.green;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.isDetail ? 0 : 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.04),
                border: Border(bottom: BorderSide(color: themeColor.withValues(alpha: 0.05))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: themeColor.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: (data['userPhotoUrl'] != null && data['userPhotoUrl'].isNotEmpty)
                          ? NetworkImage(data['userPhotoUrl']) : null,
                      child: (data['userPhotoUrl'] == null || data['userPhotoUrl'].isEmpty)
                          ? const Icon(Icons.person, size: 24) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(data['userName'] ?? 'Nhà nông', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
                            if (data['userRole'] == 'expert') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                ),
                                child: Text("CHUYÊN GIA", style: TextStyle(fontSize: 9, color: Colors.blue[800], fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(TimeAgo.format(timestamp), style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                    onPressed: () => _showOptions(context, isOwner),
                  ),
                ],
              ),
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildContent(content),
            ),

            // Image Area
            if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
              GestureDetector(
                onTap: () {
                  if (!widget.isDetail) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: widget.post.id),
                    ));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(data['imageUrl'], width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              ),
            
            // Interaction Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (likes.isNotEmpty) 
                    _buildReactionSummary(reactions, likes),
                  const Spacer(),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.post.id)
                        .collection('comments')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final commentCount = snapshot.data?.docs.length ?? 0;
                      if (commentCount == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          "$commentCount bình luận", 
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Action Buttons
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onLongPressStart: (details) => _showReactionMenu(context, details.globalPosition),
                      onTap: () {
                          if (myReaction != null) {
                             _handleReaction(myReaction);
                          } else {
                             _handleReaction('like');
                          }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (currentReactionConfig != null)
                               Text(currentReactionConfig['icon'], style: const TextStyle(fontSize: 18))
                            else
                               Icon(Icons.thumb_up_off_alt_rounded, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              currentReactionConfig != null ? currentReactionConfig['label'] : "Thích",
                              style: TextStyle(
                                color: currentReactionConfig != null ? currentReactionConfig['color'] : Colors.grey[700],
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: "Bình luận",
                    onTap: _openCommentSheet,
                  ),
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: "Chia sẻ",
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, bool isOwner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            if (isOwner) ...[
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20)),
                title: const Text("Chỉnh sửa bài viết", style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePostScreen(post: widget.post)));
                },
              ),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle), child: const Icon(Icons.delete_rounded, color: Colors.red, size: 20)),
                title: const Text("Xóa bài viết", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  widget.post.reference.delete();
                },
              ),
            ],
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: const Icon(Icons.visibility_off_rounded, color: Colors.grey, size: 20)),
              title: const Text("Ẩn bài viết", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _isHidden = true);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
