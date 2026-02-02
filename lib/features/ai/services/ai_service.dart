import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // 10.0.2.2 là địa chỉ IP để máy ảo Android gọi về máy tính (localhost) của bác
  // Nếu bác dùng máy thật, hãy đổi thành IP của máy tính (ví dụ: 192.168.1.5)
  final String apiUrl = "https://flowery-nonrespectably-rene.ngrok-free.dev/chat";



  Future<String> sendMessage(String message, List<Map<String, String>> history) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          "message": message,
          "history": history, // Gửi lịch sử để Python xử lý Memory (RAG)
        }),
      ).timeout(const Duration(seconds: 30)); // Đợi tối đa 30s vì RAG tìm tài liệu hơi lâu

      if (response.statusCode == 200) {
        // utf8.decode để không bị lỗi font tiếng Việt khi nhận từ Python
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'];
      } else {
        print("Lỗi Server: ${response.body}");
        return "Bác thông cảm, bộ não AI đang bận tí (Lỗi: ${response.statusCode})";
      }
    } catch (e) {
      print("Lỗi kết nối AiService: $e");
      return "Không kết nối được với Server Python. Bác nhớ bật server.py lên nhé!";
    }
  }
}