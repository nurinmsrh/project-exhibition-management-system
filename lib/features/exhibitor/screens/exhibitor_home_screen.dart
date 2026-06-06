import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exhibitor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/models/exhibition_model.dart';
import '../exhibitor_bottom_nav.dart';
import 'exhibition_detail_screen.dart';
import '../../auth/screens/login_screen.dart';

class ExhibitorHomeScreen extends StatefulWidget {
  const ExhibitorHomeScreen({super.key});

  @override
  State<ExhibitorHomeScreen> createState() => _ExhibitorHomeScreenState();
}

class _ExhibitorHomeScreenState extends State<ExhibitorHomeScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExhibitorProvider>().loadExhibitions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<ExhibitorProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Exhibitions',
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
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${authProvider.currentUser?.name ?? ''}!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Browse and book booths for upcoming exhibitions.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: provider.searchExhibitions,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name or venue...',
                hintStyle: const TextStyle(color: Color(0xFF6C757D), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C757D), size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF185FA5)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['all', 'upcoming', 'ongoing', 'completed']
                  .map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedStatus = status);
                      provider.filterByStatus(status);
                    },
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
          const SizedBox(height: 12),

          // Exhibition list
          Expanded(
            child: provider.isLoadingExhibitions
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF185FA5),
              ),
            )
                : provider.exhibitionsError.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Color(0xFFDC3545)),
                  const SizedBox(height: 12),
                  Text(
                    provider.exhibitionsError,
                    style: const TextStyle(color: Color(0xFF6C757D)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.loadExhibitions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : provider.exhibitions.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy_outlined,
                      size: 48, color: Color(0xFF6C757D)),
                  const SizedBox(height: 12),
                  const Text(
                    'No exhibitions found',
                    style: TextStyle(color: Color(0xFF6C757D)),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: const Color(0xFF185FA5),
              onRefresh: provider.loadExhibitions,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: provider.exhibitions.length,
                itemBuilder: (context, index) {
                  return _ExhibitionCard(
                    exhibition: provider.exhibitions[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ExhibitorBottomNav(currentIndex: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Exhibition Card
// ─────────────────────────────────────────────────────────────────

class _ExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;

  const _ExhibitionCard({required this.exhibition});

  Color _statusBg(String status) {
    switch (status) {
      case 'upcoming':
        return const Color(0xFFCCE5FF);
      case 'ongoing':
        return const Color(0xFFD4EDDA);
      case 'completed':
        return const Color(0xFFE9ECEF);
      default:
        return const Color(0xFFE9ECEF);
    }
  }

  Color _statusText(String status) {
    switch (status) {
      case 'upcoming':
        return const Color(0xFF004085);
      case 'ongoing':
        return const Color(0xFF155724);
      case 'completed':
        return const Color(0xFF495057);
      default:
        return const Color(0xFF495057);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final status = exhibition.computedStatus;

    return Container(
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
            // Title + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

            // Venue
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Color(0xFF6C757D)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    exhibition.venue,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6C757D)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Dates
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Color(0xFF6C757D)),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(exhibition.startDate)} — ${_formatDate(exhibition.endDate)}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6C757D)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              exhibition.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1A1C1E)),
            ),
            const SizedBox(height: 12),

            // View button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<ExhibitorProvider>(),
                        child: ExhibitionDetailScreen(
                          exhibition: exhibition,
                        ),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF185FA5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'View & Book Booth',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}