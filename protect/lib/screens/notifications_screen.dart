import 'package:flutter/material.dart';
import '../models/app_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final state = AppState.instance;

  IconData _typeIcon(String type) {
    switch (type) {
      case 'medication': return Icons.medication;
      case 'activity': return Icons.directions_walk;
      case 'guardian': return Icons.supervisor_account;
      case 'device': return Icons.devices;
      case 'schedule': return Icons.calendar_today;
      case 'emergency': return Icons.sos;
      default: return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'medication': return Colors.teal;
      case 'activity': return Colors.blue;
      case 'guardian': return Colors.purple;
      case 'device': return Colors.orange;
      case 'schedule': return Colors.indigo;
      case 'emergency': return Colors.red;
      default: return Colors.grey;
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
          TextButton(
            onPressed: () => setState(() {
              for (var n in state.notifications) n['isRead'] = true;
              state.unreadNotifications = 0;
            }),
            child: const Text('모두 읽음', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final n = state.notifications[i];
          final isRead = n['isRead'] as bool;
          final type = n['type'] as String;
          return Dismissible(
            key: Key('notif_$i'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => setState(() => state.notifications.removeAt(i)),
            child: ListTile(
              tileColor: isRead ? null : Colors.blue.shade50,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor(type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_typeIcon(type), color: _typeColor(type)),
              ),
              title: Text(n['title'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
              subtitle: Text(n['body'], maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(n['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (!isRead) Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  ),
                ],
              ),
              onTap: () => setState(() {
                n['isRead'] = true;
                state.unreadNotifications = state.notifications.where((n) => n['isRead'] == false).length;
              }),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('알림 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(value: true, onChanged: (_) {}, title: const Text('약 복용 알림'), contentPadding: EdgeInsets.zero),
            SwitchListTile(value: true, onChanged: (_) {}, title: const Text('긴급 상황 알림'), contentPadding: EdgeInsets.zero),
            SwitchListTile(value: true, onChanged: (_) {}, title: const Text('보호자 메시지 알림'), contentPadding: EdgeInsets.zero),
            SwitchListTile(value: false, onChanged: (_) {}, title: const Text('활동량 알림'), contentPadding: EdgeInsets.zero),
            SwitchListTile(value: true, onChanged: (_) {}, title: const Text('일정 알림'), contentPadding: EdgeInsets.zero),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
