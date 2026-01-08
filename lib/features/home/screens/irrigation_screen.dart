import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm Firestore

// --- CONFIGURATION ---
const String apiKey = ""; // API Key Gemini (Hệ thống sẽ tự điền khi chạy)
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

    // Đăng nhập ẩn danh để có quyền ghi Firestore
    if (FirebaseAuth.instance.currentUser == null) {
      // Ưu tiên dùng token nếu có (được inject từ môi trường Canvas)
      await FirebaseAuth.instance.signInAnonymously();
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
  bool _isViewingHistory = false; // Cờ đánh dấu đang xem lịch sử

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
  }

  // --- HÀM GỌI API THỜI TIẾT ---
  Future<void> _fetchWeather(String locationName) async {
    // Nếu đang xem lịch sử mà người dùng đổi địa điểm -> quay về chế độ Live
    if (_isViewingHistory) {
      setState(() => _isViewingHistory = false);
    }

    setState(() => _isFetchingWeather = true);

    final coords = locations[locationName];
    if (coords == null) return;

    final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=${coords['lat']}&lon=${coords['lon']}&appid=$openWeatherApiKey&units=metric&lang=vi"
    );

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
            _aiResult = null; // Reset AI nếu đang ở chế độ live
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

  // --- LOGIC LƯU FIRESTORE ---
  Future<void> _saveAnalysisToFirestore(Map<String, dynamic> aiData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    const String appId = String.fromEnvironment('__app_id', defaultValue: 'default-app-id');

    try {
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc(appId)
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

      // Không hiện snackbar làm phiền nữa, lưu ngầm thôi
    } catch (e) {
      print("Lỗi lưu Firestore: $e");
    }
  }

  // --- HIỂN THỊ LỊCH SỬ (MỚI THÊM) ---
  void _showAnalysisHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa đăng nhập, không thể xem lịch sử.')));
      return;
    }

    const String appId = String.fromEnvironment('__app_id', defaultValue: 'default-app-id');

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
                      .doc(appId)
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
                            // KHÔI PHỤC TRẠNG THÁI CŨ
                            setState(() {
                              _aiResult = data['ai_analysis'];
                              selectedLocation = data['location'] ?? selectedLocation;
                              selectedStage = data['stage'] ?? selectedStage;
                              treeAge = data['tree_age'] ?? treeAge;

                              // Khôi phục cả thời tiết lúc đó để ngữ cảnh đúng
                              if (data['weather'] != null) {
                                _currentTemp = (data['weather']['temp'] as num?)?.toDouble();
                                _currentHumidity = (data['weather']['humidity'] as num?)?.toDouble();
                                weatherCondition = data['weather']['condition'] ?? weatherCondition;
                              }

                              _isViewingHistory = true; // Đánh dấu đang xem lại
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

  // --- LOGIC AI GEMINI ---
  Future<void> _askGemini() async {
    if (apiKey.isEmpty) {
      setState(() => _aiError = "Đang chạy trong môi trường demo không có API Key.");
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _aiResult = null;
      _aiError = null;
      _isViewingHistory = false; // Reset cờ xem lịch sử khi phân tích mới
    });

    final basicCalc = _calculateWaterAmount();

    // Prompt JSON
    final prompt = '''
      Tôi là nông dân trồng sầu riêng tại $selectedLocation, Đăk Lăk.
      
      DỮ LIỆU THỰC TẾ:
      - Nhiệt độ: ${_currentTemp ?? 'N/A'}°C
      - Độ ẩm: ${_currentHumidity ?? 'N/A'}%
      - Lượng mưa: ${_rainVolume ?? 0}mm
      - Trạng thái: $weatherCondition
      - Giai đoạn: $selectedStage
      - Tuổi cây: $treeAge năm
      - Loại đất: $soilType
      
      GỢI Ý CƠ BẢN: ${basicCalc['amount']}, tần suất ${basicCalc['frequency']}
      
      Hãy đóng vai chuyên gia nông nghiệp, phân tích và trả về kết quả dưới định dạng **JSON THUẦN** (không markdown, không code block) với các trường sau:
      {
        "weather_impact": "Phân tích ngắn gọn về ảnh hưởng của thời tiết hôm nay lên cây (tối đa 2 câu).",
        "water_action": "Hành động cụ thể về tưới nước hôm nay (tăng/giảm bao nhiêu %, lưu ý gì).",
        "nutrition_tips": "Lời khuyên dinh dưỡng/phân bón ngắn gọn cho giai đoạn này.",
        "summary_color": "Mã màu hex (ví dụ #FF0000 cho cảnh báo, #00AA00 cho tốt) thể hiện mức độ khẩn cấp."
      }
      Đảm bảo JSON hợp lệ.
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
            icon: const Icon(Icons.history), // Nút Lịch sử mới
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
            // --- HEADER THỜI TIẾT ---
            _buildWeatherHeader(),

            // Cảnh báo nếu đang xem lịch sử
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

            const SizedBox(height: 20),

            // --- INPUT FIELDS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildDropdown('Khu vực canh tác', selectedLocation, locations.keys.toList(), (val) {
                    setState(() { selectedLocation = val!; _isViewingHistory = false; }); // Reset history flag
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
                      Expanded(child: _buildReadOnlyField('Thời tiết (API)', weatherCondition, Icons.cloud, Colors.orange)),
                    ],
                  )
                ],
              ),
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

  // --- WIDGET HEADER ---
  Widget _buildWeatherHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isViewingHistory
              ? [Colors.grey[700]!, Colors.blueGrey[500]!] // Màu khác khi xem lịch sử
              : [Colors.green[700]!, Colors.teal[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isViewingHistory ? '🕒 Dữ liệu lịch sử' : '⛅ Thời Tiết Thời Gian Thực',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          if (_currentTemp != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedLocation, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      '${_currentTemp!.toStringAsFixed(1)}°C',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      weatherCondition,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
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

  // --- WIDGET AI SECTION ---
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
                // Header Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isViewingHistory ? Colors.amber[50] : Colors.deepPurple[50], // Màu nền thay đổi
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

                // Body Card
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

  // --- CÁC WIDGET HELPER KHÁC (GIỮ NGUYÊN) ---

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

  // --- LOGIC CŨ GIỮ NGUYÊN ---
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

  // Logic tính toán (Không đổi)
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
    return { 'amount': '${baseAmount - 20}-$baseAmount L/gốc', 'frequency': frequency, 'time': 'Sáng sớm/Chiều mát', 'soil_moisture': soilMoisture, 'note': note };
  }

  Widget _buildWeeklySchedule() {
    List<bool> schedule = _getWeeklySchedule();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📅 Lịch tưới tuần này', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: schedule[i] ? Colors.blue : Colors.grey[200],
                    child: Icon(Icons.water_drop, size: 16, color: schedule[i] ? Colors.white : Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(['T2','T3','T4','T5','T6','T7','CN'][i], style: const TextStyle(fontSize: 10)),
                ],
              );
            }),
          )
        ],
      ),
    );
  }

  List<bool> _getWeeklySchedule() {
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