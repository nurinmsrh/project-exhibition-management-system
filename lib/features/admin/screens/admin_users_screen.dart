import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/user_model.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All Roles';
  String _selectedStatus = 'All Status';
  final Set<String> _selectedUserIds = {};
  int _currentPage = 1;
  final int _pageSize = 10;

  final List<String> _roles = ['All Roles', 'admin', 'organizer', 'exhibitor'];
  final List<String> _statuses = ['All Status', 'active', 'inactive'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _applyFilters(List<UserModel> users) {
    return users.where((u) {
      final matchRole = _selectedRole == 'All Roles' ||
          u.role.toLowerCase() == _selectedRole.toLowerCase();
      final matchStatus = _selectedStatus == 'All Status' ||
          ((_selectedStatus == 'active') == u.isActive);
      return matchRole && matchStatus;
    }).toList();
  }

  List<UserModel> _paginate(List<UserModel> users) {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, users.length);
    if (start >= users.length) return [];
    return users.sublist(start, end);
  }

  int _totalPages(int totalCount) =>
      (totalCount / _pageSize).ceil().clamp(1, 999);

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedRole = 'All Roles';
      _selectedStatus = 'All Status';
      _currentPage = 1;
      _selectedUserIds.clear();
    });
    context.read<AdminProvider>().searchUsers('');
  }

  Future<void> _confirmDelete(String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$name"?'),
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
    if (confirmed == true && mounted) {
      final success = await context.read<AdminProvider>().deleteUser(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'User deleted.' : 'Failed to delete user.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmBulkDeactivate() async {
    if (_selectedUserIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Users'),
        content: Text(
            'Deactivate ${_selectedUserIds.length} selected user(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final provider = context.read<AdminProvider>();
      for (final uid in _selectedUserIds) {
        await provider.updateUserStatus(uid, false);
      }
      setState(() => _selectedUserIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected users deactivated.')),
      );
    }
  }

  Future<void> _confirmBulkDelete() async {
    if (_selectedUserIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Users'),
        content:
        Text('Delete ${_selectedUserIds.length} selected user(s)? This cannot be undone.'),
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
    if (confirmed == true && mounted) {
      final provider = context.read<AdminProvider>();
      for (final uid in _selectedUserIds) {
        await provider.deleteUser(uid);
      }
      setState(() => _selectedUserIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected users deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final allUsers = provider.users;
    final filtered = _applyFilters(allUsers);
    final paginated = _paginate(filtered);
    final totalPages = _totalPages(filtered.length);

    // KPI counts from full user list (unfiltered)
    final allRaw = provider.users;
    final totalUsers = allRaw.length;
    final activeUsers = allRaw.where((u) => u.isActive).length;
    final inactiveUsers = totalUsers - activeUsers;
    final adminUsers = allRaw.where((u) => u.role == 'admin').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF185FA5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage User Accounts',
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
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiGrid(
                    totalUsers: totalUsers,
                    activeUsers: activeUsers,
                    inactiveUsers: inactiveUsers,
                    adminUsers: adminUsers,
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 10),
                  _buildFilterRow(),
                  const SizedBox(height: 16),
                  _buildTable(paginated, filtered),
                  const SizedBox(height: 14),
                  _buildPagination(filtered.length, totalPages),
                ],
              ),
            ),
          ),
          _buildBulkActions(),
        ],
      ),
    );
  }

  // ── KPI GRID ────────────────────────────────────────────
  Widget _buildKpiGrid({
    required int totalUsers,
    required int activeUsers,
    required int inactiveUsers,
    required int adminUsers,
  }) {
    final activePercent = totalUsers == 0
        ? 0.0
        : (activeUsers / totalUsers * 100);
    final inactivePercent = totalUsers == 0
        ? 0.0
        : (inactiveUsers / totalUsers * 100);
    final adminPercent = totalUsers == 0
        ? 0.0
        : (adminUsers / totalUsers * 100);

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
          value: totalUsers.toString(),
          sub: 'vs. last month',
          badge: '↑ 5.2%',
        ),
        _KpiCard(
          icon: Icons.person_add_outlined,
          label: 'Active Users',
          value: activeUsers.toString(),
          sub: '${activePercent.toStringAsFixed(2)}% of total users',
        ),
        _KpiCard(
          icon: Icons.person_off_outlined,
          label: 'Inactive Users',
          value: inactiveUsers.toString(),
          sub: '${inactivePercent.toStringAsFixed(2)}% of total users',
        ),
        _KpiCard(
          icon: Icons.shield_outlined,
          label: 'Administrators',
          value: adminUsers.toString(),
          sub: '${adminPercent.toStringAsFixed(2)}% of total users',
        ),
      ],
    );
  }

  // ── SEARCH BAR ──────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          context.read<AdminProvider>().searchUsers(val);
          setState(() => _currentPage = 1);
        },
        decoration: const InputDecoration(
          hintText: 'Search by name, email, or phone...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF6C757D)),
          prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF6C757D)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ── FILTER ROW ──────────────────────────────────────────
  Widget _buildFilterRow() {
    return Row(
      children: [
        _DropdownFilter(
          value: _selectedRole,
          items: _roles,
          onChanged: (val) => setState(() {
            _selectedRole = val!;
            _currentPage = 1;
          }),
        ),
        const SizedBox(width: 8),
        _DropdownFilter(
          value: _selectedStatus,
          items: _statuses,
          onChanged: (val) => setState(() {
            _selectedStatus = val!;
            _currentPage = 1;
          }),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.refresh, size: 15),
          label: const Text('Reset', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            side: const BorderSide(color: Color(0xFFDEE2E6)),
            foregroundColor: const Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }

  // ── TABLE ───────────────────────────────────────────────
  Widget _buildTable(List<UserModel> paginated, List<UserModel> filtered) {
    final allSelected = paginated.isNotEmpty &&
        paginated.every((u) => _selectedUserIds.contains(u.uid));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedUserIds.addAll(paginated.map((u) => u.uid));
                      } else {
                        _selectedUserIds
                            .removeAll(paginated.map((u) => u.uid));
                      }
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Expanded(
                  child: Text('User',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C757D))),
                ),
                const SizedBox(
                  width: 80,
                  child: Text('Role',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C757D))),
                ),
                const SizedBox(
                  width: 70,
                  child: Text('Status',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C757D))),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDEE2E6)),
          // Rows
          if (paginated.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No users found.',
                  style: TextStyle(color: Color(0xFF6C757D))),
            )
          else
            ...paginated.map((user) => _buildUserRow(user)),
        ],
      ),
    );
  }

  Widget _buildUserRow(UserModel user) {
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: _selectedUserIds.contains(user.uid),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedUserIds.add(user.uid);
                    } else {
                      _selectedUserIds.remove(user.uid);
                    }
                  });
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              // Avatar + name/email
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE6F1FB),
                child: Text(
                  initials,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF185FA5)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF6C757D)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Role badge
              SizedBox(
                width: 80,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFE8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatRole(user.role),
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF5F5E5A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              // Status toggle
              SizedBox(
                width: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await context
                            .read<AdminProvider>()
                            .updateUserStatus(user.uid, !user.isActive);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 16,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: user.isActive
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFFB4B2A9),
                        ),
                        child: Align(
                          alignment: user.isActive
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF6C757D)),
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

  // ── PAGINATION ──────────────────────────────────────────
  Widget _buildPagination(int totalCount, int totalPages) {
    return Row(
      children: [
        Text(
          'Showing ${((_currentPage - 1) * _pageSize) + 1}–'
              '${((_currentPage * _pageSize).clamp(0, totalCount))} of $totalCount users',
          style:
          const TextStyle(fontSize: 11, color: Color(0xFF6C757D)),
        ),
        const Spacer(),
        Row(
          children: [
            _PageBtn(
              label: '<',
              onTap: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
            ),
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
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  // ── BULK ACTIONS ────────────────────────────────────────
  Widget _buildBulkActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDEE2E6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDEE2E6)),
              ),
              child: Text(
                '${_selectedUserIds.length} selected',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6C757D)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _selectedUserIds.isEmpty
                  ? null
                  : _confirmBulkDeactivate,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDEE2E6)),
              ),
              child: const Text('Deactivate',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed:
              _selectedUserIds.isEmpty ? null : _confirmBulkDelete,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDEE2E6)),
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'organizer':
        return 'Event Organizer';
      case 'exhibitor':
        return 'Exhibitor';
      default:
        return role;
    }
  }
}

// ── REUSABLE WIDGETS ────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final String? badge;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.badge,
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
              Icon(icon, size: 14, color: const Color(0xFF6C757D)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6C757D))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600)),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3DE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF3B6D11))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF6C757D))),
        ],
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
          isDense: true,
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _PageBtn({required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF185FA5) : Colors.white,
          border: Border.all(color: const Color(0xFFDEE2E6)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.white : const Color(0xFF6C757D),
            ),
          ),
        ),
      ),
    );
  }
}