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
import 'package:daklakagent/features/home/screens/chat_screen.dart';
import 'expert_chat_list_screen.dart'; // Import danh sách tin nhắn
// Import màn hình Chat AI, Thời tiết & Profile mới
import 'package:daklakagent/features/ai/screens/ai_chat.dart';
import 'package:daklakagent/features/weather/Screens/weather_screen.dart';
import 'package:daklakagent/features/home/screens/profile_screen.dart';
import 'package:daklakagent/features/auth/screens/login_screen.dart';
import 'notification_screen.dart';
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
                selectedIcon: Icon(Icons.home, color: Colors.green[800], size: 26),
                icon: const Icon(Icons.home_outlined, color: Colors.grey),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.cloud, color: Colors.green[800], size: 26),
                icon: const Icon(Icons.cloud_outlined, color: Colors.grey),
                label: 'Thời tiết',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.message, color: Colors.green[800], size: 26),
                icon: const Icon(Icons.message_outlined, color: Colors.grey),
                label: 'Tin nhắn',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.person, color: Colors.green[800], size: 26),
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
                    padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 20, 16, 60),
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
                        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            )
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
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
            ),
          ),
        ),
        
        // Nút thông báo
        const SizedBox(width: 12),
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
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 26),
                    onPressed: () {
                      if (user == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
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
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            );
          }
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
          _buildCategoryTitle("Thương mại & Cộng đồng", Icons.storefront_outlined),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _FeatureCard(
                icon: Icons.store_mall_directory_outlined,
                label: "Chợ trực tuyến",
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
                    MaterialPageRoute(builder: (context) => const AgriPriceHome()),
                  );
                },
              ),
              _FeatureCard(
                icon: Icons.groups_outlined,
                label: "Mạng xã hội",
                color: Colors.indigo,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chức năng đang phát triển")),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildCategoryTitle("Tra cứu & Chăm sóc", Icons.eco_outlined),
          const SizedBox(height: 12),
          GridView.count(
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
          const SizedBox(height: 24),
          
          _buildCategoryTitle("Chuyên gia & AI", Icons.smart_toy_outlined),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
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
                        )
                      ]
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
  String get searchFieldLabel => 'Nhập tên tiện ích hoặc chuyên gia';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    final Map<String, Widget> routes = {
      "Giá Nông Sản": const AgriPriceHome(),
      "Lịch Tưới": const IrrigationScreen(),
      "Tra cứu sâu bệnh": const PestDiseaseScreen(),
      "AI Phân Tích Chuyên Sâu": const ExpertScreen(),
      "Đặt lịch Chuyên gia": const FindExpertScreen(),
      "Phân tích ảnh bệnh": const AnalyzeDiseaseScreen(),
      "Hỏi AI & Cập nhật giá": const AiChatScreen(),
    };
    
    final results = routes.keys.where((k) => k.toLowerCase().contains(query.toLowerCase())).toList();

    if (results.isEmpty) {
      return const Center(child: Text("Không tìm thấy kết quả phù hợp"));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.search, color: Colors.green[700]),
          title: Text(results[index]),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => routes[results[index]]!));
          },
        );
      },
    );
  }
}

// ==========================================
// THÀNH PHẦN LOGO AI KÉO THẢ TỰ DO
// ==========================================
class DraggableAiBot extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const DraggableAiBot({super.key, required this.onTap, required this.onDismiss});

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
                  BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
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