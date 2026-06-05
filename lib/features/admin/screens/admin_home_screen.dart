import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalExhibitions = 0;
  int _totalApplications = 0;
  int _pendingApplications = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    final provider = context.read<AdminProvider>();
    await Future.wait([
      provider.loadUsers(),
      provider.loadExhibitions(),
      provider.loadApplications(),
    ]);
    if (mounted) {
      setState(() {
        _totalUsers = provider.users.length;
        _activeUsers =
            provider.users.where((u) => u.isActive).length;
        _totalExhibitions = provider.exhibitions.length;
        _totalApplications = provider.applications.length;
        _pendingApplications = provider.applications
            .where((a) => a.status == 'pending')
            .length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined,
                color: Color(0xFF6C757D)),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) context.go('/');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(authProvider),
            const SizedBox(height: 20),
            _buildKpiGrid(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── WELCOME BANNER ───────────────────────────────────────
  Widget _buildWelcomeBanner(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF185FA5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _initials(
                  authProvider.currentUser?.name ?? 'Admin'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${authProvider.currentUser?.name ?? 'Admin'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Here\'s an overview of the system.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI GRID ─────────────────────────────────────────────
  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _KpiCard(
          icon: Icons.person_outline,
          label: 'Total Users',
          value: '$_totalUsers',
          sub: '$_activeUsers active',
          iconColor: const Color(0xFF185FA5),
          bgColor: const Color(0xFFE6F1FB),
        ),
        _KpiCard(
          icon: Icons.event_outlined,
          label: 'Exhibitions',
          value: '$_totalExhibitions',
          sub: 'All exhibitions',
          iconColor: const Color(0xFF1D9E75),
          bgColor: const Color(0xFFE1F5EE),
        ),
        _KpiCard(
          icon: Icons.assignment_outlined,
          label: 'Applications',
          value: '$_totalApplications',
          sub: 'Total submitted',
          iconColor: const Color(0xFFEF9F27),
          bgColor: const Color(0xFFFAEEDA),
        ),
        _KpiCard(
          icon: Icons.pending_actions_outlined,
          label: 'Pending',
          value: '$_pendingApplications',
          sub: 'Awaiting review',
          iconColor: const Color(0xFFDC3545),
          bgColor: const Color(0xFFFCEBEB),
        ),
      ],
    );
  }

  // ── BOTTOM NAV ───────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
        Border(top: BorderSide(color: Color(0xFFDEE2E6))),
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
                isActive: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Events',
                onTap: () =>
                    context.go('/admin/exhibitions'),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _NavItem(
                    icon: Icons.description_outlined,
                    label: 'Applications',
                    onTap: () =>
                        context.go('/admin/applications'),
                  ),
                  if (_pendingApplications > 0)
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
                          '$_pendingApplications',
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              _NavItem(
                icon: Icons.people_outline,
                label: 'Users',
                onTap: () => context.go('/admin/users'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'A';
  }
}

// ── REUSABLE WIDGETS ─────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color iconColor;
  final Color bgColor;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6C757D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6C757D),
            ),
          ),
        ],
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
              fontWeight: isActive
                  ? FontWeight.w700
                  : FontWeight.w400,
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