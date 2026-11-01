import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/app/theme/katara_colors.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  final Widget child;
  final String currentLocation;

  int _indexForLocation(String loc) {
    if (loc.startsWith('/home/practice')) return 1;
    if (loc.startsWith('/home/culture')) return 2;
    if (loc.startsWith('/home/quests')) return 3;
    if (loc.startsWith('/home/profile')) return 4;
    return 0;
  }

  void _onTapIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home/learn');
      case 1:
        context.go('/home/practice');
      case 2:
        context.go('/home/culture');
      case 3:
        context.go('/home/quests');
      case 4:
        context.go('/home/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kataraPalette;
    final currentIndex = _indexForLocation(currentLocation);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(top: BorderSide(color: palette.outline)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          backgroundColor: palette.surface,
          indicatorColor: palette.primary.withValues(alpha: 0.16),
          onDestinationSelected: (idx) => _onTapIndex(context, idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Belajar',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded),
              label: 'Latihan',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance_rounded),
              label: 'Budaya',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events_rounded),
              label: 'Misi',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
