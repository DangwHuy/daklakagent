import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =========, required String initialLocation, required String initialLocation, required String initialLocation=================================
// 1. MÀN HÌNH CHÍNH (WRAPPER)
// ==========================================
class WeatherScreen extends StatefulWidget {
  final String? initialLocation;

  const WeatherScreen({super.key, this.initialLocation});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_showScrollTop) {
        setState(() => _showScrollTop = true);
      } else if (_scrollController.offset <= 200 && _showScrollTop) {
        setState(() => _showScrollTop = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Disable material 3 tint
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
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Chi tiết thời tiết",
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
      floatingActionButton: _showScrollTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Colors.green[600],
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            )
          : null,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // WIDGET CHÍNH CÓ CHỨC NĂNG CHỌN KHU VỰC
            ProWeatherCardV35(initialLocation: widget.initialLocation),

            const SizedBox(height: 50),
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
  bool _showDetails = false;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLocationName,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                    items: listData.map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item['khu_vuc'],
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              item['khu_vuc'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                            ),
                          ],
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

  // --- HÀM XÂY DỰNG THẺ THÔNG MINH (PHIÊN BẢN HIỆN ĐẠI) ---
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          // 1. Header (Nhiệt độ & Thời tiết)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 18, color: themeColor),
                        const SizedBox(width: 4),
                        Text(khuVuc, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                      ]
                    ),
                    const SizedBox(height: 6),
                    Text(moTa.toUpperCase(), style: TextStyle(color: Colors.grey[700], fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop, size: 16, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Text("Độ ẩm: $doAm%", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Image.network(
                      "https://openweathermap.org/img/wn/$iconThoiTiet@2x.png",
                      width: 70, height: 70,
                      errorBuilder: (_,__,___) => const Icon(Icons.cloud, size: 60),
                    ),
                    Text("${nhietDo.round()}°", style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: themeColor)),
                  ],
                ),
              ],
            ),
          ),

          // 2. Dashboard Chỉ số (3 ô vuông bo góc)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: _buildRiskGauge("Lũ lụt", chiSoLuLut, Icons.tsunami, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _buildRiskGauge("Nấm", chiSoNam, Icons.coronavirus, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildRiskGauge("Nhiệt", chiSoStress, Icons.thermostat, Colors.deepOrange)),
              ],
            ),
          ),

          // 3. Nội dung Cảnh báo & Kế hoạch (có thể Ẩn/Hiện)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                  icon: Icon(
                    _showDetails ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: themeColor,
                  ),
                  label: Text(
                    _showDetails ? "Thu gọn chi tiết" : "Xem chi tiết cảnh báo & kế hoạch",
                    style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: themeColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: !_showDetails
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // Cảnh báo
                            if (item['danh_sach_canh_bao'] != null)
                              ...(item['danh_sach_canh_bao'] as List).map((cb) => _buildAlertCard(cb)).toList(),

                            const SizedBox(height: 16),

                            // Kế hoạch hành động
                            if (item['ke_hoach_hanh_dong'] != null)
                              _buildActionPlan(item['ke_hoach_hanh_dong']),

                            const SizedBox(height: 10),
                          ],
                        ),
                ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isHighRisk ? color[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: isHighRisk ? color[600] : Colors.green[600], size: 30),
          const SizedBox(height: 8),
          Text("$value%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isHighRisk ? color[700] : Colors.green[800])),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isHighRisk ? color[600] : Colors.green[600])),
        ],
      ),
    );
  }

  Widget _buildAlertCard(dynamic cb) {
    String iconName = cb['icon'] ?? 'info';
    Color color = _getIconColor(iconName);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Icon(_getIconData(iconName), size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cb['tieu_de'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(cb['noi_dung'] ?? '', style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black54)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2, offset: const Offset(0, 1))],
                  ),
                  child: Row(
                    children: [
                     const Icon(Icons.psychology_outlined, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cb['hanh_dong'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue[800]))),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionPlan(Map<String, dynamic> keHoach) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.playlist_add_check_circle_rounded, size: 20, color: Colors.green[800]),
              ),
              const SizedBox(width: 10),
              Text("Hành Động Khuyến Nghị", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green[900], fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          if (keHoach['uu_tien_cao'] != null)
            _buildPriorityList("LÀM NGAY HÔM NAY", keHoach['uu_tien_cao'], Colors.red),
          if (keHoach['trung_binh'] != null)
            _buildPriorityList("KẾ HOẠCH TUẦN NÀY", keHoach['trung_binh'], Colors.orange),
        ],
      ),
    );
  }

  Widget _buildPriorityList(String title, dynamic items, MaterialColor color) {
    List list = items is List ? items : [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 16, color: color[700]),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color[800], letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          ...list.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                   margin: const EdgeInsets.only(top: 6),
                   width: 5, height: 5,
                   decoration: BoxDecoration(color: color[400], shape: BoxShape.circle)
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.toString(), style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87))),
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