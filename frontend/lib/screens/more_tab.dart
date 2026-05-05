import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../models/user_model.dart';
import 'notifications_screen.dart';
import 'games_screen.dart';
import 'location_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.currentUser;
    final isAdmin = user?.userType == UserType.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('더보기'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _profileHeader(context, user),
          const Divider(height: 1),
          _menuSection('기능', [
            _menuItem(context, Icons.notifications, '알림 관리', '${AppState.instance.unreadNotifications}개의 새 알림',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            _menuItem(context, Icons.location_on, '위치 추적', '실시간 위치 확인',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationScreen()))),
            _menuItem(context, Icons.games, '건강 게임', '미션과 게임으로 건강 포인트 획득',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen()))),
          ]),
          _menuSection('계정', [
            _menuItem(context, Icons.person, '내 프로필', '개인정보 및 설정 관리',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
            _menuItem(context, Icons.watch, 'IoT 기기 관리', '연결된 기기 확인 및 설정', () => _showDeviceManagement(context)),
            _menuItem(context, Icons.security, '보안 설정', 'PIN 번호, 생체인식 설정', () => _showSecuritySettings(context)),
          ]),
          if (isAdmin)
            _menuSection('관리자', [
              _menuItem(context, Icons.admin_panel_settings, '관리자 패널', '사용자 및 시스템 관리',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                  color: Colors.purple),
            ]),
          _menuSection('앱 정보', [
            _menuItem(context, Icons.info, '앱 정보', '버전 1.0.0', () {}),
            _menuItem(context, Icons.privacy_tip, '개인정보처리방침', '', () {}),
            _menuItem(context, Icons.help, '도움말 / 문의', '', () {}),
          ]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('로그아웃', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context, UserModel? user) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.blue.shade50,
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.blue.shade200,
              child: Icon(Icons.person, size: 40, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? '사용자', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(user?.userTypeLabel ?? '', style: TextStyle(color: Colors.blue.shade600)),
                  Text(user?.phone ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _menuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ),
        ...items,
      ],
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? Colors.blue.shade600).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? Colors.blue.shade600, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  void _showDeviceManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('IoT 기기 관리', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...AppState.instance.devices.map((d) => ListTile(
            leading: Icon(
              d.type == 'wearable' ? Icons.watch : d.type == 'fall_sensor' ? Icons.personal_injury :
              d.type == 'door_sensor' ? Icons.door_front_door : d.type == 'heart_rate' ? Icons.monitor_heart : Icons.gps_fixed,
              color: d.isConnected ? Colors.blue.shade600 : Colors.grey,
            ),
            title: Text(d.name),
            subtitle: Text(d.isConnected ? '연결됨 · ${d.batteryLevel}%' : '연결 끊김'),
            trailing: d.isConnected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(onPressed: () {}, child: const Text('재연결', style: TextStyle(fontSize: 12))),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSecuritySettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('보안 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(value: true, onChanged: (_) {}, title: const Text('자동 로그인'), contentPadding: EdgeInsets.zero),
            SwitchListTile(value: false, onChanged: (_) {}, title: const Text('PIN 로그인'), contentPadding: EdgeInsets.zero),
            SwitchListTile(value: false, onChanged: (_) {}, title: const Text('생체인식 로그인'), contentPadding: EdgeInsets.zero),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('비밀번호 변경')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              AppState.instance.logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
