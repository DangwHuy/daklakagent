import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class ExpertRegistrationScreen extends StatefulWidget {
  const ExpertRegistrationScreen({super.key});

  @override
  State<ExpertRegistrationScreen> createState() => _ExpertRegistrationScreenState();
}

class _ExpertRegistrationScreenState extends State<ExpertRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _workplaceController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _selectedExpertise = "Cà phê";
  final List<String> _expertiseOptions = [
    "Cà phê", "Sầu riêng", "Hồ tiêu", "Cây ăn quả", "Cây lúa", "Chăn nuôi gia súc", "Phân bón & Khác"
  ];

  PlatformFile? _selectedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null) {
        _fullNameController.text = user.displayName!;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _educationController.dispose();
    _workplaceController.dispose();
    _skillsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đính kèm hồ sơ năng lực (File PDF/Doc)")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Bạn chưa đăng nhập");

      String fileUrl = '';
      
      // Upload file
      if (_selectedFile!.path != null) {
        File file = File(_selectedFile!.path!);
        final storageRef = FirebaseStorage.instance.ref().child(
            'expert_profiles/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.${_selectedFile!.extension}');
        final snapshot = await storageRef.putFile(file);
        fileUrl = await snapshot.ref.getDownloadURL();
      } else if (_selectedFile!.bytes != null) {
         // Kịch bản platform Web (fallback)
         final storageRef = FirebaseStorage.instance.ref().child(
            'expert_profiles/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.${_selectedFile!.extension}');
         final snapshot = await storageRef.putData(_selectedFile!.bytes!);
         fileUrl = await snapshot.ref.getDownloadURL();
      }

      // Lưu lên Firestore collection "expert_requests"
      await FirebaseFirestore.instance.collection('expert_requests').add({
        'userId': user.uid,
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'education': _educationController.text.trim(),
        'workplace': _workplaceController.text.trim(),
        'skills': _skillsController.text.trim(),
        'expertise': _selectedExpertise,
        'bio': _bioController.text.trim(),
        'portfolioUrl': fileUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Show dialog thành công
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                  child: Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 60),
                ),
                const SizedBox(height: 16),
                const Text("Gửi hồ sơ thành công!", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text("Quản trị viên sẽ đánh giá và liên hệ bạn trong thời gian sớm nhất. Xin cảm ơn!", 
                     style: TextStyle(color: Colors.grey[700], fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    onPressed: () {
                      Navigator.pop(ctx); // Đóng modal
                      Navigator.pop(context); // Trở về màn trước
                    },
                    child: const Text("Trở về", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          )
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Có lỗi xảy ra: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Builder ---
  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.grey[50],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green[700]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        validator: (value) => (value == null || value.trim().isEmpty) ? "Vui lòng không để trống" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Đăng ký Chuyên gia", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Trở thành chuyên gia nông nghiệp", 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green[800])),
                  const SizedBox(height: 8),
                  Text("Nhập thông tin bên dưới để gửi yêu cầu phê duyệt cho Quản trị viên.", 
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 30),

                  _buildTextField("Họ và Tên", _fullNameController),
                  _buildTextField("Số điện thoại liên hệ", _phoneController, keyboardType: TextInputType.phone),

                  // Lĩnh vực Dropdown
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedExpertise,
                      decoration: InputDecoration(
                        labelText: "Lĩnh vực tư vấn chính",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      items: _expertiseOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedExpertise = v!),
                    ),
                  ),

                  _buildTextField("Trình độ học vấn", _educationController, hint: "VD: Kỹ sư Nông nghiệp ĐH XYZ..."),
                  _buildTextField("Đang làm việc tại", _workplaceController, hint: "VD: Viện Khoa học KT Nông Lâm..."),
                  _buildTextField("Kỹ năng nổi bật", _skillsController, maxLines: 2, hint: "Quy trình chăm sóc, Xử lý ra hoa..."),
                  _buildTextField("Mô tả kinh nghiệm bản thân", _bioController, maxLines: 3, hint: "Giới thiệu đôi nét về số năm kinh nghiệm làm việc..."),

                  const SizedBox(height: 8),
                  const Text("Hồ sơ năng lực đính kèm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  
                  InkWell(
                    onTap: _pickFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file_outlined, color: Colors.blue[700], size: 40),
                          const SizedBox(height: 8),
                          Text(
                             _selectedFile == null 
                               ? "Bấm vào đây để Upload file PDF/Doc" 
                               : "Đã chọn: ${_selectedFile!.name}",
                             style: TextStyle(
                               color: _selectedFile == null ? Colors.blue[700] : Colors.green[800], 
                               fontWeight: _selectedFile == null ? FontWeight.normal : FontWeight.bold
                             ),
                             textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Nút Submit
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      child: const Text("GỬI HỒ SƠ", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(child: CircularProgressIndicator(color: Colors.green)),
            )
        ],
      ),
    );
  }
}
