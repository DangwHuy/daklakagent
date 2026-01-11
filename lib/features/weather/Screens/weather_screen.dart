import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =========, required String initialLocation, required String initialLocation, required String initialLocation=================================
// 1. MÀN HÌNH CHÍNH (WRAPPER)
// ==========================================
class WeatherScreen extends StatelessWidget {
  final String? initialLocation;

  // 2. SỬA DÒNG NÀY (Thêm this.initialLocation vào trong ngoặc)
  const WeatherScreen({super.key, this.initialLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('CHI TIẾT THỜI TIẾT'),
        backgroundColor: Colors.green[800],
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // WIDGET CHÍNH CÓ CHỨC NĂNG CHỌN KHU VỰC
            ProWeatherCardV35(initialLocation: initialLocation),

            const SizedBox(height: 24),

            // WIDGET PHỤ: CẨM NANG VIETGAP
            const _VietGapFastGuide(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. WIDGET LOGIC: PRO WEATHER CARD V3.5
// ==========================================
class ProWeatherCardV35 extends StatefulWidget {
  final String? initialLocation;

  // 2. SỬA DÒNG NÀY
  const ProWeatherCardV35({super.key, this.initialLocation});

  @override
  State<ProWeatherCardV35> createState() => _ProWeatherCardV35State();
}

class _ProWeatherCardV35State extends State<ProWeatherCardV35> {
  late Future<Map<String, dynamic>> _dataFuture;

  // Biến lưu khu vực đang chọn
  String? _selectedLocationName;

  // ⚠️⚠️⚠️ THAY LINK NGROK MỚI CỦA BẠN VÀO ĐÂY
  final String pythonApiUrl = 'https://arica-baldish-consuelo.ngrok-free.dev/api/phan-tich-sau-rieng';

  @override
  void initState() {
    super.initState();
    _selectedLocationName = widget.initialLocation;
    _dataFuture = fetchProData();
  }

  Future<void> refreshData() async {
    setState(() {
      _dataFuture = fetchProData();
      _selectedLocationName = null; // Reset lựa chọn khi tải lại
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
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không kết nối được AI: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        // --- 1. LOADING ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 300,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.green[700]),
                const SizedBox(height: 16),
                const Text("Đang tải dữ liệu các vùng trồng...", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // --- 2. ERROR ---
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
                Icon(Icons.wifi_off, color: Colors.red[700], size: 40),
                const SizedBox(height: 10),
                Text("Lỗi: ${snapshot.error}", textAlign: TextAlign.center),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: refreshData, child: const Text("Thử lại")),
              ],
            ),
          );
        }

        // --- 3. DATA READY ---
        final data = snapshot.data!;
        final List<dynamic> listData = data['du_lieu'] ?? [];

        if (listData.isEmpty) return const Center(child: Text("Không có dữ liệu khu vực."));

        // Logic chọn mặc định khu vực đầu tiên nếu chưa chọn
        if (_selectedLocationName == null && listData.isNotEmpty) {
          _selectedLocationName = listData[0]['khu_vuc'];
        }

        // Lấy dữ liệu của khu vực đang chọn
        final selectedArea = listData.firstWhere(
              (element) => element['khu_vuc'] == _selectedLocationName,
          orElse: () => listData[0],
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // === MENU CHỌN KHU VỰC (DROPDOWN) ===
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLocationName,
                    isExpanded: true,
                    icon: const Icon(Icons.location_on, color: Colors.green),
                    items: listData.map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item['khu_vuc'],
                        child: Text(
                          item['khu_vuc'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLocationName = newValue;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // === HIỂN THỊ CHI TIẾT KHU VỰC ĐÃ CHỌN ===
              // Không dùng ListView nữa, hiển thị trực tiếp 1 cái
              _buildSmartCardV35(selectedArea),

              const SizedBox(height: 10),

              // Nút cập nhật nhỏ bên dưới
              TextButton.icon(
                onPressed: refreshData,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text("Cập nhật lúc: ${data['thoi_gian']}"),
              )
            ],
          ),
        );
      },
    );
  }

  // --- HÀM XÂY DỰNG THẺ THÔNG MINH (Đã chỉnh sửa để hiện full màn hình) ---
  Widget _buildSmartCardV35(dynamic item) {
    String khuVuc = item['khu_vuc'] ?? 'N/A';
    double nhietDo = (item['nhiet_do'] as num?)?.toDouble() ?? 0.0;
    double doAm = (item['do_am'] as num?)?.toDouble() ?? 0.0;
    String moTa = item['mo_ta'] ?? '';
    String iconThoiTiet = item['icon_thoi_tiet'] ?? '01d';

    int chiSoLuLut = (item['chi_so_nguy_co_lu_lut'] as num?)?.toInt() ?? 0;
    int chiSoNam = (item['chi_so_nguy_co_nam'] as num?)?.toInt() ?? 0;
    int chiSoStress = (item['chi_so_stress_nhiet'] as num?)?.toInt() ?? 0;

    // Màu chủ đạo
    Color themeColor = _getThemeColor(item['mau_sac_app'] ?? 'green');
    if (chiSoLuLut >= 70) themeColor = Colors.red;

    return Container(
      width: double.infinity, // Full chiều ngang
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(color: themeColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          // 1. Header (Nhiệt độ & Thời tiết)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor.withOpacity(0.2), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(khuVuc, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(moTa.toUpperCase(), style: TextStyle(color: Colors.grey[700], fontSize: 13, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.water_drop, size: 14, color: Colors.blue[700]),
                        Text(" $doAm% ẩm", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                Column(
                  children: [
                    Image.network(
                      "https://openweathermap.org/img/wn/$iconThoiTiet@2x.png",
                      width: 60, height: 60,
                      errorBuilder: (_,__,___) => const Icon(Icons.cloud, size: 60),
                    ),
                    Text("$nhietDo°C", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: themeColor)),
                  ],
                ),
              ],
            ),
          ),

          // 2. Dashboard Chỉ số (3 ô tròn)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildRiskGauge("Lũ lụt", chiSoLuLut, Icons.tsunami, Colors.red)),
                const SizedBox(width: 10),
                Expanded(child: _buildRiskGauge("Nấm", chiSoNam, Icons.coronavirus, Colors.orange)),
                const SizedBox(width: 10),
                Expanded(child: _buildRiskGauge("Nhiệt", chiSoStress, Icons.thermostat, Colors.deepOrange)),
              ],
            ),
          ),

          // 3. Nội dung Cảnh báo & Kế hoạch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cảnh báo
                if (item['danh_sach_canh_bao'] != null)
                  ...(item['danh_sach_canh_bao'] as List).map((cb) => _buildAlertCard(cb)).toList(),

                const SizedBox(height: 16),

                // Kế hoạch hành động
                if (item['ke_hoach_hanh_dong'] != null)
                  _buildActionPlan(item['ke_hoach_hanh_dong']),

                const SizedBox(height: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- CÁC WIDGET CON (ĐÃ LÀM ĐẸP) ---

  Widget _buildRiskGauge(String label, int value, IconData icon, MaterialColor color) {
    bool isHighRisk = value >= 50;
    return Column(
      children: [
        Container(
          height: 60, width: 60,
          decoration: BoxDecoration(
            color: isHighRisk ? color[50] : Colors.green[50],
            shape: BoxShape.circle,
            border: Border.all(color: isHighRisk ? color : Colors.green, width: 2),
          ),
          child: Icon(icon, color: isHighRisk ? color : Colors.green, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text("$value%", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isHighRisk ? color : Colors.black)),
      ],
    );
  }

  Widget _buildAlertCard(dynamic cb) {
    String iconName = cb['icon'] ?? 'info';
    Color color = _getIconColor(iconName);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconData(iconName), size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(cb['tieu_de'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
            ],
          ),
          const SizedBox(height: 6),
          Text(cb['noi_dung'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                const Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(child: Text(cb['hanh_dong'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[800]))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionPlan(Map<String, dynamic> keHoach) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.playlist_add_check, size: 24, color: Colors.green[800]),
              const SizedBox(width: 8),
              Text("HÀNH ĐỘNG CỤ THỂ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900], fontSize: 16)),
            ],
          ),
          const Divider(),
          if (keHoach['uu_tien_cao'] != null)
            _buildPriorityList("LÀM NGAY HÔM NAY:", keHoach['uu_tien_cao'], Colors.red),
          if (keHoach['trung_binh'] != null)
            _buildPriorityList("KẾ HOẠCH TUẦN NÀY:", keHoach['trung_binh'], Colors.orange),
        ],
      ),
    );
  }

  Widget _buildPriorityList(String title, dynamic items, MaterialColor color) {
    List list = items is List ? items : [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color[700])),
          const SizedBox(height: 4),
          ...list.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("•", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(child: Text(e.toString(), style: const TextStyle(fontSize: 13))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  // --- UTILS ---
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
      case 'flood': return Icons.tsunami;
      case 'warning': return Icons.warning_amber_rounded;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'medical_services': return Icons.medical_services;
      case 'eco': return Icons.eco;
      default: return Icons.info;
    }
  }

  Color _getIconColor(String iconName) {
    if (['flood', 'warning', 'local_fire_department'].contains(iconName)) return Colors.red;
    if (['eco', 'check_circle'].contains(iconName)) return Colors.green;
    if (iconName == 'medical_services') return Colors.blue;
    return Colors.orange;
  }
}

// ==========================================
// 3. WIDGET CẨM NANG (Phụ trợ)
// ==========================================
class _VietGapFastGuide extends StatelessWidget {
  const _VietGapFastGuide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📘 Tra cứu nhanh VietGAP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildGuideItem(Icons.water, "Ngập úng", "Rút nước > Rải vôi > Tưới thuốc nấm"),
          _buildGuideItem(Icons.bug_report, "Phòng bệnh", "Dọn cỏ, tỉa cành thông thoáng"),
        ],
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String title, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        dense: true,
      ),
    );
  }
}
