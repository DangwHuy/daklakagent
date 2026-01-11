import 'package:flutter/material.dart';

class PestDiseaseScreen extends StatefulWidget {
  const PestDiseaseScreen({super.key});

  @override
  State<PestDiseaseScreen> createState() => _PestDiseaseScreenState();
}

class _PestDiseaseScreenState extends State<PestDiseaseScreen> {
  String selectedCategory = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredData = [];

  final List<String> categories = ['Tất cả', 'Bệnh hại', 'Côn trùng', 'Nấm bệnh', 'Vi khuẩn', 'Sinh lý'];

  final List<Map<String, dynamic>> pestDiseaseData = [
    {
      'name': 'Bệnh xì mủ thân (Phytophthora)',
      'type': 'Nấm bệnh',
      'severity': 'Rất cao',
      'icon': Icons.coronavirus,
      'color': Colors.red,
      'season': 'Mùa mưa',
      'affected_parts': ['Thân', 'Rễ', 'Lá', 'Trái'],
      'symptoms': [
        'Vết bệnh ướt, chảy mủ vàng/nâu trên thân',
        'Vỏ cây nứt, mủ khô thành vệt trắng',
        'Lá vàng, rụng, cây suy kiệt dần',
        'Trái rụng hàng loạt khi bệnh nặng',
        'Rễ thối đen, có mùi hôi thối',
      ],
      'treatment': [
        'Cắt bỏ cành bệnh, quét vôi vào vết cắt',
        'Aliette 80WP: 2.5g/lít, tưới gốc + phun thân',
        'Metalaxyl: 2ml/lít, quét trực tiếp vết bệnh',
        'Phosphonate: Tiêm vào thân (2-3ml/lỗ)',
        'Trichoderma: 3-5kg/gốc, trộn phân chuồng',
      ],
      'prevention': [
        'Tránh làm tổn thương vỏ cây',
        'Thoát nước tốt vào mùa mưa',
        'Bón cân đối NPK, tránh thừa đạm',
        'Phun thuốc phòng trước mùa mưa',
        'Vệ sinh vườn, tiêu hủy cây bệnh',
      ],
      'emergency_level': 'Khẩn cấp',
      'tags': ['xì mủ', 'phytophthora', 'thối rễ', 'chảy nhựa'],
    },
    {
      'name': 'Bệnh thán thư (Anthracnose)',
      'type': 'Nấm bệnh',
      'severity': 'Cao',
      'icon': Icons.water_damage,
      'color': Colors.orange,
      'season': 'Mùa mưa',
      'affected_parts': ['Lá', 'Trái', 'Cành'],
      'symptoms': [
        'Đốm nâu trên lá, lan rộng hình đồng tâm',
        'Trái: Đốm đen lõm, thối khô từ cuống',
        'Cành: Khô chết ngọn, teo tóp',
        'Lá rụng hàng loạt khi bệnh nặng',
        'Vết bệnh có viền vàng xung quanh',
      ],
      'treatment': [
        'Carbendazim 50WP: 1g/lít, phun 7 ngày/lần',
        'Mancozeb 80WP: 2g/lít, phun phòng',
        'Hexaconazole 5SC: 1ml/lít, trị bệnh',
        'Antracol 70WP: 2-2.5g/lít nước',
        'Cắt tỉa cành bệnh tiêu hủy',
      ],
      'prevention': [
        'Tỉa cành tạo tán thông thoáng',
        'Thu gom lá bệnh tiêu hủy',
        'Bón Kali tăng sức đề kháng',
        'Phun thuốc phòng trước mùa mưa',
        'Tránh tưới nước lên lá buổi chiều',
      ],
      'emergency_level': 'Cao',
      'tags': ['thán thư', 'anthracnose', 'đốm lá', 'thối trái'],
    },
    {
      'name': 'Bệnh cháy lá (Leaf blight)',
      'type': 'Nấm bệnh',
      'severity': 'Trung bình',
      'icon': Icons.local_fire_department,
      'color': Colors.red,
      'season': 'Quanh năm',
      'affected_parts': ['Lá'],
      'symptoms': [
        'Lá khô từ mép vào trong, màu nâu đen',
        'Viền vàng xung quanh vết cháy',
        'Bệnh lan nhanh trong điều kiện nóng ẩm',
        'Cây còi cọc, giảm năng suất',
        'Lá rụng sớm, cây trơ cành',
      ],
      'treatment': [
        'Benomyl 50WP: 1g/lít, phun 2 lần cách 7 ngày',
        'Thiophanate-methyl 70WP: 1.5g/lít',
        'Kết hợp Mancozeb để tăng hiệu quả',
        'Copper Oxychloride 50WP: 2g/lít',
        'Cắt tỉa lá bệnh triệt để',
      ],
      'prevention': [
        'Tưới nước hợp lý, tránh ẩm ướt kéo dài',
        'Bón phân hữu cơ + Trichoderma',
        'Tỉa cành tạo độ thông thoáng',
        'Phun thuốc đồng định kỳ',
        'Giữ vườn sạch sẽ',
      ],
      'emergency_level': 'Trung bình',
      'tags': ['cháy lá', 'fusarium', 'khô lá', 'cháy mép lá'],
    },
    {
      'name': 'Sâu đục trái (Durian fruit borer)',
      'type': 'Côn trùng',
      'severity': 'Cao',
      'icon': Icons.bug_report,
      'color': Colors.purple,
      'season': 'Ra trái',
      'affected_parts': ['Trái'],
      'symptoms': [
        'Sâu non màu nâu, đục lỗ chui vào trái',
        'Phân thải ra ngoài lỗ đục',
        'Trái thối, rụng sớm',
        'Giảm 30-70% năng suất',
        'Trái biến dạng, không phát triển',
      ],
      'treatment': [
        'Bao trái bằng túi chuyên dụng',
        'Emamectin benzoate 2EC: 0.5ml/lít',
        'Chlorantraniliprole 20SC: 0.3ml/lít',
        'Bacillus thuringiensis: 1g/lít',
        'Dùng bẫy pheromone thu hút',
      ],
      'prevention': [
        'Bao trái khi trái 2-4 tuần tuổi',
        'Đặt bẫy pheromone: 4-5 bẫy/1000m²',
        'Vệ sinh vườn, thu gom trái rụng',
        'Phun thuốc phòng khi trái non',
        'Kiểm tra trái thường xuyên',
      ],
      'emergency_level': 'Cao',
      'tags': ['sâu đục trái', 'fruit borer', 'bao trái', 'trái thối'],
    },
    {
      'name': 'Rệp sáp (Mealybugs)',
      'type': 'Côn trùng',
      'severity': 'Trung bình',
      'icon': Icons.pest_control,
      'color': Colors.pink,
      'season': 'Quanh năm',
      'affected_parts': ['Lá', 'Chồi', 'Trái'],
      'symptoms': [
        'Rệp màu trắng, có sáp phủ bên ngoài',
        'Bám thành cụm ở lá non, chồi, trái',
        'Tiết mật ngọt, gây nấm muội đen',
        'Lá biến dạng, cây sinh trưởng kém',
        'Kiến xuất hiện nhiều quanh cây',
      ],
      'treatment': [
        'Buprofezin 25WP: 0.5g/lít',
        'Imidacloprid 10SL: 1ml/lít',
        'Dầu khoáng 1-2%, phun trực tiếp',
        'Nấm ký sinh Verticillium lecanii',
        'Dùng bàn chải chà xát cành',
      ],
      'prevention': [
        'Thả ong ký sinh, bọ rùa',
        'Kiểm soát kiến trong vườn',
        'Tỉa bỏ cành bị hại nặng',
        'Phun thuốc phòng định kỳ',
        'Giữ vườn thông thoáng',
      ],
      'emergency_level': 'Trung bình',
      'tags': ['rệp sáp', 'mealybugs', 'nấm muội đen', 'chồi non'],
    },
    {
      'name': 'Bệnh nấm hồng (Pink disease)',
      'type': 'Nấm bệnh',
      'severity': 'Trung bình',
      'icon': Icons.science,
      'color': Colors.pink,
      'season': 'Mùa mưa',
      'affected_parts': ['Cành'],
      'symptoms': [
        'Màng nấm màu hồng phủ trên cành',
        'Cành khô chết từ ngọn xuống',
        'Lá vàng, rụng, cây suy kiệt',
        'Bệnh phát triển mạnh trong mùa mưa',
        'Cành giòn, dễ gãy',
      ],
      'treatment': [
        'Cắt sâu 20cm dưới vết bệnh',
        'Copper Oxychloride 50WP: Quét trực tiếp',
        'Validamycin 3SL: 2ml/lít, quét cành',
        'Hexaconazole 5SC: 1ml/lít phun',
        'Difenoconazole 25EC: 0.5ml/lít',
      ],
      'prevention': [
        'Tỉa cành tạo tán thông thoáng',
        'Vệ sinh vườn sau mùa mưa',
        'Bón phân cân đối, tránh thừa đạm',
        'Phun thuốc đồng định kỳ',
        'Kiểm tra cành thường xuyên',
      ],
      'emergency_level': 'Trung bình',
      'tags': ['nấm hồng', 'pink disease', 'chết cành', 'corticium'],
    },
    {
      'name': 'Bọ xít muỗi (Helopeltis)',
      'type': 'Côn trùng',
      'severity': 'Trung bình',
      'icon': Icons.airline_seat_legroom_reduced,
      'color': Colors.green,
      'season': 'Ra chồi non',
      'affected_parts': ['Chồi', 'Lá non', 'Trái non'],
      'symptoms': [
        'Vết chích tạo đốm nâu trên chồi non',
        'Chồi khô, chết ngọn',
        'Lá non biến dạng, xoăn lại',
        'Trái non bị chích tạo vết thâm',
        'Cây phát triển kém',
      ],
      'treatment': [
        'Alpha-cypermethrin 10EC: 1ml/lít',
        'Cypermethrin 25EC: 0.5ml/lít',
        'Phun vào sáng sớm hoặc chiều mát',
        'Phun kỹ mặt dưới lá và chồi non',
        'Lặp lại sau 7 ngày nếu cần',
      ],
      'prevention': [
        'Phun thuốc phòng khi ra chồi non',
        'Giữ vườn thông thoáng',
        'Bẫy đèn thu hút vào ban đêm',
        'Kiểm tra chồi non thường xuyên',
        'Trồng cây xua đuổi (sả, húng)',
      ],
      'emergency_level': 'Trung bình',
      'tags': ['bọ xít muỗi', 'helopeltis', 'chích hút', 'chồi non'],
    },
    {
      'name': 'Bệnh khô cành (Dieback)',
      'type': 'Nấm bệnh',
      'severity': 'Cao',
      'icon': Icons.park,
      'color': Colors.brown,
      'season': 'Quanh năm',
      'affected_parts': ['Cành'],
      'symptoms': [
        'Cành khô từ ngọn xuống thân',
        'Vỏ cành nứt, có đốm đen',
        'Lá rụng, để lại cành trơ trọi',
        'Cây phát triển kém, giảm năng suất',
        'Nhựa chảy ở vết bệnh',
      ],
      'treatment': [
        'Cắt sâu 30cm dưới vết bệnh',
        'Carbendazim 50WP: 1g/lít, quét cành',
        'Thiophanate-methyl 70WP: 1.5g/lít',
        'Quét vôi/vôi + đồng bảo vệ vết cắt',
        'Bón phân cân đối, tăng Kali',
      ],
      'prevention': [
        'Bón phân cân đối, tăng Kali',
        'Tỉa cành hợp lý, tránh gây vết thương',
        'Tưới nước đầy đủ trong mùa khô',
        'Phun thuốc phòng định kỳ',
        'Vệ sinh vườn sau thu hoạch',
      ],
      'emergency_level': 'Cao',
      'tags': ['khô cành', 'dieback', 'botryodiplodia', 'chết ngọn'],
    },
    {
      'name': 'Tuyến trùng hại rễ',
      'type': 'Côn trùng',
      'severity': 'Cao',
      'icon': Icons.line_axis,
      'color': Colors.orange,
      'season': 'Quanh năm',
      'affected_parts': ['Rễ'],
      'symptoms': [
        'Rễ có u sưng, nốt sần',
        'Cây còi cọc, lá vàng',
        'Rễ phụ kém phát triển',
        'Cây dễ đổ ngã khi có gió',
        'Năng suất giảm rõ rệt',
      ],
      'treatment': [
        'Ethoprophos 10G: 2-3kg/1000m²',
        'Carbofuran 3G: 3-4kg/1000m²',
        'Chitosan: 2-3kg/gốc, trộn đất',
        'Tưới nấm đối kháng Paecilomyces',
        'Bón vôi cải tạo đất: 1-2 tấn/ha',
      ],
      'prevention': [
        'Luân canh cây trồng',
        'Bón phân hữu cơ hoai mục',
        'Sử dụng cây giống sạch bệnh',
        'Xử lý đất trước khi trồng',
        'Trồng cây kháng tuyến trùng',
      ],
      'emergency_level': 'Cao',
      'tags': ['tuyến trùng', 'nematode', 'u rễ', 'rễ sần'],
    },
    {
      'name': 'Bệnh đốm lá (Leaf spot)',
      'type': 'Nấm bệnh',
      'severity': 'Thấp',
      'icon': Icons.circle_outlined,
      'color': Colors.blue,
      'season': 'Mùa mưa',
      'affected_parts': ['Lá'],
      'symptoms': [
        'Đốm tròn màu nâu, viền vàng',
        'Kích thước 2-10mm, lan rộng',
        'Lá vàng, rụng sớm',
        'Bệnh nặng trong mùa mưa ẩm',
        'Nhiều đốm hợp thành mảng lớn',
      ],
      'treatment': [
        'Chlorothalonil 75WP: 2g/lít',
        'Mancozeb 80WP: 2g/lít',
        'Hexaconazole 5SC: 1ml/lít',
        'Propiconazole 25EC: 1ml/lít',
        'Thu gom lá bệnh tiêu hủy',
      ],
      'prevention': [
        'Thu gom lá bệnh tiêu hủy',
        'Tỉa cành tạo độ thông thoáng',
        'Bón phân cân đối, tăng Kali',
        'Phun thuốc phòng trước mùa mưa',
        'Tránh tưới nước lên lá buổi chiều',
      ],
      'emergency_level': 'Thấp',
      'tags': ['đốm lá', 'leaf spot', 'cercospora', 'vàng lá'],
    },
    {
      'name': 'Rầy mềm (Aphids)',
      'type': 'Côn trùng',
      'severity': 'Thấp',
      'icon': Icons.ads_click,
      'color': Colors.green,
      'season': 'Ra chồi non',
      'affected_parts': ['Lá non', 'Chồi'],
      'symptoms': [
        'Rầy tập trung mặt dưới lá non',
        'Lá quăn queo, biến dạng',
        'Tiết mật ngọt thu hút kiến',
        'Nấm muội đen phát triển',
        'Cây sinh trưởng kém',
      ],
      'treatment': [
        'Imidacloprid 10SL: 1ml/lít',
        'Acetamiprid 20SP: 0.3g/lít',
        'Dầu khoáng: 1-2% phun trực tiếp',
        'Thả bọ rùa, ong ký sinh',
        'Phun xà phòng diệt côn trùng',
      ],
      'prevention': [
        'Bảo vệ thiên địch tự nhiên',
        'Kiểm tra mặt dưới lá thường xuyên',
        'Phun thuốc phòng khi ra chồi non',
        'Trồng cây xua đuổi (bạc hà, tỏi)',
        'Giữ vườn thông thoáng',
      ],
      'emergency_level': 'Thấp',
      'tags': ['rầy mềm', 'aphids', 'chích hút', 'lá quăn'],
    },
    {
      'name': 'Thiếu dinh dưỡng Bo (Boron)',
      'type': 'Sinh lý',
      'severity': 'Trung bình',
      'icon': Icons.warning,
      'color': Colors.amber,
      'season': 'Ra hoa - Đậu trái',
      'affected_parts': ['Toàn cây'],
      'symptoms': [
        'Lá non biến dạng, dày lên',
        'Chồi ngọn chết, cành mọc um tùm',
        'Trái nứt, biến dạng',
        'Hoa kém phát triển, rụng nhiều',
        'Trái non rụng hàng loạt',
      ],
      'treatment': [
        'Phun Borax 0.1% hoặc Solubor',
        'Bón phân có chứa Bo: 1-2kg/ha',
        'Phun kết hợp với Canxi',
        'Bón phân hữu cơ giàu vi lượng',
        'Tưới nước đầy đủ',
      ],
      'prevention': [
        'Bón phân cân đối vi lượng',
        'Kiểm tra đất định kỳ',
        'Bón vôi cải tạo đất chua',
        'Sử dụng phân hữu cơ thường xuyên',
        'Phun Bo định kỳ trước ra hoa',
      ],
      'emergency_level': 'Trung bình',
      'tags': ['thiếu bo', 'boron', 'nứt trái', 'rụng trái non'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredData = pestDiseaseData;
    _searchController.addListener(_filterData);
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty && selectedCategory == 'Tất cả') {
        _filteredData = pestDiseaseData;
      } else {
        _filteredData = pestDiseaseData.where((item) {
          bool matchesSearch = query.isEmpty ||
              item['name'].toLowerCase().contains(query) ||
              item['symptoms'].any((symptom) => symptom.toLowerCase().contains(query)) ||
              item['treatment'].any((treatment) => treatment.toLowerCase().contains(query)) ||
              item['tags'].any((tag) => tag.toLowerCase().contains(query));

          bool matchesCategory = selectedCategory == 'Tất cả' ||
              item['type'] == selectedCategory;

          return matchesSearch && matchesCategory;
        }).toList();
      }
    });
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
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[700]!, Colors.red[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔬 Bác Sĩ Cây Trồng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Chẩn đoán & điều trị 50+ loại sâu bệnh sầu riêng',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Thống kê nhanh
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatItem('🦠', 'Bệnh hại', '8'),
                  _buildStatItem('🐛', 'Côn trùng', '5'),
                  _buildStatItem('🌱', 'Sinh lý', '1'),
                  _buildStatItem('💊', 'Giải pháp', '50+'),
                ],
              ),
            ),
          ),

          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
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
                      _filterData();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Kết quả tìm kiếm
          if (_searchController.text.isNotEmpty || selectedCategory != 'Tất cả')
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📋 Tìm thấy ${_filteredData.length} kết quả',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty || selectedCategory != 'Tất cả')
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = 'Tất cả';
                          _searchController.clear();
                        });
                        _filterData();
                      },
                      child: Text(
                        '🔄 Xóa bộ lọc',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // List
          Expanded(
            child: _filteredData.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredData.length,
              itemBuilder: (context, index) {
                return _buildPestDiseaseCard(_filteredData[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,

          )),
          Text(label, style: const TextStyle(
            fontSize: 10,

          )),
        ],
      ),
    );
  }

  Widget _buildPestDiseaseCard(Map<String, dynamic> item) {
    Color severityColor;
    switch (item['severity']) {
      case 'Rất cao':
        severityColor = Colors.red;
        break;
      case 'Cao':
        severityColor = Colors.orange;
        break;
      case 'Trung bình':
        severityColor = Colors.amber;
        break;
      default:
        severityColor = Colors.green;
    }

    Color emergencyColor;
    switch (item['emergency_level']) {
      case 'Khẩn cấp':
        emergencyColor = Colors.red;
        break;
      case 'Cao':
        emergencyColor = Colors.orange;
        break;
      case 'Trung bình':
        emergencyColor = Colors.amber;
        break;
      default:
        emergencyColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item['icon'], color: item['color'], size: 28),
          ),
          title: Text(
            item['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildTag(item['type'], _getCategoryColor(item['type'])),
                  _buildTag(item['severity'], severityColor),
                  _buildTag(item['season'], Colors.blue[300]!),
                  _buildTag(item['emergency_level'], emergencyColor),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin meta
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetaItem('📊', 'Mức độ', item['severity']),
                        _buildMetaItem('🌤️', 'Mùa', item['season']),
                        _buildMetaItem('🎯', 'Khẩn cấp', item['emergency_level']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bộ phận ảnh hưởng
                  Text(
                    '📍 Bộ phận ảnh hưởng:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: (item['affected_parts'] as List).map((part) {
                      return Chip(
                        label: Text(part, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.red[50],
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  _buildSection('🔴 Triệu chứng nhận biết', item['symptoms'], Colors.red),
                  const SizedBox(height: 16),
                  _buildSection('💊 Biện pháp điều trị', item['treatment'], Colors.blue),
                  const SizedBox(height: 16),
                  _buildSection('🛡️ Phòng ngừa', item['prevention'], Colors.green),

                  const SizedBox(height: 12),

                  // Tags
                  Text(
                    '🏷️ Từ khóa liên quan:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: (item['tags'] as List).map((tag) {
                      return Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey[100],
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetaItem(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: color)),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bệnh hại':
        return Colors.red[700]!;
      case 'Côn trùng':
        return Colors.orange[700]!;
      case 'Nấm bệnh':
        return Colors.purple[700]!;
      case 'Vi khuẩn':
        return Colors.blue[700]!;
      case 'Sinh lý':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
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
            'Không tìm thấy sâu bệnh phù hợp',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử điều chỉnh từ khóa tìm kiếm hoặc danh mục',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedCategory = 'Tất cả';
                _searchController.clear();
              });
              _filterData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa tất cả bộ lọc'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Tìm kiếm sâu bệnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Nhập tên sâu bệnh, triệu chứng...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tìm theo: tên bệnh, triệu chứng, giải pháp, từ khóa',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              _filterData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Tìm kiếm'),
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