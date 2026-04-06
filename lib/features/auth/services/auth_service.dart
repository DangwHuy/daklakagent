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
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

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
      return null;
    } on FirebaseAuthException catch (e) {
      return _xuLyLoiFirebase(e);
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }

  // 2. Hàm Đăng Nhập Email/Password
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

  // 3. Hàm lấy Role
  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['role']?.toString() ?? 'farmer';
        }
      } catch (e) {
        print("Lỗi lấy role: $e");
        return 'farmer';
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
      case 'user-disabled':
        return 'Tài khoản này chưa đăng ký hoặc bị khóa.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Sai thông tin đăng nhập, bà con kiểm tra lại nhé.';
      case 'email-already-in-use':
        return 'Email này đã có người dùng rồi.';
      case 'invalid-email':
        return 'Email không đúng định dạng.';
      default:
        return 'Lỗi kết nối: ${e.message}';
    }
  }
}