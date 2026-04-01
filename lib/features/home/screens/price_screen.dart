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

      // ĐỒNG BỘ TẠI ĐÂY:
      if (_selectedCrop == 'Sầu Riêng') {
        _processDurianData(rawList); // Sử dụng hàm mới viết ở trên
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
    List<Map<String, dynamic>> tempList = [];

    for (var item in rawList) {
      // Lấy tên loại (VD: Sầu riêng Thái (VIP A))
      String name = item['loai']?.toString() ?? 'Sầu riêng';

      // Lấy giá (Vì bảng sầu riêng mới chỉ có 1 cột giá chung, không chia vùng)
      String price = item['gia']?.toString() ?? '0';
      String change = item['thay_doi']?.toString() ?? '-';

      tempList.add({
        'name': name,
        'price': price,
        'unit': 'đ/kg',
        'icon': 'Images/Durian.png',
        'text_icon': '🍈',
        'color': Colors.green,
        'change': change
      });
    }

    setState(() {
      _displayList = tempList;
      _durianTypes = []; // Xóa các Chip chọn loại (Ri6, Thái...) vì đã hiện hết ở danh sách
      _selectedDurianType = null;
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tên sản phẩm/Khu vực (Tự động xuống dòng)
                  Text(
                    item['name'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      height: 1.3, // Khoảng cách dòng cho thoáng
                    ),
                    softWrap: true, // Cho phép xuống dòng
                  ),

                  const SizedBox(height: 8),

                  // 2. Giá và Đơn vị (Dùng RichText để đơn vị dính liền vào giá)
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: item['price'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const TextSpan(text: ' '), // Khoảng trắng nhỏ
                        TextSpan(
                          text: item['unit'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),



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
  final Map<String, double> provincePrices;

  PricePoint({
    required this.date,
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

  // Hàm tính toán dải giá trị để biểu đồ luôn nằm trong khung hình
  double _getMinY() {
    double min = double.maxFinite;

    for (var p in _visibleDataPoints) {
      double pPrice = p.provincePrices[_selectedProvince] ?? 0;

      if (pPrice > 0 && pPrice < min) {
        min = pPrice;
      }
    }

    return min == double.maxFinite ? 0 : min * 0.95;
  }
  double _parsePrice(dynamic priceRaw) {
    if (priceRaw == null) return 0;

    String cleanStr = priceRaw
        .toString()
        .replaceAll('.', '')
        .replaceAll(',', '');

    // Có dạng khoảng giá: 50000-60000
    if (cleanStr.contains('-')) {
      var parts = cleanStr.split('-');
      if (parts.length == 2) {
        double min = double.tryParse(parts[0].trim()) ?? 0;
        double max = double.tryParse(parts[1].trim()) ?? 0;
        return (min + max) / 2;
      }
    }

    return double.tryParse(cleanStr.trim()) ?? 0;
  }
  double _getMaxY() {
    double max = 0;

    for (var p in _visibleDataPoints) {
      double pPrice = p.provincePrices[_selectedProvince] ?? 0;

      if (pPrice > max) {
        max = pPrice;
      }
    }

    return max == 0 ? 100000 : max * 1.05;
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
    String collectionId = switch (widget.cropType) {
      'Cà Phê' => 'Coffee',
      'Hồ Tiêu' => 'Pepper',
      'Sầu Riêng' => 'Durian',
      _ => 'Durian'
    };

    try {
      // 1. THÊM orderBy để đảm bảo lấy được các ngày gần đây nhất
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Price')
          .doc(collectionId)
          .collection('History')
          .orderBy(FieldPath.documentId, descending: true) // Lấy ngày mới nhất lên đầu
          .limit(100) // Chỉ cần 100 ngày gần nhất là thừa đủ cho biểu đồ
          .get();
      print("--- DEBUG FIREBASE ---");
      print("Số lượng document lấy được: ${snapshot.docs.length}");
      if (snapshot.docs.isNotEmpty) {
        print("ID của document đầu tiên: ${snapshot.docs.first.id}");
        print("Data của document đầu tiên: ${snapshot.docs.first.data()}");
      }
      List<PricePoint> tempPoints = [];
      Set<String> foundProvinces = {};

      for (var doc in snapshot.docs) {
        DateTime? date;
        try {
          date = DateTime.parse(doc.id.trim());
        } catch (_) { continue; }

        Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

        // 2. Đảm bảo lấy đúng field 'data' như trong hình Firestore
        List<dynamic> dataList = docData['data'] ?? docData['latest_data'] ?? [];

        Map<String, double> pricesMap = {};
        for (var item in dataList) {
          // 1. Tự động lấy Tên (Vùng/Loại): Thử lấy 'location', nếu null thì lấy 'loai'
          String loc = (item['location'] ?? item['loai'])?.toString() ?? '';

          // 2. Tự động lấy Giá: Thử lấy 'price', nếu null thì lấy 'gia'
          // Hàm _parsePrice của bạn sẽ tự xử lý chuỗi "150.000 - 160.000"
          double price = _parsePrice(item['price'] ?? item['gia'] ?? 0);

          if (loc.isNotEmpty && price > 0) {
            pricesMap[loc] = price;
            foundProvinces.add(loc);
          }
        }

        if (pricesMap.isNotEmpty) {
          tempPoints.add(PricePoint(date: date, provincePrices: pricesMap));
        }

      }

      // Sắp xếp lại theo thời gian xuôi (từ cũ đến mới) để vẽ biểu đồ
      tempPoints.sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _allDataPoints = tempPoints;
          _availableProvinces = foundProvinces.toList()..sort();

          if (_availableProvinces.isNotEmpty) {
            // Nếu chưa chọn hoặc loại cũ không tồn tại trong data mới
            if (_selectedProvince.isEmpty || !_availableProvinces.contains(_selectedProvince)) {
              // Ưu tiên chọn Ri6 nếu có, không thì lấy loại đầu tiên
              _selectedProvince = _availableProvinces.firstWhere(
                      (element) => element.contains('Ri6'),
                  orElse: () => _availableProvinces.first
              );
            }
          }
          _updateVisibleData();
        });
      }
    } catch (e) {
      debugPrint("Lỗi Fetch History: $e");
    }
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
      priceLast = last.provincePrices[_selectedProvince] ?? 0;
      priceFirst = first.provincePrices[_selectedProvince] ?? 0;
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
            const SizedBox(height: 20),

            // BIỂU ĐỒ

            _buildProvinceSelector(),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: _visibleDataPoints.isEmpty
                  ? const Center(child: Text("Không có dữ liệu"))
                  : _buildSingleLineChart(), // Dùng chung hàm biểu đồ đơn giống Cafe
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
                    ? "${widget.cropType} - ${_selectedProvince.isNotEmpty ? _selectedProvince : (widget.selectedSubCrop ?? 'Chọn loại')}"
                    : "Giá ${widget.cropType} - $_selectedProvince",
                // --- SỬA CHỖ NÀY ---
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2, // Khoảng cách giữa các dòng cho thoáng khi xuống hàng
                ),
                softWrap: true, // Cho phép tự động xuống hàng khi hết chiều ngang
                maxLines: null, // Không giới hạn số dòng (hoặc để 3-4 nếu bạn muốn giới hạn)
                // ------------------
              ),
              const SizedBox(height: 8), // Tăng khoảng cách một chút cho thoáng
              Text(
                "${NumberFormat('#,###').format(currentPrice)} đ",
                style: const TextStyle(
                    fontSize: 24, // Có thể tăng size lên một chút vì giờ nó là tâm điểm
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                ),
              ),
            ],
          ),
        ),
        // Giữ nguyên phần chọn W, M, Y bên phải
        Row(
          children: ['W', 'M', 'Y'].map((time) {
            bool isSelected = _selectedTimeFrame == time;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedTimeFrame = time;
                _updateVisibleData();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(left: 4),
                decoration: isSelected
                    ? BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8))
                    : null,
                child: Text(
                    time,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.green : Colors.grey[400]
                    )
                ),
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





  Widget _buildSingleLineChart() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _visibleDataPoints.length; i++) {
      double val = _visibleDataPoints[i].provincePrices[_selectedProvince] ?? 0;
      if (val > 0) spots.add(FlSpot(i.toDouble(), val));
    }
    if (spots.isEmpty) return const Center(child: Text("Chưa có dữ liệu cho tỉnh này"));

    return LineChart(
      LineChartData(
        minY: _getMinY(),
        maxY: _getMaxY(),
        // --- THÊM PHẦN NÀY ĐỂ TÙY CHỈNH TOOLTIP ---
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.green, // Nền trắng cho nổi bật
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                // Định dạng số: 94,000
                final String formattedValue = NumberFormat('#,###').format(spot.y);

                return LineTooltipItem(
                  formattedValue,
                  const TextStyle(
                    color: Color(0xFFFFFFFF), // Màu xanh đậm giống màu chủ đạo của bạn
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
        ),
        // ------------------------------------------
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _primaryChartColor,
            barWidth: 3,
            dotData: FlDotData(show: spots.length < 10),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                    colors: [_primaryChartColor.withOpacity(0.2), _primaryChartColor.withOpacity(0.0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter
                )
            ),
          ),
        ],
      ),
    );
  }


  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      // HIỆN TRỤC GIÁ BÊN TRÁI
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 45,
          getTitlesWidget: (value, meta) {
            // Chỉ hiện 3-4 mốc giá cho đỡ rối
            if (value == meta.min || value == meta.max) return const SizedBox();
            return Text(
              "${(value / 1000).toStringAsFixed(0)}k", // Hiện kiểu 90k, 95k
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: _selectedTimeFrame == 'W' ? 1 : (_selectedTimeFrame == 'M' ? 5 : 30),
          getTitlesWidget: (double value, TitleMeta meta) {
            int index = value.toInt();
            if (index < 0 || index >= _visibleDataPoints.length) return const SizedBox();
            return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                child: Text(
                    DateFormat('dd/MM').format(_visibleDataPoints[index].date),
                    style: const TextStyle(color: Colors.grey, fontSize: 10)
                )
            );
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
              // Bọc phần tiêu đề trong Expanded để nó tự co giãn và xuống dòng nếu cần
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: config.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology_outlined, color: config.color, size: 22),
                    ),
                    const SizedBox(width: 10),
                    // Dùng Flexible hoặc để Text tự nhiên trong Expanded
                    Flexible(
                      child: Text(
                        "AI Phân tích",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.visible, // Đảm bảo chữ có thể xuống dòng
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8), // Khoảng cách nhỏ để không dính vào Badge

              // Nhãn dán (Badge) - Giữ nguyên kích thước cố định
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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