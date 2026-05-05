import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_state.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'location_screen.dart';

class GuardianTab extends StatefulWidget {
  const GuardianTab({super.key});

  @override
  State<GuardianTab> createState() => _GuardianTabState();
}

class _GuardianTabState extends State<GuardianTab> {
  final state = AppState.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    state.addListener(_refresh);
    _loadGuardianData();
  }

  @override
  void dispose() {
    state.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadGuardianData() async {
    final user = state.currentUser;
    if (user == null || user.userId == null) return;
    setState(() => _isLoading = true);
    if (user.userType == UserType.guardian) {
      await _loadRecipients();
    } else {
      await _loadLinkedGuardians();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadRecipients() async {
    final user = state.currentUser;
    if (user?.userType != UserType.guardian || user?.userId == null) return;
    final result = await ApiService.getGuardianRecipients(user!.userId!);
    if (!mounted || result.data == null) return;
    state.guardianUsers
      ..clear()
      ..addAll(result.data!.map(_recipientFromApi));
    state.notifyChanged();
  }

  Future<void> _loadLinkedGuardians() async {
    final userId = state.currentUserId;
    if (userId == null) return;
    final result = await ApiService.getGuardianLinks(userId);
    if (!mounted || result.data == null) return;
    state.applyGuardianLinks(result.data!);
  }

  Map<String, dynamic> _recipientFromApi(Map<String, dynamic> row) {
    final recipient = row['recipient'] is Map
        ? Map<String, dynamic>.from(row['recipient'] as Map)
        : <String, dynamic>{};
    final dashboard = row['dashboard'] is Map
        ? Map<String, dynamic>.from(row['dashboard'] as Map)
        : <String, dynamic>{};
    return {
      'user_id': recipient['user_id'],
      'name': recipient['user_name'] ?? '보호 대상자',
      'phone': recipient['user_phone'] ?? '',
      'type': _typeLabel(recipient['user_type'] as String?),
      'relation_id': row['relation_id'],
      'relation': row['relation_name'] ?? '보호자',
      'share_location': row['share_location'] == true,
      'share_health': row['share_health'] == true,
      'share_activity': row['share_activity'] == true,
      'status': dashboard['safety_status'] ?? '안전',
      'lastUpdate': '방금 전',
      'heartRate': 72,
      'steps': 2340,
      'location':
          dashboard['location_status'] ?? recipient['user_address'] ?? '-',
      'hasAlert':
          (dashboard['notification_status'] as String? ?? '').contains('읽지 않은'),
    };
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'ELDERLY':
        return '독거노인';
      case 'CHILD':
        return '아동';
      case 'GUARDIAN':
        return '보호자';
      default:
        return '일반 사용자';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuardian = state.currentUser?.userType == UserType.guardian;
    return Scaffold(
      appBar: AppBar(
        title: Text(isGuardian ? '보호 대상자 관리' : '보호자 연동'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadGuardianData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isGuardian
              ? _buildGuardianView()
              : _buildUserGuardianView(),
    );
  }

  Widget _buildGuardianView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.guardianUsers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('연결된 보호 대상자가 없습니다.',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
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
                    backgroundColor:
                        hasAlert ? Colors.red.shade100 : Colors.blue.shade100,
                    child: Icon(Icons.person,
                        color: hasAlert ? Colors.red : Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(user['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(user['type'],
                                  style: const TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            if (hasAlert) ...[
                              const SizedBox(width: 8),
                              const Chip(
                                label: Text('주의',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 11)),
                                backgroundColor: Color(0xFFFFEBEE),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ],
                        ),
                        Text('마지막 업데이트: ${user['lastUpdate']}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user['status'] == '안전'
                          ? Colors.green.shade100
                          : user['status'] == '주의'
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user['status'],
                      style: TextStyle(
                        color: user['status'] == '안전'
                            ? Colors.green.shade700
                            : user['status'] == '주의'
                                ? Colors.red.shade700
                                : Colors.blue.shade700,
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
                  _statChip(Icons.monitor_heart, '${user['heartRate']} bpm',
                      Colors.red),
                  _statChip(
                      Icons.directions_walk, '${user['steps']} 보', Colors.blue),
                  _statChip(Icons.location_on, user['location'], Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LocationScreen())),
                    icon: const Icon(Icons.location_on, size: 16),
                    label: const Text('위치'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: () => _sendMessage(user['name'],
                        receiverId: user['user_id'] as int?),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('메시지'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: ElevatedButton.icon(
                    onPressed: () => _callPhone(user['phone'] as String?),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white),
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
    final guardians = state.linkedGuardians;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('연결된 보호자',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                if (guardians.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('연결된 보호자가 없습니다. 아래 버튼으로 보호자 계정을 연동하세요.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...guardians.map(
                    (guardian) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text('${guardian['priority'] ?? 1}',
                            style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(guardian['name'] as String? ?? '보호자'),
                      subtitle: Text(
                          '${guardian['relation'] ?? '보호자'} · ${guardian['phone'] ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.message),
                            onPressed: () => _sendMessage(
                              guardian['name'] as String? ?? '보호자',
                              receiverId: guardian['guardian_id'] as int?,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone),
                            onPressed: () =>
                                _callPhone(guardian['phone'] as String?),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('공유 설정',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _shareSwitch(
                  label: '위치 정보 공유',
                  value: state.shareLocation,
                  onChanged: (v) => _updateSharing(location: v),
                ),
                _shareSwitch(
                  label: '건강 데이터 공유',
                  value: state.shareHealth,
                  onChanged: (v) => _updateSharing(health: v),
                ),
                _shareSwitch(
                  label: '활동 데이터 공유',
                  value: state.shareActivity,
                  onChanged: (v) => _updateSharing(activity: v),
                ),
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

  Widget _shareSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label),
      subtitle: state.linkedGuardians.isEmpty
          ? const Text('보호자를 먼저 연동하면 공유 설정이 저장됩니다.',
              style: TextStyle(fontSize: 12))
          : null,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
                child: Text(user['name'],
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            _detailRow('상태', user['status']),
            _detailRow('심박수', '${user['heartRate']} bpm'),
            _detailRow('걸음 수', '${user['steps']} 보'),
            _detailRow('위치', user['location']),
            _detailRow('마지막 업데이트', user['lastUpdate']),
            const SizedBox(height: 20),
            const Text('오늘의 활동 일정',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('아침 혈압약 복용'),
                subtitle: Text('08:00')),
            const ListTile(
                leading: Icon(Icons.radio_button_unchecked),
                title: Text('점심 당뇨약 복용'),
                subtitle: Text('12:00')),
            const ListTile(
                leading: Icon(Icons.radio_button_unchecked),
                title: Text('저녁 비타민 복용'),
                subtitle: Text('18:00')),
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
          SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _sendMessage(String name, {int? receiverId}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$name에게 메시지'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: '메시지를 입력하세요'),
            maxLines: 3),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final senderId = state.currentUserId;
              if (senderId != null &&
                  receiverId != null &&
                  ctrl.text.isNotEmpty) {
                await ApiService.sendMessage(
                  senderId: senderId,
                  receiverId: receiverId,
                  body: ctrl.text,
                );
              }
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(dialogContext)
                  .showSnackBar(SnackBar(content: Text('$name에게 메시지를 보냈습니다.')));
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }

  Future<void> _callPhone(String? phone) async {
    final cleaned = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록된 전화번호가 없습니다.')),
      );
      return;
    }
    await launchUrl(Uri.parse('tel:$cleaned'));
  }

  Future<void> _updateSharing({
    bool? location,
    bool? health,
    bool? activity,
  }) async {
    final previousLocation = state.shareLocation;
    final previousHealth = state.shareHealth;
    final previousActivity = state.shareActivity;

    state.setShareSettings(
      location: location,
      health: health,
      activity: activity,
    );

    final payload = {
      'share_location': state.shareLocation,
      'share_health': state.shareHealth,
      'share_activity': state.shareActivity,
    };

    final relationId = state.linkedGuardians.isNotEmpty
        ? state.linkedGuardians.first['relation_id']
        : null;

    ({Map<String, dynamic>? data, String? error}) result;
    if (relationId is int) {
      result = await ApiService.updateSharing(relationId, payload);
    } else if (state.currentUserId == null) {
      result = (data: null, error: '로그인이 필요합니다.');
    } else {
      result = await ApiService.updateProfile(state.currentUserId!, payload);
    }

    if (!mounted || result.error == null) return;

    state.setShareSettings(
      location: previousLocation,
      health: previousHealth,
      activity: previousActivity,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error!)),
    );
  }

  void _addGuardian() {
    final loginCtrl = TextEditingController();
    final relationCtrl = TextEditingController(text: '보호자');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('보호자 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: loginCtrl,
              decoration: const InputDecoration(
                labelText: '보호자 아이디 *',
                hintText: '보호자로 가입한 로그인 아이디',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: relationCtrl,
              decoration: const InputDecoration(labelText: '관계'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final userId = state.currentUserId;
              final loginId = loginCtrl.text.trim();
              if (userId == null || loginId.isEmpty) return;
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              final result = await ApiService.connectGuardian(userId, {
                'guardian_login_id': loginId,
                'recipient_id': userId,
                'relation_name': relationCtrl.text.trim().isEmpty
                    ? '보호자'
                    : relationCtrl.text.trim(),
                'priority': state.linkedGuardians.length + 1,
              });
              if (!mounted) return;
              setState(() => _isLoading = false);
              if (result.data != null) {
                state.addGuardianLinkFromApi(result.data!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('보호자가 연동되었습니다.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.error ?? '보호자 연동 실패')),
                );
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}
