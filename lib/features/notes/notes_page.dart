import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/router/app_router.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Iconsax.add),
          ),
        ],
      ),
      body: const Center(
        child: Text('Notes feature – quick capture + list'),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 3),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        final routes = [
          AppRoutes.today,
          AppRoutes.habits,
          AppRoutes.focus,
          AppRoutes.notes,
          AppRoutes.trips,
        ];
        if (index != currentIndex) {
          AppRouter.pushReplacement(context, routes[index]);
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Iconsax.home), selectedIcon: Icon(Iconsax.home_1), label: 'Today'),
        NavigationDestination(icon: Icon(Iconsax.task_square), selectedIcon: Icon(Iconsax.task_square5), label: 'Habits'),
        NavigationDestination(icon: Icon(Iconsax.chart_2), selectedIcon: Icon(Iconsax.chart_21), label: 'Focus'),
        NavigationDestination(icon: Icon(Iconsax.note_1), selectedIcon: Icon(Iconsax.note_15), label: 'Notes'),
        NavigationDestination(icon: Icon(Iconsax.map), selectedIcon: Icon(Iconsax.map5), label: 'Trips'),
      ],
    );
  }
}
