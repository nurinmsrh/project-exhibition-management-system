import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/application_model.dart';
import '../admin_bottom_nav.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState
    extends State<AdminApplicationsScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AdminProvider>();
      await provider.loadApplications();
      if (mounted) {
        setState(() {
          _pendingCount = provider.applications
              .where((a) => a.status == 'pending')
              .length;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFFD4EDDA);
      case 'pending':
        return const Color(0xFFFFF3CD);
      case 'rejected':
        return const Color(0xFFFCEBEB);
      case 'cancelled':
        return const Color(0xFFE9ECEF);
      default:
        return const Color(0xFFE9ECEF);
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF155724);
      case 'pending':
        return const Color(0xFF856404);
      case 'rejected':
        return const Color(0xFF721C24);
      case 'cancelled':
        return const Color(0xFF495057);
      default:
        return const Color(0xFF495057);
    }
  }

  Future<void> _updateStatus(BuildContext context,
      ApplicationModel application,
      String newStatus,) async {
    String reason = '';

    if (newStatus == 'rejected' || newStatus == 'cancelled') {
      final reasonController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) =>
            AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(
                newStatus == 'rejected'
                    ? 'Reject Application'
                    : 'Cancel Booking',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newStatus == 'rejected'
                        ? 'Please provide a reason for rejection:'
                        : 'Please provide a reason for cancellation:',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6C757D)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter reason...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Color(0xFF8E8E93)),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFFDEE2E6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFFDEE2E6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF185FA5), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFF6C757D))),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC3545),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(newStatus == 'rejected'
                      ? 'Reject'
                      : 'Cancel Booking'),
                ),
              ],
            ),
      );
      if (confirmed != true) return;
      reason = reasonController.text.trim();
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) =>
            AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: const Text(
                'Approve Application',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              content: const Text(
                'Are you sure you want to approve this application?',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6C757D)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFF6C757D))),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
      );
      if (confirmed != true) return;
    }

    if (context.mounted) {
      await context.read<AdminProvider>().updateApplicationStatus(
        application.id,
        newStatus,
        reason: reason,
      );
      if (mounted) {
        setState(() {
          _pendingCount = context
              .read<AdminProvider>()
              .applications
              .where((a) => a.status == 'pending')
              .length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: Color(0xFF185FA5)),
          onPressed: () => context.go('/admin'),
        ),
        title: const Text(
          'Manage Applications',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFDEE2E6)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        provider.searchApplications(val),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText:
                      'Search by company or exhibition...',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93)),
                      prefixIcon: Icon(Icons.search,
                          size: 18,
                          color: Color(0xFF6C757D)),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Status filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'all',
                      'pending',
                      'approved',
                      'rejected',
                      'cancelled',
                    ].map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(
                                    () => _selectedStatus = status);
                            provider
                                .filterApplicationsByStatus(status);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF185FA5)
                                  : Colors.white,
                              borderRadius:
                              BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF185FA5)
                                    : const Color(0xFFDEE2E6),
                              ),
                            ),
                            child: Text(
                              status[0].toUpperCase() +
                                  status.substring(1),
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
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.applications.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 48,
                      color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    'No applications found.',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6C757D)),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () =>
                  provider.loadApplications(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 80),
                itemCount: provider.applications.length,
                itemBuilder: (context, index) {
                  final application =
                  provider.applications[index];
                  return _buildApplicationCard(
                      application);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNav(
        currentRoute: '/admin/applications',
        pendingCount: _pendingCount,
      ),
    );
  }

  Widget _buildApplicationCard(ApplicationModel application) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: company + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    application.companyName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusBgColor(application.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    application.status[0].toUpperCase() +
                        application.status.substring(1),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusTextColor(application.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Exhibit description
            Text(
              application.exhibitDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
            const SizedBox(height: 6),

            // Meta info
            Row(
              children: [
                const Icon(Icons.store_outlined,
                    size: 12, color: Color(0xFF6C757D)),
                const SizedBox(width: 4),
                Text(
                  '${application.boothIds.length} booth(s)',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6C757D)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: Color(0xFF6C757D)),
                const SizedBox(width: 4),
                Text(
                  _formatDate(application.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6C757D)),
                ),
              ],
            ),

            // Rejection reason
            if (application.rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFDC3545)
                          .withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Color(0xFFDC3545)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${application.rejectionReason}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF721C24)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (application.status == 'pending') ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFDEE2E6)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _updateStatus(
                              context, application, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                      ),
                      child: const Text('Approve',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _updateStatus(
                              context, application, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC3545),
                        side: const BorderSide(
                            color: Color(0xFFDC3545)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                      ),
                      child: const Text('Reject',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],

            if (application.status == 'approved') ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFDEE2E6)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      _updateStatus(
                          context, application, 'cancelled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC3545),
                    side:
                    const BorderSide(color: Color(0xFFDC3545)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                    const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Cancel Booking',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}