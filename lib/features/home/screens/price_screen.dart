import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AgriPriceHome(),
  ));
}

class AgriPriceHome extends StatefulWidget {
  const AgriPriceHome({super.key});

  @override
  State<AgriPriceHome> createState() => _AgriPriceHomeState();
}

class _AgriPriceHomeState extends State<AgriPriceHome> {
  // --- MÀU SẮC CHỦ ĐẠO ---
  final Color _primaryColor = const Color(0xFF2E7D32); // Xanh lá đậm
  final Color _accentColor = const Color(0xFFE8F5E9);  // Xanh lá nhạt (nền)

  // --- TRẠNG THÁI DỮ LIỆU ---
  bool _isLoading = true;
  String? _errorMessage;
  String _lastUpdated = '';

  List<Map<String, dynamic>> _displayList = [];
  final List<String> _cropOptions = ['Sầu Riêng', 'Cà Phê', 'Hồ Tiêu'];
  String _selectedCrop = 'Sầu Riêng';

  List<String> _durianTypes = [];
  String? _selectedDurianType;
  List<Map<String, dynamic>> _rawDurianData = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- LOGIC FETCH DATA ---
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String docId = 'Durian';
      if (_selectedCrop == 'Cà Phê') docId = 'Coffee';
      if (_selectedCrop == 'Hồ Tiêu') docId = 'Pepper';

      // Giả lập delay mạng nhẹ để thấy hiệu ứng loading
      // await Future.delayed(const Duration(milliseconds: 500));

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Price')
          .doc(docId)
          .get();

      if (!doc.exists) {
        setState(() {
          _isLoading = false;
          _displayList = [];
          _lastUpdated = 'Chưa có dữ liệu';
        });
        return;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> rawList = data['latest_data'] ?? [];
      String updated = data['updated_at'] ?? DateTime.now().toIso8601String();

      if (_selectedCrop == 'Sầu Riêng') {
        _processDurianData(rawList);
      } else {
        _processGeneralData(rawList);
      }

      setState(() {
        _lastUpdated = updated;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _processDurianData(List<dynamic> rawList) {
    List<Map<String, dynamic>> prices = rawList.map((e) => Map<String, dynamic>.from(e)).toList();
    List<String> types = prices.map((e) => e['loai']?.toString() ?? 'Khác').toSet().toList();

    String currentType = _selectedDurianType ?? (types.isNotEmpty ? types.first : '');
    if (!types.contains(currentType) && types.isNotEmpty) currentType = types.first;

    _rawDurianData = prices;
    _durianTypes = types;
    _selectedDurianType = currentType;

    _filterDurianDisplay();
  }

  void _filterDurianDisplay() {
    final selectedRow = _rawDurianData.firstWhere(
            (item) => item['loai'] == _selectedDurianType,
        orElse: () => {}
    );

    List<Map<String, dynamic>> tempList = [];
    if (selectedRow.isNotEmpty) {
      selectedRow.forEach((key, value) {
        if (key != 'loai' && value != null) {
          tempList.add({
            'name': key,
            'price': value.toString(),
            'unit': 'đ/kg',

            // --- SỬA ĐOẠN NÀY ---
            // Đường dẫn phải chính xác từng chữ cái (Hoa/Thường)
            'icon': 'Images/Durian.png',

            // Icon dự phòng nếu ảnh lỗi
            'color': Colors.orangeAccent,
          });
        }
      });
    }
    setState(() {
      _displayList = tempList;
    });
  }

  void _processGeneralData(List<dynamic> rawList) {
    List<Map<String, dynamic>> tempList = [];

    for (var item in rawList) {
      // --- LOGIC CHỌN ẢNH VÀ ICON ---
      String iconPath;
      String textIcon;
      Color itemColor;

      if (_selectedCrop == 'Cà Phê') {
        iconPath = 'assets/coffee_icon.png'; // Nếu chưa có ảnh cà phê thì cứ để vậy
        textIcon = '☕';
        itemColor = Colors.brown;
      } else {
        // Đây là HỒ TIÊU
        // Chú ý: Tên file phải chính xác từng ký tự (gạch nối, đuôi jpg)
        iconPath = 'Images/black-pepper-grains.jpg';
        textIcon = '⚫'; // Icon hạt tiêu dự phòng
        itemColor = Colors.black87;
      }

      tempList.add({
        'name': item['location'],
        'price': item['price'],
        'unit': 'đ/kg',
        'icon': iconPath,      // Đã gán đường dẫn ảnh ở trên
        'text_icon': textIcon, // Đã gán icon dự phòng
        'color': itemColor,
        'change': item['change']
      });
    }

    setState(() {
      _displayList = tempList;
      _durianTypes = [];
    });
  }

  String _formatLastUpdated() {
    try {
      if (!_lastUpdated.contains('T') && !_lastUpdated.contains('-')) return '$_lastUpdated';
      final dateTime = DateTime.parse(_lastUpdated).toLocal();
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (_) {
      return '$_lastUpdated';
    }
  }

  // --- UI CHÍNH ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: _primaryColor,
        child: CustomScrollView(
          slivers: [
            // 1. APP BAR
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: _primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Thị Trường Nông Sản',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, Colors.green[400]!],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(right: -20, top: -20, child: Icon(Icons.eco, size: 150, color: Colors.white.withOpacity(0.1))),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),
                            const Text("Cập nhật mới nhất:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(_formatLastUpdated(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
              ],
            ),

            // 2. BODY CONTENT
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- THANH CHỌN LOẠI CÂY ---
                    const Text("Bạn quan tâm loại nào?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _cropOptions.map((crop) {
                          bool isSelected = _selectedCrop == crop;
                          return GestureDetector(
                            onTap: () {
                              if (!isSelected) {
                                setState(() {
                                  _selectedCrop = crop;
                                  _selectedDurianType = null;
                                });
                                _fetchData();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? _primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                    color: isSelected ? _primaryColor : Colors.grey[300]!,
                                    width: 1.5
                                ),
                                boxShadow: isSelected ? [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                              ),
                              child: Text(
                                crop,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- THANH CHỌN PHỤ (SUB-FILTER) ---
                    if (_selectedCrop == 'Sầu Riêng' && _durianTypes.isNotEmpty) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _durianTypes.map((type) {
                            bool isSelected = _selectedDurianType == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(type),
                                selected: isSelected,
                                // --- SỬA PADDING TẠI ĐÂY ---
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Nới lỏng padding
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.orange[900] : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                                backgroundColor: Colors.white,
                                selectedColor: Colors.orange[100],
                                checkmarkColor: Colors.orange[800],
                                side: BorderSide(color: isSelected ? Colors.orange : Colors.grey[300]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedDurianType = type;
                                    });
                                    _filterDurianDisplay();
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // --- DANH SÁCH GIÁ ---
                    if (_isLoading)
                      Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: _primaryColor)))
                    else if (_errorMessage != null)
                      _buildErrorWidget(_errorMessage!)
                    else if (_displayList.isEmpty)
                        _buildInfoWidget('Không có dữ liệu.')
                      else
                        ..._displayList.map((item) => _buildModernPriceCard(item)),

                    const SizedBox(height: 20),
                    PriceChartWidget(
                      cropType: _selectedCrop,
                      selectedSubCrop: _selectedDurianType,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CARD ĐÃ SỬA ---
  Widget _buildModernPriceCard(Map<String, dynamic> item) {
    String change = item['change']?.toString() ?? '';
    bool isUp = change.contains('+');
    bool isDown = change.contains('-');

    // Logic kiểm tra hiển thị ảnh hay text
    String iconPath = item['icon'].toString().toLowerCase();
    // Thêm điều kiện kiểm tra .jpg
    bool hasAssetImage = iconPath.contains('.png') || iconPath.contains('.jpg');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Cột 1: Icon (ĐÃ SỬA LOGIC)
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(8), // Thêm padding bên trong để ảnh không bị sát viền
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                // Logic: Ưu tiên Load ảnh từ assets, nếu lỗi (do chưa có file) thì hiện text
                child: hasAssetImage
                    ? Image.asset(
                  item['icon'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback nếu không tìm thấy file ảnh
                    return Text(item['text_icon'] ?? '', style: const TextStyle(fontSize: 24));
                  },
                )
                    : Text(item['text_icon'] ?? '', style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),

            // Cột 2: Tên & Giá
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'].toString().toUpperCase(),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        item['price'],
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[700]),
                      ),
                      const SizedBox(width: 4),
                      Text(item['unit'], style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),

            // Cột 3: Tăng giảm
            if (change.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUp ? Colors.green[50] : (isDown ? Colors.red[50] : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                        isUp ? Icons.arrow_drop_up : (isDown ? Icons.arrow_drop_down : Icons.remove),
                        color: isUp ? Colors.green : (isDown ? Colors.red : Colors.grey),
                        size: 20
                    ),
                    Text(
                      change.replaceAll('+', '').replaceAll('-', ''),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isUp ? Colors.green[700] : (isDown ? Colors.red[700] : Colors.grey[700])
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(child: Text('Lỗi: $message', style: const TextStyle(color: Colors.red)));
  }

  Widget _buildInfoWidget(String message) {
    return Center(child: Text(message, style: const TextStyle(color: Colors.grey)));
  }
}

// --------------------------------------------------------Biểu Đồ------------------------------------------------------------



// --- 1. MODEL DỮ LIỆU ---
class PricePoint {
  final DateTime date;
  final double mienTay;
  final double mienDong;
  final double tayNguyen;
  final Map<String, double> provincePrices;

  PricePoint({
    required this.date,
    this.mienTay = 0,
    this.mienDong = 0,
    this.tayNguyen = 0,
    this.provincePrices = const {},
  });
}

// Model cho Dự đoán (New)
class ForecastInfo {
  final double day1;
  final double day3;
  final double day7;
  final String trend;

  ForecastInfo({
    required this.day1,
    required this.day3,
    required this.day7,
    required this.trend,
  });
}

class PriceChartWidget extends StatefulWidget {
  final String cropType; // 'Sầu Riêng', 'Cà Phê', 'Hồ Tiêu'
  final String? selectedSubCrop; // VD: 'Sầu riêng Ri6 đẹp'

  const PriceChartWidget({
    super.key,
    required this.cropType,
    this.selectedSubCrop,
  });

  @override
  State<PriceChartWidget> createState() => _PriceChartWidgetState();
}

class _PriceChartWidgetState extends State<PriceChartWidget> {
  // --- STATE ---
  int _currentTabIndex = 0;
  String _selectedTimeFrame = 'W';
  String _selectedProvince = '';
  List<String> _availableProvinces = [];
  bool _isLoading = true;

  // Data Lịch sử
  List<PricePoint> _allDataPoints = [];
  List<PricePoint> _visibleDataPoints = [];

  // Data Dự đoán (New) -> Map<Key, ForecastInfo>
  // Key là Tên Tỉnh (Cafe) hoặc Tên Loại - Vùng (Sầu riêng)
  Map<String, ForecastInfo> _forecastMap = {};

  final Color _primaryChartColor = const Color(0xFF2E7D32);
  final Color _colMienTay = const Color(0xFF4CAF50);
  final Color _colMienDong = const Color(0xFFFF9800);
  final Color _colTayNguyen = const Color(0xFF795548);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant PriceChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropType != widget.cropType ||
        oldWidget.selectedSubCrop != widget.selectedSubCrop) {
      _fetchData();
    }
  }

  // Wrapper gọi cả 2 hàm fetch
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchHistoryData(),
      _fetchForecastData(), // <--- Gọi hàm lấy dự đoán
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  double _parsePrice(dynamic priceRaw) {
    if (priceRaw == null) return 0;
    String cleanStr = priceRaw.toString().replaceAll('.', '').replaceAll(',', '');
    // Xử lý range giá (50000-60000)
    if (cleanStr.contains('-')) {
      try {
        var parts = cleanStr.split('-');
        double min = double.parse(parts[0].trim());
        double max = double.parse(parts[1].trim());
        return (min + max) / 2;
      } catch (_) { return 0; }
    }
    return double.tryParse(cleanStr.trim()) ?? 0;
  }

  // --- 2. LOGIC LẤY DỰ ĐOÁN (NEW) ---
  Future<void> _fetchForecastData() async {
    String collectionId = switch (widget.cropType) {
      'Cà Phê' => 'Coffee',
      'Hồ Tiêu' => 'Pepper',
      'Sầu Riêng' => 'Durian',
      _ => 'Durian'
    };

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Price')
          .doc(collectionId)
          .collection('Forecast')
          .doc('latest')
          .get();

      if (!doc.exists) {
        _forecastMap = {};
        return;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> forecastRaw = data['data'] ?? {}; // Field 'data' chứa map dự đoán

      Map<String, ForecastInfo> parsedMap = {};

      forecastRaw.forEach((key, value) {
        if (value is Map) {
          parsedMap[key] = ForecastInfo(
            day1: double.tryParse(value['day_1'].toString()) ?? 0,
            day3: double.tryParse(value['day_3'].toString()) ?? 0,
            day7: double.tryParse(value['day_7'].toString()) ?? 0,
            trend: value['trend_desc'] ?? 'không rõ',
          );
        }
      });

      if (mounted) {
        setState(() {
          _forecastMap = parsedMap;
        });
      }
    } catch (e) {
      debugPrint("Lỗi fetch forecast: $e");
    }
  }

  Future<void> _fetchHistoryData() async {
    // ... (Giữ nguyên logic cũ của bạn ở đây)
    // Lưu ý: Đã xoá setState isLoading ở đây để gom vào hàm _fetchData chung

    // Copy lại logic fetch history cũ vào đây...
    // Để ngắn gọn tôi tóm tắt lại logic gán _allDataPoints và _availableProvinces

    String collectionId = switch (widget.cropType) {
      'Cà Phê' => 'Coffee',
      'Hồ Tiêu' => 'Pepper',
      'Sầu Riêng' => 'Durian',
      _ => 'Durian'
    };

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Price').doc(collectionId).collection('History')
          .limit(365).get();

      List<PricePoint> tempPoints = [];
      Set<String> foundProvinces = {};

      for (var doc in snapshot.docs) {
        DateTime? date;
        try { date = DateTime.parse(doc.id); } catch (_) { continue; }
        Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

        if (widget.cropType == 'Sầu Riêng') {
          List<dynamic> dataList = docData['data'] ?? docData['latest_data'] ?? [];
          String targetType = widget.selectedSubCrop ?? 'Sầu riêng Ri6 đẹp';
          var targetItem = dataList.firstWhere((item) => item['loai'] == targetType, orElse: () => null);

          if (targetItem != null) {
            tempPoints.add(PricePoint(
              date: date,
              mienTay: _parsePrice(targetItem['Khu vực - Miền Tây Nam bộ'] ?? targetItem['Khu vực-Miền Tây Nam bộ']),
              mienDong: _parsePrice(targetItem['Khu vực - Miền Đông Nam bộ'] ?? targetItem['Khu vực-Miền Đông Nam bộ']),
              tayNguyen: _parsePrice(targetItem['Khu vực - Tây Nguyên'] ?? targetItem['Khu vực-Tây Nguyên']),
            ));
          }
        } else {
          List<dynamic> dataList = docData['data'] ?? [];
          Map<String, double> pricesMap = {};
          for (var item in dataList) {
            String loc = item['location'] ?? '';
            double price = _parsePrice(item['price']);
            if (loc.isNotEmpty && price > 0) {
              pricesMap[loc] = price;
              foundProvinces.add(loc);
            }
          }
          if (pricesMap.isNotEmpty) tempPoints.add(PricePoint(date: date, provincePrices: pricesMap));
        }
      }

      tempPoints.sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _allDataPoints = tempPoints;
          if (widget.cropType != 'Sầu Riêng') {
            _availableProvinces = foundProvinces.toList()..sort();
            if (_selectedProvince.isEmpty && _availableProvinces.isNotEmpty) {
              if (_availableProvinces.contains('Đắk Lắk')) _selectedProvince = 'Đắk Lắk';
              else _selectedProvince = _availableProvinces.first;
            }
          }
          _updateVisibleData();
        });
      }
    } catch (e) { print(e); }
  }

  void _updateVisibleData() {
    if (_allDataPoints.isEmpty) { _visibleDataPoints = []; return; }
    DateTime latestDate = _allDataPoints.last.date;
    DateTime startDate;
    if (_selectedTimeFrame == 'W') startDate = latestDate.subtract(const Duration(days: 6));
    else if (_selectedTimeFrame == 'M') startDate = latestDate.subtract(const Duration(days: 29));
    else startDate = latestDate.subtract(const Duration(days: 365));

    _visibleDataPoints = _allDataPoints.where((p) => p.date.isAfter(startDate.subtract(const Duration(seconds: 1)))).toList();
  }

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    bool isDurian = widget.cropType == 'Sầu Riêng';
    double currentPrice = 0;
    double growth = 0;

    // 1. Tính toán giá & tăng trưởng (Logic cũ)
    if (_visibleDataPoints.isNotEmpty) {
      PricePoint last = _visibleDataPoints.last;
      PricePoint first = _visibleDataPoints.first;
      double priceLast = 0;
      double priceFirst = 0;

      if (isDurian) {
        priceLast = last.mienTay > 0 ? last.mienTay : (last.tayNguyen > 0 ? last.tayNguyen : last.mienDong);
        priceFirst = first.mienTay > 0 ? first.mienTay : (first.tayNguyen > 0 ? first.tayNguyen : first.mienDong);
      } else {
        priceLast = last.provincePrices[_selectedProvince] ?? 0;
        priceFirst = first.provincePrices[_selectedProvince] ?? 0;
      }
      currentPrice = priceLast;
      growth = priceLast - priceFirst;
    }

    // -----------------------------------------------------------
    // 2. 🔥 LOGIC AI (GIẢ LẬP DỰA TRÊN DỮ LIỆU) 🔥
    // Trong thực tế, bạn sẽ lấy text này từ field 'analysis' trên Firebase
    // -----------------------------------------------------------
    TrendSignal aiSignal;
    String aiSummary;
    String aiAction;

    // Logic đơn giản để demo: Dựa vào giá tăng/giảm (growth)
    if (growth > 0) {
      aiSignal = TrendSignal.positive;
      aiSummary = "Đà tăng giá đang được củng cố nhờ nhu cầu xuất khẩu ổn định. Nguồn cung tại các vùng trồng chính chưa có dấu hiệu dư thừa đột biến.";
      aiAction = "Nông dân có thể cân nhắc giữ hàng chờ giá tốt hơn hoặc bán rải rác để chốt lời an toàn.";
    } else if (growth < 0) {
      aiSignal = TrendSignal.risk;
      aiSummary = "Áp lực điều chỉnh giảm đang diễn ra do nguồn cung từ các vụ thu hoạch mới bắt đầu rộ lên, trong khi sức mua từ thương lái chững lại.";
      aiAction = "Thận trọng quan sát, tránh bán tháo ồ ạt. Cân nhắc bán ngay nếu cần dòng tiền gấp.";
    } else {
      aiSignal = TrendSignal.neutral;
      aiSummary = "Thị trường đang trong giai đoạn đi ngang tích lũy. Giá cả ít biến động do cung cầu đang ở trạng thái cân bằng.";
      aiAction = "Tiếp tục chăm sóc vườn cây, theo dõi sát diễn biến thời tiết và thông tin cửa khẩu.";
    }
    // -----------------------------------------------------------

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 5, blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(currentPrice, growth),
          const SizedBox(height: 20),

          if (_isLoading) const Center(child: CircularProgressIndicator())
          else ...[
            if (isDurian) _buildDurianControls() else _buildProvinceSelector(),
            const SizedBox(height: 20),

            // BIỂU ĐỒ
            SizedBox(
              height: 220,
              child: _visibleDataPoints.isEmpty
                  ? const Center(child: Text("Không có dữ liệu"))
                  : isDurian
                  ? (_currentTabIndex == 0 ? _buildDurianLineChart() : _buildDurianBarChart())
                  : _buildSingleLineChart(),
            ),

            // CHÚ THÍCH CHART SẦU RIÊNG
            if (isDurian && _currentTabIndex == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem("Miền Tây", _colMienTay),
                    const SizedBox(width: 12),
                    _buildLegendItem("Miền Đông", _colMienDong),
                    const SizedBox(width: 12),
                    _buildLegendItem("Tây Nguyên", _colTayNguyen),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // PHẦN DỰ BÁO GIÁ (CŨ)
            _buildForecastSection(),

            // 🔥 PHẦN AI PHÂN TÍCH (MỚI) 🔥
            // Chỉ hiển thị khi đã load xong dữ liệu
            if (!_isLoading && _visibleDataPoints.isNotEmpty)
              AITrendWidget(
                signal: aiSignal,
                summary: aiSummary,
                action: aiAction,
              ),
          ]
        ],
      ),
    );
  }

  // --- WIDGET DỰ ĐOÁN (NEW) ---
  // --- 3. PHẦN HIỂN THỊ DỰ ĐOÁN (ĐÃ NÂNG CẤP FULL 3 VÙNG) ---
  Widget _buildForecastSection() {
    // 1. HEADER CHUNG
    Widget header = Row(
      children: [
        const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
        const SizedBox(width: 8),
        const Text("Dự báo AI (Beta)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );

    // 2. LOGIC HIỂN THỊ
    List<Widget> forecastWidgets = [];

    // --- TRƯỜNG HỢP SẦU RIÊNG (HIỆN 3 VÙNG) ---
    if (widget.cropType == 'Sầu Riêng') {
      String subCrop = widget.selectedSubCrop ?? "Sầu riêng Ri6 đẹp";

      // Tạo Key khớp với Python
      String keyMienTay = "$subCrop - Miền Tây Nam bộ";
      String keyMienDong = "$subCrop - Miền Đông Nam bộ";
      String keyTayNguyen = "$subCrop - Tây Nguyên";

      // Lấy dữ liệu từ Map
      ForecastInfo? infoTay = _forecastMap[keyMienTay];
      ForecastInfo? infoDong = _forecastMap[keyMienDong];
      ForecastInfo? infoTN = _forecastMap[keyTayNguyen];

      // Thêm widget từng vùng nếu có dữ liệu
      if (infoTay != null) {
        forecastWidgets.add(_buildSingleRegionForecast("Miền Tây", infoTay, _colMienTay));
      }
      if (infoDong != null) {
        forecastWidgets.add(_buildSingleRegionForecast("Miền Đông", infoDong, _colMienDong));
      }
      if (infoTN != null) {
        forecastWidgets.add(_buildSingleRegionForecast("Tây Nguyên", infoTN, _colTayNguyen));
      }
    }
    // --- TRƯỜNG HỢP CAFE / TIÊU (HIỆN 1 TỈNH) ---
    else {
      if (_forecastMap.containsKey(_selectedProvince)) {
        ForecastInfo info = _forecastMap[_selectedProvince]!;
        forecastWidgets.add(_buildSingleRegionForecast(_selectedProvince, info, _primaryChartColor));
      }
    }

    // 3. RENDER UI
    if (forecastWidgets.isEmpty) {
      return Column(
        children: [
          header,
          const SizedBox(height: 12),
          const Center(
            child: Text("🤖 Đang cập nhật dữ liệu dự báo...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 12),
        // Dùng spread operator (...) để bung danh sách widget ra
        ...forecastWidgets,
      ],
    );
  }

  // --- WIDGET CON: HIỂN THỊ 1 DÒNG DỰ BÁO ---
  Widget _buildSingleRegionForecast(String regionName, ForecastInfo info, Color labelColor) {
    bool isIncrease = info.trend.contains('tăng');
    bool isDecrease = info.trend.contains('giảm');

    Color trendColor = isIncrease ? Colors.green : (isDecrease ? Colors.red : Colors.grey);
    Color trendBg = isIncrease ? Colors.green[50]! : (isDecrease ? Colors.red[50]! : Colors.grey[100]!);

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Khoảng cách giữa các vùng
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên vùng + Xu hướng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4, height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: labelColor, borderRadius: BorderRadius.circular(2)),
                  ),
                  Text(regionName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: labelColor)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  info.trend.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: trendColor),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 12),
          // 3 Cột giá
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildForecastItem("1 ngày tới", info.day1),
              _buildForecastItem("3 ngày tới", info.day3),
              _buildForecastItem("7 ngày tới", info.day7),
            ],
          )
        ],
      ),
    );
  }

  // Widget hiển thị số tiền (giữ nguyên hoặc thêm vào nếu chưa có)
  Widget _buildForecastItem(String label, double price) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          NumberFormat('#,###').format(price),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  // --- GIỮ LẠI CÁC WIDGET CŨ ---
  // (Phần Header, Selector, Chart giữ nguyên như code cũ của bạn)

  Widget _buildHeader(double currentPrice, double growth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.cropType == 'Sầu Riêng'
                    ? (widget.selectedSubCrop ?? 'Sầu Riêng')
                    : "Giá ${widget.cropType} - $_selectedProvince",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text("${NumberFormat('#,###').format(currentPrice)} đ", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(width: 8),
                  if (_visibleDataPoints.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: growth >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4)
                      ),
                      child: Row(
                        children: [
                          Icon(growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: growth >= 0 ? Colors.green : Colors.red),
                          Text(" ${NumberFormat('#,###').format(growth.abs())}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: growth >= 0 ? Colors.green : Colors.red)),
                        ],
                      ),
                    )
                ],
              )
            ],
          ),
        ),
        Row(
          children: ['W', 'M', 'Y'].map((time) {
            bool isSelected = _selectedTimeFrame == time;
            return GestureDetector(
              onTap: () => setState(() { _selectedTimeFrame = time; _updateVisibleData(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(left: 4),
                decoration: isSelected ? BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)) : null,
                child: Text(time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.green : Colors.grey[400])),
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildProvinceSelector() {
    if (_availableProvinces.isEmpty) return const SizedBox();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _availableProvinces.map((province) {
          bool isSelected = _selectedProvince == province;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(province),
              selected: isSelected,
              selectedColor: _primaryChartColor.withOpacity(0.2),
              labelStyle: TextStyle(color: isSelected ? _primaryChartColor : Colors.black54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12),
              onSelected: (bool selected) { if (selected) setState(() => _selectedProvince = province); },
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? _primaryChartColor : Colors.transparent)),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDurianControls() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Row(children: [_buildTabButton("So sánh", 0), _buildTabButton("Theo vùng", 1)]),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isActive = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildSingleLineChart() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _visibleDataPoints.length; i++) {
      double val = _visibleDataPoints[i].provincePrices[_selectedProvince] ?? 0;
      if (val > 0) spots.add(FlSpot(i.toDouble(), val));
    }
    if (spots.isEmpty) return const Center(child: Text("Chưa có dữ liệu cho tỉnh này"));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.9),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                DateTime date = _visibleDataPoints[spot.spotIndex].date;
                return LineTooltipItem("${DateFormat('dd/MM').format(date)}\n${NumberFormat('#,###').format(spot.y)}", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, color: _primaryChartColor, barWidth: 3, dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [_primaryChartColor.withOpacity(0.3), _primaryChartColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      ),
    );
  }

  Widget _buildDurianLineChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            // Màu nền của Tooltip
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.9),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(12), // Tăng khoảng cách lề cho thoáng

            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              // 1. Sắp xếp thứ tự hiển thị: Miền Tây (0) -> Miền Đông (1) -> Tây Nguyên (2)
              // Để đảm bảo dòng nào cũng hiện đúng vị trí
              touchedSpots.sort((a, b) => a.barIndex.compareTo(b.barIndex));

              return touchedSpots.map((spot) {
                // Lấy dữ liệu
                final pricePoint = _visibleDataPoints[spot.spotIndex];
                final dateStr = DateFormat('dd/MM').format(pricePoint.date);
                final priceStr = NumberFormat('#,###').format(spot.y);

                // Xác định tên vùng và màu sắc dựa trên barIndex
                // 0: Miền Tây, 1: Miền Đông, 2: Tây Nguyên (theo thứ tự add vào lineBarsData)
                String regionName;
                if (spot.barIndex == 0) regionName = "Miền Tây";
                else if (spot.barIndex == 1) regionName = "Miền Đông";
                else regionName = "Tây Nguyên";

                // Style cho chữ
                final TextStyle labelStyle = const TextStyle(
                    color: Colors.white70, fontSize: 12, fontWeight: FontWeight.normal
                );
                final TextStyle valueStyle = const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold
                );

                // --- LOGIC HIỂN THỊ ---
                // Chỉ hiển thị Ngày tháng ở dòng đầu tiên (item đầu tiên trong danh sách)
                if (spot == touchedSpots.first) {
                  return LineTooltipItem(
                    '$dateStr\n', // Dòng 1: Ngày tháng (In đậm, to hơn)
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    children: [
                      TextSpan(text: '$regionName: ', style: labelStyle),
                      TextSpan(text: priceStr, style: valueStyle),
                    ],
                  );
                } else {
                  // Các dòng sau: Chỉ hiện Tên vùng + Giá (Không hiện lại ngày)
                  return LineTooltipItem(
                    '', // Text chính để trống
                    const TextStyle(fontSize: 0), // Hack để ẩn dòng trống
                    children: [
                      TextSpan(text: '$regionName: ', style: labelStyle),
                      TextSpan(text: priceStr, style: valueStyle),
                    ],
                  );
                }
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          _buildLineSeries(_visibleDataPoints.map((e) => FlSpot(_visibleDataPoints.indexOf(e).toDouble(), e.mienTay)).toList(), _colMienTay),
          _buildLineSeries(_visibleDataPoints.map((e) => FlSpot(_visibleDataPoints.indexOf(e).toDouble(), e.mienDong)).toList(), _colMienDong),
          _buildLineSeries(_visibleDataPoints.map((e) => FlSpot(_visibleDataPoints.indexOf(e).toDouble(), e.tayNguyen)).toList(), _colTayNguyen),
        ],
      ),
    );
  }

  Widget _buildDurianBarChart() {
    if (_visibleDataPoints.isEmpty) return const Center(child: Text("Không có dữ liệu"));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY() * 1.1, // Tăng thêm 10% chiều cao để tooltip không bị che
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.9),
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // Logic hiển thị Tooltip cho từng cột
              String regionName;
              if (rodIndex == 0) regionName = "Miền Tây";
              else if (rodIndex == 1) regionName = "Miền Đông";
              else regionName = "Tây Nguyên";

              return BarTooltipItem(
                '$regionName\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                children: <TextSpan>[
                  TextSpan(
                    text: NumberFormat('#,###').format(rod.toY),
                    style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index < 0 || index >= _visibleDataPoints.length) return const SizedBox();

                // Chỉ hiện ngày nếu không quá dày đặc
                // Nếu xem tuần (7 ngày) thì hiện hết, xem tháng thì hiện thưa ra
                if (_selectedTimeFrame == 'M' && index % 5 != 0) return const SizedBox();

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(
                    DateFormat('dd/MM').format(_visibleDataPoints[index].date),
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: _visibleDataPoints.asMap().entries.map((entry) {
          int index = entry.key;
          PricePoint point = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              _buildBarRod(point.mienTay, _colMienTay),
              _buildBarRod(point.mienDong, _colMienDong),
              _buildBarRod(point.tayNguyen, _colTayNguyen),
            ],
            barsSpace: 4, // Khoảng cách giữa các cột trong cùng 1 ngày
          );
        }).toList(),
      ),
    );
  }

  // Hàm phụ để tạo cột cho gọn code
  BarChartRodData _buildBarRod(double y, Color color) {
    return BarChartRodData(
      toY: y,
      color: color,
      width: 6, // Độ rộng của cột
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: _getMaxY() * 1.1, // Cột mờ làm nền (tùy chọn)
        color: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  // Hàm tính giá trị lớn nhất để scale biểu đồ
  double _getMaxY() {
    double max = 0;
    for (var p in _visibleDataPoints) {
      if (p.mienTay > max) max = p.mienTay;
      if (p.mienDong > max) max = p.mienDong;
      if (p.tayNguyen > max) max = p.tayNguyen;
    }
    return max == 0 ? 100000 : max; // Fallback
  }

  LineChartBarData _buildLineSeries(List<FlSpot> spots, Color color) {
    final validSpots = spots.where((spot) => spot.y > 0).toList();
    if (validSpots.isEmpty) return LineChartBarData(spots: []);
    return LineChartBarData(spots: validSpots, isCurved: true, color: color, barWidth: 3, dotData: const FlDotData(show: false));
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))]);
  }

  FlTitlesData _buildTitlesData() {
    double interval = 1;
    if (_selectedTimeFrame == 'M') interval = 5;
    if (_selectedTimeFrame == 'Y') interval = 30;

    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true, reservedSize: 30, interval: interval,
          getTitlesWidget: (double value, TitleMeta meta) {
            int index = value.toInt();
            if (index < 0 || index >= _visibleDataPoints.length) return const SizedBox();
            if (index % interval.toInt() != 0 && _selectedTimeFrame != 'W') return const SizedBox();
            return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(DateFormat('dd/MM').format(_visibleDataPoints[index].date), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)));
          },
        ),
      ),
    );
  }
}




// --- 4. ENUM & WIDGET AI PHÂN TÍCH (MỚI) ---

// --- WIDGET AI PHÂN TÍCH (PHIÊN BẢN ĐÃ NÂNG CẤP UI) ---

enum TrendSignal {
  positive, // 🟢 Tích cực
  neutral,  // 🟡 Trung lập
  risk      // 🔴 Rủi ro
}

class AITrendWidget extends StatelessWidget {
  final TrendSignal signal;
  final String summary;
  final String action;

  const AITrendWidget({
    super.key,
    required this.signal,
    required this.summary,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getSignalConfig();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.03), // Nền Pastel cực nhẹ
        borderRadius: BorderRadius.circular(20), // Bo góc mềm mại hơn
        border: Border.all(color: config.color.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Icon AI với nền tròn nhẹ
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: config.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.psychology_outlined, color: config.color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "AI Phân tích",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black87, // Để màu đen cho sang, chỉ nhấn màu ở icon/nhãn
                    ),
                  ),
                ],
              ),

              // Nhãn dán (Badge) - Dạng Pill hiện đại
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.12), // Nền nhạt
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chấm tròn nhấp nháy (giả lập bằng icon)
                    Icon(Icons.fiber_manual_record, color: config.color, size: 10),
                    const SizedBox(width: 6),
                    Text(
                      config.label,
                      style: TextStyle(
                        color: config.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- NỘI DUNG PHÂN TÍCH ---
          Text(
            summary,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.6, // Tăng line-height cho dễ đọc
              color: Colors.black87.withOpacity(0.8),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.justify,
          ),

          const SizedBox(height: 20),

          // --- BOX GỢI Ý HÀNH ĐỘNG (Nâng cấp) ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("💡", style: TextStyle(fontSize: 18)), // Dùng emoji cho thân thiện
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.45),
                      children: [
                        TextSpan(
                          text: "Gợi ý: ",
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: action,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --- DISCLAIMER (Dòng nhỏ dưới cùng) ---
          Center(
            child: Text(
              "* Phân tích tự động chỉ mang tính chất tham khảo",
              style: TextStyle(color: Colors.grey[400], fontSize: 10.5, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  // Helper cấu hình màu sắc theo mockup Soft-UI
  ({Color color, String label, IconData icon}) _getSignalConfig() {
    switch (signal) {
      case TrendSignal.positive:
        return (
        color: const Color(0xFF2E7D32), // Xanh lá đậm vừa phải
        label: "Tín hiệu Tích cực",
        icon: Icons.trending_up
        );
      case TrendSignal.risk:
        return (
        color: const Color(0xFFE53935), // Đỏ hiện đại
        label: "Rủi ro Ngắn hạn",
        icon: Icons.warning_rounded
        );
      case TrendSignal.neutral:
      default:
        return (
        color: const Color(0xFFF9A825), // Vàng đậm/Cam
        label: "Trung lập",
        icon: Icons.horizontal_rule_rounded
        );
    }
  }
}