import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final state = AppState.instance;
  bool _markingAll = false;

  IconData _typeIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication;
      case 'activity':
        return Icons.directions_walk;
      case 'guardian':
        return Icons.supervisor_account;
      case 'device':
        return Icons.devices;
      case 'schedule':
        return Icons.calendar_today;
      case 'emergency':
        return Icons.sos;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'medication':
        return Colors.teal;
      case 'activity':
        return Colors.blue;
      case 'guardian':
        return Colors.purple;
      case 'device':
        return Colors.orange;
      case 'schedule':
        return Colors.indigo;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['isRead'] == true) return;
    setState(() {
      n['isRead'] = true;
      state.unreadNotifications =
          state.notifications.where((x) => x['isRead'] == false).length;
    });
    final alertId = n['alert_id'];
    if (alertId is int) {
      await ApiService.markNotificationRead(alertId);
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    for (var n in state.notifications) {
      n['isRead'] = true;
    }
    state.unreadNotifications = 0;
    setState(() => _markingAll = false);

    final userId = state.currentUserId;
    if (userId != null) {
      await ApiService.markAllNotificationsRead(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          _markingAll
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _markAllRead,
                  child: const Text('모두 읽음',
                      style: TextStyle(color: Colors.white)),
                ),
        ],
      ),
      body: state.notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('알림이 없습니다.',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = state.notifications[i];
                final isRead = n['isRead'] as bool? ?? false;
                final type = (n['type'] as String?) ?? 'schedule';
                final priority = (n['priority'] as String?) ?? 'NORMAL';
                return Dismissible(
                  key: Key('notif_${n['alert_id'] ?? i}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) =>
                      setState(() => state.notifications.removeAt(i)),
                  child: ListTile(
                    tileColor: isRead ? null : Colors.blue.shade50,
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _typeColor(type).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_typeIcon(type),
                              color: _typeColor(type)),
                        ),
                        if (priority == 'EMERGENCY' || priority == 'HIGH')
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      n['title'] as String? ?? '알림',
                      style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.bold),
                    ),
                    subtitle: Text(
                      n['body'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(n['time'] as String? ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    onTap: () => _markRead(n),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNotificationSettings,
        icon: const Icon(Icons.settings),
        label: const Text('알림 설정'),
      ),
    );
  }

  void _showNotificationSettings() {
    final Map<String, bool> settings = {
      '약 복용 알림': true,
      '긴급 상황 알림': true,
      '보호자 메시지 알림': true,
      '활동량 알림': false,
      '일정 알림': true,
    };
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (_, setLocal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('알림 설정',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...settings.keys.map(
                (key) => SwitchListTile(
                  value: settings[key]!,
                  onChanged: (v) => setLocal(() => settings[key] = v),
                  title: Text(key),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
