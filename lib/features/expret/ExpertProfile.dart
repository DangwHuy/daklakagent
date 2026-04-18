import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class ExpertProfileSetup extends StatefulWidget {
  const ExpertProfileSetup({super.key});

  @override
  State<ExpertProfileSetup> createState() => _ExpertProfileSetupState();
}

class _ExpertProfileSetupState extends State<ExpertProfileSetup> {
  // Controller cho thông tin cơ bản
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Controller cho chuyên môn
  final _specialtyController = TextEditingController();
  final _experienceController = TextEditingController(); // Thêm năm kinh nghiệm
  final _bioController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  // Xử lý ảnh đại diện
  File? _imageFile;
  String _photoUrl = '';
  final ImagePicker _picker = ImagePicker();

  // Danh sách các khung giờ rảnh
  List<DateTime> _availableSlots = [];
  bool _isLoading = false;

  // --- FEATURE: Định vị chuyên gia ---
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _specialtyController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ─── 1. TẢI DỮ LIỆU VÀ TỰ ĐỘNG DỌN DẸP LỊCH CŨ ─────────────────────────────
  void _loadCurrentData() async {
    if (user == null) return;
    try {
      setState(() => _isLoading = true);
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

      if (doc.exists) {
        final data = doc.data()!;

        // Load thông tin cơ bản & liên hệ
        _nameController.text = data['displayName'] ?? '';
        _phoneController.text = data['phone'] ?? data['phoneNumber'] ?? '';
        _addressController.text = data['address'] ?? data['location'] ?? '';
        _photoUrl = data['photoUrl'] ?? '';

        // Load tọa độ định vị
        if (data['expertInfo'] != null) {
          final info = data['expertInfo'] as Map<String, dynamic>;
          _latitude = info['latitude'];
          _longitude = info['longitude'];
        }

        // Load thông tin chuyên gia
        if (data.containsKey('expertInfo')) {
          final info = data['expertInfo'] as Map<String, dynamic>;
          _specialtyController.text = info['specialty'] ?? '';
          _experienceController.text = info['experience']?.toString() ?? '';
          _bioController.text = info['bio'] ?? '';

          // Load lịch rảnh và LỌC BỎ các lịch trong quá khứ
          if (info['availableSlots'] != null) {
            final now = DateTime.now();
            final slots = (info['availableSlots'] as List)
                .map((e) => (e as Timestamp).toDate())
                .where((date) => date.isAfter(now)) // ĐÂY CHÍNH LÀ LOGIC LỌC LỊCH CŨ
                .toList();

            _availableSlots = slots;
            _availableSlots.sort(); // Sắp xếp tăng dần
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi load data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── 2. XỬ LÝ CHỌN VÀ UPLOAD ẢNH ──────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Giảm chất lượng ảnh để load nhanh hơn
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể chọn ảnh: $e")),
      );
    }
  }

  Future<String> _uploadImageToStorage() async {
    if (_imageFile == null) return _photoUrl;

    try {
      // Đặt tên file bằng UID của người dùng để ảnh luôn được ghi đè (tiết kiệm dung lượng)
      final ref = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${user!.uid}.jpg');

      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Lỗi upload ảnh: $e");
      return _photoUrl; // Trả về ảnh cũ nếu lỗi
    }
  }

  // ─── 3. QUẢN LÝ LỊCH RẢNH ──────────────────────────────────────────────────
  Future<void> _addTimeSlot() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: "CHỌN NGÀY RẢNH",
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: "CHỌN GIỜ BẮT ĐẦU",
    );
    if (time == null) return;

    final fullDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (fullDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể chọn giờ trong quá khứ!")));
      return;
    }

    if (_availableSlots.any((slot) => slot.isAtSameMomentAs(fullDateTime))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Giờ này đã có trong danh sách!")));
      return;
    }

    setState(() {
      _availableSlots.add(fullDateTime);
      _availableSlots.sort();
    });
  }

  // ─── 4. FEATURE: LẤY VỊ TRÍ GPS ──────────────────────────────────────────
  Future<void> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLocating = true);

    try {
      // 1. Kiểm tra dịch vụ định vị có bật không
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng bật GPS trên thiết bị!")));
        setState(() => _isLocating = false);
        return;
      }

      // 2. Kiểm tra quyền
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quyền truy cập vị trí bị từ chối!")));
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quyền vị trí bị từ chối vĩnh viễn, vui lòng mở trong Cài đặt!")));
        setState(() => _isLocating = false);
        return;
      }

      // 3. Lấy vị trí
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLocating = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Đã cập nhật vị trí GPS thành công!"),
        backgroundColor: Colors.blue,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi định vị: $e")));
      setState(() => _isLocating = false);
    }
  }

  // ─── 4. LƯU TẤT CẢ DỮ LIỆU ───────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập họ tên!")));
      return;
    }
    if (_specialtyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập chuyên ngành!")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Nếu có chọn ảnh mới thì tiến hành upload
      String finalPhotoUrl = _photoUrl;
      if (_imageFile != null) {
        finalPhotoUrl = await _uploadImageToStorage();
      }

      // 2. Cập nhật vào Firestore
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'displayName': _nameController.text.trim(),
        'photoUrl': finalPhotoUrl,
        'phone': _phoneController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'expertInfo.specialty': _specialtyController.text.trim(),
        'expertInfo.experience': _experienceController.text.trim(),
        'expertInfo.bio': _bioController.text.trim(),
        'expertInfo.latitude': _latitude,
        'expertInfo.longitude': _longitude,
        // Lưu danh sách lịch rảnh mới (đã loại bỏ lịch cũ trên UI)
        'expertInfo.availableSlots': _availableSlots.map((e) => Timestamp.fromDate(e)).toList(),
        'expertInfo.updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Đã lưu thông tin hồ sơ thành công!"),
        backgroundColor: Colors.green,
      ));

      // ĐÃ XÓA Navigator.pop(context); ở đây để tránh bị đen màn hình vì màn hình này giờ là 1 Tab.

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi lưu: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── GIAO DIỆN ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Disable material 3 tint
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/images/ai_logo.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Hồ sơ chuyên gia",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading && _nameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Avatar & Tên ---
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null) as ImageProvider?,
                          child: _imageFile == null && _photoUrl.isEmpty
                              ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ảnh đại diện uy tín giúp bà con tin tưởng hơn",
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(Icons.person_pin, "Thông tin chung"),
            _buildTextField(_nameController, "Họ và tên chuyên gia (*)", Icons.person_outline),
            _buildTextField(_phoneController, "Số điện thoại liên hệ", Icons.phone_outlined, isPhone: true),
            _buildTextField(_addressController, "Địa chỉ cơ quan / Vườn mẫu", Icons.location_on_outlined),

            // --- FEATURE ĐỊNH VỊ ---
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gps_fixed, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Vị trí định vị (GPS)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (_latitude != null && _longitude != null)
                              ? "Tọa độ: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}"
                              : "Chưa xác định vị trí GPS",
                          style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLocating ? null : _getCurrentPosition,
                        icon: _isLocating 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.my_location, size: 16),
                        label: Text(_isLocating ? "Đang quét..." : "Cập nhật"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(Icons.school_rounded, "Chuyên môn & Kinh nghiệm"),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(_specialtyController, "Chuyên ngành (*)\n(VD: Sầu riêng)", null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildTextField(_experienceController, "Kinh nghiệm\n(VD: 5 năm)", null, isNumber: true),
                ),
              ],
            ),
            _buildTextField(_bioController, "Giới thiệu tóm tắt về bản thân & thành tựu...", null, maxLines: 3),

            const SizedBox(height: 24),
            // --- Phần 3: Quản lý lịch rảnh ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(Icons.edit_calendar_rounded, "Khung giờ nhận tư vấn", padding: 0),
                TextButton.icon(
                  onPressed: _addTimeSlot,
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  label: const Text("Thêm", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                "Các khung giờ trong quá khứ đã được tự động ẩn đi.",
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),

            _availableSlots.isEmpty
                ? Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)
              ),
              child: const Center(
                  child: Text(
                      "Bạn chưa mở lịch tư vấn nào.\nHãy thêm khung giờ để bà con có thể đặt lịch.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.5)
                  )
              ),
            )
                : Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _availableSlots.map((slot) {
                return Chip(
                  avatar: const Icon(Icons.access_time, size: 16, color: Colors.green),
                  label: Text(
                    DateFormat('dd/MM - HH:mm').format(slot),
                    style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.green.shade200)
                  ),
                  deleteIcon: const Icon(Icons.cancel, size: 18, color: Colors.redAccent),
                  onDeleted: () {
                    setState(() => _availableSlots.remove(slot));
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text("LƯU HỒ SƠ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Widget helper để tái sử dụng mã UI ---
  Widget _buildSectionHeader(IconData icon, String title, {double padding = 16.0}) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[800], size: 22),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData? icon, {bool isPhone = false, bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isPhone ? TextInputType.phone : (isNumber ? TextInputType.number : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          alignLabelWithHint: maxLines > 1,
          prefixIcon: icon != null ? Icon(icon, color: Colors.green[600]) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade600, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}