import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/services/exhibition_service.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  final ExhibitionService _exhibitionService = ExhibitionService();
  List<ExhibitionModel> _exhibitions = [];
  List<ExhibitionModel> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

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
    try {
      final exhibitions =
      await _exhibitionService.getPublishedExhibitions();
      setState(() {
        _exhibitions = exhibitions;
        _filtered = exhibitions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = _exhibitions
          .where((e) =>
      e.title.toLowerCase().contains(query.toLowerCase()) ||
          e.venue.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ongoing':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exhibition Management System'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Login',
                style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => context.go('/register'),
            child: const Text('Register',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search exhibitions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Exhibition list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const Center(
              child: Text('No exhibitions found'),
            )
                : RefreshIndicator(
              onRefresh: _loadExhibitions,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final exhibition = _filtered[index];
                  return _ExhibitionCard(
                    exhibition: exhibition,
                    statusColor: _statusColor(exhibition.status),
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

class _ExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;
  final Color statusColor;

  const _ExhibitionCard({
    required this.exhibition,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exhibition.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    exhibition.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  exhibition.venue,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(exhibition.startDate)} - ${_formatDate(exhibition.endDate)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exhibition.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Login to Book a Booth'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}