import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController(); // Thêm controller cho Tên
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleSignUp() async {
    String name = _nameController.text.trim(); // Lấy tên
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPass.isEmpty) {
      _showSnackBar("Vui lòng điền đầy đủ thông tin!", Colors.orange);
      return;
    }

    if (password != confirmPass) {
      _showSnackBar("Mật khẩu nhập lại không khớp!", Colors.red);
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Mật khẩu phải có ít nhất 6 ký tự.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    // Gọi hàm đăng ký mới (truyền thêm name)
    String? ketQua = await _authService.signUp(
        email: email,
        password: password,
        name: name
    );

    setState(() => _isLoading = false);

    if (ketQua == null) {
      _showSnackBar("Đăng ký thành công! Đang chuyển hướng...", Colors.green);

      // Đóng màn hình đăng ký để về Login hoặc để AuthGate tự chuyển
      if (mounted) Navigator.pop(context);
    } else {
      _showSnackBar(ketQua, Colors.red);
    }
  }

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
        child: SingleChildScrollView(
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

              // Ô Nhập Họ và Tên (MỚI)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Họ và Tên",
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  hintText: "Ví dụ: Nguyễn Văn A",
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

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

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
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