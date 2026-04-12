import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daklakagent/features/home/pest_disease/submit_disease_screen.dart';

class PestDiseaseScreen extends StatefulWidget {
  const PestDiseaseScreen({super.key});

  @override
  State<PestDiseaseScreen> createState() => _PestDiseaseScreenState();
}

class _PestDiseaseScreenState extends State<PestDiseaseScreen>
    with TickerProviderStateMixin {
  String selectedCategory = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _bannerController;
  late Animation<double> _bannerAnim;

  // ── Màu sắc chủ đạo Nature Green ──────────────────────────────────────────
  static const Color kPrimary    = Color(0xFF2D6A4F);
  static const Color kPrimaryL   = Color(0xFF40916C);
  static const Color kAccent     = Color(0xFF74C69D);
  static const Color kAccentL    = Color(0xFFB7E4C7);
  static const Color kBg         = Color(0xFFF0F7F4);
  static const Color kCard       = Colors.white;
  static const Color kWarn       = Color(0xFFE76F51);
  static const Color kWarnLight  = Color(0xFFFFF3F0);

  final List<String> categories = [
    'Tất cả', 'Bệnh hại', 'Côn trùng', 'Nấm bệnh', 'Vi khuẩn', 'Sinh lý'
  ];

  // ── Xác định mùa hiện tại theo tháng (Miền Nam VN) ────────────────────────
  String get _currentSeason {
    final month = DateTime.now().month;
    return (month >= 5 && month <= 11) ? 'Mùa mưa' : 'Mùa khô';
  }

  String get _seasonEmoji => _currentSeason == 'Mùa mưa' ? '🌧️' : '☀️';
  String get _seasonWarning => _currentSeason == 'Mùa mưa'
      ? 'Cao điểm bệnh nấm & vi khuẩn — Kiểm tra vườn thường xuyên!'
      : 'Cao điểm côn trùng & nhện đỏ — Chú ý tưới đủ nước!';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
    _bannerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _bannerAnim = CurvedAnimation(parent: _bannerController, curve: Curves.easeOutBack);
    _bannerController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _parseColor(String? s) {
    const map = {
      'Colors.red': Color(0xFFE53935), 'Colors.orange': Color(0xFFFB8C00),
      'Colors.amber': Color(0xFFFFB300), 'Colors.purple': Color(0xFF8E24AA),
      'Colors.pink': Color(0xFFE91E63), 'Colors.blue': Color(0xFF1E88E5),
      'Colors.green': Color(0xFF43A047), 'Colors.brown': Color(0xFF6D4C41),
    };
    return map[s] ?? const Color(0xFF757575);
  }

  IconData _parseIcon(String? s) {
    const map = <String, IconData>{
      'Icons.coronavirus': Icons.coronavirus, 'Icons.water_damage': Icons.water_damage,
      'Icons.local_fire_department': Icons.local_fire_department,
      'Icons.bug_report': Icons.bug_report, 'Icons.pest_control': Icons.pest_control,
      'Icons.science': Icons.science, 'Icons.park': Icons.park,
      'Icons.warning': Icons.warning, 'Icons.circle_outlined': Icons.circle_outlined,
    };
    return map[s] ?? Icons.eco_outlined;
  }

  Color _getCategoryColor(String cat) {
    const map = {
      'Bệnh hại': Color(0xFFE53935), 'Côn trùng': Color(0xFFFB8C00),
      'Nấm bệnh': Color(0xFF8E24AA), 'Vi khuẩn': Color(0xFF1E88E5),
      'Sinh lý': Color(0xFF43A047),
    };
    return map[cat] ?? const Color(0xFF757575);
  }

  Color _severityColor(String? s) {
    switch (s) {
      case 'Rất cao': return const Color(0xFFD32F2F);
      case 'Cao':     return const Color(0xFFF57C00);
      case 'Trung bình': return const Color(0xFFFBC02D);
      default:        return const Color(0xFF388E3C);
    }
  }

  bool _isInCurrentSeason(String? season) {
    if (season == null || season == 'Quanh năm') return true;
    return season == _currentSeason;
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: _buildFAB(),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildSeasonBanner()),
            SliverToBoxAdapter(child: _buildCategoryFilter()),
            _buildDiseaseList(),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    final topPadding = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      expandedHeight: 180, // Increased from 160 to prevent overflow
      pinned: true,
      backgroundColor: const Color(0xFFF4F6F8),
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.black87,
      centerTitle: false,
      leadingWidth: 70, // Ensure enough space for the custom back button
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFFF4F6F8),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 6, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indent the title row to the right to avoid overlapping with the back button
                Padding(
                  padding: const EdgeInsets.only(left: 54), // Room for back button
                  child: Row(
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tra Cứu Sâu Bệnh',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Bác sĩ cây trồng • Cập nhật liên tục',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Search bar - wrap in a container with a bit more breathing room
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm bệnh, triệu chứng, từ khóa...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: kPrimaryL),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.cancel_rounded, color: Colors.grey[400]),
                              onPressed: () {
                                _searchController.clear();
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Season Banner ──────────────────────────────────────────────────────────
  Widget _buildSeasonBanner() {
    return ScaleTransition(
      scale: _bannerAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _currentSeason == 'Mùa mưa'
                ? [const Color(0xFF1565C0), const Color(0xFF1E88E5)]
                : [const Color(0xFFE65100), const Color(0xFFFB8C00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: (_currentSeason == 'Mùa mưa'
                ? const Color(0xFF1E88E5)
                : const Color(0xFFFB8C00)).withOpacity(0.35),
            blurRadius: 16, offset: const Offset(0, 6),
          )],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_seasonEmoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('⚠️ CẢNH BÁO $_currentSeason',
                          style: const TextStyle(color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(_seasonWarning,
                      style: const TextStyle(color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.w500, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Filter ────────────────────────────────────────────────────────
  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((cat) {
            final selected = cat == selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? kPrimary : const Color(0xFFDDEEE6)),
                  boxShadow: selected ? [BoxShadow(
                    color: kPrimary.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3),
                  )] : [],
                ),
                child: Text(cat, style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF4A6B58),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                )),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Disease List ───────────────────────────────────────────────────────────
  Widget _buildDiseaseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pest_diseases')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: _buildErrorState());
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: CircularProgressIndicator(color: kPrimaryL),
            )),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final filtered = docs.where((doc) {
          final item = doc.data() as Map<String, dynamic>;
          final name = (item['name'] ?? '').toString().toLowerCase();
          final symptoms = List<String>.from(item['symptoms'] ?? []);
          final tags = List<String>.from(item['tags'] ?? []);
          final type = item['type'] ?? '';

          final matchSearch = _searchQuery.isEmpty ||
              name.contains(_searchQuery) ||
              symptoms.any((s) => s.toLowerCase().contains(_searchQuery)) ||
              tags.any((t) => t.toLowerCase().contains(_searchQuery));

          final matchCat = selectedCategory == 'Tất cả' || type == selectedCategory;
          return matchSearch && matchCat;
        }).toList();

        // Sắp xếp: bệnh đang trong mùa lên trên
        filtered.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aInSeason = _isInCurrentSeason(aData['season']) ? 0 : 1;
          final bInSeason = _isInCurrentSeason(bData['season']) ? 0 : 1;
          return aInSeason.compareTo(bInSeason);
        });

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final data = filtered[index].data() as Map<String, dynamic>;
                final inSeason = _isInCurrentSeason(data['season']);
                return _buildCard(data, inSeason);
              },
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }

  // ── Disease Card ───────────────────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> item, bool inSeason) {
    final color = _parseColor(item['color']);
    final icon = _parseIcon(item['icon']);
    final affectedParts = List<String>.from(item['affected_parts'] ?? []);
    final symptoms = List<String>.from(item['symptoms'] ?? []);
    final treatment = List<String>.from(item['treatment'] ?? []);
    final prevention = List<String>.from(item['prevention'] ?? []);
    final tags = List<String>.from(item['tags'] ?? []);
    final imageUrl = item['imageUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: inSeason
            ? Border.all(color: kWarn.withOpacity(0.4), width: 1.5)
            : Border.all(color: const Color(0xFFE8F3ED)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              if (inSeason)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                      color: kWarn, shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('!', style: TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(children: [
            Expanded(child: Text(item['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                    color: Color(0xFF1A2E23)))),
            if (inSeason)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kWarnLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kWarn.withOpacity(0.4)),
                ),
                child: Text('$_seasonEmoji Đang vào mùa',
                    style: const TextStyle(fontSize: 10, color: kWarn,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Wrap(spacing: 6, runSpacing: 5, children: [
              _tag(item['type'] ?? '', _getCategoryColor(item['type'] ?? '')),
              _tag(item['severity'] ?? '', _severityColor(item['severity'])),
              _tag(item['season'] ?? '', const Color(0xFF1E88E5)),
            ]),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Divider(color: const Color(0xFFE8F3ED), height: 24),

                // Image
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl,
                      width: double.infinity, height: 200, fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, prog) => prog == null ? child
                          : Container(height: 200, color: const Color(0xFFF0F7F4),
                          child: Center(child: CircularProgressIndicator(color: kPrimaryL))),
                      errorBuilder: (_, __, ___) => Container(height: 120,
                          decoration: BoxDecoration(color: const Color(0xFFF0F7F4),
                              borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Icon(Icons.broken_image_rounded,
                              color: Colors.grey[300], size: 40))),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Meta row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5FBF7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _metaItem('📊', 'Mức độ', item['severity'] ?? '—'),
                    _dividerV(),
                    _metaItem('🌤️', 'Mùa', item['season'] ?? '—'),
                    _dividerV(),
                    _metaItem('🎯', 'Khẩn cấp', item['emergency_level'] ?? '—'),
                  ]),
                ),
                const SizedBox(height: 14),

                // Affected parts
                _sectionLabel('📍 Bộ phận ảnh hưởng'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8,
                  children: affectedParts.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(p, style: const TextStyle(fontSize: 12,
                        color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600)),
                  )).toList(),
                ),
                const SizedBox(height: 14),

                if (symptoms.isNotEmpty) ...[
                  _infoSection('🔴 Triệu chứng nhận biết', symptoms, const Color(0xFFE53935)),
                  const SizedBox(height: 10),
                ],
                if (treatment.isNotEmpty) ...[
                  _infoSection('💊 Biện pháp điều trị', treatment, const Color(0xFF1E88E5)),
                  const SizedBox(height: 10),
                ],
                if (prevention.isNotEmpty) ...[
                  _infoSection('🛡️ Phòng ngừa', prevention, const Color(0xFF43A047)),
                  const SizedBox(height: 14),
                ],

                // Tags
                _sectionLabel('🏷️ Từ khóa'),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6,
                  children: tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7F4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFB7E4C7)),
                    ),
                    child: Text('#$t', style: const TextStyle(fontSize: 12,
                        color: Color(0xFF40916C))),
                  )).toList(),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SubmitDiseaseScreen())),
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_circle_outline_rounded),
      label: const Text('Đề xuất bệnh', style: TextStyle(fontWeight: FontWeight.w700)),
      elevation: 6,
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────
  Widget _tag(String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _metaItem(String emoji, String label, String value) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: Color(0xFF1A2E23))),
    ]);
  }

  Widget _dividerV() => Container(width: 1, height: 40, color: const Color(0xFFDDEEE6));

  Widget _sectionLabel(String text) => Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2D6A4F)));

  Widget _infoSection(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(margin: const EdgeInsets.only(top: 6, right: 8),
                width: 5, height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            Expanded(child: Text(item, style: const TextStyle(fontSize: 13, height: 1.5))),
          ]),
        )),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded, size: 72, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text('Không tìm thấy kết quả',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Thử điều chỉnh từ khóa hoặc danh mục',
            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ]),
    ));
  }

  Widget _buildErrorState() {
    return Center(child: Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_rounded, size: 72, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text('Không thể tải dữ liệu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
    ));
  }
}