import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Hàm Đăng Ký
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // A. Tạo tài khoản Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // B. Nếu tạo Auth thành công -> Tạo tiếp dữ liệu trong Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': name,
          'role': 'farmer',
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl': '',
          'expertInfo': {
            'isOnline': false,
            'specialty': '',
            'location': 'Đăk Lăk'
          }
        });
      }

      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      return _xuLyLoiFirebase(e);
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }

  // 2. Hàm Đăng Nhập
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _xuLyLoiFirebase(e);
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }

  // 3. Hàm lấy Role (Đã sửa để an toàn hơn)
  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Lấy document snapshot
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

        // Kiểm tra doc có tồn tại và có dữ liệu không
        if (doc.exists && doc.data() != null) {
          // Ép kiểu dữ liệu về Map để truy xuất an toàn
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Trả về role, nếu null thì mặc định là 'farmer'
          return data['role']?.toString() ?? 'farmer';
        }
      } catch (e) {
        print("Lỗi lấy role: $e"); // Log lỗi nếu có
        return 'farmer'; // Gặp lỗi thì mặc định cho làm nông dân
      }
    }
    return 'farmer';
  }

  // 4. Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Xử lý lỗi
  String _xuLyLoiFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Tài khoản này chưa đăng ký.';
      case 'wrong-password':
        return 'Sai mật khẩu rồi, bà con kiểm tra lại nhé.';
      case 'email-already-in-use':
        return 'Email này đã có người dùng rồi.';
      case 'invalid-email':
        return 'Email không đúng định dạng.';
      case 'weak-password':
        return 'Mật khẩu yếu quá, hãy đặt dài hơn 6 ký tự.';
      default:
        return 'Lỗi kết nối: ${e.message}';
    }
  }
}