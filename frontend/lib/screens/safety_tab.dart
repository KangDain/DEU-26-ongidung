import 'dart:async';
import 'package:flutter/material.dart';
import 'emergency_screen.dart';

class SafetyTab extends StatefulWidget {
  const SafetyTab({super.key});

  @override
  State<SafetyTab> createState() => _SafetyTabState();
}

class _SafetyTabState extends State<SafetyTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _motionDetected = false;
  bool _noResponseAlert = false;
  int _lastActivityMinutes = 2;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _lastActivityMinutes++);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSafe =
        !_motionDetected && !_noResponseAlert && _lastActivityMinutes < 30;
    return Scaffold(
      appBar: AppBar(
        title: const Text('실시간 안전 모니터링'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _safetyStatusCard(isSafe),
            const SizedBox(height: 16),
            _motionDetectionCard(),
            const SizedBox(height: 16),
            _noResponseCard(),
            const SizedBox(height: 16),
            _activityTimelineCard(),
            const SizedBox(height: 16),
            _emergencyButton(),
          ],
        ),
      ),
    );
  }

  Widget _safetyStatusCard(bool isSafe) {
    return Card(
      color: isSafe ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) {
                final scale = 1.0 + (_pulseController.value * 0.1);
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isSafe ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(isSafe ? Icons.shield : Icons.warning,
                    color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSafe ? '현재 안전' : '주의 필요',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isSafe ? Colors.green.shade700 : Colors.red.shade700),
            ),
            Text(
              isSafe ? '모든 센서가 정상 작동 중입니다' : '이상 징후가 감지되었습니다',
              style: TextStyle(
                  color: isSafe ? Colors.green.shade600 : Colors.red.shade600),
            ),
            const SizedBox(height: 8),
            Text('마지막 활동: $_lastActivityMinutes분 전',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _motionDetectionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.personal_injury, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text('움직임 감지 (아동 위험 감지)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Switch(
                  value: _motionDetected,
                  onChanged: (v) => setState(() => _motionDetected = v),
                  activeThumbColor: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('아동의 위험 구역 이탈 또는 위험 움직임을 감지합니다.',
                style: TextStyle(color: Colors.grey)),
            if (_motionDetected)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('비정상 움직임 감지됨', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _noResponseCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.elderly, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text('무응답 감지 (독거노인)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Switch(
                  value: _noResponseAlert,
                  onChanged: (v) => setState(() => _noResponseAlert = v),
                  activeThumbColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('일정 시간 이상 움직임이 없을 경우 보호자에게 알림을 전송합니다.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('무응답 감지 기준: '),
                DropdownButton<int>(
                  value: 30,
                  items: [15, 30, 60, 120]
                      .map(
                          (v) => DropdownMenuItem(value: v, child: Text('$v분')))
                      .toList(),
                  onChanged: (_) {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityTimelineCard() {
    final events = [
      ('09:30', '정상 활동', Icons.check_circle, Colors.green),
      ('10:15', '심박 정상 (72bpm)', Icons.monitor_heart, Colors.blue),
      ('11:00', '보호자 메시지 수신', Icons.message, Colors.purple),
      ('11:45', '약 복용 완료', Icons.medication, Colors.teal),
    ];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘의 활동 기록',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ...events.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(e.$1,
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontFamily: 'monospace')),
                      const SizedBox(width: 12),
                      Icon(e.$3, size: 18, color: e.$4),
                      const SizedBox(width: 8),
                      Text(e.$2),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _emergencyButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EmergencyScreen())),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.sos, size: 28),
        label: const Text('긴급 호출',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
