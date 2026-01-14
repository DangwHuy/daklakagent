import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'price_screen.dart';
import 'irrigation_screen.dart';
import 'pest_disease_screen.dart';
import 'expert_screen.dart' hide AnalyzeDiseaseScreen;
import 'FarmerView.dart';


// [THÊM MỚI] Import màn hình Chat AI
import 'package:daklakagent/features/ai/screens/ai_chat.dart';
import 'package:daklakagent/features/weather/Screens/weather_screen.dart';
import 'disease.dart';
// ==========================================
// GIAO DIỆN CHÍNH (HOME SCREEN) V3.6 (AI UPDATE)
// ==========================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  // [THÊM MỚI] Hàm mở màn hình Chat AI
  void _openAiChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AiChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],

      // [THÊM MỚI] Nút nổi AI (Floating Action Button)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAiChat(context),
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text("Hỏi AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      appBar: AppBar(
        title: const Text("Trợ Lý Của Bà Con"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _handleSignOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger refresh for weather widget
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: Colors.green[700],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                // [CẬP NHẬT] Đổi child thành Column để chứa thêm Thanh tìm kiếm AI
                child: Column(
                  children: [
                    _buildWelcomeCard(user?.email),
                    const SizedBox(height: 20),
                    // [THÊM MỚI] Thanh tìm kiếm AI
                    _buildAiSearchBar(context),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 🔴 THÔNG ĐIỆP CHIA SẺ VỚI BÀ CON ĐẮK LẮK (GIỮ NGUYÊN)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[50]!, Colors.orange[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[200]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red[300]!, width: 2),
                        ),
                        child: Icon(Icons.favorite, color: Colors.red[600], size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Chúc bà con năm mới bội thu!",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              " và Cà phê vẫn giữ giá tốt. Trời Đắk Lắk đang se lạnh, bà con nhớ giữ ấm và thăm vườn thường xuyên nhé. Vụ mùa bội thu đang chờ phía trước! 🌱",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tiêu đề phân tích
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: Colors.green[700], size: 28),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Phân Tích Thông Minh AI v3.5",
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_damage, color: Colors.red[700], size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "Siêu thông minh",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 👇 WIDGET CHÍNH - PHÂN TÍCH V3.5
              const ProWeatherCardV35(),

              const SizedBox(height: 24),

              // Tiện ích
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.apps, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    const Text(
                      "Tiện ích nông nghiệp",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              _buildGridMenu(context),
              const SizedBox(height: 80), // [CẬP NHẬT] Thêm padding dưới để không bị nút FAB che
            ],
          ),
        ),
      ),
    );
  }

  // [THÊM MỚI] Widget Thanh tìm kiếm AI
  Widget _buildAiSearchBar(BuildContext context) {
    return InkWell(
      onTap: () => _openAiChat(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.green[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Hỏi AI: 'Giá sầu riêng hôm nay?'",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic, color: Colors.blue[700], size: 20),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String? email) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Xin chào bà con,",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                email ?? "Nhà nông 4.0",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _FeatureCard(
            icon: Icons.trending_up,
            label: "Giá Nông Sản",
            color: Colors.amber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PriceScreen()),
              );
            },
          ),
          _FeatureCard(
            icon: Icons.water_drop_outlined,
            label: "Lịch Tưới",
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IrrigationScreen()),
              );
            },
          ),
          _FeatureCard(
            icon: Icons.bug_report_outlined,
            label: "Tra cứu sâu bệnh",
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PestDiseaseScreen()),
              );
            },
          ),
          _FeatureCard(
            icon: Icons.forum_outlined,
            label: "AI Phân Tích Chuyên Sâu",
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpertScreen()),
              );
            },
          ),
          _FeatureCard(
            icon: Icons.calendar_month_outlined, // Icon lịch
            label: "Đặt lịch Chuyên gia",
            color: Colors.teal, // Màu khác biệt
            onTap: () {
              // Chuyển sang màn hình Tìm & Đặt lịch
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FindExpertScreen()),
              );
            },
          ),
          _FeatureCard(
            icon: Icons.camera_alt_outlined, // Icon camera/phân tích ảnh
            label: "Phân tích ảnh bệnh",
            color: Colors.green, // Gợi ý: màu xanh nông nghiệp
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyzeDiseaseScreen(),
                  ),
                );
              },
          ),
        ],
      ),
    );
  }
}

class ProWeatherCardV35 extends StatefulWidget {
  const ProWeatherCardV35({super.key});

  @override
  State<ProWeatherCardV35> createState() => _ProWeatherCardV35State();
}

class _ProWeatherCardV35State extends State<ProWeatherCardV35> {
  late Future<Map<String, dynamic>> _dataFuture;

  // ⚠️ THAY LINK NGROK MỚI CỦA BẠN Ở ĐÂY
  final String pythonApiUrl = 'https://arica-baldish-consuelo.ngrok-free.dev/api/phan-tich-sau-rieng';

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchProData();
  }

  Future<void> refreshData() async {
    setState(() {
      _dataFuture = fetchProData();
    });
  }

  Future<Map<String, dynamic>> fetchProData() async {
    try {
      final response = await http.get(
        Uri.parse(pythonApiUrl),
        headers: {
          "ngrok-skip-browser-warning": "true",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: ElevatedButton.icon(
              onPressed: refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text("Thử lại"),
            ),
          );
        }

        final data = snapshot.data!;
        final List<dynamic> listData = data['du_lieu'] ?? [];

        if (listData.isEmpty) return const Text("Không có dữ liệu");

        // Hiển thị danh sách các thẻ rút gọn theo chiều ngang
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Giúp các thẻ căn đỉnh
            children: listData.map((item) => _buildSmartCardShort(item)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSmartCardShort(dynamic item) {
    // --- Lấy dữ liệu ---
    String khuVuc = item['khu_vuc'] ?? 'N/A';
    double nhietDo = (item['nhiet_do'] as num?)?.toDouble() ?? 0.0;
    double doAm = (item['do_am'] as num?)?.toDouble() ?? 0.0;
    double gio = (item['gio'] as num?)?.toDouble() ?? 0.0;
    int may = (item['may'] as num?)?.toInt() ?? 0;
    String moTa = item['mo_ta'] ?? '';
    String iconThoiTiet = item['icon_thoi_tiet'] ?? '01d';
    double mua1h = (item['mua_1h'] as num?)?.toDouble() ?? 0.0;
    int caoDo = (item['cao_do'] as num?)?.toInt() ?? 0;

    int chiSoLuLut = (item['chi_so_nguy_co_lu_lut'] as num?)?.toInt() ?? 0;
    int chiSoNam = (item['chi_so_nguy_co_nam'] as num?)?.toInt() ?? 0;
    int chiSoStress = (item['chi_so_stress_nhiet'] as num?)?.toInt() ?? 0;

    // --- LOGIC XÁC ĐỊNH MÀU SẮC VÀ TRẠNG THÁI ---
    // Tìm chỉ số rủi ro cao nhất để quyết định màu
    int maxRisk = [chiSoLuLut, chiSoNam, chiSoStress].reduce((curr, next) => curr > next ? curr : next);

    Color statusColor = const Color(0xFF2E7D32); // Màu xanh lá đậm (Giống hình)
    String statusText = "Môi trường ổn định";
    IconData statusIcon = Icons.check_box;

    if (maxRisk >= 70) {
      statusColor = const Color(0xFFD32F2F); // Đỏ
      statusText = "Nguy hiểm (Chi tiết >)";
      statusIcon = Icons.warning;
    } else if (maxRisk >= 40) {
      statusColor = const Color(0xFFEF6C00); // Cam
      statusText = "Cảnh báo (Chi tiết >)";
      statusIcon = Icons.info;
    } else {
      statusText = "Môi trường ổn định (Chi tiết >)";
    }

    return Container(
      width: 340,
      margin: const EdgeInsets.only(right: 16),
      // ClipRRect để bo góc cho cả ảnh con bên trong
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Bo góc tổng thể thẻ
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === PHẦN TRÊN (Thông tin thời tiết) ===
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Dòng 1: Địa điểm (Giống hình 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.red[700], size: 20),
                      const SizedBox(width: 6),
                      Text("$khuVuc (${caoDo}m)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Dòng 2: Icon mây + Nhiệt độ + Mô tả (Căn giữa)
                  Column(
                    children: [
                      Image.network(
                        "https://openweathermap.org/img/wn/$iconThoiTiet@2x.png",
                        width: 80, height: 80,
                        errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 80, color: Colors.grey),
                      ),
                      Text("$nhietDo°C", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                      const SizedBox(height: 4),
                      Text(moTa, style: TextStyle(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 20),

                  // Dòng 3: 3 Thông số (Ẩm, Gió, Mưa) - Giống hình 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeatherStat(Icons.water_drop_outlined, "$doAm%", "(Ẩm)"),
                      Container(width: 1, height: 30, color: Colors.grey[300]), // Vách ngăn
                      _buildWeatherStat(Icons.air, "${gio}m/s", "(Gió)"),
                      Container(width: 1, height: 30, color: Colors.grey[300]), // Vách ngăn
                      _buildWeatherStat(Icons.cloud_queue, "${mua1h}mm", "(Mưa)"),
                    ],
                  ),
                ],
              ),
            ),

            // === PHẦN DƯỚI: THANH TRẠNG THÁI (MÀU XANH) ===
            // Thay thế hoàn toàn phần Lũ lụt/Nấm cũ
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeatherScreen(
                      // Lúc này chữ initialLocation sẽ hết báo đỏ
                      initialLocation: khuVuc,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity, // Full chiều ngang
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: statusColor, // Màu thay đổi theo mức độ nguy hiểm
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(19), // Bo góc dưới trùng với thẻ cha
                    bottomRight: Radius.circular(19),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    // Icon lấp lánh ở góc phải giống hình
                    const Icon(Icons.auto_awesome, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget con hiển thị thông số (Ẩm, Gió, Mưa)
  Widget _buildWeatherStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.black87),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // Widget con hiển thị dòng chi tiết trong Dialog
  Widget _buildRiskRow(String label, int value) {
    Color color = value > 50 ? Colors.red : Colors.green;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("$value/100", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Widget hiển thị Tag nhỏ (Nghỉ ngơi, Cảnh báo)
  Widget _buildTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 0.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color[800], fontWeight: FontWeight.bold)),
    );
  }

  // Widget thông tin nhỏ (Mưa, Gió...)
  Widget _buildMiniInfo(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }

  // Widget thẻ LŨ LỤT (To)
  Widget _buildRiskCardBig(String label, int value, IconData icon, MaterialColor color) {
    // Logic màu sắc: Nếu an toàn (thấp) thì màu xanh, cao thì màu đỏ
    Color bgColor = value < 30 ? Colors.green[50]! : Colors.red[50]!;
    Color borderColor = value < 30 ? Colors.green[200]! : Colors.red[200]!;
    Color iconColor = value < 30 ? Colors.green[700]! : Colors.red;
    Color dotColor = value < 30 ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[700]), // Icon nhà
          const SizedBox(width: 8),
          Icon(Icons.circle, size: 12, color: dotColor), // Chấm tròn màu
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "$value", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                TextSpan(text: "/100", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget thẻ Nấm/Nhiệt (Nhỏ)
  Widget _buildRiskCardSmall(String label, int value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color[50], // Màu nền nhạt theo theme
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color[200]!, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color[700]),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color[900])),
            ],
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "$value", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color[800])),
                TextSpan(text: "/100", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET THẺ CHỨC NĂNG
// ==========================================
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}