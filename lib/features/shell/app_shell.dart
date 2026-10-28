import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/features/dashboard/login_home.dart';
import 'package:doctro/features/consultation/chat/pages/home_page.dart';
import 'package:doctro/features/notifications/notifications.dart';
import 'package:doctro/features/profile/profile.dart';

class _ShellDestination {
  final List<List<dynamic>> icon;
  final String label;

  const _ShellDestination({required this.icon, required this.label});
}

const _destinations = <_ShellDestination>[
  _ShellDestination(icon: HugeIcons.strokeRoundedHome01, label: 'Home'),
  _ShellDestination(icon: HugeIcons.strokeRoundedMessage01, label: 'Chat'),
  _ShellDestination(
      icon: HugeIcons.strokeRoundedNotification01, label: 'Alerts'),
  _ShellDestination(icon: HugeIcons.strokeRoundedUser, label: 'Profile'),
];

/// The app's persistent bottom-tab shell around its top destinations (Home,
/// Chat, Notifications, Profile). This is what the `'loginHome'` route now
/// resolves to, so every existing `pushNamedAndRemoveUntil('loginHome',
/// ...)` call site lands here without change.
///
/// Each tab keeps its own full `Scaffold` (app bar, drawer, etc.) - this
/// widget only supplies the outer `Scaffold`'s `bottomNavigationBar` and an
/// `IndexedStack` to keep a tab's state alive once visited. Tabs are built
/// lazily on first visit rather than all at once, so switching to Chat
/// doesn't fire off every tab's startup network calls before the user ever
/// looks at them.
class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;
  late final _tabs = List<Widget?>.filled(_destinations.length, null);

  @override
  void initState() {
    super.initState();
    _tabs[_index] = _buildTab(_index);
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const LoginHomeScreen(chat: '');
      case 1:
        return const HomePage();
      case 2:
        return const NotificationsScreen();
      case 3:
        return const ProfileScreen();
      default:
        throw StateError('No tab at index $index');
    }
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _tabs[index] ??= _buildTab(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            _tabs[i] ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: _select,
        backgroundColor: AyurezeTheme.surface,
        selectedItemColor: AyurezeTheme.iconPrimary,
        unselectedItemColor: AyurezeTheme.textSecondary,
        items: [
          for (final destination in _destinations)
            BottomNavigationBarItem(
              icon: HugeIcon(icon: destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
