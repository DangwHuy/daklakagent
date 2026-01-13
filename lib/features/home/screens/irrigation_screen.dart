import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- CONFIGURATION ---
const String apiKey = ""; // API Key Gemini
const String openWeatherApiKey = "4be89a65fe75c2f972c0f24084943bc1"; // API Key OpenWeatherMap

// --- MAIN ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    const firebaseConfigStr = String.fromEnvironment('FIREBASE_CONFIG');
    if (firebaseConfigStr.isNotEmpty) {
      final Map<String, dynamic> firebaseConfig = jsonDecode(firebaseConfigStr);
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: firebaseConfig['apiKey'],
          appId: firebaseConfig['appId'],
          messagingSenderId: firebaseConfig['messagingSenderId'],
          projectId: firebaseConfig['projectId'],
          authDomain: firebaseConfig['authDomain'],
          storageBucket: firebaseConfig['storageBucket'],
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    // [QUAN TRỌNG] Đăng nhập Email cố định để khớp UID với ESP32
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: "huy@gmail.com",
            password: "123456"
        );
        print("✅ Đã đăng nhập: huy@gmail.com (UID: ${FirebaseAuth.instance.currentUser?.uid})");
      } catch (e) {
        print("⚠️ Lỗi đăng nhập: $e");
      }
    }

  } catch (e) {
    print("Firebase init error: $e");
  }
  runApp(const DurianAgriApp());
}

class DurianAgriApp extends StatelessWidget {
  const DurianAgriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đăk Lăk Agri Smart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const IrrigationScreen(),
    );
  }
}

// --- MÀN HÌNH CHÍNH ---
class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  // [SỬA LỖI] Định nghĩa AppID chung cho toàn bộ màn hình để tránh lệch pha
  final String _appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');

  // Dữ liệu người dùng chọn
  String selectedStage = 'Ra hoa';
  int treeAge = 5;
  String soilType = 'Đất thịt';

  // --- DỮ LIỆU THỜI TIẾT ---
  String selectedLocation = 'Buôn Ma Thuột';
  String weatherCondition = 'Nắng nhẹ';
  double? _currentTemp;
  double? _currentHumidity;
  double? _rainVolume;
  bool _isFetchingWeather = false;

  // --- DỮ LIỆU DỰ BÁO ---
  List<dynamic> _dailyForecasts = []; // Danh sách 5 ngày tới
  double _predictedRain24h = 0.0; // Tổng lượng mưa 24h tới
  bool _isForecastLoading = false;

  // --- DỮ LIỆU QUẢN LÝ NƯỚC ---
  final TextEditingController _totalTreesController = TextEditingController(text: '100');
  final TextEditingController _waterReserveController = TextEditingController(text: '50');

  // --- DỮ LIỆU IOT ---
  int? _realtimeSoilMoisture;
  String _iotControlMode = "AUTO"; // Mặc định tự động
  String _iotPumpStatusTarget = "OFF";  // Trạng thái lệnh hiện tại
  bool _isSendingCommand = false;
  StreamSubscription? _controlSub;

  // Danh sách địa điểm hỗ trợ
  final Map<String, Map<String, double>> locations = {
    "Krông Pắc": {"lat": 12.69, "lon": 108.30, "cao_do": 500},
    "Cư M'gar": {"lat": 12.86, "lon": 108.08, "cao_do": 530},
    "Buôn Hồ": {"lat": 12.92, "lon": 108.30, "cao_do": 480},
    "Buôn Ma Thuột": {"lat": 12.6667, "lon": 108.0500, "cao_do": 536},
    "Ea Kar": {"lat": 12.80, "lon": 108.45, "cao_do": 420}
  };

  // Trạng thái AI
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aiResult;
  String? _aiError;
  bool _isViewingHistory = false;

  final List<String> stages = [
    'Ra hoa',
    'Đậu trái',
    'Phát triển trái',
    'Thu hoạch',
    'Nghỉ ngơi'
  ];

  final List<String> soilTypes = [
    'Đất thịt',
    'Đất thịt pha cát',
    'Đất đỏ bazan',
    'Đất phù sa'
  ];

  @override
  void initState() {
    super.initState();
    _fetchWeather(selectedLocation);
    _loadFarmConfig();
    _listenToControlConfig(); // Bắt đầu lắng nghe cấu hình
    _totalTreesController.addListener(() => setState(() {}));
    _waterReserveController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _totalTreesController.dispose();
    _waterReserveController.dispose();
    _controlSub?.cancel();
    super.dispose();
  }

  // --- [SỬA LỖI] LẮNG NGHE & TỰ KHỞI TẠO CẤU HÌNH ---
  void _listenToControlConfig() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Đường dẫn chính xác: artifacts/default-app-id/users/{uid}/config/pump_control
    final docRef = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(user.uid)
        .collection('config')
        .doc('pump_control');

    _controlSub = docRef.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // Nếu có dữ liệu, cập nhật UI
        setState(() {
          _iotControlMode = snapshot.data()!['mode'] ?? "AUTO";
          // [CẬP NHẬT] Đọc pump_status thay vì command
          _iotPumpStatusTarget = snapshot.data()!['pump_status'] ?? "OFF";
        });
      } else {
        // [QUAN TRỌNG] Nếu chưa có, tự động tạo file config mặc định
        print("⚠️ Chưa có file config, đang tự tạo...");
        docRef.set({
          'mode': "AUTO",
          'pump_status': "OFF", // [CẬP NHẬT] Tạo trường pump_status
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }, onError: (e) => print("Lỗi lắng nghe Config: $e"));
  }

  // --- GỬI LỆNH ĐIỀU KHIỂN BƠM ---
  Future<void> _sendCommandToPump(bool isAuto, bool turnOn) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSendingCommand = true);

    try {
      // Ghi đúng vào đường dẫn mà ESP32 đang đọc
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(user.uid)
          .collection('config')
          .doc('pump_control')
          .set({
        'mode': isAuto ? "AUTO" : "MANUAL",
        // [CẬP NHẬT] Ghi pump_status thay vì command
        'pump_status': turnOn ? "ON" : "OFF",
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // UI sẽ tự cập nhật nhờ hàm _listenToControlConfig

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gửi lệnh: $e')));
    } finally {
      setState(() => _isSendingCommand = false);
    }
  }

  Future<void> _loadFarmConfig() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(user.uid)
          .collection('config')
          .doc('farm_data')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _totalTreesController.text = (data['total_trees'] ?? 100).toString();
            _waterReserveController.text = (data['water_reserve'] ?? 50.0).toString();
          });
        }
      }
    } catch (e) {
      print("Lỗi tải cấu hình: $e");
    }
  }

  Future<void> _saveFarmConfig() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(user.uid)
          .collection('config')
          .doc('farm_data')
          .set({
        'total_trees': int.tryParse(_totalTreesController.text) ?? 0,
        'water_reserve': double.tryParse(_waterReserveController.text) ?? 0.0,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã đồng bộ dữ liệu lên Cloud!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu: $e')));
    }
  }

  void _confirmIrrigation() async {
    Map<String, dynamic> rec = _calculateWaterAmount();
    int waterPerTreeLiters = rec['raw_amount'] ?? 50;
    int totalTrees = int.tryParse(_totalTreesController.text) ?? 0;
    double currentReserve = double.tryParse(_waterReserveController.text) ?? 0;

    double standardNeedM3 = (waterPerTreeLiters * totalTrees) / 1000;
    double actualNeedM3 = standardNeedM3;
    double savedM3 = 0;

    bool isRainy = _predictedRain24h > 10;
    bool isSoilWet = (_realtimeSoilMoisture ?? 0) > 70;

    if (isRainy || isSoilWet) {
      actualNeedM3 = 0;
      savedM3 = standardNeedM3;
    }

    double newReserve = currentReserve - actualNeedM3;
    if (newReserve < 0) newReserve = 0;

    setState(() {
      _waterReserveController.text = newReserve.toStringAsFixed(2);
    });
    await _saveFarmConfig();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("✅ Xác nhận tưới thành công"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRainy || isSoilWet)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                        isSoilWet
                            ? "Đất đang đủ ẩm (${_realtimeSoilMoisture}%). Đã tự động ghi nhận HOÃN TƯỚI."
                            : "Sắp mưa lớn (${_predictedRain24h.toStringAsFixed(1)}mm). Đã tự động ghi nhận HOÃN TƯỚI.",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            const Divider(),
            _buildDialogRow("Nhu cầu chuẩn:", "${standardNeedM3.toStringAsFixed(2)} m³"),
            _buildDialogRow("Thực tế tiêu thụ:", "${actualNeedM3.toStringAsFixed(2)} m³", isBold: true),
            _buildDialogRow("Hồ chứa còn lại:", "${newReserve.toStringAsFixed(2)} m³"),
            if (savedM3 > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("🎉 Bạn đã tiết kiệm được ${savedM3.toStringAsFixed(2)} m³ nước!", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
              )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Đóng"))
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // --- HÀM GỌI API THỜI TIẾT HIỆN TẠI ---
  Future<void> _fetchWeather(String locationName) async {
    if (_isViewingHistory) {
      setState(() => _isViewingHistory = false);
    }

    setState(() => _isFetchingWeather = true);

    final coords = locations[locationName];
    if (coords == null) return;

    final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=${coords['lat']}&lon=${coords['lon']}&appid=$openWeatherApiKey&units=metric&lang=vi"
    );

    _fetchForecast(coords['lat']!, coords['lon']!);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        double temp = (data['main']['temp'] as num).toDouble();
        double humidity = (data['main']['humidity'] as num).toDouble();
        String description = data['weather'][0]['main'];
        double rain1h = data.containsKey('rain') ? (data['rain']['1h'] as num?)?.toDouble() ?? 0.0 : 0.0;

        String mappedCondition = 'Nắng nhẹ';
        if (description == 'Rain' || description == 'Drizzle' || description == 'Thunderstorm') {
          mappedCondition = rain1h > 5 ? 'Mưa to' : 'Mưa nhẹ';
        } else if (description == 'Clouds') {
          mappedCondition = 'Âm u';
        } else if (description == 'Clear') {
          mappedCondition = temp > 33 ? 'Nắng gắt' : 'Nắng nhẹ';
        }

        setState(() {
          _currentTemp = temp;
          _currentHumidity = humidity;
          _rainVolume = rain1h;
          weatherCondition = mappedCondition;
          if (!_isViewingHistory) {
            _aiResult = null;
          }
          _aiError = null;
        });
      }
    } catch (e) {
      print("Lỗi kết nối thời tiết: $e");
    } finally {
      setState(() => _isFetchingWeather = false);
    }
  }

  // --- HÀM GỌI API DỰ BÁO 5 NGÀY ---
  Future<void> _fetchForecast(double lat, double lon) async {
    setState(() => _isForecastLoading = true);
    final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$openWeatherApiKey&units=metric&lang=vi"
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['list'];

        double totalRain = 0;
        for (int i = 0; i < 8 && i < list.length; i++) {
          if (list[i].containsKey('rain')) {
            totalRain += (list[i]['rain']['3h'] as num?)?.toDouble() ?? 0.0;
          }
        }

        List<dynamic> daily = [];
        String currentDay = "";

        for (var item in list) {
          String dateTimeText = item['dt_txt'];
          String day = dateTimeText.split(' ')[0];

          if (day != currentDay && dateTimeText.contains("12:00:00")) {
            daily.add(item);
            currentDay = day;
          }
        }
        if (daily.length < 5) {
          daily = [];
          currentDay = "";
          for (var item in list) {
            String day = item['dt_txt'].split(' ')[0];
            if (day != currentDay) {
              daily.add(item);
              currentDay = day;
            }
          }
        }

        setState(() {
          _predictedRain24h = totalRain;
          _dailyForecasts = daily.take(5).toList();
        });
      }
    } catch (e) {
      print("Lỗi dự báo: $e");
    } finally {
      setState(() => _isForecastLoading = false);
    }
  }

  Future<void> _saveAnalysisToFirestore(Map<String, dynamic> aiData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(user.uid)
          .collection('analyses')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'location': selectedLocation,
        'stage': selectedStage,
        'tree_age': treeAge,
        'weather': {
          'temp': _currentTemp,
          'humidity': _currentHumidity,
          'condition': weatherCondition
        },
        'ai_analysis': aiData,
      });
    } catch (e) {
      print("Lỗi lưu Firestore: $e");
    }
  }

  void _showAnalysisHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa đăng nhập, không thể xem lịch sử.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📜 Lịch sử Phân tích', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('artifacts')
                      .doc(_appId)
                      .collection('users')
                      .doc(user.uid)
                      .collection('analyses')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Center(child: Text('Lỗi tải dữ liệu'));
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return const Center(child: Text('Chưa có lịch sử nào.'));

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (ctx, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final Timestamp? ts = data['timestamp'] as Timestamp?;
                        final DateTime date = ts?.toDate() ?? DateTime.now();
                        final String dateStr = "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2,'0')}";

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                            child: const Icon(Icons.history, color: Colors.green),
                          ),
                          title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${data['stage']} - ${data['location']}"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            setState(() {
                              _aiResult = data['ai_analysis'];
                              selectedLocation = data['location'] ?? selectedLocation;
                              selectedStage = data['stage'] ?? selectedStage;
                              treeAge = data['tree_age'] ?? treeAge;

                              if (data['weather'] != null) {
                                _currentTemp = (data['weather']['temp'] as num?)?.toDouble();
                                _currentHumidity = (data['weather']['humidity'] as num?)?.toDouble();
                                weatherCondition = data['weather']['condition'] ?? weatherCondition;
                              }

                              _isViewingHistory = true;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã tải lại kết quả phân tích cũ.'), duration: Duration(seconds: 1))
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- LOGIC AI GEMINI (NÂNG CẤP ĐỌC IOT) ---
  Future<void> _askGemini() async {
    if (apiKey.isEmpty) {
      setState(() => _aiError = "Đang chạy trong môi trường demo không có API Key.");
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _aiResult = null;
      _aiError = null;
      _isViewingHistory = false;
    });

    final basicCalc = _calculateWaterAmount();

    String forecastSummary = "Không có dữ liệu dự báo";
    if (_dailyForecasts.isNotEmpty) {
      forecastSummary = _dailyForecasts.take(3).map((item) {
        final dateTxt = item['dt_txt'].split(' ')[0];
        final temp = (item['main']['temp'] as num).toDouble().toStringAsFixed(1);
        final rain = item.containsKey('rain') ? (item['rain']['3h'] as num?)?.toDouble() ?? 0.0 : 0.0;
        return "$dateTxt: ${temp}C, Mưa ${rain}mm";
      }).join("; ");
    }

    int totalTrees = int.tryParse(_totalTreesController.text) ?? 0;
    double reserve = double.tryParse(_waterReserveController.text) ?? 0;
    int waterPerTree = basicCalc['raw_amount'] ?? 50;
    double totalUsageM3 = (waterPerTree * totalTrees) / 1000;

    // --- [MỚI] Lấy dữ liệu IoT để gửi AI ---
    String iotSoil = _realtimeSoilMoisture != null ? "$_realtimeSoilMoisture%" : "Chưa kết nối";
    String iotPump = _iotPumpStatusTarget;
    String iotMode = _iotControlMode;

    final prompt = '''
      CONTEXT: Chuyên gia nông nghiệp sầu riêng tại $selectedLocation (Tây Nguyên).
      
      INPUT DATA:
      - Vườn: Tuổi $treeAge, Giai đoạn $selectedStage, Đất $soilType.
      - Hiện tại (API): ${_currentTemp ?? 'N/A'}C, Ẩm ${_currentHumidity ?? 'N/A'}%, Mưa ${_rainVolume ?? 0}mm, $weatherCondition.
      
      - DỮ LIỆU CẢM BIẾN THỰC TẾ (IOT):
        + Độ ẩm đất: $iotSoil
        + Trạng thái Bơm: $iotPump
        + Chế độ vận hành: $iotMode
      
      - Tài nguyên: $totalTrees cây, Hồ chứa còn $reserve m3.
      - Nhu cầu tưới (Máy tính): $waterPerTree L/cây => Tổng ${totalUsageM3.toStringAsFixed(2)} m3/lần.
      - Dự báo 3 ngày tới: $forecastSummary.

      NHIỆM VỤ:
      1. Phân tích tác động thời tiết và SO SÁNH với dữ liệu cảm biến thực tế.
      2. Đưa ra quyết định tưới dựa trên sự thật (Cảm biến):
         + Nếu Độ ẩm đất > 70%: Khuyên TUYỆT ĐỐI KHÔNG TƯỚI (dù lý thuyết bảo tưới).
         + Nếu Độ ẩm đất < 40% mà Bơm đang TẮT: Cảnh báo khẩn cấp bật bơm.
         + Nếu đang chế độ AUTO: Đánh giá xem hệ thống tự động có đang hoạt động hợp lý không.
      3. Kiểm tra nguồn nước dự trữ.

      OUTPUT FORMAT (JSON only, no markdown):
      {
        "weather_impact": "Phân tích ngắn gọn (tối đa 20 từ).",
        "water_action": "Quyết định tưới cụ thể (Dựa trên cả dự báo mưa và cảm biến đất).",
        "nutrition_tips": "Lời khuyên dinh dưỡng cho $selectedStage.",
        "summary_color": "#HexColor (Màu cảnh báo: đỏ/cam/xanh/tím)."
      }
    ''';

    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{ "parts": [{"text": prompt}] }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['candidates']?[0]['content']?['parts']?[0]['text'] ?? "{}";
        rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();

        try {
          final Map<String, dynamic> jsonResult = jsonDecode(rawText);
          setState(() => _aiResult = jsonResult);
          _saveAnalysisToFirestore(jsonResult);
        } catch (e) {
          setState(() => _aiError = "Lỗi đọc dữ liệu AI. Vui lòng thử lại.");
        }
      } else {
        setState(() => _aiError = "Lỗi kết nối AI: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _aiError = "Lỗi: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lịch Tưới Thông Minh'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showAnalysisHistory,
            tooltip: 'Xem lại lịch sử',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchWeather(selectedLocation),
            tooltip: 'Cập nhật thời tiết',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- [MỚI] IOT DASHBOARD (THAY THẾ HEADER THỜI TIẾT CŨ) ---
            _buildIoTDashboard(),

            // --- HEADER DỰ BÁO ---
            if (_isForecastLoading)
              const LinearProgressIndicator(minHeight: 2, color: Colors.orange)
            else if (_dailyForecasts.isNotEmpty)
              _buildForecastSection(),

            if (_isViewingHistory)
              Container(
                width: double.infinity,
                color: Colors.amber[100],
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.history, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Đang xem kết quả phân tích cũ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),

            // --- CẢNH BÁO THÔNG MINH ---
            if (!_isViewingHistory)
              _buildSmartAlert(),

            const SizedBox(height: 10),

            // --- [MỚI] BẢNG ĐIỀU KHIỂN BƠM ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPumpControlPanel(),
            ),

            const SizedBox(height: 20),

            // --- INPUT FIELDS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildDropdown('Khu vực canh tác', selectedLocation, locations.keys.toList(), (val) {
                    setState(() { selectedLocation = val!; _isViewingHistory = false; });
                    _fetchWeather(val!);
                  }, icon: Icons.location_on, color: Colors.red),

                  const SizedBox(height: 16),

                  _buildDropdown('Giai đoạn sinh trưởng', selectedStage, stages, (val) {
                    setState(() { selectedStage = val!; _aiResult = null; _isViewingHistory = false; });
                  }, icon: Icons.spa, color: Colors.green),

                  const SizedBox(height: 16),

                  _buildTreeAgeSlider(),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _buildDropdown('Loại đất', soilType, soilTypes, (val) {
                        setState(() { soilType = val!; _aiResult = null; _isViewingHistory = false; });
                      }, icon: Icons.landscape, color: Colors.brown)),
                      const SizedBox(width: 16),
                      // Hiển thị thời tiết API như dữ liệu tham khảo
                      Expanded(child: _buildReadOnlyField('Thời tiết (API)', weatherCondition, Icons.cloud, Colors.orange)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- QUẢN LÝ NGUỒN NƯỚC & DỰ TRỮ ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildWaterPlanningSection(),
            ),

            const SizedBox(height: 24),

            // --- KHUYẾN NGHỊ CƠ BẢN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildIrrigationRecommendation(),
            ),

            const SizedBox(height: 24),

            // --- AI SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAISection(),
            ),

            const SizedBox(height: 24),

            // --- LỊCH TƯỚI THÔNG MINH ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildWeeklySchedule(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStageDetails(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildWarningSigns(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- [SỬA LỖI] WIDGET DASHBOARD IOT HIỂN THỊ DỮ LIỆU THẬT ---
  Widget _buildIoTDashboard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildWeatherHeader();

    // Sử dụng _appId đã định nghĩa chung
    // Lắng nghe dữ liệu cảm biến và trạng thái bơm từ cùng một đường dẫn config/pump_control
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(user.uid)
          .collection('config')
          .doc('pump_control')
          .snapshots(),
      builder: (context, snapshot) {
        int soil = 0;
        // Sử dụng dữ liệu thật từ API thời tiết thay vì từ ESP32 giả lập
        double temp = _currentTemp ?? 0.0;
        double hum = _currentHumidity ?? 0.0;

        String pumpStatus = "OFF";
        bool hasData = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          soil = (data['soil'] as num?)?.toInt() ?? 0;
          // Không lấy temp/hum từ Firestore nữa (để tránh số 30.5 giả)
          pumpStatus = data['pump_status'] ?? "OFF";
          hasData = true;

          if (_realtimeSoilMoisture != soil) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if(mounted) setState(() => _realtimeSoilMoisture = soil);
            });
          }
        }

        if (_isViewingHistory) return _buildWeatherHeader();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[800]!, Colors.teal[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hasData ? "Dữ liệu Thực tế (IoT)" : "Đang kết nối cảm biến...",
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(selectedLocation, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: hasData ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi, size: 14, color: hasData ? Colors.greenAccent : Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(hasData ? "ONLINE" : "OFFLINE", style: TextStyle(color: hasData ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Cột 1: Độ ẩm đất
                  Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: soil / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(soil < 40 ? Colors.redAccent : Colors.white),
                            ),
                          ),
                          Column(
                            children: [
                              Text("$soil%", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const Text("Độ Ẩm Đất", style: TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                  // Cột 2: Trạng thái Bơm
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: pumpStatus == "ON" ? Colors.blue : Colors.white10,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30)
                        ),
                        child: Icon(Icons.water_drop_outlined,
                            size: 32,
                            color: pumpStatus == "ON" ? Colors.white : Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      Text(pumpStatus == "ON" ? "ĐANG TƯỚI" : "ĐANG TẮT",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  // Cột 3: Nhiệt độ / Ẩm không khí (Lấy từ API)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(children: [
                        const Icon(Icons.thermostat, color: Colors.orangeAccent, size: 16),
                        Text(" ${temp.toStringAsFixed(1)}°C", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.cloud, color: Colors.lightBlueAccent, size: 16),
                        Text(" ${hum.toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // --- [SỬA LỖI] BẢNG ĐIỀU KHIỂN CÓ PHẢN HỒI ---
  Widget _buildPumpControlPanel() {
    bool isAuto = _iotControlMode == "AUTO";
    // Check nút nào đang active
    bool isManualOn = !isAuto && _iotPumpStatusTarget == "ON";
    bool isManualOff = !isAuto && _iotPumpStatusTarget == "OFF";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("🎮 Bảng Điều Khiển Bơm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  Text(isAuto ? "Tự động" : "Thủ công", style: TextStyle(fontSize: 12, color: isAuto ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                  Switch(
                    value: isAuto,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      _sendCommandToPump(val, false); // Chuyển chế độ, mặc định tắt bơm an toàn
                    },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          if (isAuto)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: const [
                  Icon(Icons.auto_mode, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text("Hệ thống đang tự động tưới theo cảm biến. Bạn không cần thao tác.", style: TextStyle(color: Colors.green, fontSize: 13))),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSendingCommand ? null : () => _sendCommandToPump(false, true),
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text("BẬT BƠM"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isManualOn ? Colors.blue : Colors.grey[300], // Sáng lên nếu đang ON
                      foregroundColor: isManualOn ? Colors.white : Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSendingCommand ? null : () => _sendCommandToPump(false, false),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text("TẮT BƠM"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isManualOff ? Colors.red : Colors.grey[300], // Sáng lên nếu đang OFF
                      foregroundColor: isManualOff ? Colors.white : Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  // --- CÁC WIDGET CŨ (GIỮ NGUYÊN) ---

  Widget _buildWeatherHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.teal[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🕒 Dữ liệu lịch sử / Thời tiết API', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          if (_currentTemp != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedLocation, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('${_currentTemp!.toStringAsFixed(1)}°C', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    Text(weatherCondition, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.white),
                      Text('${_currentHumidity}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('Độ ẩm', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                )
              ],
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildForecastSection() {
    return Container(
      width: double.infinity,
      color: Colors.green[50],
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Icon(Icons.calendar_month, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text("Dự báo 5 ngày tới", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _dailyForecasts.length,
              itemBuilder: (context, index) {
                final item = _dailyForecasts[index];
                final dateTxt = item['dt_txt'].toString();
                final dateObj = DateTime.tryParse(dateTxt) ?? DateTime.now();
                final temp = (item['main']['temp'] as num).toDouble();
                final iconCode = item['weather'][0]['icon'];
                final rain = item.containsKey('rain') ? (item['rain']['3h'] as num?)?.toDouble() ?? 0.0 : 0.0;

                return Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${dateObj.day}/${dateObj.month}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Image.network("https://openweathermap.org/img/wn/$iconCode.png", width: 40, height: 40),
                      Text("${temp.toStringAsFixed(1)}°", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      if (rain > 0)
                        Text("${rain.toStringAsFixed(1)}mm", style: const TextStyle(fontSize: 10, color: Colors.blue)),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSmartAlert() {
    bool shouldPostpone = _predictedRain24h > 10;

    if (!shouldPostpone && _predictedRain24h <= 2) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: shouldPostpone ? Colors.orange[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: shouldPostpone ? Colors.orange : Colors.blue),
      ),
      child: Row(
        children: [
          Icon(
            shouldPostpone ? Icons.warning_amber : Icons.info_outline,
            color: shouldPostpone ? Colors.deepOrange : Colors.blue[800],
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shouldPostpone ? "KHUYẾN NGHỊ: HOÃN TƯỚI!" : "LƯU Ý THỜI TIẾT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: shouldPostpone ? Colors.deepOrange : Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shouldPostpone
                      ? "Dự báo có mưa lớn (${_predictedRain24h.toStringAsFixed(1)}mm) trong 24h tới. Hãy tận dụng nước mưa để tiết kiệm."
                      : "Sắp có mưa nhẹ (${_predictedRain24h.toStringAsFixed(1)}mm). Có thể giảm lượng nước tưới.",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWaterPlanningSection() {
    Map<String, dynamic> rec = _calculateWaterAmount();
    int waterPerTree = rec['raw_amount'] ?? 50;

    int totalTrees = int.tryParse(_totalTreesController.text) ?? 0;
    double reserveCapacityM3 = double.tryParse(_waterReserveController.text) ?? 0;

    double totalWaterNeededLiters = (waterPerTree * totalTrees).toDouble();
    double totalWaterNeededM3 = totalWaterNeededLiters / 1000;

    double remainingIrrigations = 0;
    if (totalWaterNeededM3 > 0) {
      remainingIrrigations = reserveCapacityM3 / totalWaterNeededM3;
    }

    bool isLowWater = remainingIrrigations < 3 && totalTrees > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🚰 Quản lý nguồn nước & Dự trữ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              IconButton(
                icon: const Icon(Icons.save, color: Colors.blue),
                tooltip: "Lưu cài đặt",
                onPressed: _saveFarmConfig,
              )
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _totalTreesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Tổng số cây',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    suffixText: 'cây',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _waterReserveController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Dung tích hồ',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    suffixText: 'm³',
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng nước cần/lần:', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '${totalWaterNeededM3.toStringAsFixed(1)} m³',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                  ),
                  Text('(${totalWaterNeededLiters.toInt()} lít)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.blue[200]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Dự trữ đủ tưới:', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        remainingIrrigations.isInfinite ? '∞' : remainingIrrigations.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isLowWater ? Colors.red : Colors.green[700]
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('lần', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          if (isLowWater) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.red[900]),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Cảnh báo: Nguồn nước thấp! Hãy cân nhắc giảm lượng tưới.', style: TextStyle(fontSize: 12, color: Colors.red[900], fontWeight: FontWeight.bold))),
                ],
              ),
            )
          ],

          const SizedBox(height: 16),

          // Nút Xác Nhận Tưới
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmIrrigation,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("XÁC NHẬN ĐÃ TƯỚI HÔM NAY"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIrrigationRecommendation() {
    Map<String, dynamic> recommendation = _calculateWaterAmount();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.cyan[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.blue, size: 28),
              const SizedBox(width: 10),
              const Text('Khuyến nghị cơ bản (Quy trình)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const Divider(),
          _buildInfoRow('Lượng nước:', recommendation['amount'], isHighlight: true),
          const SizedBox(height: 8),
          _buildInfoRow('Tần suất:', recommendation['frequency']),
          const SizedBox(height: 8),
          _buildInfoRow('Thời điểm:', recommendation['time']),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(8)),
            child: Text(recommendation['note'], style: TextStyle(fontSize: 12, color: Colors.amber[900])),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isHighlight ? Colors.blue[800] : Colors.black87, fontSize: isHighlight ? 16 : 14)),
      ],
    );
  }

  Map<String, dynamic> _calculateWaterAmount() {
    int baseAmount = 50;
    if (treeAge <= 5) { baseAmount = 50; } else if (treeAge <= 10) { baseAmount = 100; } else { baseAmount = 200; }
    if (soilType == 'Đất thịt pha cát') { baseAmount = (baseAmount * 1.2).toInt(); } else if (soilType == 'Đất đỏ bazan') { baseAmount = (baseAmount * 1.0).toInt(); }
    if (weatherCondition == 'Nắng gắt') { baseAmount = (baseAmount * 1.3).toInt(); } else if (weatherCondition == 'Mưa nhẹ') { baseAmount = (baseAmount * 0.7).toInt(); } else if (weatherCondition == 'Mưa to') { baseAmount = (baseAmount * 0.3).toInt(); }

    String frequency = '', soilMoisture = '', note = '';
    switch (selectedStage) {
      case 'Ra hoa': frequency = '1-2 lần/tuần'; soilMoisture = '60-70%'; note = 'Giảm tưới kích thích hoa.'; break;
      case 'Đậu trái': baseAmount = (baseAmount * 1.2).toInt(); frequency = '2-3 lần/tuần'; soilMoisture = '70-80%'; note = 'Tránh sốc nước rụng trái.'; break;
      case 'Phát triển trái': baseAmount = (baseAmount * 1.5).toInt(); frequency = '2-3 lần/tuần'; soilMoisture = '75-85%'; note = 'Đủ nước nuôi cơm trái.'; break;
      case 'Thu hoạch': frequency = '1-2 lần/tuần'; soilMoisture = '50-60%'; note = 'Cắt nước trước thu hoạch.'; break;
      default: frequency = '1 lần/tuần'; soilMoisture = '40-50%'; note = 'Dưỡng cây.';
    }

    // [LOGIC MỚI] Ưu tiên dữ liệu cảm biến thực tế
    if (_realtimeSoilMoisture != null && _realtimeSoilMoisture! > 70) {
      note = "ĐẤT ĐỦ ẨM (${_realtimeSoilMoisture}%): Hệ thống khuyến nghị KHÔNG CẦN TƯỚI.";
    } else if (_predictedRain24h > 10) {
      note = "DỰ BÁO MƯA LỚN: Nên tạm ngưng hoặc giảm tưới để tiết kiệm nước!";
    }

    return { 'raw_amount': baseAmount, 'amount': '${baseAmount - 20}-$baseAmount L/gốc', 'frequency': frequency, 'time': 'Sáng sớm/Chiều mát', 'soil_moisture': soilMoisture, 'note': note };
  }

  Widget _buildAISection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _askGemini,
            icon: _isAnalyzing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.psychology_alt),
            label: Text(_isAnalyzing ? 'ĐANG KẾT NỐI CHUYÊN GIA...' : 'HỎI CHUYÊN GIA AI (LƯU KẾT QUẢ)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        if (_aiError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_aiError!, style: const TextStyle(color: Colors.red)),
          ),

        if (_aiResult != null) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isViewingHistory ? Colors.amber[50] : Colors.deepPurple[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: _isViewingHistory ? Colors.amber[800] : Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                          _isViewingHistory ? 'KẾT QUẢ LỊCH SỬ' : 'PHÂN TÍCH CHUYÊN SÂU',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _isViewingHistory ? Colors.amber[900] : Colors.deepPurple)
                      ),
                      const Spacer(),
                      if (!_isViewingHistory) ...[
                        const Icon(Icons.cloud_done, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('Đã lưu', style: TextStyle(fontSize: 10, color: Colors.green[700])),
                      ]
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildAIItem(
                        icon: Icons.thermostat,
                        color: Colors.orange,
                        title: "Tác động thời tiết",
                        content: _aiResult!['weather_impact'] ?? '',
                      ),
                      const Divider(height: 24),
                      _buildAIItem(
                        icon: Icons.water_drop,
                        color: Colors.blue,
                        title: "Điều chỉnh tưới",
                        content: _aiResult!['water_action'] ?? '',
                        isBold: true,
                      ),
                      const Divider(height: 24),
                      _buildAIItem(
                        icon: Icons.science,
                        color: Colors.green,
                        title: "Dinh dưỡng & Phân bón",
                        content: _aiResult!['nutrition_tips'] ?? '',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildAIItem({required IconData icon, required Color color, required String title, required String content, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(content, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.black87, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, {required IconData icon, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(icon, color: color),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreeAgeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tuổi cây (năm)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.3))),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('3 năm', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  Text('$treeAge năm', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('15 năm', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
              Slider(
                value: treeAge.toDouble(),
                min: 3, max: 15, divisions: 12,
                activeColor: Colors.blue,
                onChanged: (val) => setState(() { treeAge = val.toInt(); _aiResult = null; _isViewingHistory = false; }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySchedule() {
    List<Map<String, dynamic>> schedule = _getSmartWeeklySchedule();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Lịch tưới tuần này (Thông minh)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: schedule.map((item) {
              int status = item['status'];
              bool isToday = item['isToday'];
              bool isPast = item['isPast'];
              String day = item['day'];
              String date = item['date'];

              Color bgColor = Colors.grey[100]!;
              Color iconColor = Colors.grey[400]!;
              IconData icon = Icons.circle_outlined;

              if (status == 1) {
                bgColor = Colors.blue[100]!;
                iconColor = Colors.blue[700]!;
                icon = Icons.water_drop;
              } else if (status == 2) {
                bgColor = Colors.orange[100]!;
                iconColor = Colors.orange[700]!;
                icon = Icons.cloud_off;
              }

              if (isPast) {
                if (status > 0) {
                  bgColor = Colors.grey[300]!;
                  iconColor = Colors.grey[600]!;
                  icon = Icons.check_circle;
                }
              }

              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: Colors.orange, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Center(
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.orange[800] : Colors.grey[700],
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.water_drop, size: 12, color: Colors.blue),
              Text(' Cần tưới ', style: TextStyle(fontSize: 11)),
              SizedBox(width: 8),
              Icon(Icons.cloud_off, size: 12, color: Colors.orange),
              Text(' Hoãn (Mưa) ', style: TextStyle(fontSize: 11)),
              SizedBox(width: 8),
              Icon(Icons.circle_outlined, size: 12, color: Colors.grey),
              Text(' Nghỉ', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSmartWeeklySchedule() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    DateTime startOfWeek = now.subtract(Duration(days: currentWeekday - 1));

    List<bool> basePattern = _getBaseSchedulePattern();

    List<Map<String, dynamic>> result = [];

    for (int i = 0; i < 7; i++) {
      DateTime date = startOfWeek.add(Duration(days: i));
      bool isToday = (date.year == now.year && date.month == now.month && date.day == now.day);

      DateTime dateOnly = DateTime(date.year, date.month, date.day);
      DateTime nowOnly = DateTime(now.year, now.month, now.day);
      bool isPast = dateOnly.isBefore(nowOnly);

      double predictedRain = 0.0;
      for (var item in _dailyForecasts) {
        String dtTxt = item['dt_txt'] ?? '';
        DateTime itemDate = DateTime.tryParse(dtTxt) ?? DateTime(1970);

        if (itemDate.year == date.year && itemDate.month == date.month && itemDate.day == date.day) {
          if (item['weather'][0]['main'] == 'Rain') {
            predictedRain = 15.0;
          } else if (item.containsKey('rain')) {
            predictedRain = (item['rain']['3h'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }

      int status = 0;
      if (basePattern[i]) {
        if (predictedRain > 5.0) {
          status = 2;
        } else {
          status = 1;
        }
      } else {
        status = 0;
      }

      result.add({
        'day': ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][i],
        'date': "${date.day}/${date.month}",
        'status': status,
        'isToday': isToday,
        'isPast': isPast,
      });
    }
    return result;
  }

  List<bool> _getBaseSchedulePattern() {
    if (selectedStage == 'Ra hoa') return [true, false, false, true, false, false, false];
    if (selectedStage == 'Đậu trái' || selectedStage == 'Phát triển trái') return [true, false, true, false, true, false, false];
    if (selectedStage == 'Thu hoạch') return [true, false, false, false, true, false, false];
    return [true, false, false, false, false, false, false];
  }

  Widget _buildStageDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📌 Thông tin giai đoạn', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 8),
        Text(_getStageDetails(selectedStage), style: const TextStyle(fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _buildWarningSigns() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⚠️ Dấu hiệu cần chú ý', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 8),
        const Text('• Thiếu nước: Lá héo ngày nắng, vàng mép lá.\n• Thừa nước: Rễ đen, lá vàng rụng, đất nhão.', style: TextStyle(fontSize: 13, height: 1.5)),
      ]),
    );
  }

  String _getStageDetails(String stage) {
    if (stage == 'Ra hoa') return 'Cần khô hạn để phân hóa mầm hoa. Tưới lại khi mắt cua sáng.';
    if (stage == 'Đậu trái') return 'Giữ ẩm ổn định. Sốc nước sẽ gây rụng trái non hàng loạt.';
    if (stage == 'Phát triển trái') return 'Giai đoạn cần nhiều nước và dinh dưỡng nhất để lớn trái.';
    if (stage == 'Thu hoạch') return 'Cắt nước 15-20 ngày trước thu hoạch để cơm khô ráo, ngọt.';
    return 'Giai đoạn phục hồi cây sau thu hoạch.';
  }
}