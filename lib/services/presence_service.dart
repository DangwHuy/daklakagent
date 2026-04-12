import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cập nhật trạng thái Online/Offline
  Future<void> updateUserStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
      print('PresenceService: Đã cập nhật trạng thái Online=$isOnline');
    } catch (e) {
      print('PresenceService Error: $e');
    }
  }

  // Lắng nghe trạng thái của một người dùng cụ thể (Real-time)
  Stream<DocumentSnapshot> getUserPresenceStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
}
