enum UserType { elderly, child, guardian, general, admin }

class UserModel {
  final String id;
  final String name;
  final String birthDate;
  final String phone;
  final String address;
  final String guardianPhone;
  final UserType userType;
  final String? profileImage;
  final List<String> medications;
  final List<EmergencyContact> emergencyContacts;
  bool isAutoLogin;
  String? pinCode;

  UserModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.phone,
    required this.address,
    required this.guardianPhone,
    required this.userType,
    this.profileImage,
    this.medications = const [],
    this.emergencyContacts = const [],
    this.isAutoLogin = false,
    this.pinCode,
  });

  String get userTypeLabel {
    switch (userType) {
      case UserType.elderly:
        return '독거노인';
      case UserType.child:
        return '아동';
      case UserType.guardian:
        return '보호자';
      case UserType.general:
        return '일반 사용자';
      case UserType.admin:
        return '관리자';
    }
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;
  final int priority;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
    required this.priority,
  });
}

class IoTDevice {
  final String id;
  final String name;
  final String type;
  bool isConnected;
  int batteryLevel;

  IoTDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = true,
    this.batteryLevel = 80,
  });

  String get typeLabel {
    switch (type) {
      case 'wearable':
        return '웨어러블 기기';
      case 'fall_sensor':
        return '낙상 감지 센서';
      case 'door_sensor':
        return '도어 센서';
      case 'heart_rate':
        return '심박 센서';
      case 'gps':
        return '위치 추적 기기';
      default:
        return '기기';
    }
  }
}

class HealthData {
  final DateTime timestamp;
  final int? heartRate;
  final int? steps;
  final String? status;

  const HealthData({
    required this.timestamp,
    this.heartRate,
    this.steps,
    this.status,
  });
}

class MedicationRecord {
  final String name;
  final String time;
  bool isTaken;

  MedicationRecord({
    required this.name,
    required this.time,
    this.isTaken = false,
  });
}
