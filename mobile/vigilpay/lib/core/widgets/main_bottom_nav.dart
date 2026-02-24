import 'package:flutter/material.dart';

import '../constants/route_constants.dart';
import '../theme/app_theme.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    required this.currentRoute,
    super.key,
  });

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final currentIndex = switch (currentRoute) {
      RouteConstants.products => 1,
      RouteConstants.supportFeedback => 2,
      RouteConstants.profile => 3,
      _ => 0,
    };

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        final targetRoute = switch (index) {
          1 => RouteConstants.products,
          2 => RouteConstants.supportFeedback,
          3 => RouteConstants.profile,
          _ => RouteConstants.home,
        };

        if (targetRoute == currentRoute) {
          return;
        }

        Navigator.pushReplacementNamed(context, targetRoute);
      },
      backgroundColor: VigilColors.white,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Products',
        ),
        NavigationDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent_rounded),
          label: 'Support',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
