import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';
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
  void initState() {
    super.initState();
    state.addListener(_refresh);
    _loadDashboard();
  }

  @override
  void dispose() {
    state.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDashboard() async {
    final userId = state.currentUserId;
    if (userId == null) return;
    final result = await ApiService.getDashboard(userId);
    if (!mounted) return;
    if (result.data != null) {
      setState(() => state.applyDashboard(result.data!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = state.currentUser;
    final takenCount = state.takenMedicationCount;
    final totalMeds = state.totalMedicationCount;
    final emergencyColor = state.isEmergencyActive ? Colors.red : Colors.green;
    final medicationColor = totalMeds == 0 || takenCount == totalMeds
        ? Colors.green
        : Colors.orange;
    final activityColor = state.activityStatusLabel.contains('주의')
        ? Colors.red
        : state.activityStatusLabel.contains('확인')
            ? Colors.orange
            : Colors.blue.shade300;

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
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen())),
                              child: Badge(
                                label: Text('${state.unreadNotifications}'),
                                isLabelVisible: state.unreadNotifications > 0,
                                child: const Icon(Icons.notifications,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          user?.userTypeLabel ?? '',
                          style: TextStyle(
                              color: Colors.blue.shade100, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _statusChip(
                              state.isEmergencyActive
                                  ? Icons.sos
                                  : Icons.shield,
                              state.emergencyStatusLabel,
                              emergencyColor,
                            ),
                            const SizedBox(width: 8),
                            _statusChip(Icons.medication,
                                state.medicationProgressLabel, medicationColor),
                            const SizedBox(width: 8),
                            _statusChip(Icons.directions_walk,
                                state.activityStatusLabel, activityColor),
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
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _todaySummaryCard() {
    final summaryLines = state.computedCareSummary;
    final routines = state.sortedTodayRoutines;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summaryLines.isNotEmpty) ...[
              ...summaryLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.blue.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(line,
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),
            ],
            if (routines.isEmpty)
              Text('오늘 일정이 없습니다.',
                  style: TextStyle(color: Colors.grey.shade500))
            else
              ...routines.map(
                (routine) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                          routine.isTaken
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: routine.isTaken ? Colors.green : Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(routine.name,
                              style: TextStyle(
                                decoration: routine.isTaken
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: routine.isTaken
                                    ? Colors.grey
                                    : Colors.black,
                              ))),
                      Text(routine.time,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                      const SizedBox(width: 8),
                      if (!routine.isTaken)
                        TextButton(
                          onPressed: () => _completeMedication(routine),
                          child: Text(
                              routine.category == 'medication' ? '복용완료' : '완료'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _callGuardian() {
    final user = state.currentUser;
    final contacts = user?.emergencyContacts ?? [];
    final guardianPhone = user?.guardianPhone ?? '';

    if (contacts.isEmpty && guardianPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록된 보호자 연락처가 없습니다.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('보호자에게 연락',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (contacts.isNotEmpty)
              ...contacts.map((c) => ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: Text('${c.name} (${c.relation})'),
                    subtitle: Text(c.phone),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () async {
                        Navigator.pop(context);
                        final cleaned =
                            c.phone.replaceAll(RegExp(r'[^0-9+]'), '');
                        await launchUrl(Uri.parse('tel:$cleaned'));
                      },
                    ),
                  ))
            else if (guardianPhone.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('보호자'),
                subtitle: Text(guardianPhone),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () async {
                    Navigator.pop(context);
                    final cleaned =
                        guardianPhone.replaceAll(RegExp(r'[^0-9+]'), '');
                    await launchUrl(Uri.parse('tel:$cleaned'));
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _completeMedication(dynamic med) async {
    state.setRoutineDone(med, true);
    final routineId = med.routineId;
    if (routineId is int) {
      await ApiService.completeRoutine(routineId);
    }
  }

  Widget _quickActions() {
    final actions = [
      (
        Icons.sos,
        '긴급 호출',
        Colors.red,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const EmergencyScreen()))
      ),
      (Icons.contact_phone, '보호자 연락', Colors.orange, _callGuardian),
      (
        Icons.favorite,
        '건강 체크',
        Colors.pink,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const HealthTab()))
      ),
      (
        Icons.location_on,
        '위치 확인',
        Colors.blue,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LocationScreen()))
      ),
      (
        Icons.games,
        '게임 시작',
        Colors.purple,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const GamesScreen()))
      ),
      (
        Icons.notifications_active,
        '알림 확인',
        Colors.teal,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()))
      ),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: actions
          .map((a) => GestureDetector(
                onTap: a.$4,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: a.$3.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: Icon(a.$1, color: a.$3, size: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(a.$2,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _deviceStatusCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: state.devices
            .map((d) => ListTile(
                  leading: Icon(
                    d.type == 'wearable'
                        ? Icons.watch
                        : d.type == 'fall_sensor'
                            ? Icons.personal_injury
                            : d.type == 'door_sensor'
                                ? Icons.door_front_door
                                : d.type == 'heart_rate'
                                    ? Icons.monitor_heart
                                    : Icons.gps_fixed,
                    color: d.isConnected ? Colors.blue.shade600 : Colors.grey,
                  ),
                  title: Text(d.name),
                  subtitle: Text(d.isConnected ? '연결됨' : '연결 끊김',
                      style: TextStyle(
                          color: d.isConnected ? Colors.green : Colors.red)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.battery_full,
                          size: 16,
                          color: d.batteryLevel > 50
                              ? Colors.green
                              : Colors.orange),
                      Text('${d.batteryLevel}%',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
