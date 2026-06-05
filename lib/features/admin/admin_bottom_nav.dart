import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminBottomNav extends StatelessWidget {
  final String currentRoute;
  final int pendingCount;

  const AdminBottomNav({
    super.key,
    required this.currentRoute,
    this.pendingCount = 0,
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
                label: 'Dashboard',
                isActive: currentRoute == '/admin',
                onTap: () => context.go('/admin'),
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Events',
                isActive: currentRoute == '/admin/exhibitions',
                onTap: () => context.go('/admin/exhibitions'),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _NavItem(
                    icon: Icons.description_outlined,
                    label: 'Applications',
                    isActive: currentRoute == '/admin/applications',
                    onTap: () => context.go('/admin/applications'),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      top: -2,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC3545),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                              fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              _NavItem(
                icon: Icons.people_outline,
                label: 'Users',
                isActive: currentRoute == '/admin/users',
                onTap: () => context.go('/admin/users'),
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
          Icon(icon,
              size: 22,
              color: isActive
                  ? const Color(0xFF185FA5)
                  : const Color(0xFF6C757D)),
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