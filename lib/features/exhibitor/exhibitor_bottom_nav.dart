import 'package:flutter/material.dart';
import 'screens/exhibitor_home_screen.dart';
import 'screens/my_applications_screen.dart';
import 'providers/exhibitor_provider.dart';
import 'package:provider/provider.dart';

class ExhibitorBottomNav extends StatelessWidget {
  final int currentIndex;

  const ExhibitorBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDEE2E6))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Exhibitions',
                isActive: currentIndex == 0,
                onTap: () {
                  if (currentIndex == 0) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => ExhibitorProvider(),
                        child: const ExhibitorHomeScreen(),
                      ),
                    ),
                  );
                },
              ),
              _NavItem(
                icon: Icons.description_outlined,
                label: 'My Applications',
                isActive: currentIndex == 1,
                onTap: () {
                  if (currentIndex == 1) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => ExhibitorProvider(),
                        child: const MyApplicationsScreen(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive
                ? const Color(0xFF185FA5)
                : const Color(0xFF6C757D),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
              isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive
                  ? const Color(0xFF185FA5)
                  : const Color(0xFF6C757D),
            ),
          ),
        ],
      ),
    );
  }
}