import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExpertProfileSetup extends StatefulWidget {
  const ExpertProfileSetup({super.key});

  @override
  State<ExpertProfileSetup> createState() => _ExpertProfileSetupState();
}

class _ExpertProfileSetupState extends State<ExpertProfileSetup> {
  // Controller cho chuyên môn
  final _specialtyController = TextEditingController();
  final _bioController = TextEditingController();

  // Controller cho thông tin liên hệ (Mới)
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  // Danh sách các khung giờ rảnh
  List<DateTime> _availableSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _specialtyController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Load dữ liệu cũ nếu đã từng nhập
  void _loadCurrentData() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;

        // 1. Load thông tin liên hệ (Lưu ở root để đồng bộ với Farmer App)
        _phoneController.text = data['phone'] ?? data['phoneNumber'] ?? '';
        _addressController.text = data['address'] ?? data['location'] ?? '';

        // 2. Load thông tin chuyên gia (Lưu trong expertInfo)
        if (data.containsKey('expertInfo')) {
          final info = data['expertInfo'] as Map<String, dynamic>;
          _specialtyController.text = info['specialty'] ?? '';
          _bioController.text = info['bio'] ?? '';

          // Load lịch rảnh từ Timestamp Firestore -> DateTime
          if (info['availableSlots'] != null) {
            setState(() {
              _availableSlots = (info['availableSlots'] as List)
                  .map((e) => (e as Timestamp).toDate())
                  .toList();
              _availableSlots.sort(); // Sắp xếp tăng dần
            });
          }
        }
      }
    } catch (e) {
      print("Lỗi load data: $e");
    }
  }

  // Hàm hiển thị popup chọn ngày giờ
  Future<void> _addTimeSlot() async {
    final now = DateTime.now();

    // 1. Chọn ngày
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)), // Cho phép chọn trong vòng 30 ngày tới
      helpText: "CHỌN NGÀY RẢNH",
    );
    if (date == null) return;

    // 2. Chọn giờ
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: "CHỌN GIỜ BẮT ĐẦU",
    );
    if (time == null) return;

    // 3. Gộp lại thành DateTime
    final fullDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // Kiểm tra trùng lặp
    if (_availableSlots.any((slot) => slot.isAtSameMomentAs(fullDateTime))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Giờ này đã có trong danh sách!")));
      return;
    }

    setState(() {
      _availableSlots.add(fullDateTime);
      _availableSlots.sort();
    });
  }

  Future<void> _saveProfile() async {
    // Validate cơ bản
    if (_specialtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập chuyên ngành!")));
      return;
    }
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập số điện thoại để nông dân liên hệ!")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Cập nhật Firestore
      // Lưu ý: phone và address lưu ở root, expertInfo lưu nested
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'phone': _phoneController.text.trim(),
        'phoneNumber': _phoneController.text.trim(), // Lưu cả 2 trường để tương thích ngược
        'address': _addressController.text.trim(),
        'expertInfo.specialty': _specialtyController.text.trim(),
        'expertInfo.bio': _bioController.text.trim(),
        'expertInfo.availableSlots': _availableSlots.map((e) => Timestamp.fromDate(e)).toList(),
        'expertInfo.updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu thông tin thành công!")));
      Navigator.pop(context); // Quay về trang chủ sau khi lưu
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi lưu: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Cài Đặt Hồ Sơ"),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Phần 1: Thông tin Liên hệ (MỚI) ---
            const Text("Thông tin liên hệ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 5),
            const Text("Thông tin này sẽ hiển thị cho nông dân sau khi bạn ĐỒNG Ý lịch hẹn.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Số điện thoại (*)",
                hintText: "Nhập số để bà con gọi",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Địa chỉ / Cơ quan",
                hintText: "VD: Viện Eakmat, Buôn Ma Thuột...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 30),

            // --- Phần 2: Thông tin chuyên môn ---
            const Text("Thông tin chuyên môn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 10),
            TextField(
              controller: _specialtyController,
              decoration: const InputDecoration(
                labelText: "Chuyên ngành (*)",
                hintText: "VD: Cà phê, Sầu riêng, Tiêu...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Giới thiệu kinh nghiệm",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 1),
            const SizedBox(height: 10),

            // --- Phần 3: Quản lý lịch rảnh ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Lịch Rảnh Sắp Tới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                ElevatedButton.icon(
                  onPressed: _addTimeSlot,
                  icon: const Icon(Icons.add),
                  label: const Text("Thêm Giờ"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 5),
            const Text("Thêm các khung giờ bạn có thể nhận tư vấn để nông dân đặt lịch.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 15),

            _availableSlots.isEmpty
                ? Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text("Chưa có lịch rảnh nào được thêm.", style: TextStyle(color: Colors.grey))),
            )
                : Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _availableSlots.map((slot) {
                return Chip(
                  avatar: const Icon(Icons.access_time, size: 16, color: Colors.white),
                  label: Text(
                    DateFormat('dd/MM - HH:mm').format(slot),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.blue[400],
                  deleteIcon: const Icon(Icons.cancel, size: 18, color: Colors.white),
                  onDeleted: () {
                    setState(() => _availableSlots.remove(slot));
                  },
                  padding: const EdgeInsets.all(8),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("LƯU CÀI ĐẶT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}