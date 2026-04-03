import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/mini_player.dart';
import '../widgets/create_menu_bottom_sheet.dart';
import '../widgets/user_drawer.dart';
import '../providers/player_provider.dart';
import '../core/app_theme.dart';

class MainScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/library');
        break;
      case 3:
        showCreateMenu(context);
        // Restore index so BottomNav doesn't stay on "Create"
        setState(() {
          _currentIndex = _getSelectedIndex(context);
        });
        break;
    }
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/search') || location.startsWith('/podcast')) {
      return 1;
    }
    if (location.startsWith('/library') || 
        location.startsWith('/liked-songs') ||
        location.startsWith('/downloads') ||
        location.startsWith('/playlist') ||
        location.startsWith('/album')) {
      return 2;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Update index whenever navigation happens outside tap
    final newIndex = _getSelectedIndex(context);
    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
    }

    // Activate the player sync provider here
    ref.watch(playerSyncProvider);

    final location = GoRouterState.of(context).uri.toString();
    final isPlayerVisible = location.startsWith('/player');

    final currentSong = ref.watch(currentSongProvider);
    final bottomPadding = isPlayerVisible 
        ? 0.0 
        : (currentSong != null ? 110.0 : 70.0);

    // ─── Build ──────────────────────────────────────────────────────────────────
    
    return Scaffold(
      drawer: const UserDrawer(),
      body: Stack(
        children: [
          // The main content area
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: widget.child,
          ),
          
          // Floating MiniPlayer + Bottom Navigation area
          if (!isPlayerVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayer(),
                  BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: _onTap,
                    elevation: 0,
                    backgroundColor: AppTheme.background.withOpacity(0.95),
                    selectedFontSize: 11,
                    unselectedFontSize: 11,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(LucideIcons.home, size: 22),
                        activeIcon: Icon(Icons.home_filled, size: 24),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(LucideIcons.search, size: 22),
                        activeIcon: Icon(LucideIcons.search, size: 22),
                        label: 'Tìm kiếm',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(LucideIcons.library, size: 22),
                        activeIcon: Icon(LucideIcons.library, size: 22),
                        label: 'Thư viện',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(LucideIcons.plusSquare, size: 22),
                        label: 'Tạo',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
