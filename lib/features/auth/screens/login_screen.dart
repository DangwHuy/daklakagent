import 'package:flutter/material.dart';
import 'package:daklakagent/features/auth/screens/signup_screen.dart';
import 'package:daklakagent/features/auth/services/auth_service.dart'; // Import AuthService của bạn
import 'package:daklakagent/features/home/screens/home_screen.dart'; // Import Home để fallback

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Khởi tạo AuthService (kết nối với file code bạn vừa gửi)
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 1. Kiểm tra nhập liệu
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập email và mật khẩu!")),
      );
      return;
    }

    // 2. Bắt đầu loading
    setState(() => _isLoading = true);

    // 3. Gọi AuthService của bạn
    // Hàm này trả về null nếu thành công, trả về String lỗi nếu thất bại
    String? ketQua = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // 4. Xử lý kết quả
    if (!mounted) return;

    if (ketQua == null) {
      // === TRƯỜNG HỢP THÀNH CÔNG (QUAN TRỌNG) ===

      // Chờ một chút xíu (100ms) để xem AuthGate ở main.dart có kịp bắt sự kiện không
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        // TẮT LOADING NGAY LẬP TỨC (Đây là chỗ sửa lỗi xoay mãi)
        setState(() => _isLoading = false);

        // CHỦ ĐỘNG CHUYỂN TRANG (Lưới an toàn)
        // Nếu AuthGate chưa kịp chuyển, dòng này sẽ đảm bảo người dùng được vào Home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      }
    } else {
      // === TRƯỜNG HỢP THẤT BẠI ===
      // Tắt loading và hiện thông báo lỗi từ AuthService trả về
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ketQua), // Hiển thị thông báo tiếng Việt từ _xuLyLoiFirebase
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Đăng Nhập Agent", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.agriculture, size: 60, color: Colors.green),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24, width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text("Đăng Nhập Ngay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có tài khoản?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    child: const Text(
                      "Đăng ký ngay",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}