import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final state = AppState.instance;
  bool _isEditing = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _birthCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _guardianCtrl;
  late TextEditingController _healthCtrl;
  late TextEditingController _medicationCtrl;
  late TextEditingController _emergencyNoteCtrl;

  @override
  void initState() {
    super.initState();
    final u = state.currentUser;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _birthCtrl = TextEditingController(text: u?.birthDate ?? '');
    _phoneCtrl = TextEditingController(text: u?.phone ?? '');
    _addressCtrl = TextEditingController(text: u?.address ?? '');
    _guardianCtrl = TextEditingController(text: u?.guardianPhone ?? '');
    _healthCtrl =
        TextEditingController(text: u?.healthInfo ?? '혈액형 A형, 특이사항 없음');
    _medicationCtrl =
        TextEditingController(text: u?.medicationNote ?? '혈압약, 당뇨약, 비타민');
    _emergencyNoteCtrl =
        TextEditingController(text: u?.emergencyNote ?? '알레르기 없음');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _birthCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _guardianCtrl.dispose();
    _healthCtrl.dispose();
    _medicationCtrl.dispose();
    _emergencyNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = state.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isEditing
                ? _saveProfile
                : () => setState(() => _isEditing = true),
            child: Text(_isEditing ? '저장' : '수정',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.blue.shade100,
                  child:
                      Icon(Icons.person, size: 64, color: Colors.blue.shade700),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: Colors.blue.shade600, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
              child: Chip(
                  label: Text(user?.userTypeLabel ?? ''),
                  backgroundColor: Colors.blue.shade50)),
          const SizedBox(height: 20),
          _infoSection('기본 정보', [
            _infoField('이름', _nameCtrl, Icons.person),
            _infoField('이메일', _emailCtrl, Icons.email),
            _infoField('생년월일', _birthCtrl, Icons.cake),
            _infoField('연락처', _phoneCtrl, Icons.phone),
            _infoField('주소', _addressCtrl, Icons.location_on),
            _infoField('보호자 연락처', _guardianCtrl, Icons.contact_phone),
          ]),
          const SizedBox(height: 16),
          _infoSection('건강 정보', [
            _infoField('건강 정보', _healthCtrl, Icons.monitor_heart),
            _infoField('복용 약', _medicationCtrl, Icons.medication),
            _infoField('응급 참고사항', _emergencyNoteCtrl, Icons.emergency),
          ]),
          const SizedBox(height: 16),
          _emergencyContactsSection(),
          const SizedBox(height: 20),
          if (_isEditing)
            OutlinedButton.icon(
              onPressed: () => _showDeleteAccountDialog(),
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('계정 삭제', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final userId = state.currentUserId;
    if (userId == null) {
      setState(() => _isEditing = false);
      return;
    }
    final result = await ApiService.updateProfile(userId, {
      'user_name': _nameCtrl.text,
      'email': _emailCtrl.text,
      'user_birth_date': _birthCtrl.text,
      'user_phone': _phoneCtrl.text,
      'user_address': _addressCtrl.text,
      'guardian_phone': _guardianCtrl.text,
      'health_info': _healthCtrl.text,
      'medication_note': _medicationCtrl.text,
      'emergency_note': _emergencyNoteCtrl.text,
    });
    if (!mounted) return;
    if (result.data != null) {
      state.loginFromApi(result.data!['user'] as Map<String, dynamic>);
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('프로필이 저장되었습니다.'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.error ?? '프로필 저장 실패'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _infoSection(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoField(String label, TextEditingController ctrl, IconData icon,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        enabled: _isEditing && enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: !(_isEditing && enabled),
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _emergencyContactsSection() {
    final contacts = state.currentUser?.emergencyContacts ?? [];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('비상 연락망',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...contacts.map((c) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.shade100,
                    child: Text('${c.priority}',
                        style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(c.phone),
                  trailing: _isEditing
                      ? const Icon(Icons.edit, size: 18, color: Colors.grey)
                      : null,
                )),
            if (_isEditing)
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('비상 연락처 추가'),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text('계정을 삭제하면 모든 데이터가 영구 삭제됩니다.\n정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
