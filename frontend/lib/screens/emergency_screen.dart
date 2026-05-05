import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_state.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _sosSent = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  bool _isCounting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
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
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _cancelSOS() {
    _countdownTimer?.cancel();
    setState(() { _isCounting = false; _countdown = 5; });
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
            onTap: _sosSent ? null : _isCounting ? _cancelSOS : _startSOS,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (_, child) {
                final scale = _isCounting || _sosSent ? 1.0 + (_animController.value * 0.1) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _sosSent ? Colors.red : _isCounting ? Colors.orange : Colors.red.shade700,
                  boxShadow: [
                    BoxShadow(
                      color: (_sosSent || _isCounting ? Colors.red : Colors.red.shade700).withOpacity(0.4),
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
                      Text('$_countdown', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))
                    else
                      Text(_sosSent ? '발송 완료' : '긴급 호출', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isCounting)
            Column(
              children: [
                Text('$_countdown초 후 긴급 신호가 발송됩니다', style: TextStyle(color: Colors.orange.shade700, fontSize: 16)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _cancelSOS,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('취소'),
                ),
              ],
            )
          else if (!_sosSent)
            const Text('버튼을 누르면 보호자와 응급기관에\n자동으로 연락됩니다', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _sosSentCard() {
    return Card(
      color: Colors.red.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text('긴급 신호가 발송되었습니다!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
            SizedBox(height: 4),
            Text('• 보호자에게 알림 전송 완료\n• 현재 위치 공유 중\n• 응급 센터 연결 시도 중',
                style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _emergencyContactsList() {
    final contacts = AppState.instance.currentUser?.emergencyContacts ?? [];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('비상 연락망', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...contacts.map((c) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: Text('${c.priority}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ),
              title: Text(c.name),
              subtitle: Text(c.phone),
              contentPadding: EdgeInsets.zero,
              trailing: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.name}에게 전화 연결 중...'))),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('연결'),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _emergencyInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('긴급 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),
            _InfoRow('이름', '홍길동'),
            _InfoRow('생년월일', '1950-03-15'),
            _InfoRow('혈액형', 'A형'),
            _InfoRow('복용 약', '혈압약, 당뇨약'),
            _InfoRow('알레르기', '없음'),
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
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
