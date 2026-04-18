import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SubmitDiseaseScreen extends StatefulWidget {
  const SubmitDiseaseScreen({super.key});

  @override
  State<SubmitDiseaseScreen> createState() => _SubmitDiseaseScreenState();
}

class _SubmitDiseaseScreenState extends State<SubmitDiseaseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  int _currentStep = 0;

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color kPrimary  = Color(0xFF2D6A4F);
  static const Color kPrimaryL = Color(0xFF40916C);
  static const Color kBg       = Color(0xFFF0F7F4);
  static const Color kAccentL  = Color(0xFFB7E4C7);

  // ── Controllers ────────────────────────────────────────────────────────────
  final _nameCtrl       = TextEditingController();
  File? _pickedImage;
  final _submitterCtrl  = TextEditingController(); // tên người đề xuất (tuỳ chọn)
  final ImagePicker _picker = ImagePicker();

  // List fields — mỗi cái dùng 1 controller text để nhập rồi thêm vào list
  final List<String> _affectedParts = [];
  final List<String> _symptoms      = [];
  final List<String> _treatment     = [];
  final List<String> _prevention    = [];
  final List<String> _tags          = [];

  final _partCtrl       = TextEditingController();
  final _symptomCtrl    = TextEditingController();
  final _treatmentCtrl  = TextEditingController();
  final _preventionCtrl = TextEditingController();
  final _tagCtrl        = TextEditingController();

  // Dropdowns
  String _type           = 'Bệnh hại';
  String _severity       = 'Trung bình';
  String _season         = 'Quanh năm';
  String _emergencyLevel = 'Trung bình';
  String _icon           = 'Icons.bug_report';
  String _color          = 'Colors.green';

  final _types     = ['Bệnh hại', 'Côn trùng', 'Nấm bệnh', 'Vi khuẩn', 'Sinh lý'];
  final _severities = ['Rất cao', 'Cao', 'Trung bình', 'Thấp'];
  final _seasons    = ['Mùa mưa', 'Mùa khô', 'Quanh năm'];
  final _emergencies = ['Khẩn cấp', 'Cao', 'Trung bình', 'Thấp'];

  // --- VIETNAMESE LOCALIZATION FOR ICONS ---
  final Map<String, String> _iconMap = {
    'Sâu bọ / Côn trùng': 'Icons.bug_report',
    'Vi khuẩn / Virus': 'Icons.coronavirus',
    'Thuốc / BVTV': 'Icons.pest_control',
    'Ẩm ướt / Úng nước': 'Icons.water_damage',
    'Cháy lá / Khô quắt': 'Icons.local_fire_department',
    'Phòng thí nghiệm': 'Icons.science',
    'Cây trồng / Công viên': 'Icons.park',
    'Cảnh báo khẩn cấp': 'Icons.warning',
  };

  // --- VIETNAMESE LOCALIZATION FOR COLORS ---
  final Map<String, String> _colorMap = {
    'Xanh lá (Bình thường)': 'Colors.green',
    'Đỏ (Cực cao)': 'Colors.red',
    'Cam (Cần chú ý)': 'Colors.orange',
    'Vàng hổ phách': 'Colors.amber',
    'Tím': 'Colors.purple',
    'Xanh dương': 'Colors.blue',
    'Nâu (Khô hạn)': 'Colors.brown',
    'Hồng': 'Colors.pink',
  };

  String get _iconLabel => _iconMap.entries.firstWhere((e) => e.value == _icon).key;
  String get _colorLabel => _colorMap.entries.firstWhere((e) => e.value == _color).key;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _submitterCtrl, _partCtrl,
      _symptomCtrl, _treatmentCtrl, _preventionCtrl, _tagCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_symptoms.isEmpty) {
      _showSnack('Vui lòng thêm ít nhất 1 triệu chứng', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String imageUrl = "";
      if (_pickedImage != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'pest_diseases/submissions/${DateTime.now().millisecondsSinceEpoch}.jpg'
        );
        await ref.putFile(_pickedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // Đẩy thẳng vào 'pest_diseases'
      await FirebaseFirestore.instance.collection('pest_diseases').add({
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'severity': _severity,
        'season': _season,
        'emergency_level': _emergencyLevel,
        'affected_parts': _affectedParts,
        'symptoms': _symptoms,
        'treatment': _treatment,
        'prevention': _prevention,
        'tags': _tags,
        'icon': _icon,
        'color': _color,
        'imageUrl': imageUrl,
        'submitter_name': _submitterCtrl.text.trim(),

        // Giữ nguyên trạng thái chờ duyệt và ẩn
        'isActive': false,
        'status': 'pending',

        'createdAt': FieldValue.serverTimestamp(),
        'source': 'user_submit',
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showSnack('Lỗi khi gửi: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: kPrimary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Gửi thành công!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Đề xuất của bạn đã được gửi và đang chờ admin xét duyệt.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5)),
        ]),
        actions: [
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Về trang chủ', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('🌿 Đề Xuất Bệnh Mới'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(children: [
          _buildStepIndicator(),
          Expanded(child: _buildCurrentStep()),
          _buildBottomNav(),
        ]),
      ),
    );
  }

  // ── Step Indicator ─────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = ['Thông tin', 'Chi tiết', 'Điều trị', 'Xem lại'];
    return Container(
      color: kPrimary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i < _currentStep;
          final active = i == _currentStep;
          return Expanded(
            child: Row(children: [
              Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: done || active ? Colors.white : Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: done
                      ? const Icon(Icons.check, color: kPrimary, size: 16)
                      : Text('${i+1}', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800,
                      color: active ? kPrimary : Colors.white70))),
                ),
                const SizedBox(height: 4),
                Text(steps[i], style: TextStyle(
                    fontSize: 10, color: active ? Colors.white : Colors.white54,
                    fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
              ]),
              if (i < steps.length - 1)
                Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 20),
                    color: i < _currentStep ? Colors.white : Colors.white.withOpacity(0.3))),
            ]),
          );
        }),
      ),
    );
  }

  // ── Step Content ───────────────────────────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3Review();
      default: return const SizedBox();
    }
  }

  // Step 0: Thông tin cơ bản
  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('📋 Thông tin cơ bản', 'Điền các thông tin chính về loại bệnh'),
        const SizedBox(height: 20),

        _formCard(children: [
          _inputField(_nameCtrl, 'Tên bệnh / sâu hại *', Icons.eco_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên bệnh' : null),
          const SizedBox(height: 16),
          _inputField(_submitterCtrl, 'Tên người đề xuất (tuỳ chọn)', Icons.person_outline),
          const SizedBox(height: 16),
          
          // --- IMAGE PICKER WIDGET ---
          const Text('Ảnh minh họa *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFDFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDEEE6)),
              ),
              child: _pickedImage != null 
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_pickedImage!, width: double.infinity, height: 160, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _pickedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      )
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Nhấn để chọn ảnh từ máy', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _formCard(children: [
          _dropdownField('Loại bệnh *', _type, _types, Icons.category_outlined,
                  (v) => setState(() => _type = v!)),
          const SizedBox(height: 16),
          _dropdownField('Mùa xuất hiện', _season, _seasons, Icons.wb_sunny_outlined,
                  (v) => setState(() => _season = v!)),
          const SizedBox(height: 16),
          _dropdownField('Mức độ nghiêm trọng', _severity, _severities, Icons.bar_chart,
                  (v) => setState(() => _severity = v!)),
          const SizedBox(height: 16),
          _dropdownField('Mức độ khẩn cấp', _emergencyLevel, _emergencies, Icons.warning_amber_outlined,
                  (v) => setState(() => _emergencyLevel = v!)),
        ]),
        const SizedBox(height: 16),

        _formCard(children: [
          _dropdownField('Icon đại diện', _iconLabel, _iconMap.keys.toList(), Icons.widgets_outlined,
                  (v) => setState(() => _icon = _iconMap[v!]!)),
          const SizedBox(height: 16),
          _dropdownField('Màu sắc hiển thị', _colorLabel, _colorMap.keys.toList(), Icons.palette_outlined,
                  (v) => setState(() => _color = _colorMap[v!]!)),
        ]),
      ]),
    );
  }

  // Step 1: Bộ phận & triệu chứng
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('🔬 Bộ phận & Triệu chứng', 'Mô tả bộ phận bị ảnh hưởng và dấu hiệu nhận biết'),
        const SizedBox(height: 20),

        _formCard(children: [
          _listEditor(
            title: '📍 Bộ phận ảnh hưởng',
            items: _affectedParts,
            controller: _partCtrl,
            hint: 'Ví dụ: Thân, Lá, Rễ...',
            onAdd: () => _addItem(_affectedParts, _partCtrl),
            onRemove: (i) => setState(() => _affectedParts.removeAt(i)),
          ),
        ]),
        const SizedBox(height: 16),

        _formCard(children: [
          _listEditor(
            title: '🔴 Triệu chứng nhận biết *',
            items: _symptoms,
            controller: _symptomCtrl,
            hint: 'Ví dụ: Lá vàng và rụng sớm...',
            onAdd: () => _addItem(_symptoms, _symptomCtrl),
            onRemove: (i) => setState(() => _symptoms.removeAt(i)),
            required: true,
          ),
        ]),
      ]),
    );
  }

  // Step 2: Điều trị & Từ khóa
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('💊 Điều trị & Phòng ngừa', 'Biện pháp xử lý và các từ khóa liên quan'),
        const SizedBox(height: 20),

        _formCard(children: [
          _listEditor(
            title: '💊 Biện pháp điều trị',
            items: _treatment,
            controller: _treatmentCtrl,
            hint: 'Ví dụ: Phun thuốc Mancozeb...',
            onAdd: () => _addItem(_treatment, _treatmentCtrl),
            onRemove: (i) => setState(() => _treatment.removeAt(i)),
          ),
        ]),
        const SizedBox(height: 16),

        _formCard(children: [
          _listEditor(
            title: '🛡️ Phòng ngừa',
            items: _prevention,
            controller: _preventionCtrl,
            hint: 'Ví dụ: Thoát nước tốt...',
            onAdd: () => _addItem(_prevention, _preventionCtrl),
            onRemove: (i) => setState(() => _prevention.removeAt(i)),
          ),
        ]),
        const SizedBox(height: 16),

        _formCard(children: [
          _listEditor(
            title: '🏷️ Từ khóa / Tags',
            items: _tags,
            controller: _tagCtrl,
            hint: 'Ví dụ: sầu riêng, nấm bệnh...',
            onAdd: () => _addItem(_tags, _tagCtrl),
            onRemove: (i) => setState(() => _tags.removeAt(i)),
          ),
        ]),
      ]),
    );
  }

  // Step 3: Review
  Widget _buildStep3Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('✅ Xem lại & Gửi', 'Kiểm tra thông tin trước khi gửi cho admin duyệt'),
        const SizedBox(height: 20),

        _formCard(children: [
          _reviewRow('Tên bệnh', _nameCtrl.text),
          _reviewRow('Loại', _type),
          _reviewRow('Mức độ', _severity),
          _reviewRow('Mùa', _season),
          _reviewRow('Khẩn cấp', _emergencyLevel),
          _reviewRow('Icon', _iconLabel),
          _reviewRow('Màu sắc', _colorLabel),
          if (_submitterCtrl.text.isNotEmpty)
            _reviewRow('Người đề xuất', _submitterCtrl.text),
        ]),
        if (_pickedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_pickedImage!, height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 12),

        if (_affectedParts.isNotEmpty) _reviewListCard('📍 Bộ phận ảnh hưởng', _affectedParts),
        if (_symptoms.isNotEmpty) _reviewListCard('🔴 Triệu chứng', _symptoms),
        if (_treatment.isNotEmpty) _reviewListCard('💊 Điều trị', _treatment),
        if (_prevention.isNotEmpty) _reviewListCard('🛡️ Phòng ngừa', _prevention),
        if (_tags.isNotEmpty) _reviewListCard('🏷️ Tags', _tags),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.5)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Color(0xFFE65100), size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(
                'Đề xuất sẽ được admin xét duyệt trước khi hiển thị công khai.',
                style: TextStyle(fontSize: 13, color: Color(0xFF5D4037), height: 1.4))),
          ]),
        ),
      ]),
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12, offset: const Offset(0, -4),
        )],
      ),
      child: Row(children: [
        if (_currentStep > 0)
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() => _currentStep--),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: const BorderSide(color: kPrimary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('← Quay lại', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () {
              if (_currentStep < 3) {
                if (_validateStep()) setState(() => _currentStep++);
              } else {
                _submit();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_currentStep < 3 ? 'Tiếp theo →' : '🚀 Gửi đề xuất',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  bool _validateStep() {
    if (_currentStep == 0 && _nameCtrl.text.trim().isEmpty) {
      _showSnack('Vui lòng nhập tên bệnh', Colors.orange);
      return false;
    }
    if (_currentStep == 1 && _symptoms.isEmpty) {
      _showSnack('Vui lòng thêm ít nhất 1 triệu chứng', Colors.orange);
      return false;
    }
    return true;
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────
  Widget _stepHeader(String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
          color: Color(0xFF1A2E23))),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
    ]);
  }

  Widget _formCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F3ED)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF4A6B58), fontSize: 14),
        prefixIcon: Icon(icon, color: kPrimaryL, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDEEE6))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDEEE6))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimaryL, width: 2)),
        filled: true, fillColor: const Color(0xFFFAFDFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _dropdownField(String label, String value, List<String> options,
      IconData icon, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF4A6B58), fontSize: 14),
        prefixIcon: Icon(icon, color: kPrimaryL, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDEEE6))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDEEE6))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimaryL, width: 2)),
        filled: true, fillColor: const Color(0xFFFAFDFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _listEditor({
    required String title,
    required List<String> items,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    bool required = false,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: Color(0xFF2D6A4F))),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => onAdd(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDDEEE6))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDDEEE6))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kPrimaryL, width: 2)),
              filled: true, fillColor: const Color(0xFFFAFDFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: kPrimary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ]),
      if (items.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
          children: items.asMap().entries.map((e) => Container(
            padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB7E4C7)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(e.value, style: const TextStyle(fontSize: 12, color: Color(0xFF2D6A4F))),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onRemove(e.key),
                child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF40916C)),
              ),
            ]),
          )).toList(),
        ),
      ] else if (required) ...[
        const SizedBox(height: 6),
        Text('* Bắt buộc có ít nhất 1 mục',
            style: TextStyle(fontSize: 11, color: Colors.orange[700])),
      ],
    ]);
  }

  Widget _reviewRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        SizedBox(width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
        Expanded(child: Text(value, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2E23)))),
      ]),
    );
  }

  Widget _reviewListCard(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F3ED)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: Color(0xFF2D6A4F))),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('• ', style: TextStyle(color: Color(0xFF40916C))),
            Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
          ]),
        )),
      ]),
    );
  }

  void _addItem(List<String> list, TextEditingController ctrl) {
    final val = ctrl.text.trim();
    if (val.isEmpty) return;
    setState(() { list.add(val); ctrl.clear(); });
  }
}