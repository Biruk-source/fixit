import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = 'AIzaSyCw-LSrnR3pLKiSCAtFl4NJFf6ofEU9Pjk';
  final String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=';

  Future<String> getAIResponse(String userMessage) async {
    final uri = Uri.parse('$apiUrl$apiKey');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": userMessage}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text.trim();
    } else {
      print("Gemini API error: ${response.body}");
      return "Sorry, something went wrong with the AI.";
    }
  }
}
