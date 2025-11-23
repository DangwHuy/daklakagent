import 'package:flutter/material.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  String selectedStage = 'Ra hoa';
  int treeAge = 5;

  final List<String> stages = [
    'Ra hoa',
    'Đậu trái',
    'Phát triển trái',
    'Thu hoạch',
    'Nghỉ ngơi'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lịch Tưới Thông Minh'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💧 Hệ Thống Tưới Khoa Học',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tính toán lượng nước tối ưu cho sầu riêng',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Chọn giai đoạn
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giai đoạn sinh trưởng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: DropdownButton<String>(
                      value: selectedStage,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
                      items: stages.map((String stage) {
                        return DropdownMenuItem<String>(
                          value: stage,
                          child: Text(stage),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedStage = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tuổi cây
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tuổi cây',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: treeAge.toDouble(),
                          min: 3,
                          max: 15,
                          divisions: 12,
                          label: '$treeAge năm',
                          activeColor: Colors.blue[700],
                          onChanged: (value) {
                            setState(() {
                              treeAge = value.toInt();
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$treeAge năm',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Khuyến nghị tưới
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildIrrigationRecommendation(),
            ),

            const SizedBox(height: 16),

            // Lịch tưới tuần
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWeeklySchedule(),
            ),

            const SizedBox(height: 16),

            // Lưu ý quan trọng
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Lưu ý quan trọng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Tưới vào sáng sớm (5-7h) hoặc chiều mát (16-18h)\n'
                          '• Tránh tưới lúc trời nóng gây sốc nhiệt\n'
                          '• Kiểm tra độ ẩm đất trước khi tưới\n'
                          '• Giảm/ngừng tưới khi trời mưa\n'
                          '• Tưới chậm, thấm sâu (không tưới ào ào)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[900],
                        height: 1.6,
                      ),
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

  Widget _buildIrrigationRecommendation() {
    Map<String, dynamic> recommendation = _calculateWaterAmount();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.cyan[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.water_drop, color: Colors.blue[700], size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khuyến nghị tưới',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    Text(
                      'Giai đoạn: $selectedStage',
                      style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lượng nước/lần:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      recommendation['amount'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tần suất:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      recommendation['frequency'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thời điểm:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      recommendation['time'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates, size: 18, color: Colors.amber[900]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation['note'],
                    style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    List<String> daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    List<bool> shouldWater = _getWeeklySchedule();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Lịch tưới tuần này',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: shouldWater[index] ? Colors.blue[100] : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: shouldWater[index] ? Colors.blue[700]! : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        shouldWater[index] ? Icons.water_drop : Icons.water_drop_outlined,
                        color: shouldWater[index] ? Colors.blue[700] : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    daysOfWeek[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: shouldWater[index] ? FontWeight.bold : FontWeight.normal,
                      color: shouldWater[index] ? Colors.blue[700] : Colors.grey[600],
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '✓ = Cần tưới  •  ○ = Không cần',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateWaterAmount() {
    int baseAmount = 50;

    // Tính theo tuổi cây
    if (treeAge <= 5) {
      baseAmount = 50;
    } else if (treeAge <= 10) {
      baseAmount = 100;
    } else {
      baseAmount = 200;
    }

    String frequency = '';
    String note = '';

    switch (selectedStage) {
      case 'Ra hoa':
        frequency = 'Mỗi tuần 1-2 lần';
        note = 'Giảm tưới để kích thích ra hoa';
        break;
      case 'Đậu trái':
        baseAmount = (baseAmount * 1.2).toInt();
        frequency = 'Mỗi tuần 2-3 lần';
        note = 'Tăng lượng nước để trái phát triển';
        break;
      case 'Phát triển trái':
        baseAmount = (baseAmount * 1.5).toInt();
        frequency = 'Mỗi tuần 2-3 lần';
        note = 'Duy trì ổn định để trái đều và ngon';
        break;
      case 'Thu hoạch':
        frequency = 'Mỗi tuần 1-2 lần';
        note = 'Giảm tưới trước thu hoạch 2 tuần';
        break;
      default:
        frequency = 'Mỗi tuần 1 lần';
        note = 'Duy trì cây khỏe trong mùa nghỉ';
    }

    return {
      'amount': '${baseAmount - 30} - $baseAmount lít/gốc',
      'frequency': frequency,
      'time': 'Sáng sớm 5-7h hoặc chiều mát 16-18h',
      'note': note,
    };
  }

  List<bool> _getWeeklySchedule() {
    // Tính lịch tưới dựa vào giai đoạn
    switch (selectedStage) {
      case 'Ra hoa':
        return [true, false, false, true, false, false, false];
      case 'Đậu trái':
      case 'Phát triển trái':
        return [true, false, true, false, true, false, false];
      case 'Thu hoạch':
        return [true, false, false, false, true, false, false];
      default:
        return [true, false, false, false, false, false, false];
    }
  }
}