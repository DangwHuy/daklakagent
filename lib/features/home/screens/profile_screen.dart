import 'dart:io';
import 'dart:typed_data'; // Đã thêm thư viện này để đọc byte dữ liệu
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
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

  // Hàm xử lý đăng xuất
  void _handleSignOut(BuildContext context) async {
    await _auth.signOut();
  }

  // Hàm chọn và tải ảnh lên Firebase Storage (Đã được nâng cấp để fix lỗi object-not-found)
  Future<void> _uploadAvatar() async {
    try {
      // 1. Chọn ảnh từ thư viện
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Giới hạn kích thước để tải nhanh hơn
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return; // Người dùng hủy chọn

      setState(() {
        _isLoading = true;
      });

      String uid = _user!.uid;

      // 2. Chuyển đổi ảnh sang dạng byte để tránh lỗi quyền truy cập file trên máy ảo
      final Uint8List imageData = await image.readAsBytes();

      // Khai báo metadata để Firebase hiểu đây là file ảnh
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // 3. Tham chiếu đến Firebase Storage (lưu vào thư mục avatars/uid)
      final storageRef = FirebaseStorage.instance.ref().child('avatars/$uid');

      // 4. Tải dữ liệu ảnh lên và CHỜ TIẾN TRÌNH HOÀN TẤT (TaskSnapshot)
      final TaskSnapshot snapshot = await storageRef.putData(imageData, metadata);

      // 5. Lấy link URL của ảnh TỪ TIẾN TRÌNH VỪA TẢI XONG (Chắc chắn 100% file đã tồn tại)
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // 6. Cập nhật Profile của User trên Firebase Auth
      await _user!.updatePhotoURL(downloadUrl);

      // Reload lại user để cập nhật UI
      await _user!.reload();
      setState(() {
        _user = _auth.currentUser;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật ảnh đại diện thành công!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải ảnh: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Cập nhật tên hiển thị
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
                setState(() {
                  _user = _auth.currentUser;
                });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Phần Header chứa Avatar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 30, top: 20),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _uploadAvatar,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.green[100],
                                backgroundImage: _user?.photoURL != null
                                    ? NetworkImage(_user!.photoURL!)
                                    : null,
                                child: _user?.photoURL == null
                                    ? Icon(Icons.person, size: 50, color: Colors.green[800])
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.camera_alt, color: Colors.green[700], size: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _user?.displayName ?? "Nhà nông chưa đặt tên",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.email ?? "Chưa có email",
                        style: TextStyle(fontSize: 14, color: Colors.green[100]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Danh sách tùy chọn
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildProfileOption(
                        icon: Icons.edit,
                        title: "Chỉnh sửa tên hiển thị",
                        onTap: _updateDisplayName,
                      ),
                      _buildProfileOption(
                        icon: Icons.security,
                        title: "Đổi mật khẩu",
                        onTap: () {
                          // TODO: Thêm chức năng đổi mật khẩu nếu cần
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Tính năng đang phát triển")),
                          );
                        },
                      ),
                      _buildProfileOption(
                        icon: Icons.help_outline,
                        title: "Hỗ trợ kỹ thuật",
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),

                      // Nút Đăng xuất
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleSignOut(context),
                          icon: const Icon(Icons.logout),
                          label: const Text("Đăng xuất", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red[700],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hiển thị loading khi đang tải ảnh
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green[700]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}