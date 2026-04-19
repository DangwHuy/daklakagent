import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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
import 'package:daklakagent/features/community/screens/posts_screen.dart';
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
    const PostsScreen(), // Tab 2: Diễn đàn
    const ExpertChatListScreen(), // Tab 3: Tin nhắn
    const ProfileScreen(), // Tab 4: Cá nhân (Giao diện Profile đầy đủ)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Content flows under the bottom nav bar
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
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
        height: 75,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B894).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double tabWidth = constraints.maxWidth / 5;
            return Stack(
              children: [
                // Hiệu ứng "Bong bóng" trượt (Sliding Bubble)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  left: _selectedIndex * tabWidth,
                  child: Container(
                    width: tabWidth,
                    height: 75,
                    alignment: Alignment.center,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00B894).withOpacity(0.2),
                            const Color(0xFF55E6C1).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                // Các Tab Icon
                Row(
                  children: [
                    _buildNavItem(0, Icons.grid_view_rounded, Icons.grid_view_outlined, "Home"),
                    _buildNavItem(1, Icons.wb_sunny_rounded, Icons.wb_sunny_outlined, "Thời tiết"),
                    _buildNavItem(2, Icons.forum_rounded, Icons.forum_outlined, "Hội nhóm"),
                    _buildNavItem(3, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, "Chat"),
                    _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, "Tôi"),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: isSelected ? 1.15 : 1.0,
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? const Color(0xFF00B894) : Colors.grey[400],
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF009B77) : Colors.grey[400],
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
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
    final int hour = DateTime.now().hour;
    List<Color> headerColors;
    String greeting;
    IconData timeIcon;

    if (hour >= 5 && hour < 12) {
      headerColors = [const Color(0xFF00C6FF), const Color(0xFF0072FF)]; // Buổi sáng: Khởi đầu mới
      greeting = "Chào buổi sáng,";
      timeIcon = Icons.light_mode_rounded;
    } else if (hour >= 12 && hour < 18) {
      headerColors = [const Color(0xFFFF8008), const Color(0xFFFFC837)]; // Buổi chiều: Ánh ráng vàng
      greeting = "Chào buổi chiều,";
      timeIcon = Icons.wb_twilight_rounded;
    } else {
      headerColors = [const Color(0xFF607D8B), const Color(0xFF455A64)]; // Buổi tối: Màu xám dịu (Blue Grey)
      greeting = "Chào buổi tối,";
      timeIcon = Icons.nights_stay_rounded;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: const Color(0xFF00B894),
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
                        colors: headerColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Đám mây bềnh bồng (scattered clouds)
                        Positioned(
                          left: -30,
                          top: 10,
                          child: Icon(Icons.cloud, size: 100, color: Colors.white.withOpacity(0.08)),
                        ),
                        Positioned(
                          right: 60,
                          top: -15,
                          child: Icon(Icons.cloud, size: 70, color: Colors.white.withOpacity(0.05)),
                        ),
                        // Biểu tượng mặt trời / mặt trăng lớn
                        Positioned(
                          right: -20,
                          top: -30,
                          child: Icon(
                            timeIcon,
                            size: 150,
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        // Nội dung chính: Tên và Lời chào
                        StreamBuilder<User?>(
                          stream: FirebaseAuth.instance.userChanges(),
                          builder: (context, snapshot) {
                            final user =
                                snapshot.data ?? FirebaseAuth.instance.currentUser;
                            return _buildWelcomeCard(context, user, greeting);
                          },
                        ),
                      ],
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
                    const Icon(Icons.apps, color: Color(0xFF00B894)),
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
              const SizedBox(height: 32),

              _buildMembershipSection(context),
              
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
  Widget _buildWelcomeCard(BuildContext context, User? user, String greeting) {
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
                      Text(
                        greeting,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
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

  // ============================================================================
  // GÓI HỘI VIÊN (MEMBERSHIP PACKAGES)
  // ============================================================================
  Widget _buildMembershipSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Gói hội viên",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          "Ea Agri AI đề xuất cho bạn",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.teal[600],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset(
                          'assets/images/de_xuat_cho_ban.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 320, // Tăng chiều cao để không bị tràn màn hình trên thiết bị nhỏ
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildPackageCard(
                headerColor: const Color(0xFF00B894),
                isPopular: true,
                badgeText: 'FREE',
                typeTitle: 'Gói dùng thử',
                mainTitle: 'NHÀ NÔNG\nTIẾT KIỆM',
                mainIcon: Icons.eco_rounded,
                savingText: 'Miễn phí trải nghiệm\ncông nghệ AI mới',
                packageTitle: 'Green Cơ Bản',
                packageSubtitle: 'Cá Nhân',
                price: '0đ / vĩnh viễn',
                trialText: '',
              ),
              _buildPackageCard(
                headerColor: const Color(0xFF1E88E5), // Blueish
                isPopular: false,
                badgeText: 'HOT',
                typeTitle: 'Gói ưu chuộng',
                mainTitle: 'CHUYÊN GIA\nUNLIMITED',
                mainIcon: Icons.psychology_rounded,
                savingText: 'Tiết kiệm lên đến\n1.000.000 VNĐ',
                packageTitle: 'Green Chuyên Gia',
                packageSubtitle: 'Ưu tiên đặt lịch',
                price: 'Từ 69.000đ/tháng',
                trialText: '1 tháng dùng thử',
              ),
              _buildPackageCard(
                headerColor: const Color(0xFFFFB300), // Amber/Orange
                isPopular: false,
                badgeText: 'PRO',
                typeTitle: 'Gói cao cấp',
                mainTitle: 'NÔNG TRẠI\nCA CAO',
                mainIcon: Icons.agriculture_rounded,
                savingText: 'Tiết kiệm lên đến\n5.000.000 VNĐ',
                packageTitle: 'Green Nông Trại',
                packageSubtitle: 'Chủ Nông Trại',
                price: 'Từ 199.000đ/tháng',
                trialText: 'Báo cáo độc quyền',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard({
    required Color headerColor,
    required bool isPopular,
    String badgeText = '',
    required String typeTitle,
    required String mainTitle,
    required IconData mainIcon,
    required String savingText,
    required String packageTitle,
    required String packageSubtitle,
    required String price,
    required String trialText,
  }) {
    return Container(
      width: 175, // Kích thước thẻ cố định để hiện lấp ló thẻ sau
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Khu vực hình ảnh nền
              Container(
                height: 110,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [headerColor, headerColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Nội dung chữ trên nền khối màu
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeTitle,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: headerColor),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mainTitle,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                    // Icon chìm dưới góc phải thay cho hình ảnh 3D
                    Positioned(
                      right: -10,
                      bottom: -15,
                      child: Icon(mainIcon, size: 85, color: Colors.white.withOpacity(0.2)),
                    ),
                  ],
                ),
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Divider(color: Colors.grey[200], thickness: 1, height: 1),
              ),

              // Chi tiết báo giá
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        savingText,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        packageTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      Text(
                        packageSubtitle,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          price,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87),
                        ),
                      ),
                      if (trialText.isNotEmpty)
                        Text(
                          trialText,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF00B894), fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Badge nổi bên góc phải (ví dụ: x110, HOT)
          if (isPopular || badgeText.isNotEmpty)
            Positioned(
              top: -6,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPopular ? Colors.blue[100] : Colors.orange[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Text(
                  badgeText.isNotEmpty ? badgeText : 'HOT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isPopular ? Colors.blue[800] : Colors.orange[800],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    return const _PaginatedFeatureGrid();
  }
}

class _ProWeatherCardV35State extends State<ProWeatherCardV35> {
  late Future<List<Map<String, dynamic>>> _dataFuture;

  // Cấu hình API OpenWeatherMap (Giống IrrigationScreen)
  static const String openWeatherApiKey = "4be89a65fe75c2f972c0f24084943bc1";
  static const Map<String, Map<String, double>> locations = {
    "Buôn Ma Thuột": {"lat": 12.6667, "lon": 108.0500, "cao_do": 536},
    "Krông Pắc": {"lat": 12.69, "lon": 108.30, "cao_do": 500},
    "Cư M'gar": {"lat": 12.86, "lon": 108.08, "cao_do": 530},
    "Buôn Hồ": {"lat": 12.92, "lon": 108.30, "cao_do": 480},
    "Ea Kar": {"lat": 12.80, "lon": 108.45, "cao_do": 420}
  };

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchMultiLocationData();
  }

  Future<void> refreshData() async {
    setState(() {
      _dataFuture = fetchMultiLocationData();
    });
  }

  // HÀM HỖ TRỢ LẤY VỊ TRÍ HIỆN TẠI
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: const Duration(seconds: 5),
    ).catchError((_) => null);
  }

  // TÍNH TOÁN SAI SỐ CHỈ SỐ NGUY CƠ (Rule-based)
  Map<String, int> _calculateRisks({
    required double temp,
    required double humidity,
    required double rain,
  }) {
    // 1. Nguy cơ nấm (Phụ thuộc mạnh vào độ ẩm và nhiệt độ trung bình)
    int chiSoNam = 0;
    if (humidity > 85) chiSoNam += 40;
    if (humidity > 92) chiSoNam += 30;
    if (temp >= 24 && temp <= 28) chiSoNam += 20;

    // 2. Nguy cơ lũ lụt (Phụ thuộc lượng mưa)
    int chiSoLuLut = (rain * 5).clamp(0, 100).toInt();

    // 3. Stress nhiệt (Phụ thuộc nhiệt độ cao)
    int chiSoStress = 0;
    if (temp > 32) chiSoStress = ((temp - 32) * 10).clamp(0, 100).toInt();

    return {
      'lu_lut': chiSoLuLut,
      'nam': chiSoNam.clamp(0, 100),
      'stress': chiSoStress,
    };
  }

  Future<List<Map<String, dynamic>>> fetchMultiLocationData() async {
    try {
      // 1. Lấy vị trí hiện tại của thiết bị
      final Position? currentPos = await _determinePosition();
      
      // 2. Chuẩn bị danh sách yêu cầu (Map địa điểm mặc định + Thêm vị trí hiện tại nếu lấy được)
      final List<Map<String, dynamic>> finalResults = [];
      
      // Nếu lấy được GPS, ưu tiên hiển thị vị trí hiện tại lên đầu tiên
      if (currentPos != null) {
        final currentUrl = "https://api.openweathermap.org/data/2.5/weather?lat=${currentPos.latitude}&lon=${currentPos.longitude}&appid=$openWeatherApiKey&units=metric&lang=vi";
        try {
          final resp = await http.get(Uri.parse(currentUrl)).timeout(const Duration(seconds: 10));
          if (resp.statusCode == 200) {
            final data = json.decode(utf8.decode(resp.bodyBytes));
            final risks = _calculateRisks(
              temp: (data['main']['temp'] as num).toDouble(),
              humidity: (data['main']['humidity'] as num).toDouble(),
              rain: data.containsKey('rain') ? (data['rain']['1h'] as num?)?.toDouble() ?? 0.0 : 0.0,
            );
            
            finalResults.add({
              'khu_vuc': "Vị trí của bạn (${data['name']})",
              'nhiet_do': (data['main']['temp'] as num).toDouble(),
              'do_am': (data['main']['humidity'] as num).toDouble(),
              'gio': (data['wind']['speed'] as num).toDouble(),
              'may': (data['clouds']['all'] as num).toInt(),
              'mo_ta': data['weather'][0]['description'],
              'icon_thoi_tiet': data['weather'][0]['icon'],
              'mua_1h': data.containsKey('rain') ? (data['rain']['1h'] as num?)?.toDouble() ?? 0.0 : 0.0,
              'cao_do': 0, // OWM không trả về cao độ trực tiếp
              'chi_so_nguy_co_lu_lut': risks['lu_lut'],
              'chi_so_nguy_co_nam': risks['nam'],
              'chi_so_stress_nhiet': risks['stress'],
            });
          }
        } catch (_) {}
      }

      // 3. Lấy dữ liệu cho các địa điểm cố định còn lại
      final List<Future<Map<String, dynamic>>> fetchers = locations.entries.map((entry) async {
        final name = entry.key;
        final coords = entry.value;
        final url = "https://api.openweathermap.org/data/2.5/weather?lat=${coords['lat']}&lon=${coords['lon']}&appid=$openWeatherApiKey&units=metric&lang=vi";
        
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          
          double temp = (data['main']['temp'] as num).toDouble();
          double humidity = (data['main']['humidity'] as num).toDouble();
          double windSpeed = (data['wind']['speed'] as num).toDouble();
          int clouds = (data['clouds']['all'] as num).toInt();
          String description = data['weather'][0]['description'];
          String icon = data['weather'][0]['icon'];
          double rain1h = data.containsKey('rain') ? (data['rain']['1h'] as num?)?.toDouble() ?? 0.0 : 0.0;

          // Tính toán nguy cơ
          final risks = _calculateRisks(temp: temp, humidity: humidity, rain: rain1h);

          return {
            'khu_vuc': name,
            'nhiet_do': temp,
            'do_am': humidity,
            'gio': windSpeed,
            'may': clouds,
            'mo_ta': description,
            'icon_thoi_tiet': icon,
            'mua_1h': rain1h,
            'cao_do': coords['cao_do']?.toInt(),
            'chi_so_nguy_co_lu_lut': risks['lu_lut'],
            'chi_so_nguy_co_nam': risks['nam'],
            'chi_so_stress_nhiet': risks['stress'],
          };
        }
        return {'khu_vuc': name, 'error': true};
      }).toList();

      final results = await Future.wait(fetchers);
      finalResults.addAll(results.where((item) => item['error'] != true).toList());
      
      return finalResults;
    } catch (e) {
      throw Exception('Lỗi kết nối thời tiết: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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

        final listData = snapshot.data!;

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
      const String apiKey = "4be89a65fe75c2f972c0f24084943bc1";
      double lat = 12.6667; // Mặc định BMT
      double lon = 108.0500;

      // THỬ LẤY TỌA ĐỘ GPS THỰC TẾ
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            Position pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 3),
            );
            lat = pos.latitude;
            lon = pos.longitude;
          }
        }
      } catch (_) {}
      
      final response = await http
          .get(
            Uri.parse(
              'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final nhietDo = (data['main']['temp'] as num?)?.round() ?? 0;
        final doAm = (data['main']['humidity'] as num?)?.round() ?? 0;
        
        if (mounted) {
          setState(() {
            _weatherText = "$nhietDo°";
            _humidityText = "$doAm%";
          });
        }
      }
    } catch (e) {
      // Im lặng nếu lỗi
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
  final bool isHot;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isHot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              if (isHot)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Text(
                      'HOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PaginatedFeatureGrid extends StatefulWidget {
  const _PaginatedFeatureGrid();

  @override
  State<_PaginatedFeatureGrid> createState() => _PaginatedFeatureGridState();
}

class _PaginatedFeatureGridState extends State<_PaginatedFeatureGrid> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFeatures(BuildContext context) {
    return [
      {
        'label': "AI Phân Tích",
        'icon': Icons.psychology_rounded,
        'color': Colors.purple,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertScreen())),
      },
      {
        'label': "Đặt Lịch",
        'icon': Icons.calendar_month_outlined,
        'color': Colors.teal,
        'isHot': true,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindExpertScreen())),
      },
      {
        'label': "Lịch Tưới",
        'icon': Icons.water_drop_outlined,
        'color': Colors.blue,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IrrigationScreen())),
      },
      {
        'label': "Sâu Bệnh",
        'icon': Icons.bug_report_outlined,
        'color': Colors.red,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PestDiseaseScreen())),
      },
      {
        'label': "Ảnh Bệnh",
        'icon': Icons.camera_alt_outlined,
        'color': Colors.green,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyzeDiseaseScreen())),
      },
      {
        'label': "Chợ",
        'icon': Icons.store_mall_directory_outlined,
        'color': Colors.orange,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang phát triển"))),
      },
      {
        'label': "Giá Cả",
        'icon': Icons.trending_up,
        'color': Colors.amber,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgriPriceHome())),
      },
      {
        'label': "Diễn Đàn",
        'icon': Icons.groups_outlined,
        'color': Colors.indigo,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostsScreen())),
      },
      // Trang 2
      {
        'label': "Nhật Ký",
        'icon': Icons.book_outlined,
        'color': Colors.orange,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmDiaryScreen())),
      },
      {
        'label': "Thời Tiết",
        'icon': Icons.cloud_outlined,
        'color': Colors.lightBlue,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen(initialLocation: 'Buôn Ma Thuột'))),
      },
      {
        'label': "Tin Nhắn",
        'icon': Icons.message_outlined,
        'color': Colors.indigo,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertChatListScreen())),
      },
      {
        'label': "Hồ Sơ",
        'icon': Icons.person_outline,
        'color': Colors.blueGrey,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final features = _getFeatures(context);
    final int itemsPerPage = 8;
    final int pageCount = (features.length / itemsPerPage).ceil();

    return Column(
      children: [
        SizedBox(
          height: 230, // Tăng chiều cao dư dả một chút để hiển thị đủ 2 hàng
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * itemsPerPage;
              final end = (start + itemsPerPage > features.length) ? features.length : start + itemsPerPage;
              final pageItems = features.sublist(start, end);

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 100, // Cố định chiều cao mỗi ô là 100đp để chắc chắn không mất chữ
                ),
                itemCount: pageItems.length,
                itemBuilder: (context, index) {
                  final item = pageItems[index];
                  return _FeatureCard(
                    icon: item['icon'],
                    label: item['label'],
                    color: item['color'],
                    isHot: item['isHot'] ?? false,
                    onTap: item['onTap'],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Page Indicator (Dots)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pageCount,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 16 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: _currentPage == index ? Colors.green[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
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
