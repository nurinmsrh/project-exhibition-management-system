import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/services/exhibition_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';
import 'guest_exhibition_detail_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  final ExhibitionService _exhibitionService = ExhibitionService();
  final _searchController = TextEditingController();

  List<ExhibitionModel> _exhibitions = [];
  List<ExhibitionModel> _filtered = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadExhibitions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExhibitions() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final exhibitions = await _exhibitionService.getPublishedExhibitions();
      if (mounted) {
        setState(() {
          _exhibitions = exhibitions;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _exhibitions.where((e) {
        final matchesSearch =
            e.title.toLowerCase().contains(query) ||
                e.venue.toLowerCase().contains(query);
        final matchesStatus =
            _selectedStatus == 'all' || e.computedStatus == _selectedStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _navigateToLogin() {
    context.push('/login');
  }

  void _navigateToRegister() {
    context.push('/register');
  }

  @override
  Widget build(BuildContext context) {
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
          TextButton(
            onPressed: _navigateToLogin,
            child: const Text(
              'Login',
              style: TextStyle(
                color: Color(0xFF185FA5),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: _navigateToRegister,
            child: const Text(
              'Register',
              style: TextStyle(
                color: Color(0xFF185FA5),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome banner ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'Login or register to book a booth.',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF6C757D)),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Search bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name or venue...',
                hintStyle: const TextStyle(
                    color: Color(0xFF6C757D), fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF6C757D), size: 20),
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

          // ── Status filter chips ─────────────────────────────────
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
                      _applyFilters();
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

          // ── Exhibition list ─────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF185FA5),
              ),
            )
                : _error.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Color(0xFFDC3545)),
                  const SizedBox(height: 12),
                  Text(
                    _error,
                    style: const TextStyle(
                        color: Color(0xFF6C757D)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadExhibitions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : _filtered.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined,
                      size: 48, color: Color(0xFF6C757D)),
                  SizedBox(height: 12),
                  Text(
                    'No exhibitions found',
                    style: TextStyle(
                        color: Color(0xFF6C757D)),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: const Color(0xFF185FA5),
              onRefresh: _loadExhibitions,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 16),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  return _ExhibitionCard(
                    exhibition: _filtered[index],
                    onLoginTap: _navigateToLogin,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Exhibition Card
// ─────────────────────────────────────────────────────────────────

class _ExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;
  final VoidCallback onLoginTap;

  const _ExhibitionCard({
    required this.exhibition,
    required this.onLoginTap,
  });

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

            // Buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuestExhibitionDetailScreen(
                          exhibition: exhibition,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFF185FA5).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}