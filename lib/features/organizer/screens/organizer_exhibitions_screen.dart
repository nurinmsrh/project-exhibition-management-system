import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/organizer_provider.dart';
import '../organizer_bottom_nav.dart';
import 'organizer_exhibition_form_screen.dart';
import '../../../data/models/exhibition_model.dart';
import 'package:go_router/go_router.dart';
class OrganizerExhibitionsScreen extends StatefulWidget {
  final bool showApplicationsHint;
  const OrganizerExhibitionsScreen({super.key, this.showApplicationsHint = false});

  @override
  State<OrganizerExhibitionsScreen> createState() =>
      _OrganizerExhibitionsScreenState();
}

class _OrganizerExhibitionsScreenState
    extends State<OrganizerExhibitionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != null) {
        context.read<OrganizerProvider>().loadExhibitions(uid);
      }
      if (widget.showApplicationsHint) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tap the \u{1F4CB} icon on an exhibition to view its applications.'),
            duration: Duration(seconds: 3),
            backgroundColor: Color(0xFF185FA5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExhibitionModel> get _filtered {
    final all = context.read<OrganizerProvider>().exhibitions;
    return all.where((e) {
      final matchSearch =
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.venue.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchFilter =
          _filterStatus == 'all' || e.computedStatus == _filterStatus;
      return matchSearch && matchFilter;
    }).toList();
  }

  void _goToForm({ExhibitionModel? exhibition}) {
    if (exhibition != null) {
      context.go(
        '/organizer/exhibitions/${exhibition.id}/edit',
        extra: exhibition,
      );
    } else {
      context.go('/organizer/exhibitions/create');
    }
  }

  Future<void> _delete(ExhibitionModel exhibition) async {
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Exhibition'),
        content: Text('Delete "${exhibition.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFDC3545)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await context
          .read<OrganizerProvider>()
          .deleteExhibition(exhibition.id, uid);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<OrganizerProvider>().errorMessage),
            backgroundColor: const Color(0xFFDC3545),
          ),
        );
      }
    }
  }

  Future<void> _togglePublish(ExhibitionModel exhibition) async {
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    await context
        .read<OrganizerProvider>()
        .togglePublish(exhibition.id, !exhibition.isPublished, uid);
  }

  void _goToBooths(ExhibitionModel exhibition) {
    context.go(
      '/organizer/exhibitions/${exhibition.id}/booths',
      extra: exhibition,
    );
  }

  void _goToApplications(ExhibitionModel exhibition) {
    context.go(
      '/organizer/exhibitions/${exhibition.id}/applications',
      extra: exhibition,
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
        automaticallyImplyLeading: false,
        title: const Text(
          'My Exhibitions',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF185FA5)),
            tooltip: 'Create Exhibition',
            onPressed: () => _goToForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Search & Filter ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search exhibitions...',
                    hintStyle: const TextStyle(color: Color(0xFF6C757D)),
                    prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF6C757D)),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'upcoming', 'ongoing', 'completed',
                      'unpublished']
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
              ],
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
                _searchQuery.isNotEmpty || _filterStatus != 'all'
                    ? 'No exhibitions match your filter.'
                    : 'No exhibitions yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style:
                const TextStyle(color: Color(0xFF6C757D)),
              ),
            )
                : RefreshIndicator(
              color: const Color(0xFF185FA5),
              onRefresh: () {
                final uid = context
                    .read<AuthProvider>()
                    .currentUser
                    ?.uid;
                if (uid != null) {
                  return organizer.loadExhibitions(uid);
                }
                return Future.value();
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _ExhibitionCard(
                      exhibition: filtered[i],
                      onEdit: () => _goToForm(exhibition: filtered[i]),
                      onDelete: () => _delete(filtered[i]),
                      onTogglePublish: () => _togglePublish(filtered[i]),
                      onViewBooths: () => _goToBooths(filtered[i]),
                      onViewApplications: () => _goToApplications(filtered[i]),
                    ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const OrganizerBottomNav(currentIndex: 1),
    );
  }
}

// --- Exhibition Card ---
class _ExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;
  final VoidCallback onViewBooths;
  final VoidCallback onViewApplications;

  const _ExhibitionCard({
    required this.exhibition,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
    required this.onViewBooths,
    required this.onViewApplications,
  });

  @override
  Widget build(BuildContext context) {
    final status = exhibition.computedStatus;
    final statusStyle = _statusStyle(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    exhibition.title,
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
                    color: statusStyle['bg'],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusStyle['text'],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Color(0xFF6C757D)),
                const SizedBox(width: 4),
                Text(
                  exhibition.venue,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6C757D)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Color(0xFF6C757D)),
                const SizedBox(width: 4),
                Text(
                  '${_fmt(exhibition.startDate)} — ${_fmt(exhibition.endDate)}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6C757D)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                // Publish toggle
                OutlinedButton.icon(
                  onPressed: onTogglePublish,
                  icon: Icon(
                    exhibition.isPublished
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 14,
                  ),
                  label: Text(
                    exhibition.isPublished ? 'Unpublish' : 'Publish',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: exhibition.isPublished
                        ? const Color(0xFF6C757D)
                        : const Color(0xFF1D9E75),
                    side: BorderSide(
                      color: exhibition.isPublished
                          ? const Color(0xFF6C757D)
                          : const Color(0xFF1D9E75),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                // Booths
                IconButton(
                  onPressed: onViewBooths,
                  icon: const Icon(Icons.store_outlined,
                      color: Color(0xFF185FA5)),
                  tooltip: 'Booths',
                  visualDensity: VisualDensity.compact,
                ),
                // Applications
                IconButton(
                  onPressed: onViewApplications,
                  icon: const Icon(Icons.assignment_outlined,
                      color: Color(0xFF1D9E75)),
                  tooltip: 'Applications',
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                // Edit
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      color: Color(0xFF185FA5)),
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                ),
                // Delete
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFDC3545)),
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Map<String, Color> _statusStyle(String status) {
    switch (status) {
      case 'upcoming':
        return {'bg': const Color(0xFFCCE5FF), 'text': const Color(0xFF004085)};
      case 'ongoing':
        return {'bg': const Color(0xFFD4EDDA), 'text': const Color(0xFF155724)};
      case 'completed':
        return {'bg': const Color(0xFFE9ECEF), 'text': const Color(0xFF495057)};
      default: // unpublished
        return {'bg': const Color(0xFFE9ECEF), 'text': const Color(0xFF495057)};
    }
  }
}