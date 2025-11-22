import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Import file logic

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controller để lấy dữ liệu
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Thêm ô nhập lại mật khẩu

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Hàm xử lý Đăng Ký
  void _handleSignUp() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    // 1. Kiểm tra nhập thiếu
    if (email.isEmpty || password.isEmpty || confirmPass.isEmpty) {
      _showSnackBar("Vui lòng điền đầy đủ thông tin!", Colors.orange);
      return;
    }

    // 2. Kiểm tra mật khẩu có khớp nhau không
    if (password != confirmPass) {
      _showSnackBar("Mật khẩu nhập lại không khớp!", Colors.red);
      return;
    }

    // 3. Kiểm tra độ dài mật khẩu (Firebase yêu cầu tối thiểu 6 ký tự)
    if (password.length < 6) {
      _showSnackBar("Mật khẩu phải có ít nhất 6 ký tự.", Colors.orange);
      return;
    }

    // 4. Gọi Logic đăng ký từ AuthService
    setState(() => _isLoading = true);

    String? ketQua = await _authService.signUp(email: email, password: password);

    setState(() => _isLoading = false);

    // 5. Xử lý kết quả
    if (ketQua == null) {
      // Thành công
      _showSnackBar("Đăng ký thành công! Mời bà con đăng nhập.", Colors.green);

      // Đợi 1 giây rồi quay về màn hình đăng nhập
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      // Thất bại
      _showSnackBar(ketQua, Colors.red);
    }
  }

  // Hàm phụ để hiện thông báo nhanh
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng Ký Tài Khoản")),
      body: Center(
        child: SingleChildScrollView( // Giúp cuộn lên khi bàn phím hiện ra
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                "Tạo tài khoản mới\nđể nhận cảnh báo nông nghiệp",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Ô Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Ô Mật khẩu
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // Ô Nhập lại Mật khẩu
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Nhập lại mật khẩu",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Nút Đăng Ký
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Đăng Ký", style: TextStyle(fontSize: 18)),
                ),
              ),

              // Nút quay lại Đăng nhập
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Quay lại màn hình trước
                },
                child: const Text("Đã có tài khoản? Đăng nhập ngay"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}