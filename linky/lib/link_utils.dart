import 'dart:convert';
import 'package:http/http.dart' as http;

/// 요약 함수 - Hugging Face API 사용
Future<String?> summarizeTextWithHuggingFace(String text) async {
  const apiUrl =
      'https://api-inference.huggingface.co/models/facebook/bart-large-cnn';
  const apiToken = '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'; // 주석 해제 후 사용

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer $apiToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'inputs': text}),
  );

  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);
    if (result is List && result.isNotEmpty) {
      return result[0]['summary_text'];
    }
  }
  return null;
}
