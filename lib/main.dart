import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- THÊM THƯ VIỆN NÀY ĐỂ NHẬN THÔNG BÁO
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:daklakagent/services/presence_service.dart';

// --- GIỮ NGUYÊN CÁC IMPORT CỦA BẠN ---
import 'package:daklakagent/features/auth/screens/login_screen.dart';
import 'package:daklakagent/features/home/screens/home_screen.dart'; // Màn hình Nông dân
import 'package:daklakagent/features/home/screens/expert_home_screen.dart'; // Màn hình Chuyên gia

// 1. HÀM XỬ LÝ BACKGROUND MESSAGE (Thông báo khi app chạy ngầm/tắt)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Đã nhận tin nhắn dưới nền: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo Locale tiếng Việt cho package intl
  await initializeDateFormatting('vi', null);

  // 2. ĐĂNG KÝ HÀM LẮNG NGHE THÔNG BÁO CHẠY NGẦM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

// 3. CHUYỂN MYAPP THÀNH STATEFUL ĐỂ GỌI HÀM XIN QUYỀN LÚC MỞ APP
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final PresenceService _presenceService = PresenceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupFCM(); // Gọi hàm cài đặt FCM khi vừa mở app
    _presenceService.updateUserStatus(true); // Cập nhật online khi mở app
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceService.updateUserStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Theo dõi trạng thái ẩn/hiện/đóng app
    if (state == AppLifecycleState.resumed) {
      _presenceService.updateUserStatus(true);
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive || 
               state == AppLifecycleState.detached) {
      _presenceService.updateUserStatus(false);
    }
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Xin quyền hiển thị thông báo
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Người dùng đã cấp quyền nhận thông báo');

      // Lấy Token của thiết bị này và lưu lên Firestore
      String? token = await messaging.getToken();
      if (token != null) {
        _saveTokenToFirestore(token);
      }

      // Lắng nghe khi token thay đổi thì cập nhật lại
      messaging.onTokenRefresh.listen(_saveTokenToFirestore);
    } else {
      print('Người dùng TỪ CHỐI cấp quyền thông báo');
    }
  }

  // Hàm lưu token vào user hiện tại
  void _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        print("Đã lưu FCM Token thành công lên Firestore!");
      } catch (e) {
        print("Lỗi khi lưu token: $e");
      }
    }
  }

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

// =======================================================================
// TỪ ĐÂY TRỞ XUỐNG GIỮ NGUYÊN HOÀN TOÀN CODE CŨ (AuthGate, RoleCheck)
// =======================================================================

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