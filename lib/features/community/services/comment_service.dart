import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addComment(
    String postId, 
    String commentText, 
    {
      String? parentCommentId, 
      String? replyToUserId, 
      String? replyToUserName,
    }
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || commentText.trim().isEmpty) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'text': commentText,
      'userId': currentUser.uid,
      'userName': userData['displayName'] ?? currentUser.email!.split('@')[0],
      'userPhotoUrl': userData['photoUrl'] ?? '',
      'userRole': userData['role'] ?? 'farmer',
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'reactions': {}, 
      'parentCommentId': parentCommentId,
      'replyToUserId': replyToUserId,
      'replyToUserName': replyToUserName,
    });
  }

  // Bỏ orderBy ở đây để không bị lỗi Index
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .where('parentCommentId', isNull: true)
        .snapshots();
  }

  // Bỏ orderBy ở đây để không bị lỗi Index
  Stream<QuerySnapshot> getReplies(String postId, String parentCommentId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .snapshots();
  }

  Future<void> toggleCommentLike(String postId, String commentId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    DocumentReference commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    DocumentSnapshot commentSnapshot = await commentRef.get();
    final data = commentSnapshot.data() as Map<String, dynamic>? ?? {};
    final List likes = data['likes'] ?? [];

    if (likes.contains(currentUser.uid)) {
      await commentRef.update({
        'likes': FieldValue.arrayRemove([currentUser.uid]),
        'reactions.${currentUser.uid}': FieldValue.delete(),
      });
    } else {
      await commentRef.update({
        'likes': FieldValue.arrayUnion([currentUser.uid]),
        'reactions.${currentUser.uid}': 'like',
      });
    }
  }

  Future<void> reactToComment(String postId, String commentId, String reactionType) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
      'reactions.${currentUser.uid}': reactionType,
      'likes': FieldValue.arrayUnion([currentUser.uid])
    });
  }

  Future<void> updateComment(String postId, String commentId, String newText) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({'text': newText});
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}
