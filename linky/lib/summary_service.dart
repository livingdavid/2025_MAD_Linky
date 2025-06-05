import 'dart:convert';
import 'package:http/http.dart' as http;

/// 📏 입력 텍스트를 요약 전 간단히 정리 + 길이 제한
String cleanAndTruncateText(String input, {int maxLength = 1024}) {
  final cleaned = input.replaceAll(RegExp(r'\s+'), ' ').trim();
  return cleaned.length > maxLength ? cleaned.substring(0, maxLength) : cleaned;
}

/// 🤖 Hugging Face 요약 요청
Future<String?> summarizeTextWithHuggingFace(String text) async {
  const apiUrl =
      'https://api-inference.huggingface.co/models/facebook/bart-large-cnn';
  const apiToken =
      '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'; // ← 본인 실제 토큰으로 바꿔야 함

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'inputs': text}),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes); // ✅ 한글 깨짐 방지
      final result = jsonDecode(decodedBody);
      if (result is List && result.isNotEmpty) {
        final summary = result[0]['summary_text'];
        print('📬 요약 결과: $summary');
        return summary;
      }
    } else {
      print('❌ API 요청 실패: ${response.statusCode}');
      print('❌ 응답 본문: ${response.body}');
    }
  } catch (e) {
    print('❌ 요약 요청 오류: $e');
  }

  return null;
}

/// ✨ 텍스트를 정제 후 요약하는 전체 프로세스
Future<String?> getSummaryFromDescription(String? description) async {
  if (description == null || description.trim().isEmpty) return null;

  final cleaned = cleanAndTruncateText(description);
  return await summarizeTextWithHuggingFace(cleaned);
}
