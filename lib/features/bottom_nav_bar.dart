import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../core/router/app_router.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      // padding: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: NavigationBar(
        labelPadding: EdgeInsets.symmetric(vertical: 5),
        elevation: 10,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          final routes = [
            AppRoutes.habits,
            AppRoutes.today,
            AppRoutes.notes,
          ];
          if (index != currentIndex) {
            if (routes[index] == AppRoutes.today) {
              AppRouter.goHome(context);
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                routes[index],
                (route) => route.isFirst,
              );
            }
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Iconsax.task_square),
            selectedIcon: Icon(Iconsax.task_square5),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.home),
            selectedIcon: Icon(Iconsax.home_1),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.note_1),
            selectedIcon: Icon(Iconsax.note_15),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}
