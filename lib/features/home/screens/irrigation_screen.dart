import 'package:flutter/material.dart';
// tưới nước
class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  String selectedStage = 'Ra hoa';
  int treeAge = 5;
  String soilType = 'Đất thịt';
  String weatherCondition = 'Nắng nhẹ';

  final List<String> stages = [
    'Ra hoa',
    'Đậu trái',
    'Phát triển trái',
    'Thu hoạch',
    'Nghỉ ngơi'
  ];

  final List<String> soilTypes = [
    'Đất thịt',
    'Đất thịt pha cát',
    'Đất đỏ bazan',
    'Đất phù sa'
  ];

  final List<String> weatherConditions = [
    'Nắng gắt',
    'Nắng nhẹ',
    'Âm u',
    'Mưa nhẹ',
    'Mưa to'
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
                  const SizedBox(height: 8),
                  Text(
                    _getStageDescription(selectedStage),
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
                    'Tuổi cây (năm)',
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
                  Text(
                    _getTreeAgeDescription(treeAge),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Loại đất
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loại đất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: DropdownButton<String>(
                      value: soilType,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: Icon(Icons.terrain, color: Colors.green[700]),
                      items: soilTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            soilType = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Thời tiết
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Điều kiện thời tiết',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: DropdownButton<String>(
                      value: weatherCondition,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: Icon(Icons.wb_sunny, color: Colors.orange[700]),
                      items: weatherConditions.map((String condition) {
                        return DropdownMenuItem<String>(
                          value: condition,
                          child: Text(condition),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            weatherCondition = newValue;
                          });
                        }
                      },
                    ),
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

            // Thông tin chi tiết về giai đoạn
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStageDetails(),
            ),

            const SizedBox(height: 16),

            // Dấu hiệu nhận biết
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWarningSigns(),
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
                          '• Kiểm tra độ ẩm đất trước khi tưới (ấn ngón tay sâu 10cm)\n'
                          '• Giảm 30-50% lượng nước khi trời mưa\n'
                          '• Tưới chậm, thấm sâu (không tưới ào ào)\n'
                          '• Đào rãnh thoát nước vào mùa mưa\n'
                          '• Phủ gốc bằng rơm rạ để giữ ẩm',
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
                      'Giai đoạn: $selectedStage • Tuổi: $treeAge năm',
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
                    Flexible(
                      child: Text(
                        'Lượng nước/lần:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        recommendation['amount'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Tần suất:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        recommendation['frequency'],
                        style: TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Thời điểm:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        recommendation['time'],
                        style: TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Độ ẩm đất lý tưởng:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        recommendation['soil_moisture'],
                        style: TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildStageDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text(
                'Thông tin giai đoạn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getStageDetails(selectedStage),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSigns() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text(
                'Dấu hiệu cảnh báo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWarningItem('🚨 THIẾU NƯỚC', [
            'Lá héo rũ vào ban ngày',
            'Lá vàng từ mép vào trong',
            'Cây phát triển chậm',
            'Trái rụng non'
          ]),
          const SizedBox(height: 12),
          _buildWarningItem('💦 THỪA NƯỚC', [
            'Lá vàng toàn bộ cây',
            'Rễ thối đen, có mùi hôi',
            'Đất ẩm ướt kéo dài',
            'Cây ngừng sinh trưởng'
          ]),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String title, List<String> signs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        ...signs.map((sign) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• '),
              Expanded(child: Text(sign, style: TextStyle(fontSize: 12))),
            ],
          ),
        )).toList(),
      ],
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

    // Điều chỉnh theo loại đất
    if (soilType == 'Đất cát') {
      baseAmount = (baseAmount * 1.2).toInt();
    } else if (soilType == 'Đất sét') {
      baseAmount = (baseAmount * 0.8).toInt();
    }

    // Điều chỉnh theo thời tiết
    if (weatherCondition == 'Nắng gắt') {
      baseAmount = (baseAmount * 1.3).toInt();
    } else if (weatherCondition == 'Mưa nhẹ') {
      baseAmount = (baseAmount * 0.7).toInt();
    } else if (weatherCondition == 'Mưa to') {
      baseAmount = (baseAmount * 0.3).toInt();
    }

    String frequency = '';
    String soilMoisture = '';
    String note = '';

    switch (selectedStage) {
      case 'Ra hoa':
        frequency = 'Mỗi tuần 1-2 lần';
        soilMoisture = '60-70%';
        note = 'Giảm tưới để kích thích phân hóa mầm hoa, tránh tưới lên hoa';
        break;
      case 'Đậu trái':
        baseAmount = (baseAmount * 1.2).toInt();
        frequency = 'Mỗi tuần 2-3 lần';
        soilMoisture = '70-80%';
        note = 'Tăng lượng nước để trái non phát triển, tránh sốc nước';
        break;
      case 'Phát triển trái':
        baseAmount = (baseAmount * 1.5).toInt();
        frequency = 'Mỗi tuần 2-3 lần';
        soilMoisture = '75-85%';
        note = 'Duy trì ổn định để trái đều, cơm dày và ngon';
        break;
      case 'Thu hoạch':
        frequency = 'Mỗi tuần 1-2 lần';
        soilMoisture = '50-60%';
        note = 'Giảm tưới trước thu hoạch 2 tuần để tăng độ ngọt';
        break;
      default:
        frequency = 'Mỗi tuần 1 lần';
        soilMoisture = '40-50%';
        note = 'Duy trì cây khỏe trong mùa nghỉ, chuẩn bị cho vụ sau';
    }

    return {
      'amount': '${baseAmount - 20} - $baseAmount lít/gốc',
      'frequency': frequency,
      'time': 'Sáng sớm 5-7h hoặc chiều mát 16-18h',
      'soil_moisture': soilMoisture,
      'note': note,
    };
  }

  List<bool> _getWeeklySchedule() {
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

  String _getStageDescription(String stage) {
    switch (stage) {
      case 'Ra hoa':
        return 'Giai đoạn phân hóa mầm hoa, cần điều tiết nước hợp lý';
      case 'Đậu trái':
        return 'Trái non hình thành, cần nước ổn định';
      case 'Phát triển trái':
        return 'Trái phát triển nhanh, nhu cầu nước cao nhất';
      case 'Thu hoạch':
        return 'Chuẩn bị thu hoạch, giảm dần lượng nước';
      default:
        return 'Cây nghỉ ngơi, nhu cầu nước thấp';
    }
  }

  String _getTreeAgeDescription(int age) {
    if (age <= 5) return 'Cây non, hệ rễ đang phát triển';
    if (age <= 10) return 'Cây trưởng thành, cho trái ổn định';
    return 'Cây lâu năm, năng suất cao';
  }

  String _getStageDetails(String stage) {
    switch (stage) {
      case 'Ra hoa':
        return '• Thời gian: 2-3 tháng\n'
            '• Nhiệt độ lý tưởng: 24-30°C\n'
            '• Độ ẩm không khí: 70-80%\n'
            '• Cần xiết nước nhẹ 2-3 tuần trước khi ra hoa\n'
            '• Phun bổ sung phân bón lá chứa Bo, Kẽm';
      case 'Đậu trái':
        return '• Thời gian: 1-2 tháng\n'
            '• Tỉ lệ đậu trái: 5-15%\n'
            '• Tránh sốc nước gây rụng trái non\n'
            '• Bổ sung Canxi, Magie cho cuống trái chắc\n'
            '• Tỉa bớt trái dị hình, sâu bệnh';
      case 'Phát triển trái':
        return '• Thời gian: 3-4 tháng\n'
            '• Trái tăng trưởng nhanh về kích thước\n'
            '• Nhu cầu dinh dưỡng và nước cao nhất\n'
            '• Bón Kali để tăng chất lượng trái\n'
            '• Che phủ gốc giữ ẩm vào mùa khô';
      case 'Thu hoạch':
        return '• Thời gian: 1 tháng\n'
            '• Giảm nước 2 tuần trước thu hoạch\n'
            '• Ngừng phun thuốc trước thu hoạch 3 tuần\n'
            '• Kiểm tra độ chín bằng màu sắc và mùi thơm\n'
            '• Thu hoạch vào sáng sớm, tránh làm dập trái';
      default:
        return '• Thời gian: 2-3 tháng\n'
            '• Cắt tỉa cành già, sâu bệnh\n'
            '• Bón phân hữu cơ cải tạo đất\n'
            '• Phun thuốc phòng trừ sâu bệnh\n'
            '• Chuẩn bị cho vụ ra hoa tiếp theo';
    }
  }
}