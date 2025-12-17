// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Import 2 màn hình chính
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart'; // Đảm bảo import đúng đường dẫn file vừa tạo

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
      debugShowCheckedModeBanner: false, // Tắt chữ debug ở góc
      title: 'Agent Nông Nghiệp Đắk Lắk',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50], // Màu nền nhẹ nhàng
      ),
      // AuthGate là cổng kiểm soát
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Đang kiểm tra đăng nhập -> Hiện loading quay quay
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Có dữ liệu user -> Vào Trang Chủ
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // 3. Chưa đăng nhập -> Về trang Login
        return const LoginScreen();
      },
    );
  }
}