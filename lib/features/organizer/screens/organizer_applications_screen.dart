import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/organizer_provider.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/exhibition_model.dart';
import '../organizer_bottom_nav.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class OrganizerApplicationsScreen extends StatefulWidget {
  final ExhibitionModel? exhibition;

  const OrganizerApplicationsScreen({super.key, required this.exhibition});

  @override
  State<OrganizerApplicationsScreen> createState() =>
      _OrganizerApplicationsScreenState();
}

class _OrganizerApplicationsScreenState
    extends State<OrganizerApplicationsScreen> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
      if (widget.exhibition != null) {
        context.read<OrganizerProvider>().loadApplications(widget.exhibition!.id);
      } else {
        context.read<OrganizerProvider>().loadAllApplications(uid);
      }
    });
  }

  List<ApplicationModel> get _filtered {
    final all = context.read<OrganizerProvider>().applications;
    if (_filterStatus == 'all') return all;
    return all.where((a) => a.status == _filterStatus).toList();
  }

  // --- Approve ---
  Future<void> _approve(ApplicationModel app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Application'),
        content: Text(
            'Approve application from "${app.companyName}"? Selected booths will be marked as booked.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve',
                style: TextStyle(color: Color(0xFF1D9E75))),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await context
          .read<OrganizerProvider>()
          .approveApplication(app.id, app.exhibitionId);
      if (!success && mounted) {
        _showError(context.read<OrganizerProvider>().errorMessage);
      }
    }
  }

  // --- Reject ---
  Future<void> _reject(ApplicationModel app) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting application from "${app.companyName}".'),
            const SizedBox(height: 12),
            const Text(
              'Reason (required)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                hintStyle: const TextStyle(color: Color(0xFF6C757D)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Reject',
                style: TextStyle(color: Color(0xFFDC3545))),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await context
          .read<OrganizerProvider>()
          .rejectApplication(
          app.id, app.exhibitionId, reasonController.text.trim());
      if (!success && mounted) {
        _showError(context.read<OrganizerProvider>().errorMessage);
      }
    }
    reasonController.dispose();
  }

  // --- Cancel ---
  Future<void> _cancel(ApplicationModel app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Application'),
        content:
        Text('Cancel application from "${app.companyName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Color(0xFFDC3545))),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await context
          .read<OrganizerProvider>()
          .cancelApplication(app.id, app.exhibitionId);
      if (!success && mounted) {
        _showError(context.read<OrganizerProvider>().errorMessage);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC3545),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final organizer = context.watch<OrganizerProvider>();
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          widget.exhibition != null
              ? '${widget.exhibition!.title} — Applications'
              : 'Applications',
          style: const TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF185FA5)),
          onPressed: () => context.go('/organizer/exhibitions'),
        ),
      ),
      body: Column(
        children: [
          // --- Filter Chips ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'pending', 'approved', 'rejected',
                  'cancelled']
                    .map((status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: _filterStatus == status
                            ? Colors.white
                            : const Color(0xFF6C757D),
                      ),
                    ),
                    selected: _filterStatus == status,
                    selectedColor: const Color(0xFF185FA5),
                    backgroundColor: const Color(0xFFF8F9FA),
                    onSelected: (_) =>
                        setState(() => _filterStatus = status),
                  ),
                ))
                    .toList(),
              ),
            ),
          ),

          // --- List ---
          Expanded(
            child: organizer.isLoading
                ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF185FA5)),
            )
                : filtered.isEmpty
                ? Center(
              child: Text(
                _filterStatus != 'all'
                    ? 'No $_filterStatus applications.'
                    : 'No applications yet.',
                style:
                const TextStyle(color: Color(0xFF6C757D)),
              ),
            )
                : RefreshIndicator(
              color: const Color(0xFF185FA5),
              onRefresh: () {
                final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
                if (widget.exhibition != null) {
                  return organizer.loadApplications(widget.exhibition!.id);
                }
                return organizer.loadAllApplications(uid);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (_, i) => _ApplicationCard(
                  application: filtered[i],
                  onApprove: filtered[i].status == 'pending'
                      ? () => _approve(filtered[i])
                      : null,
                  onReject: filtered[i].status == 'pending'
                      ? () => _reject(filtered[i])
                      : null,
                  onCancel: filtered[i].status == 'pending' ||
                      filtered[i].status == 'approved'
                      ? () => _cancel(filtered[i])
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const OrganizerBottomNav(currentIndex: 2),
    );
  }
}

// ---------------------------------------------------------------------------
// Application Card
// ---------------------------------------------------------------------------
class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const _ApplicationCard({
    required this.application,
    this.onApprove,
    this.onReject,
    this.onCancel,
  });

  Map<String, Color> _statusStyle(String status) {
    switch (status) {
      case 'approved':
        return {
          'bg': const Color(0xFFD4EDDA),
          'text': const Color(0xFF155724)
        };
      case 'rejected':
        return {
          'bg': const Color(0xFFFCEBEB),
          'text': const Color(0xFF721C24)
        };
      case 'cancelled':
        return {
          'bg': const Color(0xFFE9ECEF),
          'text': const Color(0xFF495057)
        };
      default: // pending
        return {
          'bg': const Color(0xFFFFF3CD),
          'text': const Color(0xFF856404)
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = application.status;
    final style = _statusStyle(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company name + status
          Row(
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: style['bg'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: style['text'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Company description
          if (application.companyDescription.isNotEmpty)
            Text(
              application.companyDescription,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6C757D)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 6),

          // Booths
          Row(
            children: [
              const Icon(Icons.store_outlined,
                  size: 14, color: Color(0xFF6C757D)),
              const SizedBox(width: 4),
              Text(
                'Booths: ${application.boothIds.join(', ')}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6C757D)),
              ),
            ],
          ),

          // Submitted date
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: Color(0xFF6C757D)),
              const SizedBox(width: 4),
              Text(
                'Submitted: ${_fmt(application.createdAt)}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6C757D)),
              ),
            ],
          ),

          // Rejection reason
          if (status == 'rejected' &&
              application.rejectionReason != null &&
              application.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Reason: ${application.rejectionReason}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF721C24)),
              ),
            ),
          ],

          // Action buttons — only show for pending/approved
          if (onApprove != null || onReject != null || onCancel != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFDEE2E6)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (onApprove != null)
                  _ActionButton(
                    label: 'Approve',
                    color: const Color(0xFF1D9E75),
                    onPressed: onApprove!,
                  ),
                if (onApprove != null && onReject != null)
                  const SizedBox(width: 8),
                if (onReject != null)
                  _ActionButton(
                    label: 'Reject',
                    color: const Color(0xFFDC3545),
                    onPressed: onReject!,
                  ),
                const Spacer(),
                if (onCancel != null)
                  _ActionButton(
                    label: 'Cancel',
                    color: const Color(0xFF6C757D),
                    onPressed: onCancel!,
                    outlined: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// --- Action Button ---
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}