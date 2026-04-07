import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  // Hàm này giúp dự án Mobile "bắn" dữ liệu log lên Firebase để Admin xem
  static Future<void> logAction({
    required String action,
    required String target
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      // Nếu là khách chưa đăng nhập thì không ghi log hoặc ghi là 'Khách'
      if (user == null) return;

      await FirebaseFirestore.instance.collection('admin_logs').add({
        'adminEmail': user.email ?? 'Khách',
        'adminUid': user.uid,
        'action': action,
        'target': target,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Lỗi khi ghi log Admin từ Mobile: $e");
    }
  }
}