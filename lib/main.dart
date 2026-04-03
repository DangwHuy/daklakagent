import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// --- GIỮ NGUYÊN CÁC IMPORT CỦA BẠN ---
import 'package:daklakagent/features/auth/screens/login_screen.dart';
import 'package:daklakagent/features/home/screens/home_screen.dart'; // Màn hình Nông dân
import 'package:daklakagent/features/home/screens/expert_home_screen.dart'; // Màn hình Chuyên gia

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agent Nông Nghiệp Đắk Lắk',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const AuthGate(),
    );
  }
}

// CỔNG KIỂM SOÁT ĐĂNG NHẬP
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Firebase tự động lưu trạng thái đăng nhập vào bộ nhớ máy.
      // Khi mở lại app, stream này sẽ tự bắn ra User ngay lập tức nếu đã đăng nhập.
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. App đang khởi động Auth -> Hiện màn hình chờ
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        // 2. Đã tìm thấy phiên đăng nhập cũ -> Kiểm tra Role
        if (snapshot.hasData && snapshot.data != null) {
          return const RoleCheckWrapper();
        }

        // 3. Không tìm thấy (lần đầu hoặc đã logout) -> Về Login
        return const LoginScreen();
      },
    );
  }
}

// CỔNG KIỂM TRA ROLE (QUAN TRỌNG NHẤT)
class RoleCheckWrapper extends StatelessWidget {
  const RoleCheckWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const LoginScreen();

    // SỬ DỤNG StreamBuilder để lắng nghe realtime, trị dứt điểm lỗi delay token
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text("Đang đồng bộ phân quyền...", style: TextStyle(color: Colors.grey))
                ],
              ),
            ),
          );
        }

        // BỎ LỆNH ÉP VÀO HOMESCREEN KHI CÓ LỖI.
        // Thay vào đó hiển thị Loading để chờ Firebase sửa lỗi ngầm.
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text("Đang tải lại dữ liệu tài khoản...", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        // Nếu tài khoản chưa có hồ sơ trên Firestore
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const HomeScreen();
        }

        // Lấy role an toàn
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = data?['role'] ?? 'farmer';

        // ĐIỀU HƯỚNG CHUẨN XÁC
        if (role == 'expert') {
          return const ExpertHomeScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}