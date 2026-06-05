import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/services/exhibition_service.dart';
import '../admin_bottom_nav.dart';
class AdminExhibitionsScreen extends StatefulWidget {
  const AdminExhibitionsScreen({super.key});

  @override
  State<AdminExhibitionsScreen> createState() =>
      _AdminExhibitionsScreenState();
}

class _AdminExhibitionsScreenState extends State<AdminExhibitionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final Map<String, String> _boothCountCache = {};
  int _pendingCount = 0;

  final List<String> _filters = [
    'All',
    'Upcoming',
    'Ongoing',
    'Completed',
    'Unpublished',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AdminProvider>();
      await provider.loadExhibitions();
      await provider.loadApplications();
      if (mounted) {
        setState(() {
          _pendingCount = provider.applications
              .where((a) => a.status == 'pending')
              .length;
        });
      }
      await _loadAllBoothCounts(provider.exhibitions);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBoothCounts(
      List<ExhibitionModel> exhibitions) async {
    final service = ExhibitionService();
    for (final e in exhibitions) {
      final reserved = await service.getReservedBoothCount(e.id);
      final total = await service.getTotalBoothCount(e.id);
      if (mounted) {
        setState(() {
          _boothCountCache[e.id] =
          '$reserved / $total Booths Reserved';
        });
      }
    }
  }

  List<ExhibitionModel> _applyFilters(List<ExhibitionModel> all) {
    final q = _searchController.text.toLowerCase();

    return all.where((e) {
      // Search: title, venue, month name, day number
      final matchSearch = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.venue.toLowerCase().contains(q) ||
          _formatDateRange(e.startDate, e.endDate)
              .toLowerCase()
              .contains(q);

      // Status filter
      final status = e.computedStatus;
      final matchFilter = _selectedFilter == 'All' ||
          _selectedFilter.toLowerCase() == status;

      return matchSearch && matchFilter;
    }).toList();
  }

  Future<void> _deleteExhibition(ExhibitionModel exhibition) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Exhibition',
            style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600)),
        content: Text(
            'Are you sure you want to delete "${exhibition.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6C757D))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC3545)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context
          .read<AdminProvider>()
          .deleteExhibition(exhibition.id);
      await _loadAllBoothCounts(
          context.read<AdminProvider>().exhibitions);
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      '',
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return '${months[start.month]} ${start.day}–${end.day}, ${start.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final filtered = _applyFilters(provider.exhibitions);

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
          'Exhibition Management',
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
              await context.read<AdminProvider>().loadUsers();
              if (context.mounted) context.go('/');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 16),
            _buildSearchAndFilter(provider),
            const SizedBox(height: 16),
            _buildSectionHeader(),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              _buildEmptyState()
            else
              ...filtered
                  .map((e) => _buildExhibitionCard(e, provider)),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentRoute: '/admin/exhibitions',
        pendingCount: _pendingCount,
      ),
    );
  }

  // ── INFO BANNER ──────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 18, color: Color(0xFF6C757D)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Manage all exhibition events. Use filters to view by status, or search by title, venue, or date.',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH + FILTER ROW ──────────────────────────────────
  Widget _buildSearchAndFilter(AdminProvider provider) {
    return Row(
      children: [
        // Search
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border:
              Border.all(color: const Color(0xFFDEE2E6)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Search by title, venue, date...',
                hintStyle: TextStyle(
                    fontSize: 12, color: Color(0xFF8E8E93)),
                prefixIcon: Icon(Icons.search,
                    size: 16, color: Color(0xFF8E8E93)),
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Filter dropdown
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border:
            Border.all(color: const Color(0xFFDEE2E6)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: Color(0xFF6C757D)),
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF1A1C1E)),
              items: _filters
                  .map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f,
                      style: const TextStyle(
                          fontSize: 12))))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedFilter = val!),
            ),
          ),
        ),
      ],
    );
  }

  // ── SECTION HEADER ───────────────────────────────────────
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Manage Exhibitions',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1C1E),
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/admin/exhibitions/create'),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF185FA5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Create',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: const Center(
        child: Text(
          'No exhibitions found.',
          style: TextStyle(
              fontSize: 13, color: Color(0xFF6C757D)),
        ),
      ),
    );
  }

  // ── EXHIBITION CARD ──────────────────────────────────────
  Widget _buildExhibitionCard(
      ExhibitionModel exhibition, AdminProvider provider) {
    final status = exhibition.computedStatus;

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
            // Row 1: title + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exhibition.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (exhibition.isPublished)
                  _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 5),
            // Row 2: date
            Text(
              _formatDateRange(
                  exhibition.startDate, exhibition.endDate),
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
            const SizedBox(height: 3),
            // Row 3: venue
            Text(
              exhibition.venue,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
            const SizedBox(height: 10),

            // Row 4: publish toggle + booth count
            Row(
              children: [
                // Publish toggle
                GestureDetector(
                  onTap: () => provider.togglePublish(
                      exhibition.id, !exhibition.isPublished),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration:
                        const Duration(milliseconds: 200),
                        width: 32,
                        height: 18,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(9),
                          color: exhibition.isPublished
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFFB4B2A9),
                        ),
                        child: Align(
                          alignment: exhibition.isPublished
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        exhibition.isPublished
                            ? 'Published'
                            : 'Unpublished',
                        style: TextStyle(
                          fontSize: 11,
                          color: exhibition.isPublished
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFF6C757D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _boothCountCache[exhibition.id] ??
                      '— / — Booths',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6C757D)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 5: actions
            Row(
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () => context.go(
                      '/admin/exhibitions/${exhibition.id}/edit'),
                ),
                const _Divider(),
                _ActionButton(
                  label: 'View',
                  onTap: () => context.go(
                      '/admin/exhibitions/${exhibition.id}/booths'),
                ),
                const _Divider(),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: const Color(0xFFDC3545),
                  onTap: () => _deleteExhibition(exhibition),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status) {
      case 'ongoing':
        bg = const Color(0xFFD4EDDA);
        text = const Color(0xFF155724);
        break;
      case 'completed':
        bg = const Color(0xFFE9ECEF);
        text = const Color(0xFF495057);
        break;
      default:
        bg = const Color(0xFFCCE5FF);
        text = const Color(0xFF004085);
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}

// ── REUSABLE WIDGETS ─────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    this.icon,
    required this.label,
    this.color = const Color(0xFF1A1C1E),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
            ],
            Text(label,
                style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 12, color: const Color(0xFFDEE2E6));
  }
}