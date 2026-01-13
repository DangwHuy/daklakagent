import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'expert_screen.dart'; // 1. IMPORT FILE CHUYÊN GIA

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Màu nền xám nhẹ hiện đại
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Chẩn Đoán Sầu Riêng", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImageDisplay(),
            const SizedBox(height: 24),
            _buildControlButtons(),
            const SizedBox(height: 24),

            if (_isLoading)
              _buildLoading()
            else if (_resultData != null)
              _buildResultCard(),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ảnh nền hoặc placeholder
            if (_processedImageBytes == null && _image == null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Chưa có ảnh nào",
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),

            // Hiển thị ảnh
            if (_image != null && _processedImageBytes == null)
              Image.file(_image!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),

            if (_processedImageBytes != null)
              Image.memory(_processedImageBytes!, fit: BoxFit.contain, width: double.infinity, height: double.infinity),

            // Nút xóa ảnh (nếu cần)
            if (_image != null && !_isLoading)
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _image = null;
                      _processedImageBytes = null;
                      _resultData = null;
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
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
          child: _buildBigButton(
            icon: Icons.camera_alt_rounded,
            label: "Chụp Ảnh",
            color: const Color(0xFF2E7D32),
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBigButton(
            icon: Icons.photo_library_rounded,
            label: "Thư Viện",
            color: const Color(0xFF43A047),
            isOutlined: true,
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildBigButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: isOutlined ? [] : [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: isOutlined ? color : Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : color,
          foregroundColor: isOutlined ? color : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: isOutlined ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutlined ? BorderSide(color: color, width: 2) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: const [
        CircularProgressIndicator(color: Color(0xFF2E7D32)),
        SizedBox(height: 16),
        Text(
          "AI đang phân tích...",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    String status = _resultData!['status'] ?? "Không xác định";
    bool isHealthy = status == "Cây Khỏe Mạnh";
    bool isSevere = status.contains("CẢNH BÁO") || status.contains("Nặng");

    Color statusColor = isHealthy ? Colors.green : (isSevere ? Colors.red : Colors.orange.shade800);
    List<dynamic> adviceList = _resultData!['advice'] ?? [];

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            children: [
              // Header trạng thái
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: Icon(isHealthy ? Icons.verified : Icons.warning_amber_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("KẾT QUẢ PHÂN TÍCH", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Body: Lời khuyên
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services_outlined, color: Colors.grey[800], size: 22),
                        const SizedBox(width: 10),
                        Text("CHẨN ĐOÁN & ĐIỀU TRỊ", style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 15)),
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

        const SizedBox(height: 20),

        // Nút Đóng Góp Dữ Liệu
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveContribution,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text("Lưu & Đóng Góp Dữ Liệu"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // --- NÚT HỎI CHUYÊN GIA ---
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToExpert,
            icon: const Icon(Icons.support_agent),
            label: const Text("Hỏi Chuyên Gia Về Bệnh Này"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceItem(String text) {
    IconData icon = Icons.circle;
    Color iconColor = Colors.grey;
    double iconSize = 6;
    double topPadding = 8;

    if (text.contains("🔴") || text.contains("Cấp bách")) {
      icon = Icons.priority_high; iconColor = Colors.red; iconSize = 18; topPadding = 2;
    } else if (text.contains("🟠")) {
      icon = Icons.warning_amber; iconColor = Colors.orange; iconSize = 18; topPadding = 2;
    } else if (text.contains("✅")) {
      icon = Icons.check_circle_outline; iconColor = Colors.green; iconSize = 18; topPadding = 2;
    } else if (text.contains("👉")) {
      icon = Icons.lightbulb_outline; iconColor = Colors.blue; iconSize = 18; topPadding = 2;
    }

    // Xử lý Markdown in đậm
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
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      ));
      lastIndex = m.end;
    }

    if (lastIndex < cleanText.length) {
      spans.add(TextSpan(text: cleanText.substring(lastIndex)));
    }

    if (spans.isEmpty) spans.add(TextSpan(text: cleanText));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                children: spans,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- MÀN HÌNH LỊCH SỬ (HISTORY SCREEN) ---
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch Sử Phân Tích"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
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
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Chưa có lịch sử phân tích nào"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Không xác định';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final dateStr = timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp)
                  : 'N/A';

              bool isHealthy = status == "Cây Khỏe Mạnh";
              Color color = isHealthy ? Colors.green : Colors.orange.shade800;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(
                        isHealthy ? Icons.verified : Icons.warning_amber,
                        color: color
                    ),
                  ),
                  title: Text(
                    status,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  subtitle: Text("Thời gian: $dateStr"),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Text(
                data['status'] ?? "",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 30),
              const Text("Lời khuyên đã lưu:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...advice.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text("• $e"),
              )),
            ],
          ),
        ),
      ),
    );
  }
}