import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // Đảm bảo link này luôn cập nhật đúng với Terminal Ngrok đang chạy
  final String apiUrl = "https://flowery-nonrespectably-rene.ngrok-free.dev/chat";

  Future<String> sendMessage(String message, List<Map<String, String>> history) async {
    try {
      print("🚀 [1] Đang chuẩn bị gửi tới: $apiUrl");
      print("📩 [2] Nội dung: $message");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          // Ngrok đôi khi đòi giá trị bất kỳ cho header này, miễn là nó tồn tại
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          "message": message,
          "history": history,
        }),
      ).timeout(const Duration(seconds: 45)); // Tăng lên 45s vì AI đôi khi phản hồi chậm

      print("📡 [3] Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Giải mã UTF-8 để nhận tiếng Việt chuẩn
        final decodedBody = utf8.decode(response.bodyBytes);
        print("✅ [4] Raw Response: $decodedBody");

        final data = jsonDecode(decodedBody);
        return data['response'] ?? "AI không trả về nội dung.";
      } else {
        print("❌ [Lỗi Server]: ${response.statusCode} - ${response.body}");
        return "Lỗi Server (${response.statusCode}). Bác kiểm tra lại Server Python nhé!";
      }
    } catch (e) {
      print("💀 [Lỗi Kết Nối]: $e");

      if (e.toString().contains("TimeoutException")) {
        return "Kết nối quá lâu (Timeout). Có thể do Ngrok hoặc Server AI xử lý quá chậm.";
      }
      return "Không thể kết nối Server. Kiểm tra mạng hoặc link Ngrok!";
    }
  }
}