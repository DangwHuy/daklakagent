import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading          = false;
  bool _obscurePassword    = true;
  bool _obscureConfirm     = true;
  bool _acceptTerms        = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Bảng màu đồng bộ với LoginScreen
  static const Color kPrimary    = Color(0xFF1B4332);
  static const Color kAccent     = Color(0xFF52B788);
  static const Color kGold       = Color(0xFFD4A017);
  static const Color kBackground = Color(0xFFF8FAF5);
  static const Color kSurface    = Color(0xFFFFFFFF);
  static const Color kTextDark   = Color(0xFF1A2E1A);
  static const Color kTextMuted  = Color(0xFF6B7B6B);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    final name        = _nameController.text.trim();
    final email       = _emailController.text.trim();
    final password    = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPass.isEmpty) {
      _showSnackBar("Vui lòng điền đầy đủ thông tin!", Colors.orange.shade700);
      return;
    }
    if (password != confirmPass) {
      _showSnackBar("Mật khẩu nhập lại không khớp!", const Color(0xFFB91C1C));
      return;
    }
    if (password.length < 6) {
      _showSnackBar("Mật khẩu phải có ít nhất 6 ký tự.", Colors.orange.shade700);
      return;
    }
    if (!_acceptTerms) {
      _showSnackBar("Vui lòng đồng ý với điều khoản sử dụng.", Colors.orange.shade700);
      return;
    }

    setState(() => _isLoading = true);
    String? ketQua = await _authService.signUp(
      email: email,
      password: password,
      name: name,
    );
    setState(() => _isLoading = false);

    if (ketQua == null) {
      _showSnackBar("🎉 Đăng ký thành công!", kAccent);
      if (mounted) Navigator.pop(context);
    } else {
      _showSnackBar(ketQua, const Color(0xFFB91C1C));
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // Nền trang trí
          Positioned(
            top: -80,
            left: -50,
            child: _DecorCircle(size: 220, color: kAccent.withOpacity(0.10)),
          ),
          Positioned(
            bottom: 80,
            right: -40,
            child: _DecorCircle(size: 180, color: kGold.withOpacity(0.08)),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar tuỳ chỉnh
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        color: kTextDark,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Step indicator
                      _StepIndicator(),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: kAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.person_add_alt_1_rounded,
                                      color: kAccent, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Tạo tài khoản",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: kTextDark,
                                      ),
                                    ),
                                    Text(
                                      "Nhận cảnh báo nông nghiệp kịp thời",
                                      style: TextStyle(fontSize: 12, color: kTextMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Card form
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: kSurface,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimary.withOpacity(0.07),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildInputField(
                                    controller: _nameController,
                                    label: "Họ và Tên",
                                    hint: "Ví dụ: Nguyễn Văn A",
                                    icon: Icons.badge_outlined,
                                    capitalize: TextCapitalization.words,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildInputField(
                                    controller: _emailController,
                                    label: "Email",
                                    hint: "example@gmail.com",
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 14),
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
                                      onPressed: () =>
                                          setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildInputField(
                                    controller: _confirmPasswordController,
                                    label: "Nhập lại mật khẩu",
                                    hint: "Nhập lại mật khẩu ở trên",
                                    icon: Icons.lock_reset_outlined,
                                    obscure: _obscureConfirm,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: kTextMuted,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Terms checkbox
                            InkWell(
                              onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _acceptTerms,
                                        onChanged: (v) =>
                                            setState(() => _acceptTerms = v ?? false),
                                        activeColor: kAccent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5)),
                                        side: const BorderSide(color: Color(0xFFCCD5CC), width: 1.5),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                              fontSize: 13, color: kTextMuted, height: 1.5),
                                          children: [
                                            TextSpan(text: "Tôi đồng ý với "),
                                            TextSpan(
                                              text: "Điều khoản sử dụng",
                                              style: TextStyle(
                                                color: kAccent,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            TextSpan(text: " và "),
                                            TextSpan(
                                              text: "Chính sách bảo mật",
                                              style: TextStyle(
                                                color: kAccent,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            TextSpan(text: " của EaAgri Agent"),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Nút Đăng Ký
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kAccent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: kAccent.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                                    : const Text(
                                  "Tạo Tài Khoản",
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Đã có tài khoản
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Đã có tài khoản?",
                                    style: TextStyle(color: kTextMuted, fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      "Đăng nhập ngay",
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
    TextCapitalization capitalize = TextCapitalization.none,
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
          textCapitalization: capitalize,
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

class _StepIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i == 0;
        return Container(
          width: active ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF52B788) : const Color(0xFFCDE8DA),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}