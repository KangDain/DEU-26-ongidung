import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _users = [
    {
      'name': '홍길동',
      'type': '독거노인',
      'status': '활성',
      'lastLogin': '1시간 전',
      'approved': true
    },
    {
      'name': '김민준',
      'type': '아동',
      'status': '활성',
      'lastLogin': '3시간 전',
      'approved': true
    },
    {
      'name': '박영숙',
      'type': '독거노인',
      'status': '비활성',
      'lastLogin': '3일 전',
      'approved': true
    },
    {
      'name': '이서연',
      'type': '일반',
      'status': '대기',
      'lastLogin': '-',
      'approved': false
    },
    {
      'name': '최민호',
      'type': '보호자',
      'status': '활성',
      'lastLogin': '30분 전',
      'approved': true
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('관리자 패널'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.purple.shade200,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: '사용자 관리'),
            Tab(text: '기기 관리'),
            Tab(text: '데이터 관리'),
            Tab(text: '승인 관리'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UserManagementView(users: _users, onUpdate: () => setState(() {})),
          _DeviceManagementView(),
          _DataManagementView(),
          _ApprovalView(
              users: _users.where((u) => !u['approved']).toList(),
              onApprove: (u) {
                setState(() => u['approved'] = true);
              }),
        ],
      ),
    );
  }
}

class _UserManagementView extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final VoidCallback onUpdate;
  const _UserManagementView({required this.users, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
                child: _statCard(
                    '전체 사용자', '${users.length}', Icons.people, Colors.blue)),
            const SizedBox(width: 8),
            Expanded(
                child: _statCard(
                    '활성',
                    '${users.where((u) => u['status'] == '활성').length}',
                    Icons.check_circle,
                    Colors.green)),
            const SizedBox(width: 8),
            Expanded(
                child: _statCard(
                    '대기',
                    '${users.where((u) => u['status'] == '대기').length}',
                    Icons.pending,
                    Colors.orange)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('사용자 목록',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...users.map((u) => Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: u['status'] == '활성'
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  child: Text(u['name'][0],
                      style: TextStyle(
                          color: u['status'] == '활성'
                              ? Colors.green.shade700
                              : Colors.grey,
                          fontWeight: FontWeight.bold)),
                ),
                title: Text(u['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${u['type']} · 마지막 접속: ${u['lastLogin']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) => _handleUserAction(context, action, u),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('정보 수정')
                        ])),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(children: [
                        Icon(
                            u['status'] == '활성'
                                ? Icons.block
                                : Icons.check_circle,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(u['status'] == '활성' ? '비활성화' : '활성화'),
                      ]),
                    ),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red))
                        ])),
                  ],
                  child: Chip(
                    label:
                        Text(u['status'], style: const TextStyle(fontSize: 12)),
                    backgroundColor: u['status'] == '활성'
                        ? Colors.green.shade50
                        : u['status'] == '대기'
                            ? Colors.orange.shade50
                            : Colors.grey.shade100,
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _handleUserAction(
      BuildContext context, String action, Map<String, dynamic> user) {
    if (action == 'toggle') {
      user['status'] = user['status'] == '활성' ? '비활성' : '활성';
      onUpdate();
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('${user['name']} 삭제'),
          content: const Text('이 사용자를 삭제하시겠습니까?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${user['name']}이(가) 삭제되었습니다.')));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
    }
  }
}

class _DeviceManagementView extends StatelessWidget {
  final List<Map<String, dynamic>> _devices = [
    {
      'name': '스마트밴드 #001',
      'user': '홍길동',
      'type': 'wearable',
      'status': '연결됨',
      'battery': 75
    },
    {
      'name': '낙상감지 센서 #002',
      'user': '홍길동',
      'type': 'fall_sensor',
      'status': '연결됨',
      'battery': 92
    },
    {
      'name': 'GPS 트래커 #003',
      'user': '김민준',
      'type': 'gps',
      'status': '연결됨',
      'battery': 88
    },
    {
      'name': '심박센서 #004',
      'user': '박영숙',
      'type': 'heart_rate',
      'status': '연결 끊김',
      'battery': 12
    },
  ];

  _DeviceManagementView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _devices
          .map((d) => Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    d['type'] == 'wearable'
                        ? Icons.watch
                        : d['type'] == 'fall_sensor'
                            ? Icons.personal_injury
                            : d['type'] == 'gps'
                                ? Icons.gps_fixed
                                : Icons.monitor_heart,
                    color: d['status'] == '연결됨'
                        ? Colors.blue.shade600
                        : Colors.grey,
                  ),
                  title: Text(d['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('사용자: ${d['user']} · 배터리: ${d['battery']}%'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: d['status'] == '연결됨'
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(d['status'],
                            style: TextStyle(
                                color: d['status'] == '연결됨'
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12)),
                      ),
                      if (d['status'] != '연결됨')
                        TextButton(
                            onPressed: () {},
                            child: const Text('재연결',
                                style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _DataManagementView extends StatelessWidget {
  const _DataManagementView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _actionCard(context, '사용자 데이터 백업', '전체 사용자 데이터를 안전하게 백업합니다.',
            Icons.backup, Colors.blue, '백업 실행'),
        _actionCard(context, '데이터 복구', '백업에서 데이터를 복원합니다.', Icons.restore,
            Colors.green, '복구 실행'),
        _actionCard(context, '로그 데이터 삭제', '30일 이상 된 로그 데이터를 삭제합니다.',
            Icons.delete_sweep, Colors.orange, '삭제 실행'),
        const SizedBox(height: 16),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('데이터 통계',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 12),
                _DataRow('총 사용자 수', '127명'),
                _DataRow('활성 기기 수', '243개'),
                _DataRow('오늘 알림 수', '1,482건'),
                _DataRow('저장 용량 사용', '2.3 GB / 10 GB'),
                _DataRow('마지막 백업', '2026-04-07 03:00'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(BuildContext context, String title, String desc,
      IconData icon, Color color, String btnLabel) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )),
            ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('$title 실행됨'))),
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
              child: Text(btnLabel, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ApprovalView extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final Function(Map<String, dynamic>) onApprove;
  const _ApprovalView({required this.users, required this.onApprove});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('대기 중인 승인 요청이 없습니다.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: users
          .map((u) => Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person_add)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('${u['type']} · 가입 신청'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: OutlinedButton(
                            onPressed: () => ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                                    content: Text('${u['name']} 가입을 거부했습니다.'))),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red)),
                            child: const Text('거부'),
                          )),
                          const SizedBox(width: 8),
                          Expanded(
                              child: ElevatedButton(
                            onPressed: () {
                              onApprove(u);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('${u['name']} 가입을 승인했습니다.'),
                                      backgroundColor: Colors.green));
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                            child: const Text('승인'),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
