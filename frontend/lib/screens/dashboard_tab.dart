import 'package:flutter/material.dart';
import '../models/app_state.dart';
import 'emergency_screen.dart';
import 'health_tab.dart';
import 'location_screen.dart';
import 'games_screen.dart';
import 'notifications_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final state = AppState.instance;

  @override
  Widget build(BuildContext context) {
    final user = state.currentUser;
    final takenCount = state.todayMedications.where((m) => m.isTaken).length;
    final totalMeds = state.todayMedications.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '안녕하세요, ${user?.name ?? "사용자"}님',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                              child: Badge(
                                label: Text('${state.unreadNotifications}'),
                                isLabelVisible: state.unreadNotifications > 0,
                                child: const Icon(Icons.notifications, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          user?.userTypeLabel ?? '',
                          style: TextStyle(color: Colors.blue.shade100, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _statusChip(Icons.shield, state.safetyStatus, Colors.green),
                            const SizedBox(width: 8),
                            _statusChip(Icons.medication, '약 $takenCount/$totalMeds', takenCount == totalMeds ? Colors.green : Colors.orange),
                            const SizedBox(width: 8),
                            _statusChip(Icons.directions_walk, '활동 정상', Colors.blue.shade300),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('오늘의 돌봄 요약'),
                  const SizedBox(height: 8),
                  _todaySummaryCard(),
                  const SizedBox(height: 20),
                  _sectionTitle('빠른 실행'),
                  const SizedBox(height: 8),
                  _quickActions(),
                  const SizedBox(height: 20),
                  _sectionTitle('IoT 기기 상태'),
                  const SizedBox(height: 8),
                  _deviceStatusCard(),
                  const SizedBox(height: 20),
                  _sectionTitle('최근 건강 데이터'),
                  const SizedBox(height: 8),
                  _healthSummaryCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _todaySummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: state.todayMedications.map((med) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(med.isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: med.isTaken ? Colors.green : Colors.grey),
                const SizedBox(width: 12),
                Expanded(child: Text(med.name, style: TextStyle(
                  decoration: med.isTaken ? TextDecoration.lineThrough : null,
                  color: med.isTaken ? Colors.grey : Colors.black,
                ))),
                Text(med.time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 8),
                if (!med.isTaken) TextButton(
                  onPressed: () => setState(() => med.isTaken = true),
                  child: const Text('복용완료'),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      (Icons.sos, '긴급 호출', Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()))),
      (Icons.contact_phone, '보호자 연락', Colors.orange, () {}),
      (Icons.favorite, '건강 체크', Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthTab()))),
      (Icons.location_on, '위치 확인', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationScreen()))),
      (Icons.games, '게임 시작', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen()))),
      (Icons.notifications_active, '알림 확인', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: actions.map((a) => GestureDetector(
        onTap: a.$4,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: a.$3.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(a.$1, color: a.$3, size: 28),
              ),
              const SizedBox(height: 6),
              Text(a.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _deviceStatusCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: state.devices.map((d) => ListTile(
          leading: Icon(
            d.type == 'wearable' ? Icons.watch : d.type == 'fall_sensor' ? Icons.personal_injury :
            d.type == 'door_sensor' ? Icons.door_front_door : d.type == 'heart_rate' ? Icons.monitor_heart : Icons.gps_fixed,
            color: d.isConnected ? Colors.blue.shade600 : Colors.grey,
          ),
          title: Text(d.name),
          subtitle: Text(d.isConnected ? '연결됨' : '연결 끊김', style: TextStyle(color: d.isConnected ? Colors.green : Colors.red)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.battery_full, size: 16, color: d.batteryLevel > 50 ? Colors.green : Colors.orange),
              Text('${d.batteryLevel}%', style: const TextStyle(fontSize: 12)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _healthSummaryCard() {
    final latest = state.recentHealthData.isNotEmpty ? state.recentHealthData.first : null;
    if (latest == null) return const SizedBox();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _healthStat(Icons.monitor_heart, '심박수', '${latest.heartRate} bpm', Colors.red),
            _healthStat(Icons.directions_walk, '걸음 수', '${latest.steps} 보', Colors.blue),
            _healthStat(Icons.shield, '상태', latest.status ?? '-', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _healthStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
