import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../models/user_model.dart';

class HealthTab extends StatefulWidget {
  const HealthTab({super.key});

  @override
  State<HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends State<HealthTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final state = AppState.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('건강 관리'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue.shade200,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.medication), text: '약 복용'),
            Tab(icon: Icon(Icons.monitor_heart), text: '건강 데이터'),
            Tab(icon: Icon(Icons.calendar_today), text: '일정'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MedicationView(),
          _HealthDataView(),
          _ScheduleView(),
        ],
      ),
    );
  }
}

class _MedicationView extends StatefulWidget {
  @override
  State<_MedicationView> createState() => _MedicationViewState();
}

class _MedicationViewState extends State<_MedicationView> {
  final state = AppState.instance;

  @override
  Widget build(BuildContext context) {
    final taken = state.todayMedications.where((m) => m.isTaken).length;
    final total = state.todayMedications.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('오늘 복용: $taken / $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total > 0 ? taken / total : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(taken == total ? Colors.green : Colors.blue),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...state.todayMedications.map((med) => Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: med.isTaken ? Colors.green.shade100 : Colors.orange.shade100,
              child: Icon(Icons.medication, color: med.isTaken ? Colors.green : Colors.orange),
            ),
            title: Text(med.name, style: TextStyle(
              decoration: med.isTaken ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.bold,
            )),
            subtitle: Text('복용 시간: ${med.time}'),
            trailing: med.isTaken
                ? const Chip(label: Text('완료'), backgroundColor: Color(0xFFE8F5E9))
                : ElevatedButton(
                    onPressed: () => setState(() => med.isTaken = true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white),
                    child: const Text('복용'),
                  ),
          ),
        )),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _addMedication,
          icon: const Icon(Icons.add),
          label: const Text('약 추가'),
        ),
      ],
    );
  }

  void _addMedication() {
    final nameCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('약 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '약 이름')),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: '복용 시간 (예: 08:00)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() => state.todayMedications.add(MedicationRecord(name: nameCtrl.text, time: timeCtrl.text)));
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}

class _HealthDataView extends StatelessWidget {
  final state = AppState.instance;
  _HealthDataView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metricCard('심박수', '72 bpm', Icons.monitor_heart, Colors.red, '정상 범위: 60-100 bpm'),
        _metricCard('걸음 수', '2,340 보', Icons.directions_walk, Colors.blue, '목표: 5,000 보'),
        _metricCard('활동량', '정상', Icons.local_fire_department, Colors.orange, '오늘 활동 시간: 2시간 30분'),
        _metricCard('수면', '7.5 시간', Icons.bedtime, Colors.indigo, '권장: 7-8시간'),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('최근 7일 심박수 추이', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [68, 72, 70, 75, 71, 73, 72].asMap().entries.map((e) {
                      final days = ['월', '화', '수', '목', '금', '토', '일'];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${e.value}', style: const TextStyle(fontSize: 11)),
                          const SizedBox(height: 2),
                          Container(
                            width: 24,
                            height: (e.value - 60) * 4.0,
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(days[e.key], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}

class _ScheduleView extends StatefulWidget {
  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  final List<Map<String, dynamic>> _schedules = [
    {'time': '08:00', 'title': '혈압약 복용', 'type': 'medication', 'done': true},
    {'time': '10:00', 'title': '아침 산책', 'type': 'activity', 'done': true},
    {'time': '12:00', 'title': '당뇨약 복용', 'type': 'medication', 'done': false},
    {'time': '14:00', 'title': '병원 방문 (내과)', 'type': 'hospital', 'done': false},
    {'time': '18:00', 'title': '비타민 복용', 'type': 'medication', 'done': false},
    {'time': '20:00', 'title': '가벼운 스트레칭', 'type': 'activity', 'done': false},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._schedules.map((s) => Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  s['type'] == 'medication' ? Icons.medication : s['type'] == 'hospital' ? Icons.local_hospital : Icons.fitness_center,
                  color: s['done'] ? Colors.grey : Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Text(s['time'], style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13)),
              ],
            ),
            title: Text(s['title'], style: TextStyle(
              decoration: s['done'] ? TextDecoration.lineThrough : null,
              color: s['done'] ? Colors.grey : Colors.black,
            )),
            trailing: Checkbox(
              value: s['done'],
              onChanged: (v) => setState(() => s['done'] = v),
            ),
          ),
        )),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('일정 추가')),
      ],
    );
  }
}
