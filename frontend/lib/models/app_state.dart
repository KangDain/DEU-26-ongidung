import 'user_model.dart';

class AppState {
  static AppState? _instance;
  static AppState get instance => _instance ??= AppState._();
  AppState._();

  UserModel? currentUser;
  bool isLoggedIn = false;
  String safetyStatus = '안전';
  bool hasEmergency = false;
  int unreadNotifications = 3;

  final List<IoTDevice> devices = [
    IoTDevice(id: '1', name: '스마트밴드', type: 'wearable', batteryLevel: 75),
    IoTDevice(id: '2', name: '낙상감지센서', type: 'fall_sensor', batteryLevel: 92),
    IoTDevice(id: '3', name: '현관 도어센서', type: 'door_sensor', batteryLevel: 60),
    IoTDevice(id: '4', name: '심박센서', type: 'heart_rate', batteryLevel: 45, isConnected: false),
    IoTDevice(id: '5', name: 'GPS 트래커', type: 'gps', batteryLevel: 88),
  ];

  final List<MedicationRecord> todayMedications = [
    MedicationRecord(name: '혈압약 (아침)', time: '08:00', isTaken: true),
    MedicationRecord(name: '당뇨약 (점심)', time: '12:00', isTaken: false),
    MedicationRecord(name: '비타민 (저녁)', time: '18:00', isTaken: false),
  ];

  final List<HealthData> recentHealthData = [
    HealthData(timestamp: DateTime.now().subtract(const Duration(hours: 1)), heartRate: 72, steps: 2340, status: '정상'),
    HealthData(timestamp: DateTime.now().subtract(const Duration(hours: 2)), heartRate: 68, steps: 1800, status: '정상'),
    HealthData(timestamp: DateTime.now().subtract(const Duration(hours: 3)), heartRate: 75, steps: 3100, status: '정상'),
  ];

  final List<Map<String, dynamic>> notifications = [
    {'title': '약 복용 알림', 'body': '점심 당뇨약을 복용할 시간입니다.', 'time': '12:00', 'isRead': false, 'type': 'medication'},
    {'title': '활동량 알림', 'body': '오늘 목표 걸음 수의 50%를 달성했습니다.', 'time': '11:30', 'isRead': false, 'type': 'activity'},
    {'title': '보호자 메시지', 'body': '오늘 점심 드셨나요? 안부가 궁금합니다.', 'time': '11:00', 'isRead': false, 'type': 'guardian'},
    {'title': '기기 배터리', 'body': '심박센서 배터리가 45%입니다. 충전을 권장합니다.', 'time': '10:00', 'isRead': true, 'type': 'device'},
    {'title': '일정 알림', 'body': '오후 2시 병원 예약이 있습니다.', 'time': '09:00', 'isRead': true, 'type': 'schedule'},
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
      id: userData['login_id'] as String? ?? '',
      name: userData['user_name'] as String? ?? '',
      birthDate: userData['user_birth_date'] as String? ?? '',
      phone: userData['user_phone'] as String? ?? '',
      address: userData['user_address'] as String? ?? '',
      guardianPhone: userData['guardian_phone'] as String? ?? '',
      userType: userType,
      medications: const [],
      emergencyContacts: const [],
    );
    isLoggedIn = true;
  }

  // 테스트용 로컬 로그인 (백엔드 없이 UI 확인 시 사용)
  void login(String id, String password) {
    loginFromApi({
      'login_id': id,
      'user_name': id == 'admin' ? '관리자' : '홍길동',
      'user_role': id == 'admin' ? 'ADMIN' : id == 'guardian' ? 'GUARDIAN' : 'RECIPIENT',
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
  }
}
