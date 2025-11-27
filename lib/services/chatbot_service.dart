// lib/services/chatbot_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotService {
  // Local testing - use your computer's IP address for phone testing
  // For web/emulator: use 'http://localhost:5000'
  // For phone: use 'http://YOUR_IP:5000' (e.g., 'http://172.20.2.27:5000')
  static const String baseUrl = 'http://172.20.2.27:5000'; // Change to localhost or your IP
  // Production: 'https://amiable-encouragement-production.up.railway.app';
  
  /// Get chatbot response
  Future<String> getResponse(String userMessage, {String? context}) async {
    try {
      final uri = Uri.parse('$baseUrl/chatbot/chat');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': userMessage,
          'context': context ?? 'fashion_styling',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['response'] ?? 'I apologize, I couldn\'t process that.';
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get chatbot response: $e');
    }
  }
  
  /// Check if chatbot service is available
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/chatbot/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy' || data['status'] == 'fallback_mode';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

