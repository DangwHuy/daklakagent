import 'package:flutter/material.dart';

class PestDiseaseScreen extends StatefulWidget {
  const PestDiseaseScreen({super.key});

  @override
  State<PestDiseaseScreen> createState() => _PestDiseaseScreenState();
}

class _PestDiseaseScreenState extends State<PestDiseaseScreen> {
  String selectedCategory = 'Tất cả';
  final List<String> categories = ['Tất cả', 'Bệnh', 'Sâu hại', 'Nấm'];

  final List<Map<String, dynamic>> pestDiseaseData = [
    {
      'name': 'Nấm Phytophthora',
      'type': 'Nấm',
      'severity': 'Cao',
      'icon': Icons.coronavirus,
      'color': Colors.red,
      'symptoms': [
        'Rễ non thối có màu nâu đen',
        'Vỏ rễ dễ tuột ra khỏi lõi rễ',
        'Lá chuyển vàng → nâu → rụng',
        'Thân chảy nhựa màu nâu',
      ],
      'treatment': [
        'Aliette 80WP: 2.5g/lít, tưới gốc',
        'Ridomil Gold 68WP: 2-2.5g/lít',
        'Previcur 722SL: 2-3ml/lít',
        'Xẻ rãnh thoát nước ngay',
        'Rải vôi bột khử trùng đất',
      ],
      'prevention': [
        'Duy trì hệ thống thoát nước tốt',
        'Tránh ngập úng kéo dài',
        'Phun thuốc phòng bệnh định kỳ',
        'Cắt tỉa cành sát đất cao 30-40cm',
      ],
    },
    {
      'name': 'Sâu đục thân (Zeuzera)',
      'type': 'Sâu hại',
      'severity': 'Trung bình',
      'icon': Icons.bug_report,
      'color': Colors.orange,
      'symptoms': [
        'Thân có lỗ đục, mùn cưa ở gốc cây',
        'Cây héo rũ, lá vàng',
        'Nhựa chảy ra ngoài vỏ cây',
        'Cành khô dần từ ngọn xuống',
      ],
      'treatment': [
        'Dùng dây thép đục lỗ diệt sâu',
        'Bơm thuốc Cypermethrin 10EC (2ml/lít) vào lỗ',
        'Bịt lỗ bằng đất sét hoặc băng keo',
        'Cắt bỏ cành bị hại nặng',
      ],
      'prevention': [
        'Quét vôi trắng gốc cây cao 1m',
        'Kiểm tra định kỳ mỗi tuần',
        'Phun thuốc Regent 800WG tháng 1 lần',
        'Giữ vườn sạch, không để mùn cưa',
      ],
    },
    {
      'name': 'Nhện đỏ (Tetranychus)',
      'type': 'Sâu hại',
      'severity': 'Trung bình',
      'icon': Icons.pest_control,
      'color': Colors.red,
      'symptoms': [
        'Lá có đốm nhỏ màu vàng hoặc trắng',
        'Mặt dưới lá có màng lưới mỏng',
        'Lá khô, cuộn, rụng nhiều',
        'Cây còi cọc, sinh trưởng kém',
      ],
      'treatment': [
        'Abamectin 1.8EC: 1-1.5ml/lít nước',
        'Vertimec 1.8EC: 0.5ml/lít',
        'Phun 2 mặt lá, tập trung mặt dưới',
        'Lặp lại sau 7 ngày',
      ],
      'prevention': [
        'Tưới phun sương lên lá chiều mát',
        'Tránh khô hạn kéo dài',
        'Trồng cây chắn gió',
        'Kiểm tra mặt dưới lá thường xuyên',
      ],
    },
    {
      'name': 'Bệnh chết ngọn (Dieback)',
      'type': 'Nấm',
      'severity': 'Cao',
      'icon': Icons.local_fire_department,
      'color': Colors.red,
      'symptoms': [
        'Ngọn cây khô dần từ trên xuống',
        'Lá non chuyển nâu, khô',
        'Cành nhỏ khô lần lượt',
        'Vỏ cây sần sùi, nứt nẻ',
      ],
      'treatment': [
        'Cắt bỏ cành bị bệnh 30cm so với phần khỏe',
        'Bôi sát trùng vết cắt (Bordeaux)',
        'Phun Score 250EC: 0.5ml/lít',
        'Tăng cường bón phân Lân Kali',
      ],
      'prevention': [
        'Tỉa cành tạo tán thông thoáng',
        'Phun thuốc đồng định kỳ',
        'Không bón quá nhiều đạm',
        'Vệ sinh vườn, đốt cành bệnh',
      ],
    },
    {
      'name': 'Bệnh thán thư',
      'type': 'Nấm',
      'severity': 'Trung bình',
      'icon': Icons.circle,
      'color': Colors.brown,
      'symptoms': [
        'Lá có vết nâu tròn, viền vàng',
        'Vết bệnh lan rộng, lá thủng',
        'Trái non bị đốm đen, rụng',
        'Thân non có vết lõm nâu đen',
      ],
      'treatment': [
        'Antracol 70WP: 2-2.5g/lít',
        'Mancozeb 80WP: 2g/lít',
        'Phun 7-10 ngày/lần',
        'Loại bỏ lá bị bệnh',
      ],
      'prevention': [
        'Thu gom lá rụng, đốt bỏ',
        'Tránh tưới ướt lá',
        'Phun phòng mùa mưa',
        'Bón cân đối NPK',
      ],
    },
    {
      'name': 'Bọ trĩ',
      'type': 'Sâu hại',
      'severity': 'Thấp',
      'icon': Icons.bug_report_outlined,
      'color': Colors.green,
      'symptoms': [
        'Lá non bị hút dịch, cuộn lại',
        'Chồi non bị biến dạng',
        'Có chất dính màu đen trên lá',
        'Lá có màu xanh nhợt',
      ],
      'treatment': [
        'Imidacloprid 25WP: 0.3g/lít',
        'Acetamiprid 20SP: 0.3g/lít',
        'Phun kỹ mặt dưới lá',
      ],
      'prevention': [
        'Trồng cây bẫy (đậu đũa)',
        'Thả ong ký sinh',
        'Kiểm tra chồi non thường xuyên',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredData = selectedCategory == 'Tất cả'
        ? pestDiseaseData
        : pestDiseaseData.where((item) => item['type'] == selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tra Cứu Sâu Bệnh'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _showSearchDialog();
            },
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
                  '🔍 Tra Cứu & Phòng Trị',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nhận biết và xử lý sâu bệnh hại sầu riêng',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
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

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                return _buildPestDiseaseCard(filteredData[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPestDiseaseCard(Map<String, dynamic> item) {
    Color severityColor;
    switch (item['severity']) {
      case 'Cao':
        severityColor = Colors.red;
        break;
      case 'Trung bình':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.green;
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
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['severity'],
                  style: TextStyle(
                    fontSize: 11,
                    color: severityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item['type'],
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('🔴 Triệu chứng', item['symptoms'], Colors.red),
                  const SizedBox(height: 16),
                  _buildSection('💊 Cách điều trị', item['treatment'], Colors.blue),
                  const SizedBox(height: 16),
                  _buildSection('🛡️ Phòng ngừa', item['prevention'], Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Nhập tên sâu bệnh...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng đang phát triển')),
              );
            },
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
  }
}