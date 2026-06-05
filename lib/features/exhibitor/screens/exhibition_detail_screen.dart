import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exhibitor_provider.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/booth_model.dart';
import 'application_form_screen.dart';

class ExhibitionDetailScreen extends StatefulWidget {
  final ExhibitionModel exhibition;

  const ExhibitionDetailScreen({super.key, required this.exhibition});

  @override
  State<ExhibitionDetailScreen> createState() =>
      _ExhibitionDetailScreenState();
}

class _ExhibitionDetailScreenState extends State<ExhibitionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ExhibitorProvider>()
          .loadBoothsForExhibition(widget.exhibition.id);
    });
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExhibitorProvider>();
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
            // ── Exhibition Info Card ──────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status
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

                  // Venue
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

                  // Dates
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

                  // Description
                  Text(
                    exhibition.description,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF1A1C1E), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Floor Plan Section ────────────────────────────────
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
                    'Tap an available booth to select it.',
                    style:
                    TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
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
                          color: Color(0xFF185FA5), label: 'Selected'),
                      _LegendItem(
                          color: Color(0xFFEF9F27), label: 'Reserved'),
                      _LegendItem(
                          color: Color(0xFFDC3545), label: 'Booked'),
                      _LegendItem(
                          color: Color(0xFF6C757D), label: 'Unavailable'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Floor plan canvas
                  provider.isLoadingBooths
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(
                        color: Color(0xFF185FA5),
                      ),
                    ),
                  )
                      : provider.boothsError.isNotEmpty
                      ? Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        provider.boothsError,
                        style: const TextStyle(
                            color: Color(0xFFDC3545)),
                      ),
                    ),
                  )
                      : provider.booths.isEmpty
                      ? const Center(
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No booths available for this exhibition.',
                        style: TextStyle(
                            color: Color(0xFF6C757D)),
                      ),
                    ),
                  )
                      : _FloorPlanCanvas(
                    booths: provider.booths,
                    provider: provider,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // space for bottom bar
          ],
        ),
      ),

      // ── Bottom Action Bar ─────────────────────────────────────
      bottomNavigationBar: provider.selectedBooths.isEmpty
          ? null
          : Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: Color(0xFFDEE2E6))),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${provider.selectedBooths.length} booth${provider.selectedBooths.length > 1 ? 's' : ''} selected',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total: RM ${provider.totalSelectedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF185FA5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<ExhibitorProvider>(),
                        child: ApplicationFormScreen(
                          exhibition: widget.exhibition,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Apply Now',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Floor Plan Canvas — uses positionX/positionY/width/height
// ─────────────────────────────────────────────────────────────────

class _FloorPlanCanvas extends StatelessWidget {
  final List<BoothModel> booths;
  final ExhibitorProvider provider;

  const _FloorPlanCanvas({required this.booths, required this.provider});

  @override
  Widget build(BuildContext context) {
    // Compute canvas size from booth positions
    double maxX = 100;
    double maxY = 100;
    for (final b in booths) {
      final right = b.positionX + b.width;
      final bottom = b.positionY + b.height;
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    final canvasWidth = maxX + 24;
    final canvasHeight = maxY + 24;

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
            width: canvasWidth,
            height: canvasHeight,
            child: Stack(
              children: booths.map((booth) {
                return Positioned(
                  left: booth.positionX,
                  top: booth.positionY,
                  child: _BoothTile(
                    booth: booth,
                    provider: provider,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Booth Tile
// ─────────────────────────────────────────────────────────────────

class _BoothTile extends StatelessWidget {
  final BoothModel booth;
  final ExhibitorProvider provider;

  const _BoothTile({required this.booth, required this.provider});

  void _showBoothDetail(BuildContext context) {
    final isSelected = provider.isBoothSelected(booth.id);
    final isAvailable = booth.status == 'available';

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
            if (booth.description.isNotEmpty)
              _DetailRow(
                  label: 'Description', value: booth.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF6C757D)),
            ),
          ),
          if (isAvailable)
            ElevatedButton(
              onPressed: () {
                provider.toggleBoothSelection(booth);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? const Color(0xFFDC3545)
                    : const Color(0xFF185FA5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isSelected ? 'Deselect' : 'Select Booth'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = provider.boothColor(booth);
    final isAvailable = booth.status == 'available';

    return GestureDetector(
      onTap: () {
        if (isAvailable) provider.toggleBoothSelection(booth);
        _showBoothDetail(context);
      },
      child: Container(
        width: booth.width,
        height: booth.height,
        decoration: BoxDecoration(
          color: color,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Helper widgets
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