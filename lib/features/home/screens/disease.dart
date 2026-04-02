import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'expert_screen.dart'; // 1. IMPORT FILE CHUYÊN GIA

// ============================================================================
// ĐỊNH NGHĨA MÀU SẮC CHUẨN UI/UX (Dribbble Aesthetic)
// ============================================================================
class AppColors {
  static const Color primary = Color(0xFF2D6A4F); // Xanh ngọc lục bảo đậm
  static const Color background = Color(0xFFF8F9FA); // Trắng nhạt (Off-white)
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFFADB5BD);
}

// Chuẩn đoạn bệnh bằng hình ảnh
class AnalyzeDiseaseScreen extends StatefulWidget {
  const AnalyzeDiseaseScreen({super.key});

  @override
  State<AnalyzeDiseaseScreen> createState() => _AnalyzeDiseaseScreenState();
}

class _AnalyzeDiseaseScreenState extends State<AnalyzeDiseaseScreen> {
  // ⚠️ CẬP NHẬT LINK NGROK MỚI TẠI ĐÂY
  final String serverUrl = "https://dania-ariose-out.ngrok-free.dev";

  File? _image;
  Uint8List? _processedImageBytes;
  bool _isLoading = false;
  Map<String, dynamic>? _resultData;
  final ImagePicker _picker = ImagePicker();

  // ============================================================================
  // LOGIC XỬ LÝ (GIỮ NGUYÊN 100% CỦA BẠN)
  // ============================================================================

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _resultData = null;
        _processedImageBytes = null;
      });
      // Tự động phân tích khi chọn ảnh xong
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;
    if (serverUrl.contains("DÁN_LINK")) {
      _showError("Vui lòng cập nhật Server URL!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("Đang gửi ảnh đến: $serverUrl/predict");
      var request = http.MultipartRequest('POST', Uri.parse('$serverUrl/predict'));
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        Uint8List? imgBytes;
        String? base64Str = data['image_processed'];
        if (base64Str != null && base64Str.isNotEmpty) {
          try {
            imgBytes = base64Decode(base64Str.replaceAll('\n', ''));
          } catch (e) {
            print("Lỗi decode ảnh: $e");
          }
        }

        setState(() {
          _resultData = data;
          _processedImageBytes = imgBytes;
        });

      } else {
        _showError("Lỗi Server: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      _showError("Không kết nối được Server!");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContribution() async {
    if (_resultData == null) return;

    try {
      // Lưu vào collection 'history'
      await FirebaseFirestore.instance.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'status': _resultData!['status'],
        'advice': _resultData!['advice'],
        'diseases': _resultData!['diseases'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Đã đóng góp dữ liệu thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Lỗi Firebase: $e");
      _showError("Lỗi khi lưu dữ liệu: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  // --- HÀM CHUYỂN HƯỚNG SANG CHUYÊN GIA (ĐÃ UPDATE LOGIC) ---
  void _navigateToExpert() {
    if (_resultData == null) return;

    // 1. Lấy trạng thái chung
    String status = _resultData!['status'] ?? 'Chưa xác định';

    // 2. Lấy danh sách bệnh chi tiết từ JSON
    List<dynamic> diseases = _resultData!['diseases'] ?? [];
    String diseaseDetails = "";

    // 3. Tạo chuỗi mô tả chi tiết: "Bệnh Thán Thư (85%), Bệnh Đốm Rong (70%)"
    if (diseases.isNotEmpty) {
      diseaseDetails = diseases.map((d) => "${d['name']} (Độ tin cậy: ${d['confidence']}%)").join(", ");
    }

    String question;

    // 4. Tạo câu hỏi thông minh dựa trên dữ liệu
    if (status == "Cây Khỏe Mạnh") {
      question = "Qua kiểm tra hình ảnh, cây sầu riêng của tôi được chẩn đoán là Khỏe Mạnh. Xin chuyên gia tư vấn chế độ dinh dưỡng và chăm sóc định kỳ để duy trì năng suất cao?";
    } else if (diseaseDetails.isNotEmpty) {
      // Trường hợp có bệnh cụ thể -> Câu hỏi sẽ chứa tên bệnh
      question = "Hệ thống phân tích hình ảnh chẩn đoán cây sầu riêng của tôi đang mắc các bệnh sau: $diseaseDetails. Xin chuyên gia đánh giá mức độ nghiêm trọng và đưa ra phác đồ điều trị thuốc bảo vệ thực vật cụ thể cho trường hợp này?";
    } else {
      // Fallback nếu không có list bệnh
      question = "Sầu riêng của tôi đang bị tình trạng: $status. Xin chuyên gia tư vấn cách xử lý cụ thể?";
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        // Truyền câu hỏi chi tiết sang ExpertScreen
        builder: (context) => ExpertScreen(initialQuestion: question),
      ),
    );
  }

  // ============================================================================
  // GIAO DIỆN NGƯỜI DÙNG (NÂNG CẤP LÊN CHUẨN DRIBBBLE)
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Chẩn Đoán Sầu Riêng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _navigateToHistory,
            icon: const Icon(Icons.history_edu),
            tooltip: "Lịch sử phân tích",
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            _buildImageDisplay(),
            const SizedBox(height: 24),

            if (!_isLoading) _buildControlButtons(),

            const SizedBox(height: 24),

            if (_isLoading)
              _buildLoading()
            else if (_resultData != null)
              _buildResultCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Container(
      height: 340,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ảnh nền hoặc placeholder
            if (_processedImageBytes == null && _image == null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    "Chẩn đoán có ảnh nào",
                    style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),

            // Hiển thị ảnh gốc
            if (_image != null && _processedImageBytes == null)
              Image.file(_image!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),

            // Hiển thị ảnh xử lý
            if (_processedImageBytes != null)
              Image.memory(_processedImageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),

            // Nút xóa ảnh
            if (_image != null && !_isLoading)
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _image = null;
                      _processedImageBytes = null;
                      _resultData = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            label: const Text("Chụp Ảnh", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.image_outlined, color: AppColors.primary, size: 20),
            label: const Text("Thư Viện", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          "AI đang phân tích...",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600], fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    String status = _resultData!['status'] ?? "Không xác định";
    bool isHealthy = status == "Cây Khỏe Mạnh";
    bool isSevere = status.contains("CẢNH BÁO") || status.contains("Nặng");

    Color statusColor = isHealthy ? AppColors.primary : (isSevere ? Colors.red[600]! : Colors.orange.shade800);
    List<dynamic> adviceList = _resultData!['advice'] ?? [];

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header trạng thái
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Icon(isHealthy ? Icons.verified : Icons.warning_rounded, color: statusColor, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("KẾT QUẢ PHÂN TÍCH", style: TextStyle(color: statusColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Body: Lời khuyên
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services_outlined, color: AppColors.textDark, size: 22),
                        const SizedBox(width: 10),
                        const Text("CHẨN ĐOÁN & ĐIỀU TRỊ", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...adviceList.map((item) => _buildAdviceItem(item.toString())),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Hàng nút đóng góp & Hỏi chuyên gia
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveContribution,
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text("Lưu kết quả"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _navigateToExpert,
                icon: const Icon(Icons.support_agent, size: 18),
                label: const Text("Hỏi chuyên gia"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Giữ nguyên logic xử lý text, Markdown và Emoji của bạn
  Widget _buildAdviceItem(String text) {
    IconData icon = Icons.circle;
    Color iconColor = AppColors.primary;
    double iconSize = 8;
    double topPadding = 6;

    if (text.contains("🔴") || text.contains("Cấp bách")) {
      icon = Icons.priority_high; iconColor = Colors.red; iconSize = 18; topPadding = 2;
    } else if (text.contains("🟠")) {
      icon = Icons.warning_amber; iconColor = Colors.orange; iconSize = 18; topPadding = 2;
    } else if (text.contains("✅")) {
      icon = Icons.check_circle_outline; iconColor = Colors.green; iconSize = 18; topPadding = 2;
    } else if (text.contains("👉")) {
      icon = Icons.lightbulb_outline; iconColor = Colors.blue; iconSize = 18; topPadding = 2;
    }

    List<TextSpan> spans = [];
    RegExp exp = RegExp(r"\*\*(.*?)\*\*");
    Iterable<Match> matches = exp.allMatches(text);
    int lastIndex = 0;

    String cleanText = text.trim();
    if (cleanText.startsWith("-")) cleanText = cleanText.substring(1).trim();

    for (Match m in matches) {
      if (m.start > lastIndex) {
        spans.add(TextSpan(text: cleanText.substring(lastIndex, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
      ));
      lastIndex = m.end;
    }

    if (lastIndex < cleanText.length) {
      spans.add(TextSpan(text: cleanText.substring(lastIndex)));
    }

    if (spans.isEmpty) spans.add(TextSpan(text: cleanText));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding, right: 12),
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Color(0xFF495057), height: 1.5),
                children: spans,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MÀN HÌNH LỊCH SỬ (HISTORY SCREEN) - Nâng cấp nhẹ UI
// ============================================================================
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Lịch Sử Phân Tích", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Đã xảy ra lỗi khi tải dữ liệu"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Chưa có lịch sử phân tích nào", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Không xác định';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final dateStr = timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp)
                  : 'N/A';

              bool isHealthy = status == "Cây Khỏe Mạnh";
              Color color = isHealthy ? AppColors.primary : Colors.orange.shade800;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: AppColors.surface,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(
                        isHealthy ? Icons.verified : Icons.warning_amber,
                        color: color
                    ),
                  ),
                  title: Text(
                    status,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text("Thời gian: $dateStr", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    _showDetailDialog(context, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> data) {
    List<dynamic> advice = data['advice'] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Text(
                data['status'] ?? "",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1),
              ),
              const Text("Lời khuyên đã lưu:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
              const SizedBox(height: 16),
              ...advice.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 10),
                      child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                    ),
                    Expanded(child: Text(e.toString(), style: const TextStyle(height: 1.5, color: Color(0xFF495057)))),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}