import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'price_screen.dart';
import 'irrigation_screen.dart';
import 'pest_disease_screen.dart';
import 'expert_screen.dart';

// ==========================================
// GIAO DIỆN CHÍNH (HOME SCREEN) V3.5
// ==========================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Trợ Lý Sầu Riêng Pro v3.5"),
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
                child: _buildWelcomeCard(user?.email),
              ),

              const SizedBox(height: 16),

              // 🔴 THÔNG ĐIỆP CHIA SẺ VỚI BÀ CON ĐẮK LẮK
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
                                  "🌧️ Chia sẻ với bà con Đắk Lắk",
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
                              "Gửi chút nắng ấm từ phương xa về với Đắk Lắk yêu thương. Xin được san sẻ những khó khăn, mất mát mà bà con đang phải gánh chịu. Mong mọi người hãy thật vững tâm, giữ gìn sức khỏe. Cầu chúc bình an đến với từng nếp nhà, bão lũ rồi sẽ tan, ngày mai trời lại sáng! 💪",
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
              const SizedBox(height: 20),
            ],
          ),
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
            label: "Hỏi đáp chuyên gia",
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpertScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET PHÂN TÍCH THÔNG MINH V3.5
// ==========================================
class ProWeatherCardV35 extends StatefulWidget {
  const ProWeatherCardV35({super.key});

  @override
  State<ProWeatherCardV35> createState() => _ProWeatherCardV35State();
}

class _ProWeatherCardV35State extends State<ProWeatherCardV35> {
  late Future<Map<String, dynamic>> _dataFuture;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

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
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return jsonResponse;
      } else {
        throw Exception('Server trả về lỗi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không kết nối được Server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.green[700]),
                const SizedBox(height: 16),
                const Text("🧠 Bộ não AI v3.5 đang phân tích...", style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                Text("Tích hợp kiến thức VietGAP", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_off, color: Colors.red[700], size: 48),
                const SizedBox(height: 12),
                const Text("Mất kết nối với Bộ Não AI v3.5", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text("Kiểm tra Google Colab hoặc Link Ngrok", style: TextStyle(fontSize: 13, color: Colors.grey[700]), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text("Lỗi: ${snapshot.error}", style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Thử lại"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final List<dynamic> listData = data['du_lieu'] ?? [];
        final String thoiGian = data['thoi_gian'] ?? '';
        final String phienBan = data['phien_ban'] ?? '3.5';
        final String canhBaoDacBiet = data['canh_bao_dac_biet'] ?? '';

        if (listData.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber[700], size: 48),
                const SizedBox(height: 12),
                const Text("Chưa có dữ liệu phân tích", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Tải lại"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh trạng thái
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text("v$phienBan", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[700])),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.update, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(child: Text("Cập nhật: $thoiGian", style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                  TextButton.icon(
                    onPressed: refreshData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Làm mới"),
                    style: TextButton.styleFrom(foregroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ],
              ),
            ),

            if (canhBaoDacBiet.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          canhBaoDacBiet,
                          style: TextStyle(fontSize: 12, color: Colors.blue[900], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              height: 620,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: listData.length,
                itemBuilder: (context, index) => _buildSmartCardV35(listData[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmartCardV35(dynamic item) {
    String khuVuc = item['khu_vuc'] ?? 'N/A';
    double nhietDo = (item['nhiet_do'] as num?)?.toDouble() ?? 0.0;
    double nhietDoMax = (item['nhiet_do_max'] as num?)?.toDouble() ?? 0.0;
    double nhietDoMin = (item['nhiet_do_min'] as num?)?.toDouble() ?? 0.0;
    double doAm = (item['do_am'] as num?)?.toDouble() ?? 0.0;
    double gio = (item['gio'] as num?)?.toDouble() ?? 0.0;
    int may = (item['may'] as num?)?.toInt() ?? 0;
    double apSuat = (item['ap_suat'] as num?)?.toDouble() ?? 0.0;
    String moTa = item['mo_ta'] ?? '';
    String iconThoiTiet = item['icon_thoi_tiet'] ?? '01d';
    double mua1h = (item['mua_1h'] as num?)?.toDouble() ?? 0.0;
    double mua3h = (item['mua_3h'] as num?)?.toDouble() ?? 0.0;
    int caoDo = (item['cao_do'] as num?)?.toInt() ?? 0;

    // 🔴 DỮ LIỆU MỚI V3.5
    int chiSoLuLut = (item['chi_so_nguy_co_lu_lut'] as num?)?.toInt() ?? 0;
    int chiSoNam = (item['chi_so_nguy_co_nam'] as num?)?.toInt() ?? 0;
    int chiSoStress = (item['chi_so_stress_nhiet'] as num?)?.toInt() ?? 0;
    String giaiDoan = item['giai_doan_sinh_truong'] ?? 'N/A';
    String mucDoTongThe = item['muc_do_tong_the'] ?? 'an_toan';

    String mauSacApp = item['mau_sac_app'] ?? 'green';
    Color themeColor = _getThemeColor(mauSacApp);

    // ƯU TIÊN MÀU ĐỎ NẾU CÓ LŨ LỤT
    if (chiSoLuLut >= 70) {
      themeColor = Colors.red;
    } else if (chiSoLuLut >= 50) {
      themeColor = Colors.orange;
    }

    List<dynamic> canhBaoList = item['danh_sach_canh_bao'] ?? [];
    List<dynamic> canhBao24h = item['canh_bao_24h_toi'] ?? [];
    Map<String, dynamic> keHoach = item['ke_hoach_hanh_dong'] ?? {};
    List<dynamic> duBao3Moc = item['du_bao_3_moc_toi'] ?? [];

    return Container(
      width: 370,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withOpacity(0.4), width: 2.5),
        boxShadow: [
          BoxShadow(color: themeColor.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // === HEADER ===
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor.withOpacity(0.2), themeColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Image.network(
                      "https://openweathermap.org/img/wn/$iconThoiTiet@2x.png",
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.cloud, size: 60, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  khuVuc,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Icon(Icons.terrain, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text("${caoDo}m", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(moTa, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                                child: Text(giaiDoan, style: TextStyle(fontSize: 11, color: Colors.blue[900], fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getMucDoColor(mucDoTongThe).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _getMucDoColor(mucDoTongThe)),
                                ),
                                child: Text(
                                  _getMucDoText(mucDoTongThe),
                                  style: TextStyle(fontSize: 10, color: _getMucDoColor(mucDoTongThe), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("$nhietDo°C", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeColor)),
                        Text("$doAm% ẩm", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text("${nhietDoMin}°~${nhietDoMax}°", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Thông tin bổ sung
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniInfo(Icons.water_drop, "${mua1h}mm/h", "Mưa 1h"),
                    _buildMiniInfo(Icons.air, "${gio}m/s", "Gió"),
                    _buildMiniInfo(Icons.compress, "${apSuat}hPa", "Áp suất"),
                    _buildMiniInfo(Icons.cloud, "$may%", "Mây"),
                  ],
                ),

                // 🔴 CHỈ SỐ NGUY CƠ V3.5
                const SizedBox(height: 12),
                Column(
                  children: [
                    // LŨ LỤT - ƯU TIÊN SỐ 1
                    _buildRiskIndicator("🔴 LŨ LỤT", chiSoLuLut, Icons.water_damage, Colors.red),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildRiskIndicator("Nấm", chiSoNam, Icons.coronavirus, Colors.orange)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildRiskIndicator("Nhiệt", chiSoStress, Icons.local_fire_department, Colors.red)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // === BODY - CẢNH BÁO CHI TIẾT ===
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canhBaoList.isNotEmpty) ...[
                    const Text("📋 Tình hình hiện tại", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    ...canhBaoList.map((cb) => _buildAlertCard(cb)).toList(),
                  ],

                  if (canhBao24h.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event_note, size: 18, color: Colors.amber[900]),
                              const SizedBox(width: 6),
                              Text("Dự báo 24-72h tới", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900])),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...canhBao24h.map((cb) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("• ", style: TextStyle(fontSize: 18)),
                                Expanded(child: Text("${cb['noi_dung']}\n→ ${cb['hanh_dong']}", style: const TextStyle(fontSize: 12, height: 1.4))),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  ],

                  if (duBao3Moc.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildForecastSection(duBao3Moc),
                  ],

                  if (keHoach.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildActionPlan(keHoach),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRiskIndicator(String label, int value, IconData icon, MaterialColor color) {
    MaterialColor bgColor = value >= 70 ? Colors.red : (value >= 50 ? Colors.orange : (value >= 30 ? Colors.amber : Colors.green));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor[200]!, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: bgColor[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, color: bgColor[900], fontWeight: FontWeight.w600)),
          ),
          Text("$value", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: bgColor[700])),
          Text("/100", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAlertCard(dynamic cb) {
    String tieuDe = cb['tieu_de'] ?? '';
    String noiDung = cb['noi_dung'] ?? '';
    String hanhDong = cb['hanh_dong'] ?? '';
    String icon = cb['icon'] ?? 'info';
    String mucDo = cb['muc_do'] ?? '';

    bool isFlood = icon == 'flood' || tieuDe.contains('LŨ LỤT');
    bool isKhanCap = mucDo.contains('khan_cap') || tieuDe.contains('🔴');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFlood ? Colors.red[50] : (isKhanCap ? Colors.orange[50] : Colors.grey[50]),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _getIconColor(icon), width: isFlood ? 6 : 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconData(icon), size: 22, color: _getIconColor(icon)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tieuDe,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isFlood ? 15 : 14,
                    color: isFlood ? Colors.red[900] : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (noiDung.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(noiDung, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
          if (hanhDong.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hanhDong,
                      style: TextStyle(fontSize: 12, color: Colors.blue[900], fontWeight: FontWeight.w500, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForecastSection(List<dynamic> duBao) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: Colors.purple[900]),
              const SizedBox(width: 6),
              Text("Dự báo 9h tới", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[900])),
            ],
          ),
          const SizedBox(height: 10),
          ...duBao.take(3).map((item) {
            String time = item['time']?.toString().substring(11, 16) ?? '';
            double temp = (item['temp'] as num?)?.toDouble() ?? 0;
            int humidity = (item['humidity'] as num?)?.toInt() ?? 0;
            double rainProb = (item['rain_prob'] as num?)?.toDouble() ?? 0;
            String desc = item['description'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[100]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple[900])),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$temp°C • $humidity% ẩm", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                  if (rainProb > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop, size: 12, color: Colors.blue[700]),
                          const SizedBox(width: 2),
                          Text("${rainProb.toInt()}%", style: TextStyle(fontSize: 10, color: Colors.blue[900], fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionPlan(Map<String, dynamic> keHoach) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, size: 18, color: Colors.green[900]),
              const SizedBox(width: 6),
              Text("Kế hoạch hành động", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900])),
            ],
          ),
          const SizedBox(height: 10),
          if (keHoach['uu_tien_cao'] != null && (keHoach['uu_tien_cao'] as List).isNotEmpty) ...[
            _buildPrioritySection("🔴 Khẩn cấp (Hôm nay)", keHoach['uu_tien_cao'], Colors.red),
          ],
          if (keHoach['trung_binh'] != null && (keHoach['trung_binh'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPrioritySection("🟡 Trung bình (Tuần này)", keHoach['trung_binh'], Colors.orange),
          ],
          if (keHoach['dai_han'] != null && (keHoach['dai_han'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPrioritySection("🟢 Dài hạn", keHoach['dai_han'], Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildPrioritySection(String title, dynamic items, MaterialColor color) {
    List<dynamic> list = items is List ? items : [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color[700])),
        const SizedBox(height: 4),
        ...list.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• ", style: TextStyle(color: color[700])),
              Expanded(child: Text(item.toString(), style: const TextStyle(fontSize: 12, height: 1.3))),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Color _getThemeColor(String colorName) {
    switch (colorName) {
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'yellow': return Colors.amber;
      default: return Colors.green;
    }
  }

  Color _getMucDoColor(String mucDo) {
    if (mucDo.contains('khan_cap')) return Colors.red;
    if (mucDo.contains('nguy_hiem')) return Colors.orange;
    if (mucDo.contains('canh_bao')) return Colors.amber;
    return Colors.green;
  }

  String _getMucDoText(String mucDo) {
    if (mucDo.contains('khan_cap_lu')) return 'KHẨN CẤP LŨ';
    if (mucDo.contains('khan_cap')) return 'KHẨN CẤP';
    if (mucDo.contains('nguy_hiem_lu')) return 'NGUY HIỂM LŨ';
    if (mucDo.contains('nguy_hiem')) return 'NGUY HIỂM';
    if (mucDo.contains('canh_bao')) return 'CẢNH BÁO';
    return 'AN TOÀN';
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'flood': return Icons.water_damage;
      case 'warning': return Icons.warning_amber_rounded;
      case 'water_drop': return Icons.water_drop;
      case 'sunny': return Icons.sunny;
      case 'wb_sunny': return Icons.wb_sunny;
      case 'air': return Icons.air;
      case 'ac_unit': return Icons.ac_unit;
      case 'check_circle': return Icons.check_circle_outline;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'event': return Icons.event_note;
      case 'visibility': return Icons.visibility;
      case 'medical_services': return Icons.medical_services;
      case 'eco': return Icons.eco;
      default: return Icons.info_outline;
    }
  }

  Color _getIconColor(String iconName) {
    if (iconName == 'check_circle' || iconName == 'eco') return Colors.green;
    if (iconName == 'flood' || iconName == 'warning' || iconName == 'sunny' || iconName == 'local_fire_department') {
      return Colors.red;
    }
    if (iconName == 'medical_services') return Colors.blue;
    return Colors.orange;
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