import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/models/exhibition_model.dart';

class AdminBoothsScreen extends StatefulWidget {
  final String exhibitionId;

  const AdminBoothsScreen({super.key, required this.exhibitionId});

  @override
  State<AdminBoothsScreen> createState() => _AdminBoothsScreenState();
}

class _AdminBoothsScreenState extends State<AdminBoothsScreen> {
  final _boothSearchController = TextEditingController();
  String _selectedTab = 'All';
  int _currentPage = 1;
  final int _pageSize = 6;
  ExhibitionModel? _exhibition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AdminProvider>();
      await provider.loadBooths(widget.exhibitionId);
      await provider.loadExhibitions();
      if (mounted) {
        setState(() {
          try {
            _exhibition = provider.exhibitions.firstWhere(
                  (e) => e.id == widget.exhibitionId,
            );
          } catch (_) {}
        });
      }
    });
  }

  @override
  void dispose() {
    _boothSearchController.dispose();
    super.dispose();
  }

  List<BoothModel> _filteredBooths(List<BoothModel> booths) {
    final q = _boothSearchController.text.toLowerCase();
    return booths.where((b) {
      final matchSearch = q.isEmpty ||
          b.boothNumber.toLowerCase().contains(q) ||
          b.type.toLowerCase().contains(q);
      final matchTab = _selectedTab == 'All' ||
          (_selectedTab == 'Available' && b.status == 'available') ||
          (_selectedTab == 'Booked' && b.status == 'booked');
      return matchSearch && matchTab;
    }).toList();
  }

  List<BoothModel> _paginated(List<BoothModel> booths) {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, booths.length);
    if (start >= booths.length) return [];
    return booths.sublist(start, end);
  }

  int _totalPages(int count) =>
      (count / _pageSize).ceil().clamp(1, 999);

  Future<void> _deleteBooth(BoothModel booth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Booth'),
        content: Text(
            'Are you sure you want to delete booth ${booth.boothNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context
          .read<AdminProvider>()
          .deleteBooth(booth.id, widget.exhibitionId);
    }
  }

  Color _boothTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'premium':
        return const Color(0xFF7F77DD);
      case 'vip':
        return const Color(0xFFEF9F27);
      default:
        return const Color(0xFF888780);
    }
  }

  Color _boothStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF1D9E75);
      case 'booked':
        return const Color(0xFFDC3545);
      case 'reserved':
        return const Color(0xFF185FA5);
      default:
        return const Color(0xFF888780);
    }
  }

  Color _boothFillColor(String type) {
    switch (type.toLowerCase()) {
      case 'premium':
        return const Color(0xFFEEEDFE);
      case 'vip':
        return const Color(0xFFFAEEDA);
      default:
        return const Color(0xFFE6F1FB);
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[start.month]} ${start.day}–${end.day}, ${start.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final allBooths = provider.booths;
    final filtered = _filteredBooths(allBooths);
    final paginated = _paginated(filtered);
    final totalPages = _totalPages(filtered.length);
    final reservedCount = allBooths
        .where((b) => b.status == 'booked' || b.status == 'reserved')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: Color(0xFF185FA5)),
          onPressed: () => context.go('/admin/exhibitions'),
        ),
        title: const Text(
          'Floor Plan Management',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            _buildInfoBanner(),
            const SizedBox(height: 16),

            // Tab + search
            _buildTabAndSearch(),
            const SizedBox(height: 16),

            // Exhibition card + floor plan
            _buildExhibitionCard(
                allBooths, reservedCount),
            const SizedBox(height: 24),

            // Booth table section
            _buildBoothTableSection(
                filtered, paginated, totalPages),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── INFO BANNER ──────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              'Upload and manage floor plan images for your exhibitions, map out booths digitally by defining booth IDs, types, coordinates, and attributes.',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB + SEARCH ─────────────────────────────────────────
  Widget _buildTabAndSearch() {
    return Row(
      children: [
        Row(
          children: ['All', 'Available', 'Booked'].map((tab) {
            final isActive = _selectedTab == tab;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedTab = tab;
                _currentPage = 1;
              }),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Text(
                      tab,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isActive
                            ? const Color(0xFF1A1C1E)
                            : const Color(0xFF6C757D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isActive)
                      Container(
                        height: 2,
                        width: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF185FA5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => context.go(
              '/admin/exhibitions/${widget.exhibitionId}/booths/create'),
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
                  'Create Booth',
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

  // ── EXHIBITION CARD + FLOOR PLAN ─────────────────────────
  Widget _buildExhibitionCard(
      List<BoothModel> booths, int reservedCount) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section label
                const Text(
                  'Manage Exhibitions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 12),

                // Title + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _exhibition?.title ?? 'Exhibition',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(
                        _exhibition?.status ?? 'upcoming'),
                  ],
                ),
                const SizedBox(height: 5),

                // Date
                if (_exhibition != null)
                  Text(
                    _formatDateRange(
                        _exhibition!.startDate,
                        _exhibition!.endDate),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6C757D)),
                  ),
                const SizedBox(height: 3),

                // Venue
                if (_exhibition != null)
                  Text(
                    _exhibition!.venue,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6C757D)),
                  ),
                const SizedBox(height: 10),

                // Footer: booth count + actions
                Row(
                  children: [
                    Text(
                      '$reservedCount / ${booths.length} Booths Reserved',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6C757D)),
                    ),
                    const Spacer(),
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      onTap: () => context.go(
                          '/admin/exhibitions/${widget.exhibitionId}/edit'),
                    ),
                    _PipeDivider(),
                    _ActionBtn(
                      label: 'View',
                      onTap: () {},
                    ),
                    _PipeDivider(),
                    _ActionBtn(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: const Color(0xFFDC3545),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Exhibition'),
                            content: Text(
                                'Delete "${_exhibition?.title}"? This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await context
                              .read<AdminProvider>()
                              .deleteExhibition(
                              widget.exhibitionId);
                          if (mounted) {
                            context.go('/admin/exhibitions');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floor plan visualizer
          _buildFloorPlan(booths),

          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Text(
                  'Total: ${booths.length} Booths',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const Spacer(),
                const _LegendDot(
                    color: Color(0xFF185FA5), label: 'Standard'),
                const SizedBox(width: 8),
                const _LegendDot(
                    color: Color(0xFF7F77DD), label: 'Premium'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FLOOR PLAN VISUALIZER ────────────────────────────────
  Widget _buildFloorPlan(List<BoothModel> booths) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: booths.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No booths added yet.\nTap + to add booths.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Color(0xFF6C757D)),
          ),
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EXIT top-right
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_ExitTag()],
            ),
          ),
          // Booth grid
          Padding(
            padding: const EdgeInsets.all(8),
            child: _buildBoothGrid(booths),
          ),
          // Main stage
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFDEE2E6)),
              ),
              child: const Center(
                child: Text(
                  'Main Stage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ),
            ),
          ),
          // EXIT bottom row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [_ExitTag(), _ExitTag()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoothGrid(List<BoothModel> booths) {
    // Group booths into rows of 4
    const cols = 4;
    final rows = <List<BoothModel>>[];
    for (var i = 0; i < booths.length; i += cols) {
      rows.add(booths.sublist(
          i, (i + cols).clamp(0, booths.length)));
    }

    return Column(
      children: rows.map((rowBooths) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: rowBooths.map((booth) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () => context.go(
                        '/admin/exhibitions/${widget.exhibitionId}/booths/${booth.id}/edit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                      decoration: BoxDecoration(
                        color: _boothFillColor(booth.type),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                          _boothTypeColor(booth.type)
                              .withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            booth.boothNumber,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _boothTypeColor(booth.type),
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: BoxDecoration(
                              color: _boothStatusColor(
                                  booth.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;
    switch (status.toLowerCase()) {
      case 'ongoing':
        bg = const Color(0xFFD4EDDA);
        text = const Color(0xFF155724);
        label = 'Ongoing';
        break;
      case 'completed':
        bg = const Color(0xFFE9ECEF);
        text = const Color(0xFF495057);
        label = 'Completed';
        break;
      default:
        bg = const Color(0xFFCCE5FF);
        text = const Color(0xFF004085);
        label = 'Upcoming';
    }
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: text),
      ),
    );
  }

  // ── BOOTH TABLE SECTION ──────────────────────────────────
  Widget _buildBoothTableSection(List<BoothModel> filtered,
      List<BoothModel> paginated, int totalPages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDEE2E6)),
          ),
          child: TextField(
            controller: _boothSearchController,
            onChanged: (_) =>
                setState(() => _currentPage = 1),
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Search booths...',
              hintStyle: TextStyle(
                  fontSize: 12, color: Color(0xFF8E8E93)),
              prefixIcon: Icon(Icons.search,
                  size: 16, color: Color(0xFF8E8E93)),
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDEE2E6)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: const [
                    SizedBox(
                        width: 48,
                        child: Text('Booth ID',
                            style: _headerStyle)),
                    SizedBox(width: 8),
                    SizedBox(
                        width: 56,
                        child:
                        Text('Type', style: _headerStyle)),
                    SizedBox(width: 8),
                    SizedBox(
                        width: 48,
                        child:
                        Text('Size', style: _headerStyle)),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('XY Coords',
                            style: _headerStyle)),
                    SizedBox(width: 40),
                  ],
                ),
              ),
              const Divider(
                  height: 1, color: Color(0xFFDEE2E6)),

              if (paginated.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No booths found.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C757D))),
                  ),
                )
              else
                ...paginated.map((booth) =>
                    _buildBoothRow(booth)),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Pagination
        _buildPagination(filtered.length, totalPages),
      ],
    );
  }

  Widget _buildBoothRow(BoothModel booth) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  booth.boothNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _boothTypeColor(booth.type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(booth.type,
                          style:
                          const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(booth.size,
                    style: const TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '(${booth.positionX.toInt()}, ${booth.positionY.toInt()})',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6C757D)),
                ),
              ),
              SizedBox(
                width: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => context.go(
                          '/admin/exhibitions/${widget.exhibitionId}/booths/${booth.id}/edit'),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF185FA5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _deleteBooth(booth),
                      child: const Icon(Icons.delete_outline,
                          size: 14, color: Color(0xFFDC3545)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFDEE2E6)),
      ],
    );
  }

  // ── PAGINATION ───────────────────────────────────────────
  Widget _buildPagination(int totalCount, int totalPages) {
    return Row(
      children: [
        _PageBtn(
            label: '<<',
            onTap: _currentPage > 1
                ? () => setState(() => _currentPage = 1)
                : null),
        _PageBtn(
            label: '<',
            onTap: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null),
        ...List.generate(totalPages.clamp(0, 3), (i) {
          final page = i + 1;
          return _PageBtn(
            label: '$page',
            isActive: _currentPage == page,
            onTap: () => setState(() => _currentPage = page),
          );
        }),
        _PageBtn(
            label: '>',
            onTap: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null),
        _PageBtn(
            label: '>>',
            onTap: _currentPage < totalPages
                ? () => setState(
                    () => _currentPage = totalPages)
                : null),
        const Spacer(),
        Text(
          '${((_currentPage - 1) * _pageSize) + 1}–'
              '${(_currentPage * _pageSize).clamp(0, totalCount)} of $totalCount',
          style: const TextStyle(
              fontSize: 11, color: Color(0xFF6C757D)),
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
                onTap: () => context.go('/admin'),
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Events',
                isActive: true,
                onTap: () =>
                    context.go('/admin/exhibitions'),
              ),
              _NavItem(
                icon: Icons.description_outlined,
                label: 'Applications',
                onTap: () =>
                    context.go('/admin/applications'),
              ),
              _NavItem(
                icon: Icons.grid_view_outlined,
                label: 'Users',
                onTap: () =>
                    context.go('/admin/users'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6C757D),
  );
}

// ── REUSABLE WIDGETS ─────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
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

class _PipeDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 12, color: const Color(0xFFDEE2E6));
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF6C757D))),
      ],
    );
  }
}

class _ExitTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: const Text(
        'EXIT',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6C757D),
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _PageBtn(
      {required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF185FA5)
              : Colors.white,
          border:
          Border.all(color: const Color(0xFFDEE2E6)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive
                  ? Colors.white
                  : onTap == null
                  ? const Color(0xFFDEE2E6)
                  : const Color(0xFF6C757D),
            ),
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