import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePostScreen extends StatefulWidget {
  final DocumentSnapshot? post;
  const CreatePostScreen({super.key, this.post});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      final data = widget.post!.data() as Map<String, dynamic>;
      _textController.text = data['content'] ?? '';
      _existingImageUrl = data['imageUrl'];
    }
  }

  // Hàm hiển thị lựa chọn Nguồn ảnh
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text("Chọn nguồn ảnh", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: "Thư viện",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Máy ảnh",
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required MaterialColor color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color[700], size: 28),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Nén ảnh để tải lên nhanh hơn
        maxWidth: 1080,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _existingImageUrl = null; // Xóa ảnh cũ nếu đang sửa bài
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  List<String> _extractHashtags(String text) {
    final Iterable<RegExpMatch> matches = RegExp(r"\#(\w+)").allMatches(text);
    return matches.map((m) => m.group(1)!.toLowerCase()).toList();
  }

  Future<void> _submit() async {
    if (_textController.text.trim().isEmpty && _selectedImage == null && _existingImageUrl == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nội dung không được để trống')));
       return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      String? imageUrl = _existingImageUrl;

      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance.ref().child('posts').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_selectedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      final content = _textController.text.trim();
      final hashtags = _extractHashtags(content);

      final Map<String, dynamic> postData = {
        'content': content,
        'imageUrl': imageUrl,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'hashtags': hashtags,
      };

      if (widget.post != null) {
        await FirebaseFirestore.instance.collection('posts').doc(widget.post!.id).update(postData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật bài viết')));
      } else {
        // Lấy thông tin người dùng từ Firestore để đảm bảo lấy đúng tên "Đăng Huy"
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
        
        postData.addAll({
          'userName': userData?['displayName'] ?? userData?['name'] ?? user.displayName ?? 'Người dùng',
          'userPhotoUrl': userData?['photoUrl'] ?? user.photoURL ?? '',
          'userRole': userData?['role'] ?? 'farmer',
          'likes': [],
        });
        await FirebaseFirestore.instance.collection('posts').add(postData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng bài viết thành công')));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const MaterialColor themeColor = Colors.green;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: themeColor[700], size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              widget.post != null ? "Sửa bài viết" : "Tạo bài viết",
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: _isLoading 
              ? SizedBox(width: 40, child: Center(child: CircularProgressIndicator(color: themeColor[700], strokeWidth: 2)))
              : ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor[700],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text("ĐĂNG", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                // Composer Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: 8,
                        minLines: 5,
                        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Bạn đang nghĩ gì về nông nghiệp hôm nay?",
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                      if (_selectedImage != null || _existingImageUrl != null) ...[
                        const SizedBox(height: 20),
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[100]!),
                                ),
                                child: _selectedImage != null 
                                  ? Image.file(_selectedImage!, width: double.infinity, fit: BoxFit.cover) 
                                  : Image.network(_existingImageUrl!, width: double.infinity, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() { _selectedImage = null; _existingImageUrl = null; }),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                // Tips Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: themeColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: themeColor[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Mẹo: Thêm các thẻ hashtag như #lua, #caphe để bài viết của bạn dễ tìm kiếm hơn.",
                          style: TextStyle(color: themeColor[900], fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Toolbar
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  const Text("Thêm ảnh vào bài viết", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 14)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: themeColor[50], shape: BoxShape.circle),
                      child: Icon(Icons.image_rounded, color: themeColor[700], size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
