import 'package:flutter/material.dart';

class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  String selectedRegion = 'Đắk Lắk';

  final List<String> regions = [
    'Đắk Lắk',
    'Đồng Nai',
    'Bến Tre',
    'Tiền Giang',
    'Long An'
  ];

  // Dữ liệu mẫu giá nông sản
  final Map<String, List<Map<String, dynamic>>> priceData = {
    'Đắk Lắk': [
      {
        'name': 'Sầu riêng Ri6',
        'price': '85,000 - 95,000',
        'unit': 'đ/kg',
        'trend': 'up',
        'change': '+5%',
        'icon': '🍈',
        'color': Colors.green,
      },
      {
        'name': 'Sầu riêng Thái',
        'price': '70,000 - 80,000',
        'unit': 'đ/kg',
        'trend': 'up',
        'change': '+3%',
        'icon': '🍈',
        'color': Colors.green,
      },
      {
        'name': 'Cà phê nhân',
        'price': '105,000 - 108,000',
        'unit': 'đ/kg',
        'trend': 'down',
        'change': '-2%',
        'icon': '☕',
        'color': Colors.brown,
      },
      {
        'name': 'Tiêu đen',
        'price': '145,000 - 150,000',
        'unit': 'đ/kg',
        'trend': 'stable',
        'change': '0%',
        'icon': '🌶️',
        'color': Colors.grey,
      },
      {
        'name': 'Chuối',
        'price': '12,000 - 15,000',
        'unit': 'đ/kg',
        'trend': 'up',
        'change': '+8%',
        'icon': '🍌',
        'color': Colors.yellow,
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Giá Nông Sản Hôm Nay'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _showInfoDialog();
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật giá mới nhất!')),
            );
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[700]!, Colors.amber[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Bảng Giá Thị Trường',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cập nhật: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Chọn khu vực
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn khu vực',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: DropdownButton<String>(
                        value: selectedRegion,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.amber[700]),
                        items: regions.map((String region) {
                          return DropdownMenuItem<String>(
                            value: region,
                            child: Text(region),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedRegion = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Danh sách giá
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giá hôm nay',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...((priceData[selectedRegion] ?? []).map((item) => _buildPriceCard(item)).toList()),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Ghi chú
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Lưu ý',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Giá tham khảo tại thời điểm cập nhật\n'
                            '• Giá thực tế có thể thay đổi theo chất lượng\n'
                            '• Liên hệ thương lái địa phương để biết giá chính xác\n'
                            '• Kéo xuống để cập nhật giá mới nhất',
                        style: TextStyle(fontSize: 13, color: Colors.blue[900], height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> item) {
    IconData trendIcon;
    Color trendColor;

    switch (item['trend']) {
      case 'up':
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        break;
      case 'down':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: item['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item['icon'],
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item['price'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['unit'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(trendIcon, color: trendColor, size: 24),
              const SizedBox(height: 4),
              Text(
                item['change'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin'),
        content: const Text(
          'Giá nông sản được cập nhật từ các chợ đầu mối và thương lái địa phương.\n\n'
              'Để biết giá chính xác nhất, vui lòng liên hệ trực tiếp thương lái hoặc chợ đầu mối tại khu vực của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}