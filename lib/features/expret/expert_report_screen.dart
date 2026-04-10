import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class ExpertReportScreen extends StatefulWidget {
  const ExpertReportScreen({super.key});

  @override
  State<ExpertReportScreen> createState() => _ExpertReportScreenState();
}

class _ExpertReportScreenState extends State<ExpertReportScreen> {
  // Trạng thái load API
  bool _isLoadingAPI = false;
  String _apiError = "";

  // Biến lưu dữ liệu AI
  String _aiMessage = "Chưa có dữ liệu phân tích. Hãy bấm nút 'Phân tích mới' để AI tổng hợp dữ liệu của bạn nhé!";
  List<String> _radarLabels = ["Số ca", "Hoàn thành", "Doanh thu", "Tốc độ", "Đánh giá"];
  List<double> _radarValues = [0, 0, 0, 0, 0];
  DateTime? _lastAnalyzedTime; // Thời gian phân tích gần nhất

  @override
  void initState() {
    super.initState();
    // Vừa vào trang là lấy dữ liệu ĐÃ LƯU TỪ TRƯỚC ra xem ngay (Không tốn token)
    _loadSavedAIData();
  }

  // ─── ĐỌC DỮ LIỆU ĐÃ LƯU TỪ FIREBASE ───────────────────────────────────────
  Future<void> _loadSavedAIData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (docSnap.exists && docSnap.data()!.containsKey('latestAiReport')) {
        final data = docSnap.data()!['latestAiReport'];
        if (!mounted) return;
        setState(() {
          _aiMessage = data['ai_insight'] ?? _aiMessage;
          _radarValues = List<double>.from(data['radar_values'] ?? [0,0,0,0,0]);
          _lastAnalyzedTime = (data['timestamp'] as Timestamp?)?.toDate();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải cache: $e");
    }
  }

  // ─── GỌI FASTAPI ĐỂ PHÂN TÍCH MỚI VÀ LƯU LẠI ──────────────────────────────
  Future<void> _fetchNewAIData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingAPI = true;
      _apiError = "";
    });

    final String apiUrl = "https://dania-ariose-out.ngrok-free.dev/api/expert-insights/${user.uid}";
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"ngrok-skip-browser-warning": "true"},
      ).timeout(const Duration(seconds: 60)); // Đã Tăng thời gian chờ AI lên 60s

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        List<dynamic> rawValues = data['radar_chart_data']['values'];
        List<double> newRadarValues = rawValues.map((e) => (e as num).toDouble()).toList();
        String newInsight = data['ai_insight'] ?? "Không có lời khuyên.";

        // --- LƯU LÊN FIREBASE ĐỂ LẦN SAU KHÔNG CẦN GỌI LẠI ---
        final reportData = {
          'ai_insight': newInsight,
          'radar_values': newRadarValues,
          'timestamp': FieldValue.serverTimestamp(),
        };

        final batch = FirebaseFirestore.instance.batch();
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        // 1. Lưu làm bản nháp mới nhất
        batch.update(userRef, {'latestAiReport': reportData});

        // 2. Lưu vào subcollection để làm Lịch sử
        final historyRef = userRef.collection('ai_history').doc();
        batch.set(historyRef, reportData);

        await batch.commit();
        // -----------------------------------------------------

        if (!mounted) return;
        setState(() {
          _aiMessage = newInsight;
          _radarValues = newRadarValues;
          _lastAnalyzedTime = DateTime.now();
          _isLoadingAPI = false;
        });

      } else {
        if (!mounted) return;
        setState(() {
          // Bắt lỗi nếu Server Colab gặp lỗi 500
          _apiError = "Lỗi Máy chủ Colab: Mã ${response.statusCode}\nChi tiết: ${response.body}";
          _isLoadingAPI = false;
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _apiError = "Lỗi: Đã đợi quá 60s nhưng AI chưa trả lời xong. Vui lòng thử lại!";
        _isLoadingAPI = false;
      });
    } catch (e) {
      debugPrint("LỖI GỌI API THỰC TẾ: $e");
      if (!mounted) return;
      setState(() {
        // 🚀 ĐÃ FIX: In chính xác mã lỗi ra màn hình để biết tại sao hỏng
        _apiError = "Lỗi hệ thống: $e";
        _isLoadingAPI = false;
      });
    }
  }

  // ─── HIỂN THỊ LỊCH SỬ PHÂN TÍCH ───────────────────────────────────────────
  void _showHistoryBottomSheet() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Lịch sử phân tích AI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('ai_history')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Chưa có lịch sử phân tích nào."));
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: docs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final insight = data['ai_insight'] ?? '';
                      final time = (data['timestamp'] as Timestamp?)?.toDate();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.purple[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: Colors.purple),
                                  const SizedBox(width: 6),
                                  Text(
                                    time != null ? DateFormat('HH:mm - dd/MM/yyyy').format(time) : 'Không rõ thời gian',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[800], fontSize: 13),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Text(insight, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
                // 1. Thẻ AI Phân Tích Thông Minh
                _buildAIAssistantCard(),

                const SizedBox(height: 24),
                const Text(
                  "Tổng Quan Doanh Thu",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // 2. Thẻ hiển thị doanh thu
                _buildRevenueCard(revenue),

                const SizedBox(height: 24),
                const Text(
                  "Đánh Giá Năng Lực (Radar AI)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // 3. Biểu đồ Radar
                _buildRadarChartCard(),

                const SizedBox(height: 24),
                const Text(
                  "Hiệu Suất Công Việc",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // 4. Grid thống kê truyền thống
                _buildPerformanceStats(totalBookings, rating),

                const SizedBox(height: 24),

                // 5. Danh sách Top 3 Khách Hàng Thân Thiết
                _buildLoyalCustomersCard(user.uid),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── THẺ AI PHÂN TÍCH THỰC TẾ (NÂNG CẤP LƯU CACHE & LỊCH SỬ) ──────────────
  Widget _buildAIAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[800]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER CARD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Trợ lý AI Đắk Lắk",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_lastAnalyzedTime != null)
                        Text(
                          "Cập nhật: ${DateFormat('HH:mm dd/MM').format(_lastAnalyzedTime!)}",
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
                    tooltip: "Lịch sử phân tích",
                    onPressed: _showHistoryBottomSheet,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),

          // NỘI DUNG CHAT BUBBLE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.smart_toy_rounded, color: Colors.purple, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: _isLoadingAPI
                      ? const _TypingIndicator()
                      : _apiError.isNotEmpty
                      ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        // CHỖ NÀY SẼ IN RA LỖI RÕ RÀNG ĐỂ CHÚNG TA BIẾT ĐƯỜNG FIX
                        Expanded(child: Text(_apiError, style: const TextStyle(color: Colors.red, fontSize: 13))),
                      ],
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TypewriterText(
                        text: _aiMessage,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_aiMessage != "Đang chờ kết nối với Máy chủ AI...")
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.copy_rounded, color: Colors.grey, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _aiMessage));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã chép!")));
                            },
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // NÚT PHÂN TÍCH MỚI
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingAPI ? null : _fetchNewAIData,
              icon: _isLoadingAPI
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.purple, strokeWidth: 2))
                  : const Icon(Icons.bolt_rounded, size: 20),
              label: Text(
                _isLoadingAPI ? "Đang phân tích dữ liệu mới..." : "Phân tích dữ liệu mới nhất",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
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
            child: _isLoadingAPI
                ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                : RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 5,
                ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
                gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
                tickBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
                titlePositionPercentageOffset: 0.2,
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: _radarLabels[index],
                    angle: 0,
                  );
                },
                titleTextStyle: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.bold),
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
            "Biểu đồ Radar được AI tổng hợp theo dữ liệu mới nhất",
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

  // ─── DANH SÁCH TOP 3 KHÁCH HÀNG THÂN THIẾT ────────────────────────────────
  Widget _buildLoyalCustomersCard(String expertId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;
        Map<String, Map<String, dynamic>> customerStats = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final fId = data['farmerId'] ?? '';
          final fName = data['farmerName'] ?? 'Khách hàng ẩn danh';
          final fPhone = data['farmerPhone'] ?? '';

          if (fId.toString().isEmpty) continue;

          if (customerStats.containsKey(fId)) {
            customerStats[fId]!['count'] += 1;
          } else {
            customerStats[fId] = {
              'name': fName,
              'phone': fPhone,
              'count': 1,
            };
          }
        }

        var sortedCustomers = customerStats.values.toList()
          ..sort((a, b) => b['count'].compareTo(a['count']));

        var loyalCustomers = sortedCustomers.where((c) => c['count'] >= 2).take(3).toList();

        if (loyalCustomers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Top 3 Khách Hàng VIP (Thân thiết)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            ...loyalCustomers.asMap().entries.map((entry) {
              int index = entry.key;
              var c = entry.value;

              List<Color> medalColors = [Colors.amber, Colors.blueGrey, Colors.brown[400]!];
              Color medalColor = index < 3 ? medalColors[index] : Colors.blue;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: medalColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.emoji_events_rounded, color: medalColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone_rounded, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(c['phone'].toString().isNotEmpty ? c['phone'] : 'Chưa có SĐT', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text("${c['count']}", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("lượt đặt", style: TextStyle(color: Colors.green[700], fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CÁC WIDGET BỔ TRỢ CHO AI EXPERIENCE
// ═══════════════════════════════════════════════════════════════════════════

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TypewriterText({super.key, required this.text, required this.style});

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = "";
  int _currentIndex = 0;
  Timer? _timer;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  void _startTyping() {
    _timer?.cancel();
    setState(() {
      _displayedText = "";
      _currentIndex = 0;
      _isFinished = false;
    });

    if (widget.text.isEmpty) return;

    _timer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isFinished = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isFinished) {
          _timer?.cancel();
          setState(() {
            _displayedText = widget.text;
            _isFinished = true;
          });
        }
      },
      child: Text(_displayedText, style: widget.style),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double offset = (index * 0.2);
            double value = (_controller.value - offset) % 1.0;
            if (value < 0) value += 1.0;

            double height = 6 + (6 * (value < 0.5 ? value * 2 : (1 - value) * 2));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: height,
              decoration: BoxDecoration(
                color: Colors.purple[300],
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}