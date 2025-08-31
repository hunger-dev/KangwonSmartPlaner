import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/festival.dart';

class ApiClient {
  // Android Emulator에서 호스트 머신 FastAPI 접속 → 10.0.2.2 사용
  static const String baseUrl = 'http://35.208.65.81:8000';

  static Future<List<Festival>> fetchFirstPage({int limit = 16, String? q}) async {
    final uri = Uri.parse('$baseUrl/festivals/first-page')
        .replace(queryParameters: {
      'limit': limit.toString(),
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    });

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => Festival.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> generatePlan(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/plan/generate'); // 서버 라우트에 맞춰 수정
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('(${res.statusCode}) ${res.body}');
    }
  }

  /// ✅ 일정 저장
  static Future<Map<String, dynamic>> savePlanWithTicket(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/plan/save');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('(${res.statusCode}) ${res.body}');
  }
}