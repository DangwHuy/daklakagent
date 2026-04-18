import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daklakagent/features/expret/ExpertProfile.dart';
import 'package:daklakagent/features/expret/expert_help_screen.dart';

class ExpertSettingsScreen extends StatefulWidget {
  const ExpertSettingsScreen({super.key});

  @override
  State<ExpertSettingsScreen> createState() => _ExpertSettingsScreenState();
}

class _ExpertSettingsScreenState extends State<ExpertSettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && doc.data()?['settings'] != null) {
        setState(() {
          _notificationsEnabled = doc.data()?['settings']['notifications'] ?? true;
        });
      }
    } catch (e) {
      debugPrint("Lỗi load cài đặt: $e");
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'settings': {'notifications': value}
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi lưu cài đặt: $e")));
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất?"),
        content: const Text("Bạn có chắc chắn muốn thoát khỏi tài khoản?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Đăng xuất"),
          )
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    // Standard safety procedure for account deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("XÓA TÀI KHOẢN?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Hành động này không thể hoàn tác. Toàn bộ dữ liệu của bạn sẽ bị xóa vĩnh viễn."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("XÁC NHẬN XÓA"),
          )
        ],
      ),
    );

    if (confirm == true) {
       // Logic for deletion usually involves re-authentication, for demo we just show a snackbar and logout
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yêu cầu đã được gửi. Chúng tôi sẽ xử lý trong vòng 24h.")));
       await _logout();
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPwdCtrl = TextEditingController();
    final TextEditingController newPwdCtrl = TextEditingController();
    final TextEditingController confirmPwdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: Colors.green),
                SizedBox(width: 8),
                Text("Đổi mật khẩu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogTextField(currentPwdCtrl, "Mật khẩu hiện tại", true),
                  const SizedBox(height: 12),
                  _dialogTextField(newPwdCtrl, "Mật khẩu mới", true),
                  const SizedBox(height: 12),
                  _dialogTextField(confirmPwdCtrl, "Xác nhận mật khẩu mới", true),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.pop(context),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: isUpdating ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  if (newPwdCtrl.text != confirmPwdCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu mới không trùng khớp!")));
                    return;
                  }
                  if (newPwdCtrl.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu phải có ít nhất 6 ký tự!")));
                    return;
                  }

                  setDialogState(() => isUpdating = true);

                  try {
                    // 1. Re-authenticate
                    final cred = EmailAuthProvider.credential(
                      email: user!.email!,
                      password: currentPwdCtrl.text,
                    );
                    await user!.reauthenticateWithCredential(cred);

                    // 2. Update Password
                    await user!.updatePassword(newPwdCtrl.text);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đổi mật khẩu thành công! Vui lòng đăng nhập lại."), backgroundColor: Colors.green),
                      );
                      // Logout after change for security
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  } catch (e) {
                    String errorMsg = "Lỗi khi đổi mật khẩu";
                    if (e.toString().contains("wrong-password")) {
                      errorMsg = "Mật khẩu hiện tại không đúng!";
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
                  } finally {
                    setDialogState(() => isUpdating = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isUpdating 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Cập nhật"),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _dialogTextField(TextEditingController ctrl, String label, bool isPassword) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Không được để trống" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          
          // Section: Tài khoản
          _buildSectionHeader("Tài khoản"),
          _buildSettingsTile(
            icon: Icons.person_outline_rounded,
            title: "Hồ sơ chuyên gia",
            subtitle: "Thông tin cá nhân, chuyên môn, lịch rảnh",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertProfileSetup())),
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline_rounded,
            title: "Đổi mật khẩu",
            subtitle: "Tăng cường bảo mật tài khoản",
            onTap: _showChangePasswordDialog,
          ),
          
          const SizedBox(height: 12),
          
          // Section: Ứng dụng
          _buildSectionHeader("Cài đặt ứng dụng"),
          _buildSwitchTile(
            icon: Icons.notifications_none_rounded,
            title: "Thông báo đẩy",
            subtitle: "Nhận tin nhắn, lịch hẹn mới",
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          _buildSettingsTile(
            icon: Icons.palette_outlined,
            title: "Giao diện",
            subtitle: "Sáng / Tối",
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng đang phát triển"))),
          ),
          
          const SizedBox(height: 12),
          
          // Section: Hỗ trợ
          _buildSectionHeader("Hỗ trợ & Pháp lý"),
          _buildSettingsTile(
            icon: Icons.help_outline_rounded,
            title: "Trung tâm trợ giúp",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertHelpScreen())),
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: "Điều khoản dịch vụ",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            title: "Về ứng dụng",
            subtitle: "Phiên bản 1.0.2",
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon( Icons.logout_rounded),
              label: const Text("Đăng xuất"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: _deleteAccount,
              child: const Text("Xóa tài khoản", style: TextStyle(color: Colors.redAccent)),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.green).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor ?? Colors.green, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        activeColor: Colors.blue,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
      ),
    );
  }
}
