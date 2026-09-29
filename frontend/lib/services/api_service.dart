import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://192.168.0.7:8000';

  // =====================================================
  // CREATE CHAT
  // =====================================================

  static Future<void> createChat(
      String chatId,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/create'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'chat_id': chatId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Could not create chat.\n'
            '${response.statusCode}\n'
            '${response.body}',
      );
    }
  }

  // =====================================================
  // SEND MESSAGE
  // =====================================================

  static Future<String> sendMessage(
      String chatId,
      String message,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'chat_id': chatId,
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['response'] as String;
    }

    throw Exception(
      'Server error: ${response.statusCode}\n'
          '${response.body}',
    );
  }
}