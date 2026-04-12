import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  DateTime? _lastAnalyzedTime; // Thời gian phân tích gần nhất

  // Dữ liệu Radar cũ từ API sẽ không còn dùng để vẽ biểu đồ nữa,
  // nhưng vẫn giữ lại mảng labels để hiển thị
  final List<String> _radarLabels = ["Số ca", "Thành công", "Doanh thu", "Khách quen", "Đánh giá"];

  @override
  void initState() {
    super.initState();
    // Vừa vào trang là lấy dữ liệu AI ĐÃ LƯU TỪ TRƯỚC ra xem ngay (Không tốn token)
    _loadSavedAIData();
  }

  // ─── ĐỌC DỮ LIỆU AI ĐÃ LƯU TỪ FIREBASE ───────────────────────────────────────
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
          _lastAnalyzedTime = (data['timestamp'] as Timestamp?)?.toDate();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải cache: $e");
    }
  }

  // ─── GỌI FASTAPI ĐỂ LẤY NHẬN XÉT MỚI VÀ LƯU LẠI ──────────────────────────────
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
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        String newInsight = data['ai_insight'] ?? "Không có lời khuyên.";

        // --- LƯU LÊN FIREBASE ĐỂ LẦN SAU KHÔNG CẦN GỌI LẠI ---
        final reportData = {
          'ai_insight': newInsight,
          // Không cần lưu radar_values từ server nữa vì app tự tính
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
          _lastAnalyzedTime = DateTime.now();
          _isLoadingAPI = false;
        });

      } else {
        if (!mounted) return;
        setState(() {
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
        _apiError = "Lỗi hệ thống: $e";
        _isLoadingAPI = false;
      });
    }
  }

  // ─── HIỂN THỊ LỊCH SỬ PHÂN TÍCH AI ───────────────────────────────────────────
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
              child: Text("Lịch sử nhận xét AI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        centerTitle: false,
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Báo Cáo & Phân Tích",
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Thẻ AI Phân Tích Thông Minh
                _buildAIAssistantCard(),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    "TỔNG QUAN DOANH THU",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Thẻ hiển thị doanh thu
                _buildRevenueCard(revenue),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    "ĐÁNH GIÁ NĂNG LỰC",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. NÂNG CẤP: Biểu đồ Radar tự động tính toán từ Firebase
                _buildRadarChartCard(user.uid, totalBookings, revenue, rating),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    "HIỆU SUẤT CÔNG VIỆC",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Grid thống kê truyền thống
                _buildPerformanceStats(totalBookings, rating),

                const SizedBox(height: 24),

                // 5. Danh sách Top 3 Khách Hàng Thân Thiết
                _buildLoyalCustomersCard(user.uid),

                const SizedBox(height: 100), // Khoảng trống cuối trang
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── THẺ AI PHÂN TÍCH THỰC TẾ ──────────────────────────────────────────────
  Widget _buildAIAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A11CB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AI Phân Tích",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (_lastAnalyzedTime != null)
                        Text(
                          "Cập nhật: ${DateFormat('HH:mm dd/MM').format(_lastAnalyzedTime!)}",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showHistoryBottomSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.smart_toy_rounded, color: Color(0xFF6A11CB), size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5))
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
                        Expanded(child: Text(_apiError, style: const TextStyle(color: Colors.red, fontSize: 13))),
                      ],
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TypewriterText(
                        text: _aiMessage,
                        style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.5, fontWeight: FontWeight.w600),
                      ),
                      if (_aiMessage != "Đang chờ kết nối với Máy chủ AI...")
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _aiMessage));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã chép vào clipboard!")));
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.copy_rounded, color: Colors.grey[400], size: 18),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingAPI ? null : _fetchNewAIData,
              icon: _isLoadingAPI
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF6A11CB), strokeWidth: 2))
                  : const Icon(Icons.bolt_rounded, size: 20),
              label: Text(
                _isLoadingAPI ? "Đang nhờ AI nhận xét..." : "Xin nhận phân tích mới",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6A11CB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "TỔNG THU NHẬP ƯỚC TÍNH",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey[500], letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            "${NumberFormat("#,##0", "vi_VN").format(revenue)} VNĐ",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.green[700], letterSpacing: -1),
          ),
        ],
      ),
    );
  }

  // ─── NÂNG CẤP: TỰ ĐỘNG TÍNH ĐIỂM RADAR TRỰC TIẾP TỪ FIREBASE ──────────────
  Widget _buildRadarChartCard(String expertId, int uiTotalBookings, double uiTotalRevenue, double uiRating) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('expertId', isEqualTo: expertId)
            .snapshots(),
        builder: (context, snapshot) {

          // 1. Khởi tạo điểm mặc định là 4.0 (mức Khá)
          double sVolume = 4.0;
          double sSuccess = 4.0; 
          double sRevenue = 4.0;
          double sLoyalty = 4.0; 
          double sRating = uiRating > 0 ? uiRating : 4.0;

          int completedCount = 0;
          int cancelledCount = 0;
          int actualLen = 0;
          
          final Map<String, int> farmerOccurrences = {};

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            actualLen = snapshot.data!.docs.length;
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status']?.toString() ?? "").toLowerCase();
              final fId = data['farmerId']?.toString() ?? "";

              if (status == 'completed') completedCount++;
              if (status == 'cancelled') cancelledCount++;

              if (fId.isNotEmpty) {
                farmerOccurrences[fId] = (farmerOccurrences[fId] ?? 0) + 1;
              }
            }

            // --- TÍNH TOÁN ĐIỂM SỐ ---
            
            // 1. Điểm Khối lượng (Volume)
            int totalForCalc = max(actualLen, uiTotalBookings);
            if (totalForCalc > 0) {
              sVolume = (totalForCalc / 10.0) * 5.0;
              if (sVolume > 5.0) sVolume = 5.0;
              if (sVolume < 2.5) sVolume = 2.5; 
            }

            // 2. Điểm Thành công (Success Rate)
            final int finishedCount = completedCount + cancelledCount;
            if (finishedCount > 0) {
              sSuccess = (completedCount / finishedCount) * 5.0;
              if (sSuccess < 3.0) sSuccess = 3.0;
            } else if (actualLen > 0) {
              // Nếu có ca nhưng chưa ca nào kết thúc (đang pending) thì để 4.0
              sSuccess = 4.0;
            }

            // 3. Điểm Doanh thu (Revenue)
            if (uiTotalRevenue > 0) {
              sRevenue = (uiTotalRevenue / 2000000.0) * 5.0;
              if (sRevenue > 5.0) sRevenue = 5.0;
              if (sRevenue < 3.0) sRevenue = 3.0;
            }

            // 4. Điểm Khách quen (Loyalty/Retention)
            // Tính số lượng khách hàng quay lại từ lần 2 trở lên
            int repeatedFarmers = farmerOccurrences.values.where((count) => count > 1).length;
            if (actualLen > 0) {
              sLoyalty = 3.5 + (repeatedFarmers * 0.5); // Mỗi khách quen +0.5 điểm
              if (sLoyalty > 5.0) sLoyalty = 5.0;
            }
          }

          List<double> localRadarValues = [sVolume, sSuccess, sRevenue, sLoyalty, sRating];

          // 2. Giao diện Vẽ Biểu đồ
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 250,
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
                      : RadarChart(
                    RadarChartData(
                      radarShape: RadarShape.polygon,
                      tickCount: 5,
                      ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
                      gridBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1.5),
                      tickBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                      titlePositionPercentageOffset: 0.2,
                      getTitle: (index, angle) {
                        return RadarChartTitle(
                          text: _radarLabels[index],
                          angle: 0,
                        );
                      },
                      titleTextStyle: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w900),
                      dataSets: [
                        RadarDataSet(
                          fillColor: const Color(0xFF6A11CB).withValues(alpha: 0.15),
                          borderColor: const Color(0xFF6A11CB),
                          entryRadius: 4,
                          dataEntries: localRadarValues.map((v) => RadarEntry(value: v)).toList(),
                          borderWidth: 2.5,
                        ),
                      ],
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A11CB).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF6A11CB)),
                      const SizedBox(width: 8),
                      Text(
                        snapshot.data?.docs.isEmpty ?? true 
                          ? "Hãy thực hiện ca đầu tiên để AI phân tích"
                          : "Đã hoàn thành: $completedCount ca | Khách quen: ${farmerOccurrences.values.where((c) => c > 1).length} người",
                        style: TextStyle(color: const Color(0xFF6A11CB), fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        }
    );
  }


  // ─── THỐNG KÊ HIỆU SUẤT TRUYỀN THỐNG ──────────────────────────────────────
  Widget _buildPerformanceStats(int totalBookings, double rating) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.people_alt_rounded, color: Colors.blue[600], size: 32),
                const SizedBox(height: 12),
                Text(totalBookings.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text("Tổng ca tư vấn", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
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
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
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
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const Text(" / 5.0", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Đánh giá TB", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
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
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                "TOP 3 KHÁCH HÀNG VIP",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
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
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: medalColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.emoji_events_rounded, color: medalColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone_rounded, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Text(c['phone'].toString().isNotEmpty ? c['phone'] : 'Chưa có SĐT', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text("${c['count']}", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w900, fontSize: 18)),
                          Text("lượt", style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.w900)),
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