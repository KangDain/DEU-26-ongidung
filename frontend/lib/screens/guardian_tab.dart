import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../models/user_model.dart';
import 'location_screen.dart';

class GuardianTab extends StatefulWidget {
  const GuardianTab({super.key});

  @override
  State<GuardianTab> createState() => _GuardianTabState();
}

class _GuardianTabState extends State<GuardianTab> {
  final state = AppState.instance;

  @override
  Widget build(BuildContext context) {
    final isGuardian = state.currentUser?.userType == UserType.guardian;
    return Scaffold(
      appBar: AppBar(
        title: Text(isGuardian ? '보호 대상자 관리' : '보호자 연동'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: isGuardian ? _buildGuardianView() : _buildUserGuardianView(),
    );
  }

  Widget _buildGuardianView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...state.guardianUsers.map((u) => _guardianUserCard(u)),
      ],
    );
  }

  Widget _guardianUserCard(Map<String, dynamic> user) {
    final hasAlert = user['hasAlert'] == true;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: hasAlert ? Colors.red.shade50 : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showUserDetail(user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: hasAlert ? Colors.red.shade100 : Colors.blue.shade100,
                    child: Icon(Icons.person, color: hasAlert ? Colors.red : Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(user['type'], style: const TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            if (hasAlert) ...[
                              const SizedBox(width: 8),
                              const Chip(
                                label: Text('주의', style: TextStyle(color: Colors.red, fontSize: 11)),
                                backgroundColor: Color(0xFFFFEBEE),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ],
                        ),
                        Text('마지막 업데이트: ${user['lastUpdate']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user['status'] == '안전' ? Colors.green.shade100 : user['status'] == '주의' ? Colors.red.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user['status'],
                      style: TextStyle(
                        color: user['status'] == '안전' ? Colors.green.shade700 : user['status'] == '주의' ? Colors.red.shade700 : Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip(Icons.monitor_heart, '${user['heartRate']} bpm', Colors.red),
                  _statChip(Icons.directions_walk, '${user['steps']} 보', Colors.blue),
                  _statChip(Icons.location_on, user['location'], Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationScreen())),
                    icon: const Icon(Icons.location_on, size: 16),
                    label: const Text('위치'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => _sendMessage(user['name']),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('메시지'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('통화'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildUserGuardianView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('연결된 보호자', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...?state.currentUser?.emergencyContacts.map((c) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text('${c.priority}', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(c.name),
                  subtitle: Text(c.phone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.message), onPressed: () => _sendMessage(c.name)),
                      IconButton(icon: const Icon(Icons.phone), onPressed: () {}),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('공유 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _shareSwitch('위치 정보 공유', true),
                _shareSwitch('건강 데이터 공유', true),
                _shareSwitch('활동 데이터 공유', false),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _addGuardian,
          icon: const Icon(Icons.person_add),
          label: const Text('보호자 추가'),
        ),
      ],
    );
  }

  Widget _shareSwitch(String label, bool initial) {
    return StatefulBuilder(
      builder: (_, set) => SwitchListTile(
        value: initial,
        onChanged: (v) => set(() {}),
        title: Text(label),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Text(user['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            _detailRow('상태', user['status']),
            _detailRow('심박수', '${user['heartRate']} bpm'),
            _detailRow('걸음 수', '${user['steps']} 보'),
            _detailRow('위치', user['location']),
            _detailRow('마지막 업데이트', user['lastUpdate']),
            const SizedBox(height: 20),
            const Text('오늘의 활동 일정', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('아침 혈압약 복용'), subtitle: Text('08:00')),
            const ListTile(leading: Icon(Icons.radio_button_unchecked), title: Text('점심 당뇨약 복용'), subtitle: Text('12:00')),
            const ListTile(leading: Icon(Icons.radio_button_unchecked), title: Text('저녁 비타민 복용'), subtitle: Text('18:00')),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _sendMessage(String name) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$name에게 메시지'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '메시지를 입력하세요'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name에게 메시지를 보냈습니다.')));
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }

  void _addGuardian() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('보호자 추가'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: '이름')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: '연락처')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: '관계 (예: 아들, 딸)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('보호자 추가 요청을 보냈습니다.')));
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}
