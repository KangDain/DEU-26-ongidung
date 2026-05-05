import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static const _headers = {'Content-Type': 'application/json'};

  // ────────────────────────────
  // 로그인
  // 성공: 유저 정보 Map 반환
  // 실패: null 반환 (errorMessage에 사유 담김)
  // ────────────────────────────
  static Future<({Map<String, dynamic>? data, String? error})> login(
    String loginId,
    String password,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('${Config.baseUrl}/api/login'),
            headers: _headers,
            body: jsonEncode({'login_id': loginId, 'user_pw': password}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode == 200) return (data: body, error: null);
      return (data: null, error: body['detail'] as String? ?? '로그인 실패');
    } catch (_) {
      return (data: null, error: '서버에 연결할 수 없습니다.\n백엔드가 실행 중인지 확인하세요.');
    }
  }

  // ────────────────────────────
  // 회원가입
  // 성공: {'message': ..., 'user_id': ...} 반환
  // 실패: null 반환
  // ────────────────────────────
  static Future<({Map<String, dynamic>? data, String? error})> signup(
    Map<String, dynamic> userData,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('${Config.baseUrl}/api/signup'),
            headers: _headers,
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode == 200) return (data: body, error: null);
      return (data: null, error: body['detail'] as String? ?? '회원가입 실패');
    } catch (_) {
      return (data: null, error: '서버에 연결할 수 없습니다.\n백엔드가 실행 중인지 확인하세요.');
    }
  }
}
