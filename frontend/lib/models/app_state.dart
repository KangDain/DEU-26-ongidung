import 'package:flutter/foundation.dart';

import 'user_model.dart';

class AppState extends ChangeNotifier {
  static AppState? _instance;
  static AppState get instance => _instance ??= AppState._();
  AppState._();

  UserModel? currentUser;
  int? get currentUserId => currentUser?.userId;
  bool isLoggedIn = false;
  String safetyStatus = '안전';
  String healthStatus = '활동량 정상';
  String activityStatus = '활동 정상';
  String locationStatus = '위치 정상';
  bool hasEmergency = false;
  int unreadNotifications = 3;
  List<String> careSummary = [];
  bool shareLocation = true;
  bool shareHealth = true;
  bool shareActivity = false;

  final Map<String, bool> notificationSettings = {
    'medication': true,
    'emergency': true,
    'guardian': true,
    'activity': true,
    'schedule': true,
    'device': true,
  };

  final Set<String> _readLocalNotificationKeys = {};
  final Set<String> _dismissedLocalNotificationKeys = {};
  final List<Map<String, dynamic>> linkedGuardians = [];

  final List<IoTDevice> devices = [
    IoTDevice(id: '1', name: '스마트밴드', type: 'wearable', batteryLevel: 75),
    IoTDevice(id: '2', name: '낙상감지센서', type: 'fall_sensor', batteryLevel: 92),
    IoTDevice(id: '3', name: '현관 도어센서', type: 'door_sensor', batteryLevel: 60),
    IoTDevice(
        id: '4',
        name: '심박센서',
        type: 'heart_rate',
        batteryLevel: 45,
        isConnected: false),
    IoTDevice(id: '5', name: 'GPS 트래커', type: 'gps', batteryLevel: 88),
  ];

  final List<MedicationRecord> todayMedications = [
    MedicationRecord(name: '혈압약 (아침)', time: '08:00', isTaken: true),
    MedicationRecord(name: '당뇨약 (점심)', time: '12:00', isTaken: false),
    MedicationRecord(name: '비타민 (저녁)', time: '18:00', isTaken: false),
  ];

  final List<HealthData> recentHealthData = [
    HealthData(
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        heartRate: 72,
        steps: 2340,
        status: '정상'),
    HealthData(
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        heartRate: 68,
        steps: 1800,
        status: '정상'),
    HealthData(
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        heartRate: 75,
        steps: 3100,
        status: '정상'),
  ];

  final List<Map<String, dynamic>> notifications = [
    {
      'title': '약 복용 알림',
      'body': '점심 당뇨약을 복용할 시간입니다.',
      'time': '12:00',
      'isRead': false,
      'type': 'medication'
    },
    {
      'title': '활동량 알림',
      'body': '오늘 목표 걸음 수의 50%를 달성했습니다.',
      'time': '11:30',
      'isRead': false,
      'type': 'activity'
    },
    {
      'title': '보호자 메시지',
      'body': '오늘 점심 드셨나요? 안부가 궁금합니다.',
      'time': '11:00',
      'isRead': false,
      'type': 'guardian'
    },
    {
      'title': '기기 배터리',
      'body': '심박센서 배터리가 45%입니다. 충전을 권장합니다.',
      'time': '10:00',
      'isRead': true,
      'type': 'device'
    },
    {
      'title': '일정 알림',
      'body': '오후 2시 병원 예약이 있습니다.',
      'time': '09:00',
      'isRead': true,
      'type': 'schedule'
    },
  ];

  final List<Map<String, dynamic>> guardianUsers = [
    {
      'name': '김민준',
      'type': '독거노인',
      'status': '안전',
      'lastUpdate': '2분 전',
      'heartRate': 72,
      'steps': 2340,
      'location': '서울 강남구',
      'hasAlert': false,
    },
    {
      'name': '이서연',
      'type': '아동',
      'status': '활동 중',
      'lastUpdate': '5분 전',
      'heartRate': 85,
      'steps': 5200,
      'location': '서울 서초구',
      'hasAlert': false,
    },
    {
      'name': '박영숙',
      'type': '독거노인',
      'status': '주의',
      'lastUpdate': '1분 전',
      'heartRate': 95,
      'steps': 450,
      'location': '서울 송파구',
      'hasAlert': true,
    },
  ];

  List<MedicationRecord> get medicationRoutines => todayMedications
      .where((routine) => routine.category == 'medication')
      .toList()
    ..sort((a, b) => a.time.compareTo(b.time));

  List<MedicationRecord> get scheduleRoutines => todayMedications
      .where((routine) => routine.category != 'medication')
      .toList()
    ..sort((a, b) => a.time.compareTo(b.time));

  List<MedicationRecord> get sortedTodayRoutines =>
      [...todayMedications]..sort((a, b) => a.time.compareTo(b.time));

  int get takenMedicationCount =>
      medicationRoutines.where((routine) => routine.isTaken).length;

  int get totalMedicationCount => medicationRoutines.length;

  int get completedScheduleCount =>
      scheduleRoutines.where((routine) => routine.isTaken).length;

  int get totalScheduleCount => scheduleRoutines.length;

  int get connectedDeviceCount =>
      devices.where((device) => device.isConnected).length;

  bool get isEmergencyActive =>
      hasEmergency ||
      safetyStatus.contains('긴급') ||
      notifications.any((notification) =>
          notification['type'] == 'emergency' &&
          notification['isRead'] != true);

  String get emergencyStatusLabel => isEmergencyActive ? '긴급' : '안전';

  String get medicationProgressLabel => totalMedicationCount == 0
      ? '약 0/0'
      : '약 $takenMedicationCount/$totalMedicationCount';

  String get activityStatusLabel {
    if (notifications.any((notification) =>
        notification['type'] == 'activity' && notification['isRead'] != true)) {
      return '활동 주의';
    }
    if (devices.isNotEmpty && connectedDeviceCount < devices.length) {
      return '활동 확인';
    }
    return activityStatus;
  }

  List<String> get computedCareSummary {
    final rows = <String>[];
    rows.add(isEmergencyActive ? '긴급 상황이 열려 있습니다.' : '긴급 상황 없이 안전합니다.');

    if (totalMedicationCount == 0) {
      rows.add('오늘 등록된 약 복용 일정이 없습니다.');
    } else {
      rows.add('약 복용 $takenMedicationCount/$totalMedicationCount 완료');
      final nextMed = medicationRoutines
          .where((routine) => !routine.isTaken)
          .cast<MedicationRecord?>()
          .firstWhere((routine) => routine != null, orElse: () => null);
      if (nextMed != null) {
        rows.add('다음 약: ${nextMed.time} ${nextMed.name}');
      }
    }

    if (totalScheduleCount == 0) {
      rows.add('오늘 등록된 일정이 없습니다.');
    } else {
      rows.add('일정 $completedScheduleCount/$totalScheduleCount 완료');
      final nextSchedule = scheduleRoutines
          .where((routine) => !routine.isTaken)
          .cast<MedicationRecord?>()
          .firstWhere((routine) => routine != null, orElse: () => null);
      if (nextSchedule != null) {
        rows.add('다음 일정: ${nextSchedule.time} ${nextSchedule.name}');
      }
    }

    rows.add('활동 상태: $activityStatusLabel');
    if (unreadNotifications > 0) {
      rows.add('읽지 않은 알림 $unreadNotifications개');
    }
    return rows;
  }

  void notifyChanged() {
    _syncRoutineNotifications();
    _refreshUnreadCount();
    notifyListeners();
  }

  void setRoutineDone(MedicationRecord routine, bool isDone) {
    routine.isTaken = isDone;
    notifyChanged();
  }

  void addRoutineRecord(MedicationRecord routine) {
    todayMedications.add(routine);
    notifyChanged();
  }

  void removeRoutineRecord(MedicationRecord routine) {
    todayMedications.remove(routine);
    _dismissedLocalNotificationKeys.add(_routineNotificationKey(routine));
    notifyChanged();
  }

  void replaceRoutinesFromApi(Iterable<Map<String, dynamic>> rows) {
    todayMedications
      ..clear()
      ..addAll(rows.map(_routineFromApi));
    notifyChanged();
  }

  void applyNotifications(List<Map<String, dynamic>> rows) {
    notifications
      ..clear()
      ..addAll(rows.map(_notificationFromApi));
    notifyChanged();
  }

  void markNotificationRead(Map<String, dynamic> notification) {
    notification['isRead'] = true;
    final key = notification['local_key'] as String?;
    if (key != null) _readLocalNotificationKeys.add(key);
    notifyChanged();
  }

  void markAllNotificationsRead() {
    for (final notification in notifications) {
      notification['isRead'] = true;
      final key = notification['local_key'] as String?;
      if (key != null) _readLocalNotificationKeys.add(key);
    }
    notifyChanged();
  }

  void dismissNotification(Map<String, dynamic> notification) {
    final key = notification['local_key'] as String?;
    if (key != null) _dismissedLocalNotificationKeys.add(key);
    notifications.remove(notification);
    notifyChanged();
  }

  void setNotificationEnabled(String type, bool enabled) {
    notificationSettings[type] = enabled;
    notifyChanged();
  }

  void setShareSettings({
    bool? location,
    bool? health,
    bool? activity,
  }) {
    shareLocation = location ?? shareLocation;
    shareHealth = health ?? shareHealth;
    shareActivity = activity ?? shareActivity;
    for (final guardian in linkedGuardians) {
      guardian['share_location'] = shareLocation;
      guardian['share_health'] = shareHealth;
      guardian['share_activity'] = shareActivity;
    }
    notifyListeners();
  }

  void applyGuardianLinks(List<Map<String, dynamic>> rows) {
    linkedGuardians
      ..clear()
      ..addAll(rows.map(_guardianLinkFromApi));
    if (linkedGuardians.isNotEmpty) {
      final first = linkedGuardians.first;
      shareLocation = first['share_location'] == true;
      shareHealth = first['share_health'] == true;
      shareActivity = first['share_activity'] == true;
    }
    notifyListeners();
  }

  void addGuardianLinkFromApi(Map<String, dynamic> row) {
    final link = _guardianLinkFromApi(row);
    linkedGuardians.removeWhere((existing) =>
        existing['relation_id'] == link['relation_id'] ||
        existing['guardian_id'] == link['guardian_id']);
    linkedGuardians.add(link);
    shareLocation = link['share_location'] == true;
    shareHealth = link['share_health'] == true;
    shareActivity = link['share_activity'] == true;
    notifyListeners();
  }

  MedicationRecord _routineFromApi(Map<String, dynamic> row) {
    return MedicationRecord(
      routineId: row['routine_id'] is int ? row['routine_id'] as int : null,
      name: row['routine_title'] as String? ?? '일정',
      time: row['routine_notify_time'] as String? ?? '',
      category: row['routine_category'] as String? ?? 'schedule',
      isTaken: row['is_done_today'] == true,
    );
  }

  Map<String, dynamic> _notificationFromApi(Map<String, dynamic> row) {
    return {
      'alert_id': row['alert_id'],
      'title': row['title'] ?? '알림',
      'body': row['body'] ?? '',
      'time': _timeLabel(row['alert_created_at']),
      'isRead': row['is_read'] == true,
      'type': _alertTypeToUi(row['alert_type'] as String?),
      'priority': row['priority'],
    };
  }

  Map<String, dynamic> _guardianLinkFromApi(Map<String, dynamic> row) {
    final guardian = row['guardian'] is Map
        ? Map<String, dynamic>.from(row['guardian'] as Map)
        : <String, dynamic>{};
    return {
      'relation_id': row['relation_id'],
      'guardian_id': row['guardian_id'],
      'name': guardian['user_name'] ?? '보호자',
      'login_id': guardian['login_id'] ?? '',
      'phone': guardian['user_phone'] ?? '',
      'relation': row['relation_name'] ?? '보호자',
      'priority': row['priority'] ?? 1,
      'share_location': row['share_location'] == true,
      'share_health': row['share_health'] == true,
      'share_activity': row['share_activity'] == true,
    };
  }

  void _syncRoutineNotifications() {
    final activeKeys = <String>{};

    for (final routine in todayMedications) {
      final key = _routineNotificationKey(routine);
      activeKeys.add(key);
      final type = routine.category == 'medication' ? 'medication' : 'schedule';
      final enabled = notificationSettings[type] ?? true;
      final shouldShow = !routine.isTaken &&
          enabled &&
          !_dismissedLocalNotificationKeys.contains(key);

      notifications.removeWhere(
          (notification) => notification['local_key'] == key && !shouldShow);

      if (!shouldShow ||
          notifications
              .any((notification) => notification['local_key'] == key)) {
        continue;
      }

      notifications.insert(0, {
        'local_key': key,
        'routine_id': routine.routineId,
        'title': type == 'medication' ? '약 복용 알림' : '일정 알림',
        'body': type == 'medication'
            ? '${routine.time} ${routine.name} 복용 시간입니다.'
            : '${routine.time} ${routine.name} 일정이 있습니다.',
        'time': routine.time,
        'isRead': _readLocalNotificationKeys.contains(key),
        'type': type,
        'priority': 'NORMAL',
      });
    }

    notifications.removeWhere((notification) {
      final key = notification['local_key'] as String?;
      return key != null && !activeKeys.contains(key);
    });
  }

  String _routineNotificationKey(MedicationRecord routine) {
    final id = routine.routineId;
    if (id != null) return 'routine_$id';
    return 'routine_${routine.category}_${routine.name}_${routine.time}';
  }

  void _refreshUnreadCount() {
    unreadNotifications = notifications
        .where((notification) => notification['isRead'] != true)
        .length;
    hasEmergency = notifications.any((notification) =>
        notification['type'] == 'emergency' && notification['isRead'] != true);
    activityStatus = notifications.any((notification) =>
            notification['type'] == 'activity' &&
            notification['isRead'] != true)
        ? '활동 주의'
        : '활동 정상';
  }

  // 실제 백엔드 응답 데이터로 로그인 처리
  void loginFromApi(Map<String, dynamic> userData) {
    final roleStr = userData['user_role'] as String? ?? 'RECIPIENT';
    final typeStr = userData['user_type'] as String? ?? 'GENERAL';

    UserType userType;
    if (roleStr == 'ADMIN') {
      userType = UserType.admin;
    } else if (roleStr == 'GUARDIAN') {
      userType = UserType.guardian;
    } else {
      switch (typeStr) {
        case 'ELDERLY':
          userType = UserType.elderly;
          break;
        case 'CHILD':
          userType = UserType.child;
          break;
        default:
          userType = UserType.general;
      }
    }

    currentUser = UserModel(
      userId: userData['user_id'] is int
          ? userData['user_id'] as int
          : int.tryParse('${userData['user_id'] ?? ''}'),
      id: userData['login_id'] as String? ?? '',
      name: userData['user_name'] as String? ?? '',
      email: userData['email'] as String? ?? '',
      birthDate: userData['user_birth_date'] as String? ?? '',
      phone: userData['user_phone'] as String? ?? '',
      address: userData['user_address'] as String? ?? '',
      guardianPhone: userData['guardian_phone'] as String? ?? '',
      userType: userType,
      profileImage: userData['profile_image_url'] as String?,
      healthInfo: userData['health_info'] as String? ?? '',
      medicationNote: userData['medication_note'] as String? ?? '',
      emergencyNote: userData['emergency_note'] as String? ?? '',
      medications: const [],
      emergencyContacts: _contactsFromApi(userData['emergency_contacts']),
      isAutoLogin: userData['auto_login_enabled'] == true,
    );
    shareLocation = userData['share_location'] != false;
    shareHealth = userData['share_health'] != false;
    shareActivity = userData['share_activity'] == true;
    isLoggedIn = true;
    notifyChanged();
  }

  List<EmergencyContact> _contactsFromApi(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (c) => EmergencyContact(
            contactId: c['contact_id'] is int ? c['contact_id'] as int : null,
            name: c['name'] as String? ?? '보호자',
            phone: c['phone'] as String? ?? '',
            relation: c['relation'] as String? ?? '보호자',
            priority: c['priority'] is int ? c['priority'] as int : 1,
          ),
        )
        .toList();
  }

  void applyProfile(Map<String, dynamic> payload) {
    final user = payload['user'];
    if (user is Map<String, dynamic>) {
      final merged = Map<String, dynamic>.from(user)
        ..['emergency_contacts'] = payload['emergency_contacts'];
      loginFromApi(merged);
    }
  }

  void applyDashboard(Map<String, dynamic> payload) {
    final summary = payload['summary'];
    if (summary is Map<String, dynamic>) {
      safetyStatus = summary['safety_status'] as String? ?? safetyStatus;
      healthStatus = summary['health_status'] as String? ?? healthStatus;
      activityStatus = summary['activity_status'] as String? ?? activityStatus;
      locationStatus = summary['location_status'] as String? ?? locationStatus;
      hasEmergency = safetyStatus.contains('긴급');
    }

    unreadNotifications = payload['unread_notifications'] is int
        ? payload['unread_notifications'] as int
        : unreadNotifications;

    final summaryRows = payload['care_summary'];
    if (summaryRows is List) {
      careSummary
        ..clear()
        ..addAll(summaryRows.whereType<String>());
    }

    final routineRows = payload['routines'];
    if (routineRows is List) {
      todayMedications
        ..clear()
        ..addAll(
          routineRows.whereType<Map>().map(
                (r) => MedicationRecord(
                  routineId:
                      r['routine_id'] is int ? r['routine_id'] as int : null,
                  name: r['routine_title'] as String? ?? '일정',
                  time: r['routine_notify_time'] as String? ?? '',
                  category: r['routine_category'] as String? ?? 'schedule',
                  isTaken: r['is_done_today'] == true,
                ),
              ),
        );
    }

    final deviceRows = payload['devices'];
    if (deviceRows is List) {
      devices
        ..clear()
        ..addAll(
          deviceRows.whereType<Map>().map(
                (d) => IoTDevice(
                  deviceId:
                      d['device_id'] is int ? d['device_id'] as int : null,
                  id: '${d['device_id'] ?? ''}',
                  name: d['device_name'] as String? ?? 'IoT 기기',
                  type: d['device_type'] as String? ?? 'device',
                  locationName: d['location_name'] as String? ?? '',
                  isConnected: d['device_status'] == true,
                  batteryLevel:
                      d['battery_level'] is int ? d['battery_level'] as int : 0,
                ),
              ),
        );
    }

    final alertRows = payload['notifications'];
    if (alertRows is List) {
      notifications
        ..clear()
        ..addAll(
          alertRows.whereType<Map>().map(
                (a) => _notificationFromApi(Map<String, dynamic>.from(a)),
              ),
        );
    }
    notifyChanged();
  }

  String _alertTypeToUi(String? type) {
    switch (type) {
      case 'SOS':
        return 'emergency';
      case 'MESSAGE':
        return 'guardian';
      case 'NO_MOVEMENT':
      case 'MOTION_DETECTED':
        return 'activity';
      default:
        return 'schedule';
    }
  }

  String _timeLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 16) return text.substring(11, 16);
    return '방금';
  }

  // 테스트용 로컬 로그인 (백엔드 없이 UI 확인 시 사용)
  void login(String id, String password) {
    loginFromApi({
      'login_id': id,
      'user_name': id == 'admin' ? '관리자' : '홍길동',
      'user_role': id == 'admin'
          ? 'ADMIN'
          : id == 'guardian'
              ? 'GUARDIAN'
              : 'RECIPIENT',
      'user_type': 'ELDERLY',
      'user_phone': '010-1234-5678',
      'user_birth_date': '1950-03-15',
      'user_address': '서울시 강남구 테헤란로 123',
      'guardian_phone': '010-9876-5432',
    });
  }

  void logout() {
    currentUser = null;
    isLoggedIn = false;
    linkedGuardians.clear();
    notifyChanged();
  }
}
