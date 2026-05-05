import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../models/user_model.dart';
import 'dashboard_tab.dart';
import 'safety_tab.dart';
import 'health_tab.dart';
import 'guardian_tab.dart';
import 'more_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AppState _state = AppState.instance;

  final List<Widget> _tabs = const [
    DashboardTab(),
    SafetyTab(),
    HealthTab(),
    GuardianTab(),
    MoreTab(),
  ];

  @override
  void initState() {
    super.initState();
    _state.addListener(_refresh);
  }

  @override
  void dispose() {
    _state.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = _state.currentUser;
    final isGuardian = user?.userType == UserType.guardian;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈'),
          const NavigationDestination(
              icon: Icon(Icons.security_outlined),
              selectedIcon: Icon(Icons.security),
              label: '안전'),
          const NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: '건강'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: isGuardian &&
                  _state.guardianUsers.any((u) => u['hasAlert'] == true),
              child: const Icon(Icons.supervisor_account_outlined),
            ),
            selectedIcon: const Icon(Icons.supervisor_account),
            label: isGuardian ? '보호 대상' : '보호자',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('${_state.unreadNotifications}'),
              isLabelVisible: _state.unreadNotifications > 0,
              child: const Icon(Icons.more_horiz),
            ),
            label: '더보기',
          ),
        ],
      ),
    );
  }
}
