import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class HealthTab extends StatefulWidget {
  const HealthTab({super.key});

  @override
  State<HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends State<HealthTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            Tab(icon: Icon(Icons.calendar_today), text: '일정'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MedicationView(),
          _ScheduleView(),
        ],
      ),
    );
  }
}

// ─── 약 복용 탭 ───────────────────────────────────────────────────────────────

class _MedicationView extends StatefulWidget {
  @override
  State<_MedicationView> createState() => _MedicationViewState();
}

class _MedicationViewState extends State<_MedicationView> {
  final state = AppState.instance;
  bool _isLoading = false;

  List<MedicationRecord> get _meds =>
      state.todayMedications.where((m) => m.category == 'medication').toList();

  Future<void> _toggleMedication(MedicationRecord med) async {
    final newValue = !med.isTaken;
    setState(() => med.isTaken = newValue);
    final routineId = med.routineId;
    if (routineId == null) return;
    if (newValue) {
      await ApiService.completeRoutine(routineId);
    } else {
      await ApiService.updateRoutine(routineId, {'is_done_today': false});
    }
  }

  Future<void> _deleteMedication(MedicationRecord med) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('\'${med.name}\'을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final routineId = med.routineId;
    if (routineId != null) {
      await ApiService.deleteRoutine(routineId);
    }
    setState(() => state.todayMedications.remove(med));
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
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '약 이름 *')),
            const SizedBox(height: 8),
            TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(
                    labelText: '복용 시간 *', hintText: '08:00')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || timeCtrl.text.isEmpty) return;
              Navigator.pop(context);
              final userId = state.currentUserId;
              if (userId == null) return;
              setState(() => _isLoading = true);
              final result = await ApiService.addRoutine(userId, {
                'routine_title': nameCtrl.text,
                'routine_category': 'medication',
                'routine_notify_time': timeCtrl.text,
              });
              if (!mounted) return;
              setState(() => _isLoading = false);
              if (result.data != null) {
                final r = result.data!;
                state.todayMedications.add(MedicationRecord(
                  routineId: r['routine_id'] is int ? r['routine_id'] as int : null,
                  name: r['routine_title'] as String? ?? nameCtrl.text,
                  time: r['routine_notify_time'] as String? ?? timeCtrl.text,
                  category: 'medication',
                ));
                setState(() {});
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meds = _meds;
    final taken = meds.where((m) => m.isTaken).length;
    final total = meds.length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('오늘 복용: $taken / $total',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: total > 0 ? taken / total : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          taken == total ? Colors.green : Colors.blue),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (meds.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('등록된 약이 없습니다.',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...meds.map((med) => Dismissible(
                    key: Key('med_${med.routineId}_${med.name}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      await _deleteMedication(med);
                      return false;
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: med.isTaken
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          child: Icon(Icons.medication,
                              color: med.isTaken ? Colors.green : Colors.orange),
                        ),
                        title: Text(med.name,
                            style: TextStyle(
                              decoration: med.isTaken
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontWeight: FontWeight.bold,
                            )),
                        subtitle: Text('복용 시간: ${med.time}'),
                        trailing: med.isTaken
                            ? TextButton(
                                onPressed: () => _toggleMedication(med),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.orange),
                                child: const Text('취소'),
                              )
                            : ElevatedButton(
                                onPressed: () => _toggleMedication(med),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white),
                                child: const Text('복용'),
                              ),
                      ),
                    ),
                  )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addMedication,
              icon: const Icon(Icons.add),
              label: const Text('약 추가'),
            ),
            const SizedBox(height: 80),
          ],
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

// ─── 일정 탭 ──────────────────────────────────────────────────────────────────

class _ScheduleView extends StatefulWidget {
  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  final state = AppState.instance;
  bool _isLoading = false;

  List<MedicationRecord> get _schedules => state.todayMedications
      .where((m) => m.category != 'medication')
      .toList()
    ..sort((a, b) => a.time.compareTo(b.time));

  Future<void> _toggleSchedule(MedicationRecord s) async {
    final newValue = !s.isTaken;
    setState(() => s.isTaken = newValue);
    final routineId = s.routineId;
    if (routineId == null) return;
    if (newValue) {
      await ApiService.completeRoutine(routineId);
    } else {
      await ApiService.updateRoutine(routineId, {'is_done_today': false});
    }
  }

  Future<void> _deleteSchedule(MedicationRecord s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('\'${s.name}\'을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final routineId = s.routineId;
    if (routineId != null) await ApiService.deleteRoutine(routineId);
    setState(() => state.todayMedications.remove(s));
  }

  void _addSchedule() {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    String category = 'schedule';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('일정 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '일정 이름 *')),
              const SizedBox(height: 8),
              TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(
                      labelText: '시간 *', hintText: '14:00')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: '유형'),
                items: const [
                  DropdownMenuItem(value: 'schedule', child: Text('일반 일정')),
                  DropdownMenuItem(value: 'mission', child: Text('미션')),
                  DropdownMenuItem(value: 'hospital', child: Text('병원 방문')),
                  DropdownMenuItem(value: 'activity', child: Text('활동')),
                ],
                onChanged: (v) => setLocal(() => category = v ?? 'schedule'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || timeCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                final userId = state.currentUserId;
                if (userId == null) return;
                setState(() => _isLoading = true);
                final result = await ApiService.addRoutine(userId, {
                  'routine_title': titleCtrl.text,
                  'routine_category': category,
                  'routine_notify_time': timeCtrl.text,
                });
                if (!mounted) return;
                setState(() => _isLoading = false);
                if (result.data != null) {
                  final r = result.data!;
                  state.todayMedications.add(MedicationRecord(
                    routineId:
                        r['routine_id'] is int ? r['routine_id'] as int : null,
                    name: r['routine_title'] as String? ?? titleCtrl.text,
                    time: r['routine_notify_time'] as String? ?? timeCtrl.text,
                    category: r['routine_category'] as String? ?? category,
                  ));
                  setState(() {});
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'hospital':
        return Icons.local_hospital;
      case 'activity':
        return Icons.fitness_center;
      case 'mission':
        return Icons.star;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedules = _schedules;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (schedules.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('등록된 일정이 없습니다.',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...schedules.map((s) => Dismissible(
                    key: Key('sched_${s.routineId}_${s.name}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      await _deleteSchedule(s);
                      return false;
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryIcon(s.category),
                              color: s.isTaken
                                  ? Colors.grey
                                  : Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(s.time,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    fontSize: 13)),
                          ],
                        ),
                        title: Text(s.name,
                            style: TextStyle(
                              decoration: s.isTaken
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: s.isTaken ? Colors.grey : Colors.black,
                            )),
                        trailing: Checkbox(
                          value: s.isTaken,
                          onChanged: (_) => _toggleSchedule(s),
                          activeColor: Colors.blue.shade600,
                        ),
                      ),
                    ),
                  )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addSchedule,
              icon: const Icon(Icons.add),
              label: const Text('일정 추가'),
            ),
            const SizedBox(height: 80),
          ],
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
