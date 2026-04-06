import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // API cũ của google_sign_in ^6.x (KHÔNG phải v7)
  // Phải ghim trong pubspec.yaml: google_sign_in: '6.2.1' (không có ^)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // 1. Đăng Ký Email/Password
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
            'location': 'Đăk Lăk',
          },
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _xuLyLoiFirebase(e);
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }

  // 2. Đăng Nhập Email/Password
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _xuLyLoiFirebase(e);
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }

  // 3. Đăng Nhập bằng Google — dùng API cổ điển của v6.x
  Future<String?> signInWithGoogle() async {
    try {
      // Mở màn hình chọn tài khoản Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Người dùng bấm huỷ
      if (googleUser == null) return "Đã huỷ đăng nhập.";

      // Lấy thông tin token
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Tạo credential Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Đăng nhập Firebase
      final UserCredential result =
      await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        await _luuHoacCapNhatUser(user);
      }

      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      return _xuLyLoiFirebase(e);
    } catch (e) {
      return "Lỗi đăng nhập Google: $e";
    }
  }

  // Helper: Tạo mới hoặc cập nhật user trên Firestore
  Future<void> _luuHoacCapNhatUser(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? 'Người dùng Google',
        'role': 'farmer',
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': user.photoURL ?? '',
        'expertInfo': {
          'isOnline': false,
          'specialty': '',
          'location': 'Đăk Lăk',
        },
      });
    } else {
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': user.photoURL ?? '',
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 4. Lấy Role người dùng
  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        final doc =
        await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role']?.toString() ?? 'farmer';
        }
      } catch (e) {
        print("Lỗi lấy role: $e");
      }
    }
    return 'farmer';
  }

  // 5. Đăng Xuất
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Xử lý lỗi Firebase
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
      case 'account-exists-with-different-credential':
        return 'Email này đã đăng ký bằng phương thức khác.';
      default:
        return 'Lỗi kết nối: ${e.message}';
    }
  }
}