import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// ==========================================
// GIAO DIỆN CHÍNH (HOME SCREEN) V3.0
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
        title: const Text("Trợ Lý Sầu Riêng Pro v3.0"),
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
      body: SingleChildScrollView(
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
                      "Phân Tích Thông Minh AI v3.0",
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
                          "Lũ lụt",
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

            // 👇 WIDGET CHÍNH - PHÂN TÍCH V3.0
            const ProWeatherCardV3(),

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
            _buildGridMenu(),
            const SizedBox(height: 20),
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

  Widget _buildGridMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: const [
          _FeatureCard(icon: Icons.trending_up, label: "Giá Nông Sản", color: Colors.amber),
          _FeatureCard(icon: Icons.water_drop_outlined, label: "Lịch Tưới", color: Colors.blue),
          _FeatureCard(icon: Icons.bug_report_outlined, label: "Tra cứu sâu bệnh", color: Colors.red),
          _FeatureCard(icon: Icons.forum_outlined, label: "Hỏi đáp chuyên gia", color: Colors.purple),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET PHÂN TÍCH THÔNG MINH V3.0
// ==========================================
class ProWeatherCardV3 extends StatefulWidget {
  const ProWeatherCardV3({super.key});

  @override
  State<ProWeatherCardV3> createState() => _ProWeatherCardV3State();
}

class _ProWeatherCardV3State extends State<ProWeatherCardV3> {
  late Future<Map<String, dynamic>> _dataFuture;

  // ⚠️ THAY LINK NGROK MỚI
  final String pythonApiUrl = 'https://arica-baldish-consuelo.ngrok-free.dev/api/phan-tich-sau-rieng';

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchProData();
  }

  Future<Map<String, dynamic>> fetchProData() async {
    try {
      final response = await http.get(
        Uri.parse(pythonApiUrl),
        headers: {
          "ngrok-skip-browser-warning": "true",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));

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
                const Text("Đang phân tích lũ lụt...", style: TextStyle(fontSize: 14, color: Colors.grey)),
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
                const Text("Mất kết nối với Bộ Não AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text("Kiểm tra Google Colab hoặc Link Ngrok", style: TextStyle(fontSize: 13, color: Colors.grey[700]), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _dataFuture = fetchProData()),
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

        if (listData.isEmpty) return const Center(child: Text("Chưa có dữ liệu"));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.update, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text("Cập nhật: $thoiGian", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _dataFuture = fetchProData()),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Làm mới"),
                    style: TextButton.styleFrom(foregroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 580,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: listData.length,
                itemBuilder: (context, index) => _buildSmartCardV3(listData[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmartCardV3(dynamic item) {
    String khuVuc = item['khu_vuc'];
    double nhietDo = (item['nhiet_do'] as num).toDouble();
    double doAm = (item['do_am'] as num).toDouble();
    String moTa = item['mo_ta'];
    String iconThoiTiet = item['icon_thoi_tiet'];

    // 🔴 DỮ LIỆU MỚI V3.0
    int chiSoLuLut = (item['chi_so_nguy_co_lu_lut'] as num).toInt();
    int chiSoNam = (item['chi_so_nguy_co_nam'] as num).toInt();
    int chiSoStress = (item['chi_so_stress_nhiet'] as num).toInt();
    String giaiDoan = item['giai_doan_sinh_truong'] ?? '';

    String mauSacApp = item['mau_sac_app'];
    Color themeColor = _getThemeColor(mauSacApp);

    // ƯU TIÊN MÀU ĐỎ NẾU CÓ LŨ LỤT
    if (chiSoLuLut >= 60) {
      themeColor = Colors.red;
    }

    List<dynamic> canhBaoList = item['danh_sach_canh_bao'] ?? [];
    List<dynamic> canhBao24h = item['canh_bao_24h_toi'] ?? [];
    Map<String, dynamic> keHoach = item['ke_hoach_hanh_dong'] ?? {};

    return Container(
      width: 360,
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
                    Image.network("https://openweathermap.org/img/wn/$iconThoiTiet@2x.png", width: 60, height: 60),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(khuVuc, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(moTa, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                            child: Text(giaiDoan, style: TextStyle(fontSize: 11, color: Colors.blue[900], fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("$nhietDo°C", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeColor)),
                        Text("$doAm% ẩm", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),

                // 🔴 CHỈ SỐ NGUY CƠ V3.0 - THÊM LŨ LỤT
                const SizedBox(height: 12),
                Column(
                  children: [
                    // LŨ LỤT - ƯU TIÊN SỐ 1
                    _buildRiskIndicator("🔴 NGUY CƠ LŨ LỤT", chiSoLuLut, Icons.water_damage, Colors.red),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildRiskIndicator("Nấm", chiSoNam, Icons.water_drop, Colors.orange)),
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
                                Expanded(child: Text("${cb['noi_dung']}\n→ ${cb['hanh_dong']}", style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
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
    String icon = cb['icon'] ?? 'info';
    bool isFlood = icon == 'flood' || (cb['tieu_de'] ?? '').contains('LŨ LỤT');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFlood ? Colors.red[50] : Colors.grey[50],
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
              Expanded(child: Text(cb['tieu_de'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isFlood ? 15 : 14))),
            ],
          ),
          const SizedBox(height: 6),
          Text(cb['noi_dung'] ?? '', style: const TextStyle(fontSize: 13)),
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
                    cb['hanh_dong'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900], fontWeight: FontWeight.w500, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
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
              Expanded(child: Text(item.toString(), style: const TextStyle(fontSize: 12))),
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
      default: return Icons.info_outline;
    }
  }

  Color _getIconColor(String iconName) {
    if (iconName == 'check_circle') return Colors.green;
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

  const _FeatureCard({required this.icon, required this.label, required this.color});

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
          onTap: () {
            // TODO: Navigate to feature
          },
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