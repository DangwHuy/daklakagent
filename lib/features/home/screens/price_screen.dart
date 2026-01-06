import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// *******************************************************************
// !!! QUAN TRỌNG: THAY THẾ PUBLIC URL CỦA BẠN VÀO ĐÂY !!!
// Sau khi chạy code Python, copy Public URL từ ngrok (ví dụ: https://xxxxxx.ngrok-free.app)
// và dán vào biến sau.
// *******************************************************************
const String NGROK_PUBLIC_URL = 'https://flowery-nonrespectably-rene.ngrok-free.dev'; // VÍ DỤ: 'https://a823-34-12-145-20.ngrok-free.app'
// *******************************************************************


// Giá Nông sản hôm nay
class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  // Trạng thái dữ liệu
  bool _isLoading = true;
  String? _errorMessage;
  String _lastUpdated = '';

  // Dữ liệu sẽ được lưu trữ dưới dạng List<Map<String, dynamic>>
  List<Map<String, dynamic>> _durianPrices = [];

  // Danh sách các loại sầu riêng có trong dữ liệu cào được
  List<String> _durianTypes = [];
  String? _selectedType; // Loại sầu riêng đang được chọn để hiển thị

  // Tương tự code Python, các cột là:
  // 'Loại' | 'Miền Tây - Hàng đẹp' | 'Miền Tây - Hàng xô' | 'Miền Đông - Hàng đẹp' | ...
  // Vì dữ liệu API là một list of dictionaries, chúng ta cần tái cấu trúc nó
  // để lọc theo Loại (Loại 1, Loại 2, v.v.) và hiển thị các giá trị khu vực.

  @override
  void initState() {
    super.initState();
    _fetchDurianPrices();
  }

  // Hàm gọi API để lấy dữ liệu giá sầu riêng
  Future<void> _fetchDurianPrices() async {
    if (NGROK_PUBLIC_URL.contains('YOUR_PUBLIC_URL_HERE')) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: Vui lòng thay thế NGROK_PUBLIC_URL bằng URL công khai của bạn trong code Flutter.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('$NGROK_PUBLIC_URL/durian-prices');

    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));

        // Dữ liệu API trả về là List<Map<String, dynamic>> trong key 'data'
        final List<dynamic> rawData = responseData['data'] ?? [];

        // Chuyển đổi List<dynamic> thành List<Map<String, dynamic>>
        final List<Map<String, dynamic>> prices = rawData.cast<Map<String, dynamic>>();

        // Lấy danh sách các loại sầu riêng ('Loại 1', 'Loại 2', v.v.)
        final List<String> types = prices.map((e) => e['Loại'] as String).toList();

        setState(() {
          _durianPrices = prices;
          _durianTypes = types;
          // Chọn loại đầu tiên làm mặc định
          _selectedType = types.isNotEmpty ? types.first : null;
          // Thêm chữ "to" và dấu ngoặc "()"
          _lastUpdated = responseData['timestamp'] ?? DateTime.now().toIso8601String();
          _isLoading = false;
        });

      } else {
        // Xử lý lỗi API (ví dụ: lỗi cào dữ liệu 500)
        final errorDetail = json.decode(utf8.decode(response.bodyBytes))['detail'] ?? 'Không rõ';
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi tải dữ liệu: HTTP ${response.statusCode}. Chi tiết: $errorDetail';
        });
      }
    } catch (e) {
      // Xử lý lỗi mạng/kết nối
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi kết nối mạng: $e. Đảm bảo server Python đang chạy.';
      });
    }
  }

  // Hàm chuyển đổi dữ liệu thành danh sách hiển thị
  List<Map<String, dynamic>> _getDisplayData() {
    if (_selectedType == null || _durianPrices.isEmpty) {
      return [];
    }

    // Tìm hàng dữ liệu cho loại sầu riêng đang chọn
    final Map<String, dynamic>? selectedRow = _durianPrices.firstWhere(
          (item) => item['Loại'] == _selectedType,
      orElse: () => <String, dynamic>{}, // Trả về Map rỗng nếu không tìm thấy
    );

    if (selectedRow == null || selectedRow.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> displayList = [];

    // Lặp qua các cột giá ('Miền Tây - Hàng đẹp', v.v.)
    selectedRow.forEach((key, value) {
      if (key != 'Loại' && value is String && value.isNotEmpty) {
        // Tách 'Miền Tây - Hàng đẹp' thành ['Miền Tây', 'Hàng đẹp']
        final parts = key.split(' - ');
        final region = parts[0].trim();
        final type = parts.length > 1 ? parts[1].trim() : 'Giá';

        // Thêm vào danh sách hiển thị
        displayList.add({
          'name': '$region ($type)', // Tên hiển thị
          'price': value.replaceAll(RegExp(r'[^0-9,.\-]'), '').trim(), // Lấy giá trị số (ví dụ: '85,000 - 95,000')
          'unit': 'đ/kg', // Đơn vị cố định
          // Trend và icon là giả định vì API không cung cấp, nhưng tôi giữ lại để UI đẹp
          'trend': 'up',
          'change': 'N/A',
          'icon': '🍈',
          'color': Colors.amber,
        });
      }
    });

    return displayList;
  }

  // Hàm định dạng thời gian
  String _formatLastUpdated() {
    try {
      final dateTime = DateTime.parse(_lastUpdated).toLocal();
      return 'Cập nhật: ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}, ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (_) {
      return 'Cập nhật: Vừa xong';
    }
  }


  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu hiển thị dựa trên loại sầu riêng đã chọn
    final List<Map<String, dynamic>> currentPrices = _getDisplayData();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Giá Sầu Riêng Hôm Nay'), // Đổi tiêu đề cho đúng nội dung
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
        onRefresh: _fetchDurianPrices, // Gán hàm fetch API vào onRefresh
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
                      '📊 Bảng Giá Sầu Riêng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatLastUpdated(),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // **********************************************
              // CHỌN LOẠI SẦU RIÊNG (Thay vì chọn khu vực)
              // **********************************************
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn loại sầu riêng',
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
                        value: _selectedType,
                        hint: const Text("Chọn Loại..."),
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.amber[700]),
                        items: _durianTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedType = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // **********************************************
              // HIỂN THỊ TRẠNG THÁI (Loading/Error/Success)
              // **********************************************
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giá thị trường',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: Colors.amber),
                      ))
                    else if (_errorMessage != null)
                      _buildErrorWidget(_errorMessage!)
                    else if (currentPrices.isEmpty)
                        _buildInfoWidget('Không có dữ liệu giá sầu riêng cho loại này.')
                      else
                      // Danh sách giá thực tế
                        ...currentPrices.map((item) => _buildPriceCard(item)).toList(),
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
                            '• Giá thực tế có thể thay đổi theo chất lượng, loại Hàng đẹp/Hàng xô\n'
                            '• Dữ liệu được cào từ giasaurieng.net qua API FastAPI\n'
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

  // Widget hiển thị lỗi
  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lỗi: $message',
              style: TextStyle(color: Colors.red[900]),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị thông tin
  Widget _buildInfoWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> item) {
    // Trend và change bị bỏ qua vì dữ liệu API không cung cấp sự thay đổi
    // và tôi không muốn hiển thị dữ liệu sai. Tôi sẽ cố định nó là "Ổn định"
    // hoặc có thể cho một biểu tượng trung tính.

    IconData trendIcon = Icons.trending_flat;
    Color trendColor = Colors.grey;

    // Giữ lại logic cũ nhưng dùng màu trung tính nếu không có trend
    // switch (item['trend']) {
    //   case 'up':
    //     trendIcon = Icons.trending_up;
    //     trendColor = Colors.green;
    //     break;
    //   case 'down':
    //     trendIcon = Icons.trending_down;
    //     trendColor = Colors.red;
    //     break;
    //   default:
    //     trendIcon = Icons.trending_flat;
    //     trendColor = Colors.grey;
    // }

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
              color: (item['color'] as Color).withOpacity(0.1),
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
                  item['name'], // Ví dụ: 'Miền Tây (Hàng đẹp)'
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item['price'], // Ví dụ: '85,000 - 95,000'
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
                'N/A', // Dữ liệu thay đổi không có trong API
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
          'Giá sầu riêng được cào tự động từ giasaurieng.net thông qua API FastAPI/Python.\n\n'
              'Giá thực tế có thể thay đổi theo chất lượng, loại Hàng đẹp/Hàng xô.\n\n'
              'Vui lòng kéo xuống để cập nhật giá mới nhất.',
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