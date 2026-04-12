import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'price_screen.dart';
import 'irrigation_screen.dart';
import 'pest_disease_screen.dart';
import 'expert_screen.dart' hide AnalyzeDiseaseScreen;
import 'FarmerView.dart';
import 'disease.dart';
import 'package:daklakagent/features/home/screens/chat_screen.dart';
import 'expert_chat_list_screen.dart'; // Import danh sách tin nhắn
// Import màn hình Chat AI, Thời tiết & Profile mới
import 'package:daklakagent/features/ai/screens/ai_chat.dart';
import 'package:daklakagent/features/weather/Screens/weather_screen.dart';
import 'package:daklakagent/features/home/screens/profile_screen.dart';
import 'package:daklakagent/features/auth/screens/login_screen.dart';
import 'notification_screen.dart';
import 'farm_diary_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/banner_carousel.dart';
import 'dart:convert';

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
  bool _showAiBot = true;

  // Danh sách các màn hình tương ứng với các Tab ở Bottom Navigation
  final List<Widget> _screens = [
    const HomeContent(), // Tab 0: Trang chủ
    const WeatherScreen(initialLocation: 'Buôn Ma Thuột'), // Tab 1: Thời tiết
    const ExpertChatListScreen(), // Tab 2: Tin nhắn
    const ProfileScreen(), // Tab 3: Cá nhân (Giao diện Profile đầy đủ)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Content flows under the bottom nav bar
      body: Stack(
        children: [
          _screens[_selectedIndex],
          if (_showAiBot)
            DraggableAiBot(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiChatScreen()),
                );
              },
              onDismiss: () {
                setState(() {
                  _showAiBot = false;
                });
              },
            ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: NavigationBar(
            height: 65,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: Colors.green[100],
            destinations: [
              NavigationDestination(
                selectedIcon: Icon(
                  Icons.home,
                  color: Colors.green[800],
                  size: 26,
                ),
                icon: const Icon(Icons.home_outlined, color: Colors.grey),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                selectedIcon: Icon(
                  Icons.cloud,
                  color: Colors.green[800],
                  size: 26,
                ),
                icon: const Icon(Icons.cloud_outlined, color: Colors.grey),
                label: 'Thời tiết',
              ),
              NavigationDestination(
                selectedIcon: Icon(
                  Icons.message,
                  color: Colors.green[800],
                  size: 26,
                ),
                icon: const Icon(Icons.message_outlined, color: Colors.grey),
                label: 'Tin nhắn',
              ),
              NavigationDestination(
                selectedIcon: Icon(
                  Icons.person,
                  color: Colors.green[800],
                  size: 26,
                ),
                icon: const Icon(Icons.person_outline, color: Colors.grey),
                label: 'Cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// NỘI DUNG TRANG CHỦ (HomeContent)
// ==========================================

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

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
              // Curved Header & Floating Search
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Curved Header Background
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 20,
                      16,
                      60,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[700]!, Colors.green[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.userChanges(),
                      builder: (context, snapshot) {
                        final user =
                            snapshot.data ?? FirebaseAuth.instance.currentUser;
                        return _buildWelcomeCard(context, user);
                      },
                    ),
                  ),
                  // Floating Search Bar
                  Positioned(
                    bottom: -25,
                    left: 16,
                    right: 16,
                    child: _buildAiSearchBar(context),
                  ),
                ],
              ),
              const SizedBox(height: 45), // Lề bù không gian

              const BannerCarousel(),

              const SizedBox(height: 20),

              // Tiêu đề phân tích (Đã ẩn)
              Visibility(
                visible: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: Colors.green[700],
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Phân Tích Thông Minh AI v3.5",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.water_damage,
                                  color: Colors.red[700],
                                  size: 14,
                                ),
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
                  ],
                ),
              ),

              // Tiện ích
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.apps, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    const Text(
                      "Tiện ích nông nghiệp",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              _buildGridMenu(context),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiSearchBar(BuildContext context) {
    return InkWell(
      onTap: () {
        showSearch(context: context, delegate: AppSearchDelegate());
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.green[700], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Tìm kiếm tiện ích, chuyên gia...",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic, color: Colors.green[700], size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // CARD HIỂN THỊ AVATAR & TÊN ĐÃ ĐƯỢC NÂNG CẤP ĐỂ TỰ ĐỘNG LẤY ẢNH URL
  Widget _buildWelcomeCard(BuildContext context, User? user) {
    // Lấy tên hiển thị, nếu không có thì lấy email, không có nữa thì gán mặc định
    String displayName = user?.displayName ?? user?.email ?? "Nhà nông 4.0";
    String? photoUrl = user?.photoURL;

    return Row(
      children: [
        // Phần Welcome & Info
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: photoUrl == null
                      ? const EdgeInsets.all(12)
                      : EdgeInsets.zero,
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
            ),
          ),
        ),

        // Nút thời tiết mini
        const WeatherMiniBadge(),
        const SizedBox(width: 8),

        // Nút thông báo
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('receiverId', isEqualTo: user?.uid ?? '')
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = snapshot.data?.docs.length ?? 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      if (user == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                ),
                // Chấm đỏ thông báo
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green[700]!, width: 2),
                      ),
                      child: Text(
                        unreadCount > 9 ? "9+" : "$unreadCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green[800]!, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.blueGrey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryTitle("Chuyên Gia & AI", Icons.smart_toy_outlined),
          const SizedBox(height: 8),
          GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _FeatureCard(
                icon: Icons.forum_outlined,
                label: "AI Phân Tích",
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpertScreen(),
                    ),
                  );
                },
              ),
              _FeatureCard(
                icon: Icons.calendar_month_outlined,
                label: "Đặt Lịch Chuyên Gia",
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FindExpertScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildCategoryTitle("Tra Cứu & Chăm Sóc", Icons.eco_outlined),
          const SizedBox(height: 8),
          GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _FeatureCard(
                icon: Icons.water_drop_outlined,
                label: "Lịch Tưới",
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IrrigationScreen(),
                    ),
                  );
                },
              ),
              _FeatureCard(
                icon: Icons.bug_report_outlined,
                label: "Tra Cứu Sâu Bệnh",
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PestDiseaseScreen(),
                    ),
                  );
                },
              ),
              _FeatureCard(
                icon: Icons.camera_alt_outlined,
                label: "Phân Tích Ảnh Bệnh",
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
          const SizedBox(height: 16),

          _buildCategoryTitle(
            "Thương Mại & Cộng Đồng",
            Icons.storefront_outlined,
          ),
          const SizedBox(height: 8),
          GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _FeatureCard(
                icon: Icons.store_mall_directory_outlined,
                label: "Chợ Trực Tuyến",
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chức năng đang phát triển")),
                  );
                },
              ),
              _FeatureCard(
                icon: Icons.trending_up,
                label: "Giá Nông Sản",
                color: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgriPriceHome(),
                    ),
                  );
                },
              ),
              _FeatureCard(
                icon: Icons.groups_outlined,
                label: "Diễn Đàn Nông Nghiệp",
                color: Colors.indigo,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chức năng đang phát triển")),
                  );
                },
              ),
            ],
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

  final String pythonApiUrl =
      'https://arica-baldish-consuelo.ngrok-free.dev/api/phan-tich-sau-rieng';

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
      final response = await http
          .get(
            Uri.parse(pythonApiUrl),
            headers: {
              "ngrok-skip-browser-warning": "true",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 15));

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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
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
            children: listData
                .map((item) => _buildSmartCardShort(item))
                .toList(),
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

    int maxRisk = [
      chiSoLuLut,
      chiSoNam,
      chiSoStress,
    ].reduce((curr, next) => curr > next ? curr : next);

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
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
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
                      Text(
                        "$khuVuc (${caoDo}m)",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      Image.network(
                        "https://openweathermap.org/img/wn/$iconThoiTiet@2x.png",
                        width: 80,
                        height: 80,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.cloud,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "$nhietDo°C",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        moTa,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeatherStat(
                        Icons.water_drop_outlined,
                        "$doAm%",
                        "(Ẩm)",
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      _buildWeatherStat(Icons.air, "${gio}m/s", "(Gió)"),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      _buildWeatherStat(
                        Icons.cloud_queue,
                        "${mua1h}mm",
                        "(Mưa)",
                      ),
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
                    builder: (context) =>
                        WeatherScreen(initialLocation: khuVuc),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white70,
                      size: 18,
                    ),
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
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// ==========================================
// WIDGET HIỂN THỊ THỜI TIẾT MINI (BẢN TIN NHỎ)
// ==========================================
class WeatherMiniBadge extends StatefulWidget {
  const WeatherMiniBadge({super.key});

  @override
  State<WeatherMiniBadge> createState() => _WeatherMiniBadgeState();
}

class _WeatherMiniBadgeState extends State<WeatherMiniBadge> {
  String _weatherText = "--°";
  String _humidityText = "--%";
  bool _showTemp = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _showTemp = !_showTemp;
        });
      }
    });
  }

  Future<void> _fetchWeather() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://arica-baldish-consuelo.ngrok-free.dev/api/phan-tich-sau-rieng',
            ),
            headers: {
              "ngrok-skip-browser-warning": "true",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final listData = data['du_lieu'] as List<dynamic>? ?? [];
        if (listData.isNotEmpty) {
          final item = listData[0]; // Lấy của khu vực đầu tiên
          final nhietDo = (item['nhiet_do'] as num?)?.round() ?? 0;
          final doAm = (item['do_am'] as num?)?.round() ?? 0;
          if (mounted) {
            setState(() {
              _weatherText = "$nhietDo°";
              _humidityText = "$doAm%";
            });
          }
        }
      }
    } catch (e) {
      // Im lặng nếu không tới được server (tránh làm crash UI màn chính)
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const WeatherScreen(initialLocation: 'Buôn Ma Thuột'),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _showTemp
              ? Row(
                  key: const ValueKey("temp"),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.thermostat, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _weatherText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey("hum"),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _humidityText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.7), color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 26, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Tìm kiếm chức năng, tiện ích...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70, fontSize: 16),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  // Danh sách TẤT CẢ chức năng của app
  List<_SearchItem> get _allFeatures => [
    // --- Chuyên gia & AI ---
    _SearchItem(
      name: "AI Phân Tích Chuyên Sâu",
      description: "Phân tích sâu bệnh, thời tiết bằng AI",
      icon: Icons.forum_outlined,
      color: Colors.purple,
      category: "Chuyên gia & AI",
      builder: () => const ExpertScreen(),
    ),
    _SearchItem(
      name: "Đặt Lịch Chuyên Gia",
      description: "Tìm và đặt lịch hẹn với chuyên gia nông nghiệp",
      icon: Icons.calendar_month_outlined,
      color: Colors.teal,
      category: "Chuyên gia & AI",
      builder: () => const FindExpertScreen(),
    ),
    _SearchItem(
      name: "Trò chuyện AI",
      description: "Hỏi đáp với trợ lý AI thông minh",
      icon: Icons.smart_toy_outlined,
      color: Colors.deepPurple,
      category: "Chuyên gia & AI",
      builder: () => const AiChatScreen(),
    ),

    // --- Tra cứu & Chăm sóc ---
    _SearchItem(
      name: "Lịch Tưới",
      description: "Quản lý lịch tưới tiêu cho cây trồng",
      icon: Icons.water_drop_outlined,
      color: Colors.blue,
      category: "Tra cứu & Chăm sóc",
      builder: () => const IrrigationScreen(),
    ),
    _SearchItem(
      name: "Tra cứu sâu bệnh",
      description: "Tra cứu thông tin các loại sâu bệnh hại",
      icon: Icons.bug_report_outlined,
      color: Colors.red,
      category: "Tra cứu & Chăm sóc",
      builder: () => const PestDiseaseScreen(),
    ),
    _SearchItem(
      name: "Phân tích ảnh bệnh",
      description: "Chụp ảnh lá cây để AI nhận diện bệnh",
      icon: Icons.camera_alt_outlined,
      color: Colors.green,
      category: "Tra cứu & Chăm sóc",
      builder: () => const AnalyzeDiseaseScreen(),
    ),

    // --- Thương mại & Cộng đồng ---
    _SearchItem(
      name: "Giá Nông Sản",
      description: "Cập nhật giá sầu riêng, cà phê, hồ tiêu...",
      icon: Icons.trending_up,
      color: Colors.amber,
      category: "Thương mại & Cộng đồng",
      builder: () => const AgriPriceHome(),
    ),

    // --- Thời tiết ---
    _SearchItem(
      name: "Chi tiết thời tiết",
      description: "Xem thời tiết, cảnh báo thiên tai khu vực",
      icon: Icons.cloud_outlined,
      color: Colors.lightBlue,
      category: "Thời tiết",
      builder: () => const WeatherScreen(initialLocation: 'Buôn Ma Thuột'),
    ),

    // --- Cá nhân ---
    _SearchItem(
      name: "Hồ sơ cá nhân",
      description: "Quản lý thông tin tài khoản của bạn",
      icon: Icons.person_outline,
      color: Colors.blueGrey,
      category: "Cá nhân",
      builder: () => const ProfileScreen(),
    ),
    _SearchItem(
      name: "Thông báo",
      description: "Xem các thông báo lịch hẹn, tin nhắn",
      icon: Icons.notifications_outlined,
      color: Colors.orange,
      category: "Cá nhân",
      builder: () => const NotificationScreen(),
    ),
    _SearchItem(
      name: "Tin nhắn",
      description: "Danh sách tin nhắn với chuyên gia",
      icon: Icons.message_outlined,
      color: Colors.indigo,
      category: "Cá nhân",
      builder: () => const ExpertChatListScreen(),
    ),
    _SearchItem(
      name: "Nhật Ký Nông Hộ",
      description: "Ghi chép hoạt động canh tác hàng ngày",
      icon: Icons.book_outlined,
      color: Colors.orange,
      category: "Cá nhân",
      builder: () => const FarmDiaryScreen(),
    ),
  ];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchBody(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchBody(context);

  Widget _buildSearchBody(BuildContext context) {
    final lowerQuery = query.toLowerCase().trim();

    // Nếu chưa nhập gì → hiện tất cả theo nhóm
    if (lowerQuery.isEmpty) {
      return _buildAllFeatures(context);
    }

    // Lọc kết quả
    final results = _allFeatures.where((item) {
      return item.name.toLowerCase().contains(lowerQuery) ||
          item.description.toLowerCase().contains(lowerQuery) ||
          item.category.toLowerCase().contains(lowerQuery);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Không tìm thấy \"$query\"",
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              "Thử tìm: thời tiết, sâu bệnh, chuyên gia...",
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildResultTile(context, results[index]);
      },
    );
  }

  Widget _buildAllFeatures(BuildContext context) {
    // Nhóm theo category
    final Map<String, List<_SearchItem>> grouped = {};
    for (final item in _allFeatures) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            "Tất cả chức năng",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...grouped.entries.expand((entry) {
          return [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[700],
                ),
              ),
            ),
            ...entry.value.map((item) => _buildResultTile(context, item)),
          ];
        }),
      ],
    );
  }

  Widget _buildResultTile(BuildContext context, _SearchItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item.builder()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchItem {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final Widget Function() builder;

  const _SearchItem({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.builder,
  });
}

// ==========================================
// THÀNH PHẦN LOGO AI KÉO THẢ TỰ DO
// ==========================================
class DraggableAiBot extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const DraggableAiBot({
    super.key,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<DraggableAiBot> createState() => _DraggableAiBotState();
}

class _DraggableAiBotState extends State<DraggableAiBot> {
  Offset position = Offset.zero;
  bool isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      final size = MediaQuery.of(context).size;
      // Khởi tạo tọa độ bot nằm lơ lửng góc dưới bên phải (trên Bottom Navigation Bar một chút)
      position = Offset(size.width - 80, size.height - 180);
      isInitialized = true;
    }

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/images/ai_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
