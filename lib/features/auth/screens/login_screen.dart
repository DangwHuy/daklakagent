import 'package:flutter/material.dart';
import 'package:daklakagent/features/auth/screens/signup_screen.dart';
import 'package:daklakagent/features/auth/services/auth_service.dart';
import 'package:daklakagent/features/home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Bảng màu nông nghiệp hiện đại
  static const Color kPrimary     = Color(0xFF1B4332);
  static const Color kAccent      = Color(0xFF52B788);
  static const Color kGold        = Color(0xFFD4A017);
  static const Color kBackground  = Color(0xFFF8FAF5);
  static const Color kSurface     = Color(0xFFFFFFFF);
  static const Color kTextDark    = Color(0xFF1A2E1A);
  static const Color kTextMuted   = Color(0xFF6B7B6B);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: const Color(0xFFB91C1C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showErrorSnack("Vui lòng nhập đầy đủ email và mật khẩu!");
      return;
    }
    setState(() => _isLoading = true);
    String? ketQua = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ketQua == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
    } else {
      _showErrorSnack(ketQua);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    String? ketQua = await _authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);
    if (ketQua == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
    } else {
      _showErrorSnack(ketQua);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // --- Nền trang trí ---
          Positioned(
            top: -60,
            right: -60,
            child: _DecorCircle(size: 200, color: kAccent.withOpacity(0.12)),
          ),
          Positioned(
            top: 80,
            left: -40,
            child: _DecorCircle(size: 120, color: kGold.withOpacity(0.10)),
          ),
          Positioned(
            bottom: 100,
            right: -30,
            child: _DecorCircle(size: 160, color: kPrimary.withOpacity(0.06)),
          ),

          // --- Nội dung chính ---
          SafeArea(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: size.height * 0.055),

                      // ====== HERO SECTION ======
                      Center(
                        child: Column(
                          children: [
                            // Logo với hiệu ứng lớp
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kAccent.withOpacity(0.15),
                                  ),
                                ),
                                Container(
                                  width: 85,
                                  height: 85,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage('assets/images/ai_logo.png'),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                                    ],
                                  ),
                                ),
                                // Huy hiệu vàng góc phải
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: kGold,
                                    ),
                                    child: const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Ea",
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: kPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "Agri",
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w300,
                                      color: kAccent,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "🌾  Đồng hành cùng nhà nông Đắk Lắk",
                              style: TextStyle(
                                fontSize: 13,
                                color: kTextMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: size.height * 0.05),

                      // ====== CARD FORM ======
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.9),
                                blurRadius: 10,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Đăng nhập",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kTextDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Chào mừng bà con quay trở lại!",
                                style: TextStyle(fontSize: 13, color: kTextMuted),
                              ),
                              const SizedBox(height: 24),

                              // Email
                              _buildInputField(
                                controller: _emailController,
                                label: "Email",
                                hint: "example@gmail.com",
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),

                              // Password
                              _buildInputField(
                                controller: _passwordController,
                                label: "Mật khẩu",
                                hint: "Tối thiểu 6 ký tự",
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePassword,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: kTextMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),

                              // Quên mật khẩu
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    "Quên mật khẩu?",
                                    style: TextStyle(
                                      color: kAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Nút Đăng Nhập
                              _PrimaryButton(
                                label: "Đăng Nhập",
                                isLoading: _isLoading,
                                onPressed: _handleLogin,
                                primaryColor: kPrimary,
                              ),
                              const SizedBox(height: 20),

                              // Divider OR
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.5)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      "hoặc",
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.5)),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Nút Google
                              _GoogleButton(
                                isLoading: _isGoogleLoading,
                                onPressed: _handleGoogleLogin,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Đăng ký
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Chưa có tài khoản?",
                              style: TextStyle(color: kTextMuted, fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignupScreen()),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "Đăng ký ngay",
                                style: TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Thông tin phiên bản
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          "EaAgri Agent v1.0 · Đắk Lắk",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kTextDark,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: const TextStyle(fontSize: 15, color: kTextDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Icon(icon, color: kAccent, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF4F8F4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8F0E8), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// WIDGET PHỤ
// ============================================================

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color primaryColor;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3C4043),
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
        ),
        child: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google logo SVG-like bằng Text (hoặc dùng package google_fonts/svg)
            _GoogleIcon(),
            const SizedBox(width: 10),
            const Text(
              "Tiếp tục với Google",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3C4043),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google "G" icon bằng Flutter thuần (không cần package)
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Vẽ 4 cung màu Google
    final colors = [
      const Color(0xFF4285F4), // Blue
      const Color(0xFFEA4335), // Red
      const Color(0xFFFBBC05), // Yellow
      const Color(0xFF34A853), // Green
    ];
    final sweeps = [90.0, 90.0, 90.0, 90.0];
    double startAngle = -90.0;

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1.75),
        (startAngle * 3.14159265) / 180,
        (sweeps[i] * 3.14159265) / 180,
        false,
        paint,
      );
      startAngle += sweeps[i];
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}