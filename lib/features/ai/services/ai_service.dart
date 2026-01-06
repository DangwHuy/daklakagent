// Sever AI
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // API Key bạn đã cung cấp
  static const String _apiKey = "";

  // Endpoint gốc (KHÔNG bao gồm key ở đây để tránh bị lặp)
  static const String _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

  Future<String> sendMessage(String message) async {
    try {
      // Ghép key vào URL tại đây
      final url = Uri.parse("$_baseUrl?key=$_apiKey");

      // --- CẤU HÌNH TRÍ TUỆ NHÂN TẠO & ĐIỀU HƯỚNG ---
      final systemContext = """
        Bạn là 'Trợ lý Nông nghiệp Đăk Lăk' chuyên nghiệp và thân thiện.
        Trả lời ngắn gọn, súc tích, dùng từ ngữ địa phương Tây Nguyên thân mật (xưng hô 'tôi' và 'bà con' hoặc 'bác').
        
        QUY TẮC ĐIỀU HƯỚNG (RẤT QUAN TRỌNG):
        Nếu người dùng hỏi về các chức năng sau, hãy trả lời ngắn gọn và THÊM THẺ HÀNH ĐỘNG (Tag) vào cuối câu:

        1. Muốn xem GIÁ CẢ thị trường, giá cà phê, tiêu... 
           -> Thêm cuối câu: [ACTION:OPEN_PRICE]
           
        2. Muốn xem LỊCH TƯỚI, chế độ nước, độ ẩm đất...
           -> Thêm cuối câu: [ACTION:OPEN_WATER]
           
        3. Muốn tra cứu SÂU BỆNH, thuốc bảo vệ thực vật...
           -> Thêm cuối câu: [ACTION:OPEN_PEST]
           
        4. Muốn HỎI ĐÁP chuyên gia, diễn đàn...
           -> Thêm cuối câu: [ACTION:OPEN_FORUM]
           
        5. Muốn ĐẶT LỊCH HẸN trực tiếp với chuyên gia, tìm chuyên gia tư vấn riêng...
           -> Thêm cuối câu: [ACTION:OPEN_BOOKING]

        Ví dụ:
        - User: "Giá sầu riêng nay bao nhiêu?"
        - AI: "Dạ, giá sầu riêng hôm nay đang dao động từ 75k - 85k tùy loại. Bác xem bảng giá chi tiết nhé. [ACTION:OPEN_PRICE]"
        
        - User: "Tôi muốn hẹn gặp chuyên gia"
        - AI: "Dạ được, bác có thể tìm và đặt lịch với các chuyên gia uy tín tại đây ạ. [ACTION:OPEN_BOOKING]"
      """;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "$systemContext\n\nCâu hỏi: $message"}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Trích xuất câu trả lời từ JSON của Gemini
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
        return "Xin lỗi bác, hệ thống đang bận, bác hỏi lại sau nhé.";
      } else {
        // In lỗi ra console để dễ debug
        print("Lỗi Gemini: ${response.body}");
        return "Mạng hơi yếu, bác thử lại sau nhé (Lỗi: ${response.statusCode}).";
      }
    } catch (e) {
      return "Có lỗi xảy ra: $e";
    }
  }
}