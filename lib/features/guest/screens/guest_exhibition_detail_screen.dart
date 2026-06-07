import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/services/booth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';

class GuestExhibitionDetailScreen extends StatefulWidget {
  final ExhibitionModel exhibition;

  const GuestExhibitionDetailScreen({super.key, required this.exhibition});

  @override
  State<GuestExhibitionDetailScreen> createState() =>
      _GuestExhibitionDetailScreenState();
}

class _GuestExhibitionDetailScreenState
    extends State<GuestExhibitionDetailScreen> {
  final BoothService _boothService = BoothService();
  List<BoothModel> _booths = [];
  bool _isLoadingBooths = true;
  String _boothsError = '';

  @override
  void initState() {
    super.initState();
    _loadBooths();
  }

  Future<void> _loadBooths() async {
    try {
      final booths =
      await _boothService.getBoothsByExhibition(widget.exhibition.id);
      if (mounted) {
        setState(() {
          _booths = booths;
          _isLoadingBooths = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _boothsError = e.toString();
          _isLoadingBooths = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

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

  Color _boothColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF1D9E75);
      case 'booked':
        return const Color(0xFFDC3545);
      case 'unavailable':
      default:
        return const Color(0xFF6C757D);
    }
  }

  void _navigateToAuth(BuildContext context, String route) {
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final exhibition = widget.exhibition;
    final status = exhibition.computedStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          exhibition.title,
          style: const TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF185FA5)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Exhibition Info ───────────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exhibition.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: Color(0xFF6C757D)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          exhibition.venue,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF6C757D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 15, color: Color(0xFF6C757D)),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(exhibition.startDate)} — ${_formatDate(exhibition.endDate)}',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6C757D)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    exhibition.description,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1C1E),
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Register/Login Banner ─────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFCCE5FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Want to book a booth?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004085),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Create an account or login to select and apply for booths at this exhibition.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF004085)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push('/register'),
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
                            'Register',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF185FA5),
                            side: const BorderSide(color: Color(0xFF185FA5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Floor Plan (read-only) ────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Floor Plan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Read-only view. Login to select booths.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF6C757D)),
                  ),
                  const SizedBox(height: 12),

                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: const [
                      _LegendItem(
                          color: Color(0xFF1D9E75), label: 'Available'),
                      _LegendItem(
                          color: Color(0xFFDC3545), label: 'Booked'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Floor plan canvas
                  _isLoadingBooths
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(
                          color: Color(0xFF185FA5)),
                    ),
                  )
                      : _boothsError.isNotEmpty
                      ? Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        _boothsError,
                        style: const TextStyle(
                            color: Color(0xFFDC3545)),
                      ),
                    ),
                  )
                      : _booths.isEmpty
                      ? const Center(
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No booths available.',
                        style: TextStyle(
                            color: Color(0xFF6C757D)),
                      ),
                    ),
                  )
                      : _ReadOnlyFloorPlan(
                    booths: _booths,
                    boothColor: _boothColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Read-only floor plan — no tap selection
// ─────────────────────────────────────────────────────────────────

class _ReadOnlyFloorPlan extends StatelessWidget {
  final List<BoothModel> booths;
  final Color Function(String) boothColor;

  const _ReadOnlyFloorPlan({
    required this.booths,
    required this.boothColor,
  });

  @override
  Widget build(BuildContext context) {
    double maxX = 100;
    double maxY = 100;
    for (final b in booths) {
      final right = b.positionX + b.width;
      final bottom = b.positionY + b.height;
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            width: maxX + 24,
            height: maxY + 24,
            child: Stack(
              children: booths.map((booth) {
                return Positioned(
                  left: booth.positionX,
                  top: booth.positionY,
                  child: GestureDetector(
                    // Show detail on tap but no selection
                    onTap: () => _showBoothDetail(context, booth),
                    child: Container(
                      width: booth.width,
                      height: booth.height,
                      decoration: BoxDecoration(
                        color: boothColor(booth.status),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          booth.boothNumber,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showBoothDetail(BuildContext context, BoothModel booth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Booth ${booth.boothNumber}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1C1E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Type', value: booth.type),
            _DetailRow(label: 'Size', value: booth.size),
            _DetailRow(
                label: 'Price',
                value: 'RM ${booth.price.toStringAsFixed(2)}'),
            _DetailRow(
              label: 'Status',
              value: booth.status[0].toUpperCase() +
                  booth.status.substring(1),
            ),
            if (booth.amenities.isNotEmpty)
              _DetailRow(
                  label: 'Amenities',
                  value: booth.amenities.join(', ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Color(0xFF6C757D))),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF6C757D))),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6C757D)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}