import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exhibitor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/models/application_model.dart';
import '../exhibitor_bottom_nav.dart';
import 'application_detail_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser!.uid;
      context.read<ExhibitorProvider>().loadApplications(uid);
    });
  }

  List<ApplicationModel> _filtered(List<ApplicationModel> all) {
    if (_selectedStatus == 'all') return all;
    return all.where((a) => a.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExhibitorProvider>();
    final filtered = _filtered(provider.applications);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Applications',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Status filter ───────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'pending', 'approved', 'rejected', 'cancelled']
                    .map((status) {
                  final isSelected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedStatus = status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF185FA5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF185FA5)
                                : const Color(0xFFDEE2E6),
                          ),
                        ),
                        child: Text(
                          status == 'all'
                              ? 'All'
                              : status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6C757D),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── List ────────────────────────────────────────────────
          Expanded(
            child: provider.isLoadingApplications
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF185FA5),
              ),
            )
                : provider.applicationsError.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Color(0xFFDC3545)),
                  const SizedBox(height: 12),
                  Text(
                    provider.applicationsError,
                    style:
                    const TextStyle(color: Color(0xFF6C757D)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final uid = context
                          .read<AuthProvider>()
                          .currentUser!
                          .uid;
                      provider.loadApplications(uid);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined,
                      size: 56, color: Color(0xFF6C757D)),
                  const SizedBox(height: 12),
                  Text(
                    _selectedStatus == 'all'
                        ? 'No applications yet'
                        : 'No $_selectedStatus applications',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Browse exhibitions to book a booth',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6C757D)),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: const Color(0xFF185FA5),
              onRefresh: () {
                final uid = context
                    .read<AuthProvider>()
                    .currentUser!
                    .uid;
                return provider.loadApplications(uid);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _ApplicationCard(
                    application: filtered[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ExhibitorBottomNav(currentIndex: 1),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Application Card
// ─────────────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;

  const _ApplicationCard({required this.application});

  Color _statusBg(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFF3CD);
      case 'approved':
        return const Color(0xFFD4EDDA);
      case 'rejected':
        return const Color(0xFFFCEBEB);
      case 'cancelled':
        return const Color(0xFFE9ECEF);
      default:
        return const Color(0xFFE9ECEF);
    }
  }

  Color _statusText(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF856404);
      case 'approved':
        return const Color(0xFF155724);
      case 'rejected':
        return const Color(0xFF721C24);
      case 'cancelled':
        return const Color(0xFF495057);
      default:
        return const Color(0xFF495057);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final status = application.status;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<ExhibitorProvider>(),
              child: ApplicationDetailScreen(application: application),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDEE2E6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company name + status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      application.companyName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1C1E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusBg(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusText(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Booths count
              Row(
                children: [
                  const Icon(Icons.store_outlined,
                      size: 14, color: Color(0xFF6C757D)),
                  const SizedBox(width: 6),
                  Text(
                    '${application.boothIds.length} booth${application.boothIds.length > 1 ? 's' : ''} applied',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6C757D)),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Submitted date
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Color(0xFF6C757D)),
                  const SizedBox(width: 6),
                  Text(
                    'Submitted ${_formatDate(application.createdAt)}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6C757D)),
                  ),
                ],
              ),

              // Rejection reason pill
              if (status == 'rejected' &&
                  application.rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: Color(0xFF721C24)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          application.rejectionReason,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF721C24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Tap to view hint
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF185FA5),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right,
                      size: 14, color: Color(0xFF185FA5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}