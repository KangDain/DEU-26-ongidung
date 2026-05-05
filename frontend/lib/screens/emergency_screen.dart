import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_state.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _sosSent = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  bool _isCounting = false;
  List<EmergencyContact> _contacts = [];
  bool _loadingContacts = true;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final cached = AppState.instance.currentUser?.emergencyContacts ?? [];
    if (cached.isNotEmpty) {
      setState(() {
        _contacts = List.from(cached);
        _loadingContacts = false;
      });
    }

    final userId = AppState.instance.currentUserId;
    if (userId == null) {
      setState(() => _loadingContacts = false);
      return;
    }

    final result = await ApiService.getEmergencyContacts(userId);
    if (!mounted) return;

    setState(() {
      _loadingContacts = false;
      if (result.data != null) {
        final raw = result.data!;
        final list = raw['data'] is List
            ? raw['data'] as List
            : raw.values.whereType<List>().firstOrNull ?? [];
        _contacts = list
            .whereType<Map>()
            .map(
              (c) => EmergencyContact(
                contactId:
                    c['contact_id'] is int ? c['contact_id'] as int : null,
                name: c['name'] as String? ?? '보호자',
                phone: c['phone'] as String? ?? '',
                relation: c['relation'] as String? ?? '보호자',
                priority: c['priority'] is int ? c['priority'] as int : 1,
              ),
            )
            .toList();
        _contacts.sort((a, b) => a.priority.compareTo(b.priority));
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startSOS() {
    setState(() {
      _isCounting = true;
      _countdown = 5;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() {
          _sosSent = true;
          _isCounting = false;
          AppState.instance.hasEmergency = true;
        });
        AppState.instance.notifyChanged();
        _sendSos();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendSos() async {
    final userId = AppState.instance.currentUserId;
    if (userId == null) return;
    final result = await ApiService.sendSos(
      userId,
      message: '앱에서 SOS 긴급 호출을 보냈습니다.',
      locationAddress: AppState.instance.currentUser?.address,
    );
    if (!mounted || result.data != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(result.error ?? '긴급 호출 전송 실패'),
          backgroundColor: Colors.red),
    );
  }

  void _cancelSOS() {
    _countdownTimer?.cancel();
    setState(() {
      _isCounting = false;
      _countdown = 5;
    });
  }

  Future<void> _callPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전화를 걸 수 없습니다: $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sosSent ? Colors.red.shade50 : Colors.white,
      appBar: AppBar(
        title: const Text('긴급 상황 대응'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _sosButton(),
            const SizedBox(height: 24),
            if (_sosSent) _sosSentCard(),
            _emergencyContactsList(),
            const SizedBox(height: 16),
            _emergencyInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _sosButton() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _sosSent
                ? null
                : _isCounting
                    ? _cancelSOS
                    : _startSOS,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (_, child) {
                final scale = _isCounting || _sosSent
                    ? 1.0 + (_animController.value * 0.1)
                    : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _sosSent
                      ? Colors.red
                      : _isCounting
                          ? Colors.orange
                          : Colors.red.shade700,
                  boxShadow: [
                    BoxShadow(
                      color: (_sosSent || _isCounting
                              ? Colors.red
                              : Colors.red.shade700)
                          .withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sos, color: Colors.white, size: 60),
                    const SizedBox(height: 8),
                    if (_isCounting)
                      Text('$_countdown',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold))
                    else
                      Text(_sosSent ? '발송 완료' : '긴급 호출',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isCounting)
            Column(
              children: [
                Text('$_countdown초 후 긴급 신호가 발송됩니다',
                    style:
                        TextStyle(color: Colors.orange.shade700, fontSize: 16)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _cancelSOS,
                  style:
                      OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('취소'),
                ),
              ],
            )
          else if (!_sosSent)
            const Text('버튼을 누르면 보호자와 응급기관에\n자동으로 연락됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _sosSentCard() {
    return Card(
      color: Colors.red.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text('긴급 신호가 발송되었습니다!',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red)),
            SizedBox(height: 4),
            Text('• 보호자에게 알림 전송 완료\n• 현재 위치 공유 중\n• 응급 센터 연결 시도 중',
                style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _emergencyContactsList() {
    final guardianPhone = AppState.instance.currentUser?.guardianPhone ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('비상 연락망',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (_loadingContacts)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else if (_contacts.isEmpty && guardianPhone.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('등록된 비상 연락처가 없습니다.',
                    style: TextStyle(color: Colors.grey)),
              )
            else ...[
              ..._contacts.map((c) => _contactTile(
                    priority: c.priority,
                    name: '${c.name} (${c.relation})',
                    phone: c.phone,
                  )),
              if (_contacts.isEmpty && guardianPhone.isNotEmpty)
                _contactTile(priority: 1, name: '보호자', phone: guardianPhone),
            ],
          ],
        ),
      ),
    );
  }

  Widget _contactTile(
      {required int priority, required String name, required String phone}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        child: Text('$priority',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.red)),
      ),
      title: Text(name),
      subtitle: Text(phone),
      contentPadding: EdgeInsets.zero,
      trailing: ElevatedButton.icon(
        onPressed: () => _callPhone(phone),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12)),
        icon: const Icon(Icons.phone, size: 16),
        label: const Text('연결'),
      ),
    );
  }

  Widget _emergencyInfoCard() {
    final user = AppState.instance.currentUser;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('긴급 정보',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _InfoRow('이름', user?.name ?? '-'),
            _InfoRow(
              '생년월일',
              (user?.birthDate.isNotEmpty ?? false) ? user!.birthDate : '-',
            ),
            _InfoRow(
              '연락처',
              (user?.phone.isNotEmpty ?? false) ? user!.phone : '-',
            ),
            _InfoRow(
              '주소',
              (user?.address.isNotEmpty ?? false) ? user!.address : '-',
            ),
            if ((user?.medicationNote ?? '').isNotEmpty)
              _InfoRow('복용 약', user!.medicationNote),
            if ((user?.healthInfo ?? '').isNotEmpty)
              _InfoRow('건강 정보', user!.healthInfo),
            if ((user?.emergencyNote ?? '').isNotEmpty)
              _InfoRow('특이 사항', user!.emergencyNote),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
