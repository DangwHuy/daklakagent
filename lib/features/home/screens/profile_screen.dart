import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'expert_registration_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  // Handle Logout
  void _handleSignOut(BuildContext context) async {
    await _auth.signOut();
  }

  // Upload Avatar
  Future<void> _uploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return; 

      setState(() => _isLoading = true);

      String uid = _user!.uid;
      final Uint8List imageData = await image.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final storageRef = FirebaseStorage.instance.ref().child('avatars/$uid');
      final TaskSnapshot snapshot = await storageRef.putData(imageData, metadata);
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      await _user!.updatePhotoURL(downloadUrl);
      await _user!.reload();
      setState(() {
        _user = _auth.currentUser;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật ảnh đại diện thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải ảnh: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Update Display Name
  Future<void> _updateDisplayName() async {
    TextEditingController nameController = TextEditingController(text: _user?.displayName ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật tên"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Nhập tên mới của bạn"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _user!.updateDisplayName(nameController.text.trim());
                await _user!.reload();
                setState(() => _user = _auth.currentUser);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cập nhật tên thành công!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
                  );
                }
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_user?.email != null) {
      setState(() => _isLoading = true);
      try {
        await _auth.sendPasswordResetEmail(email: _user!.email!);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Đổi mật khẩu"),
              content: const Text("Chúng tôi đã gửi một email hướng dẫn đặt lại mật khẩu đến địa chỉ email của bạn. Vui lòng kiểm tra hộp thư."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đã hiểu"))
              ],
            )
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bạn chưa cung cấp Email để sử dụng hệ thống bảo mật mật khẩu"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Background màu xám nhạt như các app hiện đại
      appBar: AppBar(
        title: const Text("Tài khoản", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // 1. Khối Header User
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _uploadAvatar,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.green[100],
                              backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
                              child: _user?.photoURL == null
                                      ? Icon(Icons.person, size: 40, color: Colors.green[800])
                                      : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.black87, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _user?.displayName ?? "Nhà nông 4.0",
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.verified, color: Colors.blue[600], size: 20),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _user?.email ?? "Chưa có email liên kết",
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. Banner Member/Đóng góp giống hình
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[300]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Hội viên Nông nghiệp Xanh", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text("1,250", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                            SizedBox(width: 4),
                            Text("Điểm", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text("Đổi điểm lấy vật tư nông nghiệp & voucher", style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Grid Menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGridMenuItem(Icons.wallet, "Thanh toán", Colors.blue),
                      _buildGridMenuItem(Icons.book, "Nhật ký nông hộ", Colors.orange),
                      _buildGridMenuItem(Icons.spa, "Mô hình xanh", Colors.teal),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 4. Các Setion (List Groups)
                  _buildSectionHeader("Cơ hội hợp tác"),
                  _buildCardGroup(children: [
                    _buildListTile(Icons.storefront, "Mở gian hàng Nông sản", onTap: () {}),
                    _buildListTile(Icons.handshake_outlined, "Trở thành Chuyên gia", isLast: true, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExpertRegistrationScreen()),
                      );
                    }),
                  ]),

                  _buildSectionHeader("Thông tin cá nhân"),
                  _buildCardGroup(children: [
                    _buildListTile(Icons.person_outline, "Chỉnh sửa tên hiển thị", onTap: _updateDisplayName),
                    _buildListTile(Icons.location_on_outlined, "Địa chỉ vườn/nhà", onTap: () {}),
                    _buildListTile(Icons.shield_outlined, "Đăng nhập & Bảo mật", isLast: true, onTap: _changePassword),
                  ]),

                  _buildSectionHeader("Hỗ trợ"),
                  _buildCardGroup(children: [
                    _buildListTile(Icons.article_outlined, "Điều khoản và Chính sách", onTap: () {}),
                    _buildListTile(Icons.headset_mic_outlined, "Trung tâm hỗ trợ", isLast: true, onTap: () {}),
                  ]),
                  
                  // The feedback card
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 0), // Lên trên nút Đăng xuất
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[50]!, Colors.teal[50]!],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.favorite, color: Colors.red[300], size: 28),
                              const SizedBox(height: 12),
                              const Text("Bạn có hài lòng với ứng dụng chứ?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                              const SizedBox(height: 4),
                              const Text("Phản hồi của bạn sẽ giúp ứng dụng ngày càng hoàn thiện hơn.", style: TextStyle(color: Colors.black54, fontSize: 14)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal[400],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Đăng xuất Button (Text only)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _handleSignOut(context),
                      icon: Icon(Icons.meeting_room_outlined, color: Colors.teal[500]),
                      label: Text("Đăng xuất", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal[500])),
                    ),
                  ),
                  const SizedBox(height: 120), // Padding dài để không bị Navigation Bar đè lấp
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator(color: Colors.green))),
        ],
      ),
    );
  }

  Widget _buildGridMenuItem(IconData icon, String title, MaterialColor color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color[400], size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildCardGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, {bool isLast = false, required VoidCallback onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey[700], size: 24),
          title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        if (!isLast)
          Divider(height: 1, color: Colors.grey[100], indent: 56, endIndent: 16),
      ],
    );
  }
}