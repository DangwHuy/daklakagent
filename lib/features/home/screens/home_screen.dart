import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'price_screen.dart';
import 'irrigation_screen.dart';
import 'pest_disease_screen.dart';
import 'expert_screen.dart' hide AnalyzeDiseaseScreen;
import 'FarmerView.dart';
import 'disease.dart';

// Import màn hình Chat AI, Thời tiết & Profile mới
import 'package:daklakagent/features/ai/screens/ai_chat.dart';
import 'package:daklakagent/features/weather/Screens/weather_screen.dart';
import 'package:daklakagent/features/home/screens/profile_screen.dart';

import '../widgets/banner_carousel.dart';

// ==========================================
// MÀN HÌNH CHÍNH CÓ BOTTOM NAVIGATION BAR (V4.0)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình tương ứng với các Tab ở Bottom Navigation
  final List<Widget> _screens = [
    const HomeContent(), // Tab 0: Trang chủ
    const WeatherScreen(initialLocation: 'Buôn Ma Thuột'), // Tab 1: Thời tiết
    const AiChatScreen(), // Tab 2: Trợ lý AI
    const ProfileScreen(), // Tab 3: Cá nhân (Giao diện Profile đầy đủ)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: Colors.green[100],
        destinations: [
          NavigationDestination(
            selectedIcon: Icon(Icons.home, color: Colors.green[800], size: 28),
            icon: const Icon(Icons.home_outlined, color: Colors.grey),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.cloud, color: Colors.green[800], size: 28),
            icon: const Icon(Icons.cloud_outlined, color: Colors.grey),
            label: 'Thời tiết',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.smart_toy, color: Colors.green[800], size: 28),
            icon: const Icon(Icons.smart_toy_outlined, color: Colors.grey),
            label: 'Trợ lý AI',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person, color: Colors.green[800], size: 28),
            icon: const Icon(Icons.person_outline, color: Colors.grey),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// NỘI DUNG TRANG CHỦ (HomeContent)
// ==========================================

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  void _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  void _openAiChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AiChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

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
                child: Column(
                  children: [
                    // LẮNG NGHE SỰ THAY ĐỔI CỦA USER ĐỂ CẬP NHẬT GIAO DIỆN
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.userChanges(),
                      builder: (context, snapshot) {
                        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
                        return _buildWelcomeCard(user);
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildAiSearchBar(context),
                  ],
                ),
              ),

              const BannerCarousel(),

              const SizedBox(height: 20),



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
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

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

  // CARD HIỂN THỊ AVATAR & TÊN ĐÃ ĐƯỢC NÂNG CẤP ĐỂ TỰ ĐỘNG LẤY ẢNH URL
  Widget _buildWelcomeCard(User? user) {
    // Lấy tên hiển thị, nếu không có thì lấy email, không có nữa thì gán mặc định
    String displayName = user?.displayName ?? user?.email ?? "Nhà nông 4.0";
    String? photoUrl = user?.photoURL;

    return Row(
      children: [
        Container(
          padding: photoUrl == null ? const EdgeInsets.all(12) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: photoUrl != null
              ? CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(photoUrl),
            backgroundColor: Colors.transparent,
          )
              : const Icon(Icons.person, color: Colors.white, size: 32),
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
                displayName,
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
                MaterialPageRoute(builder: (context) => const AgriPriceHome()),
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
            icon: Icons.calendar_month_outlined,
            label: "Đặt lịch Chuyên gia",
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FindExpertScreen()),
              );
            },
          ),
          _FeatureCard(
            icon: Icons.camera_alt_outlined,
            label: "Phân tích ảnh bệnh",
            color: Colors.green,
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

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listData.map((item) => _buildSmartCardShort(item)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSmartCardShort(dynamic item) {
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

    int maxRisk = [chiSoLuLut, chiSoNam, chiSoStress].reduce((curr, next) => curr > next ? curr : next);

    Color statusColor = const Color(0xFF2E7D32);
    String statusText = "Môi trường ổn định";
    IconData statusIcon = Icons.check_box;

    if (maxRisk >= 70) {
      statusColor = const Color(0xFFD32F2F);
      statusText = "Nguy hiểm (Chi tiết >)";
      statusIcon = Icons.warning;
    } else if (maxRisk >= 40) {
      statusColor = const Color(0xFFEF6C00);
      statusText = "Cảnh báo (Chi tiết >)";
      statusIcon = Icons.info;
    } else {
      statusText = "Môi trường ổn định (Chi tiết >)";
    }

    return Container(
      width: 340,
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.red[700], size: 20),
                      const SizedBox(width: 6),
                      Text("$khuVuc (${caoDo}m)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeatherStat(Icons.water_drop_outlined, "$doAm%", "(Ẩm)"),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      _buildWeatherStat(Icons.air, "${gio}m/s", "(Gió)"),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      _buildWeatherStat(Icons.cloud_queue, "${mua1h}mm", "(Mưa)"),
                    ],
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeatherScreen(
                      initialLocation: khuVuc,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(19),
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
}

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