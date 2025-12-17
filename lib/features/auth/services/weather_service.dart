// File: lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Thay mã API Key bạn đang dùng trong Colab vào đây
  final String apiKey = '4be89a65fe75c2f972c0f24084943bc1';

  // URL API (Ví dụ dùng OpenWeatherMap)
  // Bạn có thể sửa lại URL này cho giống trong Colab của bạn
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric&lang=vi'),
      );

      if (response.statusCode == 200) {
        // Giải mã JSON nhận được
        return json.decode(response.body);
      } else {
        throw Exception('Không lấy được dữ liệu thời tiết');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}