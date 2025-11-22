import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Khởi tạo instance của FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Hàm Đăng Ký (Sign Up)
  // Trả về chuỗi: null nếu thành công, hoặc thông báo lỗi nếu thất bại
  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      return _xuLyLoiFirebase(e);
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }

  // 2. Hàm Đăng Nhập (Sign In)
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      return _xuLyLoiFirebase(e);
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }

  // 3. Hàm Đăng Xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Hàm phụ để dịch lỗi tiếng Anh sang tiếng Việt cho bà con dễ hiểu
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