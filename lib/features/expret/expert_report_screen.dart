import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart'; // THÊM THƯ VIỆN VẼ BIỂU ĐỒ

class ExpertReportScreen extends StatefulWidget {
  const ExpertReportScreen({super.key});

  @override
  State<ExpertReportScreen> createState() => _ExpertReportScreenState();
}

class _ExpertReportScreenState extends State<ExpertReportScreen> {
  // Trạng thái load API
  bool _isLoadingAPI = true;
  String _apiError = "";

  // Biến lưu dữ liệu từ FastAPI
  String _aiMessage = "Đang chờ kết nối với Máy chủ AI...";
  List<String> _radarLabels = ["Số ca", "Hoàn thành", "Doanh thu", "Tốc độ", "Đánh giá"];
  List<double> _radarValues = [0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    // Gọi hàm fetch API ngay khi mở màn hình
    _fetchAIData();
  }

  // ─── HÀM GỌI FASTAPI CHẠY TRÊN COLAB ──────────────────────────────────────
  Future<void> _fetchAIData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ⚠️ CHÚ Ý: ĐÂY LÀ LINK NGROK CỦA BẠN.
    // NẾU COLAB TẮT VÀ MỞ LẠI, NGROK SẼ ĐỔI LINK, BẠN NHỚ VÀO ĐÂY CẬP NHẬT LẠI NHÉ!
    final String apiUrl = "https://dania-ariose-out.ngrok-free.dev/api/expert-insights/uB0Tu51v36O9esYGjIVGtcToQaI2${user.uid}";

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Decode UTF-8 để hiển thị Tiếng Việt không bị lỗi font
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (!mounted) return;
        setState(() {
          _aiMessage = data['ai_insight'] ?? "Không có lời khuyên.";

          // Trích xuất dữ liệu Radar Chart
          List<dynamic> rawValues = data['radar_chart_data']['values'];
          _radarValues = rawValues.map((e) => (e as num).toDouble()).toList();

          List<dynamic> rawLabels = data['radar_chart_data']['labels'];
          _radarLabels = rawLabels.map((e) => e.toString()).toList();

          _isLoadingAPI = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _apiError = "Lỗi Server: Mã ${response.statusCode}";
          _isLoadingAPI = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = "Không thể kết nối Server AI. Vui lòng kiểm tra lại link Ngrok.";
        _isLoadingAPI = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Chưa đăng nhập")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          "Báo Cáo & Phân Tích",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Làm mới AI",
            onPressed: () {
              setState(() {
                _isLoadingAPI = true;
                _apiError = "";
              });
              _fetchAIData();
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Không có dữ liệu báo cáo."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final expertInfo = data['expertInfo'] as Map<String, dynamic>? ?? {};
          final double revenue = (expertInfo['revenue'] ?? 0.0).toDouble();
          final int totalBookings = expertInfo['bookingCount'] ?? 0;
          final double rating = (expertInfo['rating'] ?? 5.0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Thẻ AI Phân Tích Thông Minh (ĐÃ KẾT NỐI API)
                _buildAIAssistantCard(),

                const SizedBox(height: 24),
                const Text(
                  "Tổng Quan Doanh Thu",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // 2. Thẻ hiển thị doanh thu (Từ Firebase)
                _buildRevenueCard(revenue),

                const SizedBox(height: 24),
                const Text(
                  "Đánh Giá Năng Lực (Radar AI)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // 3. Biểu đồ Radar (ĐÃ KẾT NỐI API)
                _buildRadarChartCard(),

                const SizedBox(height: 24),
                const Text(
                  "Hiệu Suất Công Việc",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // 4. Grid thống kê truyền thống
                _buildPerformanceStats(totalBookings, rating),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── THẺ AI PHÂN TÍCH THỰC TẾ ──────────────────────────────────────────
  Widget _buildAIAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[700]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Gemini AI Phân Tích",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingAPI)
            const Row(
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                SizedBox(width: 12),
                Text("Hệ thống AI đang phân tích dữ liệu...",
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
              ],
            )
          else if (_apiError.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_apiError, style: const TextStyle(color: Colors.white, fontSize: 13))),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "💡 Lời khuyên cho bạn:",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _aiMessage, // Hiển thị kết quả thực từ Gemini
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── THẺ HIỂN THỊ DOANH THU ──────────────────────────────────────────────
  Widget _buildRevenueCard(double revenue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "TỔNG THU NHẬP ƯỚC TÍNH",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            "${NumberFormat("#,##0", "vi_VN").format(revenue)} VNĐ",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green[700]),
          ),
        ],
      ),
    );
  }

  // ─── BIỂU ĐỒ RADAR TỪ FL_CHART ──────────────────────────────────────────
  Widget _buildRadarChartCard() {
    if (_isLoadingAPI) {
      return Container(
        height: 250,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }
    if (_apiError.isNotEmpty) {
      return const SizedBox.shrink(); // Ẩn biểu đồ nếu lỗi API
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 5,
                ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
                gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
                tickBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
                titlePositionPercentageOffset: 0.2, // Đã thay thế titlePositionMultiplier
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: _radarLabels[index],
                    angle: 0, // Giữ chữ nằm ngang dễ đọc
                  );
                },
                titleTextStyle: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.bold), // Đã thay thế radarTextStyle
                dataSets: [
                  RadarDataSet(
                    fillColor: Colors.purple.withOpacity(0.25),
                    borderColor: Colors.purple[600]!,
                    entryRadius: 4,
                    dataEntries: _radarValues.map((v) => RadarEntry(value: v)).toList(),
                    borderWidth: 2.5,
                  ),
                ],
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Biểu đồ phân tích đa chiều dựa trên Dữ liệu và AI",
            style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
          )
        ],
      ),
    );
  }

  // ─── THỐNG KÊ HIỆU SUẤT ──────────────────────────────────────────────────
  Widget _buildPerformanceStats(int totalBookings, double rating) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                Icon(Icons.people_alt_rounded, color: Colors.blue[600], size: 32),
                const SizedBox(height: 12),
                Text(totalBookings.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Tổng ca tư vấn", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                Icon(Icons.star_rounded, color: Colors.orange[500], size: 32),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text(" / 5.0", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Đánh giá TB", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}