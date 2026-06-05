import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/booth_model.dart';

class AdminBoothTypesScreen extends StatefulWidget {
  const AdminBoothTypesScreen({super.key});

  @override
  State<AdminBoothTypesScreen> createState() =>
      _AdminBoothTypesScreenState();
}

class _AdminBoothTypesScreenState
    extends State<AdminBoothTypesScreen> {
  final _searchController = TextEditingController();
  String _selectedTab = 'All';
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AdminProvider>();
      await provider.loadAllBooths();
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

  List<BoothModel> _filtered(List<BoothModel> booths) {
    final q = _searchController.text.toLowerCase();
    return booths.where((b) {
      final matchSearch = q.isEmpty ||
          b.boothNumber.toLowerCase().contains(q) ||
          b.type.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q);
      final matchTab = _selectedTab == 'All' ||
          (_selectedTab == 'Published' && b.isPublished) ||
          (_selectedTab == 'Past' && !b.isPublished);
      return matchSearch && matchTab;
    }).toList();
  }

  // Group booths by type
  Map<String, List<BoothModel>> _groupByType(
      List<BoothModel> booths) {
    final Map<String, List<BoothModel>> grouped = {};
    for (final b in booths) {
      final key = b.type.toLowerCase();
      grouped.putIfAbsent(key, () => []).add(b);
    }
    return grouped;
  }

  Future<void> _deleteBooth(BoothModel booth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Booth'),
        content: Text(
            'Delete booth ${booth.boothNumber}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
            TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context
          .read<AdminProvider>()
          .deleteBooth(booth.id, booth.exhibitionId);
      await context.read<AdminProvider>().loadAllBooths();
    }
  }

  Future<void> _togglePublish(BoothModel booth) async {
    await context.read<AdminProvider>().updateBooth(
      booth.id,
      {'isPublished': !booth.isPublished},
      booth.exhibitionId,
    );
    await context.read<AdminProvider>().loadAllBooths();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final filtered = _filtered(provider.booths);
    final grouped = _groupByType(filtered);

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
          'Booth Management',
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
            // Info banner + create button
            _buildInfoBanner(),
            const SizedBox(height: 16),

            // Tab + search
            _buildTabAndSearch(),
            const SizedBox(height: 16),

            // Section heading + booth search
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Exhibitions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Booth type search
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFDEE2E6)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Search booth types...',
                  hintStyle: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93)),
                  prefixIcon: Icon(Icons.search,
                      size: 16,
                      color: Color(0xFF8E8E93)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Booth type cards
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFDEE2E6)),
                ),
                child: const Center(
                  child: Text(
                    'No booths found.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6C757D)),
                  ),
                ),
              )
            else
              ...grouped.entries.map((entry) =>
                  _buildBoothTypeCard(
                      entry.key, entry.value)),

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
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: Color(0xFF6C757D)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Define and manage booth types available for all exhibitions, setting prices, size, and general attributes from the system level.',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                context.go('/admin/exhibitions/create'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFDEE2E6)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add,
                      size: 13, color: Color(0xFF185FA5)),
                  SizedBox(width: 4),
                  Text(
                    'Create Booth Type',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF185FA5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
          children: ['All', 'Published', 'Past'].map((tab) {
            final isActive = _selectedTab == tab;
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedTab = tab),
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
                          borderRadius:
                          BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        Container(
          width: 140,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border:
            Border.all(color: const Color(0xFFDEE2E6)),
          ),
          child: const TextField(
            style: TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search exhibitions',
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
      ],
    );
  }

  // ── BOOTH TYPE CARD ──────────────────────────────────────
  Widget _buildBoothTypeCard(
      String type, List<BoothModel> booths) {
    final typeName = _formatTypeName(type);
    final available =
        booths.where((b) => b.status == 'available').length;
    final reserved = booths
        .where(
            (b) => b.status == 'booked' || b.status == 'reserved')
        .length;
    final isPublished =
    booths.any((b) => b.isPublished);
    final price = booths.isNotEmpty ? booths.first.price : 0.0;
    final size = booths.isNotEmpty ? booths.first.size : '';
    final description =
    booths.isNotEmpty ? booths.first.description : '';
    final typeColor = _typeColor(type);

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
            // Row 1: title + published badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$typeName Booth',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                ),
                _publishBadge(isPublished),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: size
            Text(
              'Size: $size',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
            const SizedBox(height: 3),

            // Row 3: price
            Text(
              'Price per booth: RM ${price.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6C757D)),
            ),
            const SizedBox(height: 10),

            // Row 4: stats banner
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                      label: 'Total Booths',
                      value: '${booths.length}',
                      color: typeColor),
                  Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFFDEE2E6)),
                  _StatChip(
                      label: 'Available',
                      value: '$available',
                      color: const Color(0xFF1D9E75)),
                  Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFFDEE2E6)),
                  _StatChip(
                      label: 'Reserved',
                      value: '$reserved',
                      color: const Color(0xFFDC3545)),
                ],
              ),
            ),

            // Row 5: description
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6C757D)),
              ),
            ],
            const SizedBox(height: 10),

            // Row 6: actions
            Row(
              children: [
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () {
                    if (booths.isNotEmpty) {
                      context.go(
                          '/admin/exhibitions/${booths.first.exhibitionId}/booths/${booths.first.id}/edit');
                    }
                  },
                ),
                _PipeDivider(),
                _ActionBtn(
                  icon: isPublished
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  label: isPublished
                      ? 'Unpublish'
                      : 'Publish',
                  onTap: () {
                    for (final b in booths) {
                      _togglePublish(b);
                    }
                  },
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
                        title: Text(
                            'Delete all $typeName booths?'),
                        content: Text(
                            'This will delete all ${booths.length} $typeName booths. Cannot be undone.'),
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
                            child: const Text('Delete All'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      for (final b in booths) {
                        await _deleteBooth(b);
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _publishBadge(bool isPublished) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPublished
            ? const Color(0xFFD4EDDA)
            : const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPublished ? 'Published' : 'Unpublished',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPublished
              ? const Color(0xFF155724)
              : const Color(0xFF495057),
        ),
      ),
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
                  if (_pendingCount > 0)
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
                          '$_pendingCount',
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              _NavItem(
                icon: Icons.grid_view_outlined,
                label: 'Booth Types',
                isActive: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTypeName(String type) {
    if (type.isEmpty) return type;
    return type[0].toUpperCase() + type.substring(1);
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'premium':
        return const Color(0xFF7F77DD);
      case 'vip':
        return const Color(0xFFEF9F27);
      default:
        return const Color(0xFF888780);
    }
  }
}

// ── REUSABLE WIDGETS ─────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              fontSize: 10, color: Color(0xFF6C757D)),
        ),
      ],
    );
  }
}

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
        width: 1,
        height: 12,
        color: const Color(0xFFDEE2E6));
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