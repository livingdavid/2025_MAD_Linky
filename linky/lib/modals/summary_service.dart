import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<String?> summarizeTextWithHuggingFace(String text) async {
  const apiUrl =
      'https://api-inference.huggingface.co/models/sshleifer/distilbart-cnn-12-6';
  // const apiToken = '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'; // 주석 해제 후 사용

  try {
    final shortened = text.length > 1000 ? text.substring(0, 1000) : text;

    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'inputs': shortened}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      if (result is List &&
          result.isNotEmpty &&
          result[0] is Map<String, dynamic>) {
        final summary = result[0]['summary_text'];
        debugPrint('📝 요약 결과: $summary');
        return summary;
      } else {
        debugPrint('⚠️ 예상치 못한 응답 형식: $result');
      }
    } else {
      debugPrint('❌ 요청 실패: ${response.statusCode}');
      debugPrint('❌ 응답 본문: ${response.body}');
    }
  } on TimeoutException {
    debugPrint('❌ 요청 타임아웃 발생');
  } catch (e) {
    debugPrint('❌ 요약 예외 발생: $e');
  }

  return null;
}
