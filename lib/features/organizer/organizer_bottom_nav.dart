import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrganizerBottomNav extends StatelessWidget {
  final int currentIndex;

  const OrganizerBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            context.go('/organizer');
            break;
          case 1:
            context.go('/organizer/exhibitions');
            break;
          case 2:
            context.go('/organizer/applications');
            break;
        }
      },
      selectedItemColor: const Color(0xFF185FA5),
      unselectedItemColor: const Color(0xFF6C757D),
      backgroundColor: Colors.white,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          activeIcon: Icon(Icons.event),
          label: 'Exhibitions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Applications',
        ),
      ],
    );
  }
}