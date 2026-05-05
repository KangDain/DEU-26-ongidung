enum UserType { elderly, child, guardian, general, admin }

class UserModel {
  final int? userId;
  final String id;
  final String name;
  final String email;
  final String birthDate;
  final String phone;
  final String address;
  final String guardianPhone;
  final UserType userType;
  final String? profileImage;
  final String healthInfo;
  final String medicationNote;
  final String emergencyNote;
  final List<String> medications;
  final List<EmergencyContact> emergencyContacts;
  bool isAutoLogin;
  String? pinCode;

  UserModel({
    this.userId,
    required this.id,
    required this.name,
    this.email = '',
    required this.birthDate,
    required this.phone,
    required this.address,
    required this.guardianPhone,
    required this.userType,
    this.profileImage,
    this.healthInfo = '',
    this.medicationNote = '',
    this.emergencyNote = '',
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
  final int? contactId;
  final String name;
  final String phone;
  final String relation;
  final int priority;

  const EmergencyContact({
    this.contactId,
    required this.name,
    required this.phone,
    required this.relation,
    required this.priority,
  });
}

class IoTDevice {
  final int? deviceId;
  final String id;
  final String name;
  final String type;
  final String locationName;
  bool isConnected;
  int batteryLevel;

  IoTDevice({
    this.deviceId,
    required this.id,
    required this.name,
    required this.type,
    this.locationName = '',
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
  final int? routineId;
  final String name;
  final String time;
  final String category;
  bool isTaken;

  MedicationRecord({
    this.routineId,
    required this.name,
    required this.time,
    this.category = 'medication',
    this.isTaken = false,
  });
}
