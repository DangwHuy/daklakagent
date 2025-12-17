import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'price_screen.dart';
import 'irrigation_screen.dart';
import 'pest_disease_screen.dart';
import 'expert_screen.dart';

// ==========================================
// GIAO DIỆN CHÍNH (HOME SCREEN) V3.5
// ==========================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Trợ Lý Sầu Riêng Pro v3.5"),
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
          // Trigger refresh for weather widget
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
                child: _buildWelcomeCard(user?.email),
              ),

              const SizedBox(height: 16),

              // 🔴 THÔNG ĐIỆP CHIA SẺ VỚI BÀ CON ĐẮK LẮK
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[50]!, Colors.orange[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[200]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red[300]!, width: 2),
                        ),
                        child: Icon(Icons.favorite, color: Colors.red[600], size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "🌧️ Chia sẻ với bà con Đắk Lắk",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Gửi chút nắng ấm từ phương xa về với Đắk Lắk yêu thương. Xin được san sẻ những khó khăn, mất mát mà bà con đang phải gánh chịu. Mong mọi người hãy thật vững tâm, giữ gìn sức khỏe. Cầu chúc bình an đến với từng nếp nhà, bão lũ rồi sẽ tan, ngày mai trời lại sáng! 💪",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

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

              // 👇 WIDGET CHÍNH - PHÂN TÍCH V3.5
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String? email) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 32),
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
                email ?? "Nhà nông 4.0",
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
                MaterialPageRoute(builder: (context) => const PriceScreen()),
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
            label: "Hỏi đáp chuyên gia",
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpertScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET PHÂN TÍCH THÔNG MINH V3.5
// ==========================================
class ProWeatherCardV35 extends StatefulWidget {
  const ProWeatherCardV35({super.key});

  @override
  State<ProWeatherCardV35> createState() => _ProWeatherCardV35State();
}

class _ProWeatherCardV35State extends State<ProWeatherCardV35> {
  late Future<Map<String, dynamic>> _dataFuture;

  // ⚠️ THAY LINK NGROK MỚI CỦA BẠN Ở ĐÂY
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
      } else {
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
        }

              onPressed: refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text("Thử lại"),
            ),
          );
        }

        final data = snapshot.data!;
        final List<dynamic> listData = data['du_lieu'] ?? [];


          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: listData.length,
          ),
        );
      },
    );
  }

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


    }

    return Container(
      margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
          ],
        ),
        child: Column(
          children: [
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.network(
                        "https://openweathermap.org/img/wn/$iconThoiTiet@2x.png",
                      ),
                  Row(
                    children: [
                  ),
                ],
              ),
                        children: [
                      ),
                decoration: BoxDecoration(
                  ),
                ),
                  children: [
          ],
        ),

      children: [
        Row(
          children: [
          ],
        ),
      ],

        children: [
        ],

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String value, String label) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }


    return Container(
      decoration: BoxDecoration(
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          Expanded(
          ),
              children: [
              ],
            ),

    return Container(
      decoration: BoxDecoration(
      ),
      child: Row(
        children: [
          Row(
            children: [
            ],
          ),
              children: [
              ],
            ),
        ],
    );
  }
}

// ==========================================
// WIDGET THẺ CHỨC NĂNG
// ==========================================
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