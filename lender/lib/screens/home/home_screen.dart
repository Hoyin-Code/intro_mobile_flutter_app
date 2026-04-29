import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab again pops back to its root
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined),
            label: 'Loans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: navigationShell.currentIndex == 0 &&
              GoRouterState.of(context).matchedLocation == '/items'
          ? FloatingActionButton(
              onPressed: () => context.push('/items/add'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
