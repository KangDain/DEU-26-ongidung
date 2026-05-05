import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiService {
  static const _headers = {'Content-Type': 'application/json'};

  static Uri _uri(String path) => Uri.parse('${Config.baseUrl}$path');

  static dynamic _decode(http.Response res) {
    if (res.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static String _errorMessage(dynamic body, String fallback) {
    if (body is Map && body['detail'] is String) {
      return body['detail'] as String;
    }
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    return fallback;
  }

  static Future<({Map<String, dynamic>? data, String? error})> _mapRequest(
    Future<http.Response> Function() request,
    String fallback,
  ) async {
    try {
      final res = await request().timeout(const Duration(seconds: 10));
      final body = _decode(res);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (
          data: body is Map<String, dynamic>
              ? body
              : <String, dynamic>{'data': body},
          error: null
        );
      }
      return (data: null, error: _errorMessage(body, fallback));
    } catch (_) {
      return (data: null, error: '서버에 연결할 수 없습니다.\n백엔드가 실행 중인지 확인하세요.');
    }
  }

  static Future<({List<Map<String, dynamic>>? data, String? error})>
      _listRequest(
    Future<http.Response> Function() request,
    String fallback,
  ) async {
    try {
      final res = await request().timeout(const Duration(seconds: 10));
      final body = _decode(res);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final rows = body is List
            ? body
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : <Map<String, dynamic>>[];
        return (data: rows, error: null);
      }
      return (data: null, error: _errorMessage(body, fallback));
    } catch (_) {
      return (data: null, error: '서버에 연결할 수 없습니다.\n백엔드가 실행 중인지 확인하세요.');
    }
  }

  static Future<({Map<String, dynamic>? data, String? error})> login(
    String loginId,
    String password,
  ) {
    return _mapRequest(
      () => http.post(
        _uri('/api/login'),
        headers: _headers,
        body: jsonEncode({'login_id': loginId, 'user_pw': password}),
      ),
      '로그인 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> pinLogin(
    String loginId,
    String pinCode,
  ) {
    return _mapRequest(
      () => http.post(
        _uri('/api/auth/pin'),
        headers: _headers,
        body: jsonEncode({'login_id': loginId, 'pin_code': pinCode}),
      ),
      'PIN 로그인 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> signup(
    Map<String, dynamic> userData,
  ) {
    return _mapRequest(
      () => http.post(
        _uri('/api/signup'),
        headers: _headers,
        body: jsonEncode(userData),
      ),
      '회원가입 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> resetPassword({
    required String loginId,
    required String verification,
    required String newPassword,
  }) {
    return _mapRequest(
      () => http.post(
        _uri('/api/auth/password-reset'),
        headers: _headers,
        body: jsonEncode({
          'login_id': loginId,
          'verification': verification,
          'new_password': newPassword,
        }),
      ),
      '비밀번호 재설정 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> getProfile(
      int userId) {
    return _mapRequest(
      () => http.get(_uri('/api/users/$userId/profile')),
      '프로필 조회 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> updateProfile(
    int userId,
    Map<String, dynamic> data,
  ) {
    return _mapRequest(
      () => http.patch(
        _uri('/api/users/$userId/profile'),
        headers: _headers,
        body: jsonEncode(data),
      ),
      '프로필 저장 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> getDashboard(
      int userId) {
    return _mapRequest(
      () => http.get(_uri('/api/users/$userId/dashboard')),
      '대시보드 조회 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> completeRoutine(
      int routineId) {
    return _mapRequest(
      () => http.post(_uri('/api/routines/$routineId/complete')),
      '일정 완료 처리 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> sendSos(
    int userId, {
    String? message,
    String? locationAddress,
  }) {
    return _mapRequest(
      () => http.post(
        _uri('/api/users/$userId/sos'),
        headers: _headers,
        body: jsonEncode({
          'message': message,
          'location_address': locationAddress,
        }),
      ),
      '긴급 호출 실패',
    );
  }

  static Future<({List<Map<String, dynamic>>? data, String? error})>
      getGuardianRecipients(
    int guardianId,
  ) {
    return _listRequest(
      () => http.get(_uri('/api/guardians/$guardianId/recipients')),
      '보호 대상자 조회 실패',
    );
  }

  static Future<({List<Map<String, dynamic>>? data, String? error})>
      getGuardianLinks(int userId) {
    return _listRequest(
      () => http.get(_uri('/api/users/$userId/guardian-links')),
      '보호자 연동 조회 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> connectGuardian(
    int userId,
    Map<String, dynamic> data,
  ) {
    return _mapRequest(
      () => http.post(
        _uri('/api/users/$userId/guardian-links'),
        headers: _headers,
        body: jsonEncode(data),
      ),
      '보호자 연동 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> updateSharing(
    int relationId,
    Map<String, dynamic> data,
  ) {
    return _mapRequest(
      () => http.patch(
        _uri('/api/care-relations/$relationId/sharing'),
        headers: _headers,
        body: jsonEncode(data),
      ),
      '공유 설정 저장 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> sendMessage({
    required int senderId,
    required int receiverId,
    required String body,
  }) {
    return _mapRequest(
      () => http.post(
        _uri('/api/messages'),
        headers: _headers,
        body: jsonEncode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'body': body,
        }),
      ),
      '메시지 전송 실패',
    );
  }

  static Future<({List<Map<String, dynamic>>? data, String? error})>
      getAdminUsers() {
    return _listRequest(
      () => http.get(_uri('/api/admin/users')),
      '사용자 목록 조회 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> adminApproveUser(
      int userId) {
    return _mapRequest(
      () => http.post(_uri('/api/admin/users/$userId/approve')),
      '사용자 승인 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})>
      adminDeactivateUser(int userId) {
    return _mapRequest(
      () => http.post(_uri('/api/admin/users/$userId/deactivate')),
      '사용자 비활성화 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> adminDeleteUser(
      int userId) {
    return _mapRequest(
      () => http.delete(_uri('/api/admin/users/$userId')),
      '사용자 삭제 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})>
      getEmergencyContacts(int userId) {
    return _mapRequest(
      () => http.get(_uri('/api/users/$userId/emergency-contacts')),
      '비상연락처 조회 실패',
    );
  }

  static Future<({List<Map<String, dynamic>>? data, String? error})>
      getRoutines(int userId) {
    return _listRequest(
      () => http.get(_uri('/api/users/$userId/routines')),
      '루틴 조회 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> addRoutine(
    int userId,
    Map<String, dynamic> data,
  ) {
    return _mapRequest(
      () => http.post(
        _uri('/api/users/$userId/routines'),
        headers: _headers,
        body: jsonEncode(data),
      ),
      '일정 추가 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> updateRoutine(
    int routineId,
    Map<String, dynamic> data,
  ) {
    return _mapRequest(
      () => http.patch(
        _uri('/api/routines/$routineId'),
        headers: _headers,
        body: jsonEncode(data),
      ),
      '일정 수정 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> deleteRoutine(
      int routineId) {
    return _mapRequest(
      () => http.delete(_uri('/api/routines/$routineId')),
      '일정 삭제 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> updateLocation(
    int userId,
    Map<String, dynamic> data,
  ) {
    return _mapRequest(
      () => http.post(
        _uri('/api/users/$userId/locations'),
        headers: _headers,
        body: jsonEncode(data),
      ),
      '위치 저장 실패',
    );
  }

  static Future<({List<Map<String, dynamic>>? data, String? error})>
      getLocationHistory(int userId) {
    return _listRequest(
      () => http.get(_uri('/api/users/$userId/locations')),
      '위치 기록 조회 실패',
    );
  }

  static Future<({List<Map<String, dynamic>>? data, String? error})>
      getNotifications(int userId) {
    return _listRequest(
      () => http.get(_uri('/api/users/$userId/notifications')),
      '알림 조회 실패',
    );
  }

  static Future<({List<Map<String, dynamic>>? data, String? error})>
      getMissions(int userId) {
    return _listRequest(
      () => http.get(_uri('/api/users/$userId/missions')),
      '미션 조회 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})> completeMission(
    int userId,
    int missionId,
  ) {
    return _mapRequest(
      () => http.post(_uri('/api/users/$userId/missions/$missionId/complete')),
      '미션 완료 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})>
      markNotificationRead(int alertId) {
    return _mapRequest(
      () => http.patch(_uri('/api/notifications/$alertId/read')),
      '알림 읽음 처리 실패',
    );
  }

  static Future<({Map<String, dynamic>? data, String? error})>
      markAllNotificationsRead(int userId) {
    return _mapRequest(
      () => http.post(_uri('/api/users/$userId/notifications/read-all')),
      '전체 읽음 처리 실패',
    );
  }
}
