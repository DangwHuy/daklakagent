import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PestDiseaseScreen extends StatefulWidget {
  const PestDiseaseScreen({super.key});

  @override
  State<PestDiseaseScreen> createState() => _PestDiseaseScreenState();
}

class _PestDiseaseScreenState extends State<PestDiseaseScreen> {
  String selectedCategory = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> categories = [
    'Tất cả',
    'Bệnh hại',
    'Côn trùng',
    'Nấm bệnh',
    'Vi khuẩn',
    'Sinh lý'
  ];

  @override
  void initState() {
    super.initState();
    // Lắng nghe thay đổi từ thanh tìm kiếm
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  // Hàm chuyển đổi String từ Firebase sang Color
  Color _parseColor(String? colorStr) {
    switch (colorStr) {
      case 'Colors.red':
        return Colors.red;
      case 'Colors.orange':
        return Colors.orange;
      case 'Colors.amber':
        return Colors.amber;
      case 'Colors.purple':
        return Colors.purple;
      case 'Colors.pink':
        return Colors.pink;
      case 'Colors.blue':
        return Colors.blue;
      case 'Colors.green':
        return Colors.green;
      case 'Colors.brown':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // Hàm chuyển đổi String từ Firebase sang IconData
  IconData _parseIcon(String? iconStr) {
    switch (iconStr) {
      case 'Icons.coronavirus':
        return Icons.coronavirus;
      case 'Icons.water_damage':
        return Icons.water_damage;
      case 'Icons.local_fire_department':
        return Icons.local_fire_department;
      case 'Icons.bug_report':
        return Icons.bug_report;
      case 'Icons.pest_control':
        return Icons.pest_control;
      case 'Icons.science':
        return Icons.science;
      case 'Icons.airline_seat_legroom_reduced':
        return Icons.airline_seat_legroom_reduced;
      case 'Icons.park':
        return Icons.park;
      case 'Icons.line_axis':
        return Icons.line_axis;
      case 'Icons.circle_outlined':
        return Icons.circle_outlined;
      case 'Icons.ads_click':
        return Icons.ads_click;
      case 'Icons.warning':
        return Icons.warning;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('📚 Thư Viện Sâu Bệnh'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Dùng GestureDetector để chạm ra ngoài tự đóng bàn phím
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          children: [
            // Header kết hợp Thanh tìm kiếm thiết kế mới
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[700]!, Colors.red[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔬 Bác Sĩ Cây Trồng',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Chẩn đoán & điều trị cập nhật liên tục',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  // THANH TÌM KIẾM MỚI
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên, triệu chứng, từ khóa...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter tabs
            Container(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              color: Colors.transparent,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: categories.map((category) {
                    bool isSelected = category == selectedCategory;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red[700] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.red[700]! : Colors.grey[300]!,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Lấy dữ liệu từ Firestore qua StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('pest_diseases').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: Colors.red[700]),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Lọc dữ liệu theo Search và Category
                  final filteredData = docs.where((doc) {
                    final item = doc.data() as Map<String, dynamic>;
                    final name = (item['name'] ?? '').toString().toLowerCase();
                    final type = item['type'] ?? '';

                    final symptoms = List<String>.from(item['symptoms'] ?? []);
                    final tags = List<String>.from(item['tags'] ?? []);

                    bool matchesSearch = _searchQuery.isEmpty ||
                        name.contains(_searchQuery) ||
                        symptoms.any((s) => s.toLowerCase().contains(_searchQuery)) ||
                        tags.any((t) => t.toLowerCase().contains(_searchQuery));

                    bool matchesCategory =
                        selectedCategory == 'Tất cả' || type == selectedCategory;

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filteredData.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final itemData = filteredData[index].data() as Map<String, dynamic>;
                      return _buildPestDiseaseCard(itemData);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPestDiseaseCard(Map<String, dynamic> item) {
    final affectedParts = List<String>.from(item['affected_parts'] ?? []);
    final symptoms = List<String>.from(item['symptoms'] ?? []);
    final treatment = List<String>.from(item['treatment'] ?? []);
    final prevention = List<String>.from(item['prevention'] ?? []);
    final tags = List<String>.from(item['tags'] ?? []);

    // Lấy link ảnh từ Firebase (Nếu không có thì trả về null)
    final imageUrl = item['imageUrl'] as String?;

    final itemColor = _parseColor(item['color']);
    final itemIcon = _parseIcon(item['icon']);

    Color severityColor;
    switch (item['severity']) {
      case 'Rất cao': severityColor = Colors.red; break;
      case 'Cao': severityColor = Colors.orange; break;
      case 'Trung bình': severityColor = Colors.amber; break;
      default: severityColor = Colors.green;
    }

    Color emergencyColor;
    switch (item['emergency_level']) {
      case 'Khẩn cấp': emergencyColor = Colors.red; break;
      case 'Cao': emergencyColor = Colors.orange; break;
      case 'Trung bình': emergencyColor = Colors.amber; break;
      default: emergencyColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(itemIcon, color: itemColor, size: 28),
          ),
          title: Text(
            item['name'] ?? 'Chưa cập nhật',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6), // Đã sửa lỗi ở đây
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildTag(item['type'] ?? '', _getCategoryColor(item['type'] ?? '')),
                _buildTag(item['severity'] ?? '', severityColor),
                _buildTag(item['season'] ?? '', Colors.blue[300]!),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),

                  // HIỂN THỊ HÌNH ẢNH (Nếu có link ảnh trên Firebase)
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.red[700],
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
                              const SizedBox(height: 8),
                              Text('Không thể tải ảnh', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bảng thông tin meta
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetaItem('📊', 'Mức độ', item['severity'] ?? ''),
                        _buildMetaItem('🌤️', 'Mùa', item['season'] ?? ''),
                        _buildMetaItem('🎯', 'Khẩn cấp', item['emergency_level'] ?? ''),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '📍 Bộ phận ảnh hưởng:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: affectedParts.map((part) {
                      return Chip(
                        label: Text(part, style: TextStyle(fontSize: 12, color: Colors.red[900])),
                        backgroundColor: Colors.red[50],
                        side: BorderSide.none,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  if (symptoms.isNotEmpty)
                    _buildSection('🔴 Triệu chứng nhận biết', symptoms, Colors.red),
                  const SizedBox(height: 16),

                  if (treatment.isNotEmpty)
                    _buildSection('💊 Biện pháp điều trị', treatment, Colors.blue),
                  const SizedBox(height: 16),

                  if (prevention.isNotEmpty)
                    _buildSection('🛡️ Phòng ngừa', prevention, Colors.green),
                  const SizedBox(height: 16),

                  Text(
                    '🏷️ Từ khóa liên quan:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('#$tag', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetaItem(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bệnh hại': return Colors.red[700]!;
      case 'Côn trùng': return Colors.orange[700]!;
      case 'Nấm bệnh': return Colors.purple[700]!;
      case 'Vi khuẩn': return Colors.blue[700]!;
      case 'Sinh lý': return Colors.green[700]!;
      default: return Colors.grey[700]!;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy dữ liệu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử điều chỉnh từ khóa tìm kiếm hoặc danh mục',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}