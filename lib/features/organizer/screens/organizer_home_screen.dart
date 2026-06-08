import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/organizer_provider.dart';
import '../organizer_bottom_nav.dart';
import 'package:go_router/go_router.dart';

class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        context
            .read<OrganizerProvider>()
            .loadExhibitions(authProvider.currentUser!.uid);
      }
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final organizer = context.watch<OrganizerProvider>();
    final user = authProvider.currentUser;

    final exhibitions = organizer.exhibitions;
    final upcoming = exhibitions
        .where((e) => e.computedStatus == 'upcoming')
        .length;
    final ongoing = exhibitions
        .where((e) => e.computedStatus == 'ongoing')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF185FA5)),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: organizer.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF185FA5)),
      )
          : RefreshIndicator(
        color: const Color(0xFF185FA5),
        onRefresh: () {
          if (user != null) {
            return organizer.loadExhibitions(user.uid);
          }
          return Future.value();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Welcome Banner ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF185FA5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'Organizer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.company ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Section Title ---
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 12),

            // --- KPI Cards Grid ---
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _KpiCard(
                  label: 'Total Exhibitions',
                  value: exhibitions.length.toString(),
                  icon: Icons.event,
                  color: const Color(0xFF185FA5),
                ),
                _KpiCard(
                  label: 'Upcoming',
                  value: upcoming.toString(),
                  icon: Icons.schedule,
                  color: const Color(0xFF1D9E75),
                ),
                _KpiCard(
                  label: 'Ongoing',
                  value: ongoing.toString(),
                  icon: Icons.play_circle_outline,
                  color: const Color(0xFFEF9F27),
                ),
                _KpiCard(
                  label: 'Completed',
                  value: exhibitions
                      .where((e) => e.computedStatus == 'completed')
                      .length
                      .toString(),
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF6C757D),
                ),
              ],
            ),

            if (organizer.errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                organizer.errorMessage,
                style: const TextStyle(color: Color(0xFFDC3545)),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const OrganizerBottomNav(currentIndex: 0),
    );
  }
}

// --- KPI Card Widget ---
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}