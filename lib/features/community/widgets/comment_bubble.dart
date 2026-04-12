import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/comment_service.dart';
import '../../../utils/time_ago.dart';
import 'thread_painter.dart';

class CommentBubble extends StatefulWidget {
  final String postId, commentId;
  final Map<String, dynamic> data;
  final VoidCallback onReply;
  final bool isReply;
  final bool isLastReply;

  const CommentBubble({
    super.key, 
    required this.postId, 
    required this.commentId, 
    required this.data, 
    required this.onReply, 
    required this.isReply,
    this.isLastReply = false,
  });

  @override
  State<CommentBubble> createState() => _CommentBubbleState();
}

class _CommentBubbleState extends State<CommentBubble> {
  OverlayEntry? _overlayEntry;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _userRole = widget.data['userRole'];
    if (_userRole == null) {
      _fetchUserRole();
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.data['userId']).get();
      if (mounted) {
        setState(() {
          _userRole = userDoc.data()?['role'] ?? 'farmer';
        });
      }
    } catch (e) {
      debugPrint('Error fetching user role for comment: $e');
    }
  }

  final List<Map<String, dynamic>> _reactionTypes = [
    {'value': 'like', 'label': 'Thích', 'icon': '👍', 'color': Colors.blue},
    {'value': 'love', 'label': 'Yêu thích', 'icon': '❤️', 'color': Colors.red},
    {'value': 'haha', 'label': 'Haha', 'icon': '😆', 'color': Colors.amber},
    {'value': 'wow', 'label': 'Wow', 'icon': '😮', 'color': Colors.orange},
    {'value': 'sad', 'label': 'Buồn', 'icon': '😢', 'color': Colors.amber},
    {'value': 'angry', 'label': 'Phẫn nộ', 'icon': '😡', 'color': Colors.deepOrange},
  ];

  void _showReactionMenu(BuildContext context, Offset position) {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(child: GestureDetector(onTap: _removeOverlay, behavior: HitTestBehavior.translucent, child: Container(color: Colors.transparent))),
          Positioned(
            top: position.dy - 60,
            left: position.dx > 150 ? 100 : 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))]),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _reactionTypes.map((reaction) => GestureDetector(
                    onTap: () {
                      CommentService().reactToComment(widget.postId, widget.commentId, reaction['value']);
                      _removeOverlay();
                    },
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(reaction['icon'], style: const TextStyle(fontSize: 24))),
                  )).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() { _overlayEntry?.remove(); _overlayEntry = null; }

  Widget _buildReactionSummary(Map reactions, List likes) {
    if (likes.isEmpty) return const SizedBox.shrink();

    Map<String, int> counts = {};
    reactions.forEach((key, value) => counts[value] = (counts[value] ?? 0) + 1);
    var sortedReactions = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var topReactions = sortedReactions.take(3).map((e) => e.key).toList();

    return GestureDetector(
      onTap: () => _showReactionDetails(reactions),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16.0 + (topReactions.length > 1 ? (topReactions.length - 1) * 10 : 0),
              height: 18,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: topReactions.asMap().entries.map((entry) {
                  var config = _reactionTypes.firstWhere((e) => e['value'] == entry.value, orElse: () => _reactionTypes[0]);
                  return Positioned(
                    left: entry.key * 10.0, 
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Text(config['icon'], style: const TextStyle(fontSize: 10))
                    )
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 4),
            Text("${likes.length}", style: TextStyle(color: Colors.grey[800], fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  void _showReactionDetails(Map reactions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Bày tỏ cảm xúc", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                          title: Text(userData?['displayName'] ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final Map reactions = widget.data['reactions'] ?? {};
    final List likes = widget.data['likes'] ?? [];
    String? myReaction = reactions[currentUser?.uid];
    
    final currentConfig = myReaction != null 
        ? _reactionTypes.firstWhere((e) => e['value'] == myReaction, orElse: () => _reactionTypes[0])
        : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isReply)
            SizedBox(width: 30, child: CustomPaint(painter: ThreadPainter(isLastReply: widget.isLastReply))),
          Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.withValues(alpha: 0.1), width: 1),
            ),
            child: CircleAvatar(
              radius: widget.isReply ? 14 : 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: (widget.data['userPhotoUrl'] != null && widget.data['userPhotoUrl'].isNotEmpty) ? NetworkImage(widget.data['userPhotoUrl']) : null,
              child: (widget.data['userPhotoUrl'] == null || widget.data['userPhotoUrl'].isEmpty) ? Icon(Icons.person, size: widget.isReply ? 14 : 18, color: Colors.grey) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50], 
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(4),
                      topRight: const Radius.circular(20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(widget.data['userName'] ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
                          if (_userRole == 'expert') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                "CHUYÊN GIA", 
                                style: TextStyle(
                                  fontSize: 8, 
                                  color: Colors.blue[800], 
                                  fontWeight: FontWeight.w900, 
                                  letterSpacing: 0.4
                                )
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(widget.data['text'] ?? '', style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Text(
                      TimeAgo.format((widget.data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now()), 
                      style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onLongPressStart: (details) => _showReactionMenu(context, details.globalPosition),
                      onTap: () {
                        if (myReaction != null) {
                           CommentService().toggleCommentLike(widget.postId, widget.commentId);
                        } else {
                           CommentService().reactToComment(widget.postId, widget.commentId, 'like');
                        }
                      },
                      child: Text(
                        currentConfig != null ? currentConfig['label'] : "Thích",
                        style: TextStyle(fontWeight: FontWeight.w800, color: currentConfig != null ? currentConfig['color'] : Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(onTap: widget.onReply, child: Text('Trả lời', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey[600], fontSize: 12))),
                    const Spacer(),
                    if (likes.isNotEmpty) _buildReactionSummary(reactions, likes),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
