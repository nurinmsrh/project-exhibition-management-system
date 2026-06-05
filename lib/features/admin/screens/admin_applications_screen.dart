import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/application_model.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadApplications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(
      BuildContext context,
      ApplicationModel application,
      String newStatus) async {
    String reason = '';

    if (newStatus == 'rejected' || newStatus == 'cancelled') {
      final reasonController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(newStatus == 'rejected'
              ? 'Reject Application'
              : 'Cancel Application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(newStatus == 'rejected'
                  ? 'Please provide a reason for rejection:'
                  : 'Please provide a reason for cancellation:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              child: const Text('Confirm',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      reason = reasonController.text.trim();
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve Application'),
          content: const Text(
              'Are you sure you want to approve this application?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green),
              child: const Text('Approve',
                  style: TextStyle(color: Colors.white)),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Applications'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  provider.searchApplications(value),
              decoration: InputDecoration(
                hintText: 'Search by company or status...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Status filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['all', 'pending', 'approved', 'rejected', 'cancelled']
                  .map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(status.toUpperCase()),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(
                            () => _selectedStatus = status);
                    provider.filterApplicationsByStatus(
                        status);
                  },
                  selectedColor: Colors.deepPurple,
                  labelStyle: TextStyle(
                    color: _selectedStatus == status
                        ? Colors.white
                        : Colors.black,
                    fontSize: 11,
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.applications.isEmpty
                ? const Center(child: Text('No applications found'))
                : RefreshIndicator(
              onRefresh: () => provider.loadApplications(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.applications.length,
                itemBuilder: (context, index) {
                  final application =
                  provider.applications[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  application.companyName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 10,
                                    vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                      application.status)
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _statusColor(
                                          application.status)),
                                ),
                                child: Text(
                                  application.status
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(
                                        application.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Exhibit: ${application.exhibitDescription}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booths: ${application.boothIds.length} • Submitted: ${_formatDate(application.createdAt)}',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12),
                          ),
                          if (application
                              .rejectionReason.isNotEmpty)
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Reason: ${application.rejectionReason}',
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Action buttons
                          if (application.status == 'pending')
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _updateStatus(
                                            context,
                                            application,
                                            'approved'),
                                    style: ElevatedButton
                                        .styleFrom(
                                      backgroundColor:
                                      Colors.green,
                                      foregroundColor:
                                      Colors.white,
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _updateStatus(
                                            context,
                                            application,
                                            'rejected'),
                                    style: OutlinedButton
                                        .styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(
                                          color: Colors.red),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                              ],
                            ),
                          if (application.status == 'approved')
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(
                                    context,
                                    application,
                                    'cancelled'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(
                                      color: Colors.red),
                                ),
                                child:
                                const Text('Cancel Booking'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}