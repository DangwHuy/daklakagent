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

  // Hàm lấy dữ liệu Role có tối ưu Cache
  Future<DocumentSnapshot> _fetchUserRole(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
    // QUAN TRỌNG: Source.serverAndCache
    // Ý nghĩa: "Hãy tìm trong bộ nhớ máy trước cho nhanh.
    // Nếu không có mới gọi lên mạng".
    // Giúp app vào thẳng Home ngay lập tức khi mở lại.
        .get(const GetOptions(source: Source.serverAndCache));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Phòng hờ trường hợp hiếm hoi user bị null
    if (user == null) return const LoginScreen();

    return FutureBuilder<DocumentSnapshot>(
      future: _fetchUserRole(user.uid),
      builder: (context, snapshot) {
        // Đang lấy dữ liệu -> Hiện Loading đẹp hơn
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text(
                    "Đang đồng bộ dữ liệu nông hộ...",
                    style: TextStyle(color: Colors.grey),
                  )
                ],
              ),
            ),
          );
        }

        // Xử lý lỗi hoặc không có dữ liệu
        if (snapshot.hasError) {
          // Log lỗi ra console để debug
          print("Lỗi lấy Role: ${snapshot.error}");
          // Fallback: Nếu lỗi mạng, cứ cho vào làm Nông dân trước (để không bị chặn cửa)
          return const HomeScreen();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Tài khoản Auth có, nhưng chưa có hồ sơ trong Firestore -> Tạo mới hoặc mặc định là Farmer
          return const HomeScreen();
        }

        // Lấy role an toàn
        final data = snapshot.data!.data() as Map<String, dynamic>?; // Cast về Map nullable cho an toàn
        final role = data?['role'] ?? 'farmer'; // Mặc định là farmer

        // ĐIỀU HƯỚNG
        if (role == 'expert') {
          return const ExpertHomeScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}