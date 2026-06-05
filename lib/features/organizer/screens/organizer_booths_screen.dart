// lib/features/organizer/screens/organizer_booths_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/organizer_provider.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/booth_model.dart';

class OrganizerBoothsScreen extends StatefulWidget {
  final ExhibitionModel exhibition;

  const OrganizerBoothsScreen({super.key, required this.exhibition});

  @override
  State<OrganizerBoothsScreen> createState() => _OrganizerBoothsScreenState();
}

class _OrganizerBoothsScreenState extends State<OrganizerBoothsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizerProvider>().loadBooths(widget.exhibition.id);
    });
  }

  void _showBoothForm({BoothModel? booth}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<OrganizerProvider>(),
        child: _BoothFormSheet(
          exhibitionId: widget.exhibition.id,
          booth: booth,
        ),
      ),
    );
  }

  Future<void> _deleteBooth(BoothModel booth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Booth'),
        content: Text('Delete booth "${booth.boothNumber}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFDC3545))),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context
          .read<OrganizerProvider>()
          .deleteBooth(booth.id, widget.exhibition.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizer = context.watch<OrganizerProvider>();
    final booths = organizer.booths;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          '${widget.exhibition.title} — Booths',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF185FA5)),
            tooltip: 'Add Booth',
            onPressed: () => _showBoothForm(),
          ),
        ],
      ),
      body: organizer.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF185FA5)),
      )
          : booths.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined,
                size: 48, color: Color(0xFF6C757D)),
            const SizedBox(height: 12),
            const Text(
              'No booths yet.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6C757D)),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Floor Plan ---
            _FloorPlan(booths: booths),

            // --- Booth Table ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booth List',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...booths.map(
                        (b) => _BoothListTile(
                      booth: b,
                      onEdit: () => _showBoothForm(booth: b),
                      onDelete: () => _deleteBooth(b),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floor Plan
// ---------------------------------------------------------------------------
class _FloorPlan extends StatelessWidget {
  final List<BoothModel> booths;
  const _FloorPlan({required this.booths});

  Color _boothColor(String status) {
    switch (status) {
      case 'booked':
        return const Color(0xFFDC3545);
      case 'reserved':
        return const Color(0xFFEF9F27);
      case 'unavailable':
        return const Color(0xFF6C757D);
      default:
        return const Color(0xFF1D9E75); // available
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Floor Plan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1C1E),
              ),
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: const [
                _LegendItem(color: Color(0xFF1D9E75), label: 'Available'),
                _LegendItem(color: Color(0xFFEF9F27), label: 'Reserved'),
                _LegendItem(color: Color(0xFFDC3545), label: 'Booked'),
                _LegendItem(color: Color(0xFF6C757D), label: 'Unavailable'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Plan canvas
          SizedBox(
            height: 300,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: SizedBox(
                  width: 600,
                  height: 400,
                  child: Stack(
                    children: [
                      // Grid background
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          border: Border.all(color: const Color(0xFFDEE2E6)),
                        ),
                      ),
                      // Booths
                      ...booths.map((b) => Positioned(
                        left: b.positionX,
                        top: b.positionY,
                        child: Container(
                          width: b.width,
                          height: b.height,
                          decoration: BoxDecoration(
                            color:
                            _boothColor(b.status).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _boothColor(b.status),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            b.boothNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6C757D))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Booth List Tile
// ---------------------------------------------------------------------------
class _BoothListTile extends StatelessWidget {
  final BoothModel booth;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BoothListTile({
    required this.booth,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusBg(String s) {
    switch (s) {
      case 'booked':
        return const Color(0xFFFCEBEB);
      case 'reserved':
        return const Color(0xFFFFF3CD);
      case 'unavailable':
        return const Color(0xFFE9ECEF);
      default:
        return const Color(0xFFD4EDDA);
    }
  }

  Color _statusText(String s) {
    switch (s) {
      case 'booked':
        return const Color(0xFF721C24);
      case 'reserved':
        return const Color(0xFF856404);
      case 'unavailable':
        return const Color(0xFF495057);
      default:
        return const Color(0xFF155724);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: Row(
        children: [
          // Booth number badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF185FA5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              booth.boothNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF185FA5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booth.type} · ${booth.size}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RM ${booth.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6C757D)),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusBg(booth.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              booth.status[0].toUpperCase() + booth.status.substring(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusText(booth.status),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF185FA5), size: 18),
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFDC3545), size: 18),
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Booth Form Bottom Sheet
// ---------------------------------------------------------------------------
class _BoothFormSheet extends StatefulWidget {
  final String exhibitionId;
  final BoothModel? booth;

  const _BoothFormSheet({required this.exhibitionId, this.booth});

  @override
  State<_BoothFormSheet> createState() => _BoothFormSheetState();
}

class _BoothFormSheetState extends State<_BoothFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _priceController;
  late final TextEditingController _amenitiesController;

  String _type = 'Standard';
  String _size = 'Small';
  bool _isSubmitting = false;

  bool get _isEdit => widget.booth != null;

  final List<String> _types = ['Standard', 'Premium', 'Corner', 'Island'];
  final List<String> _sizes = ['Small', 'Medium', 'Large', 'Extra Large'];

  @override
  void initState() {
    super.initState();
    _numberController =
        TextEditingController(text: widget.booth?.boothNumber ?? '');
    _priceController = TextEditingController(
        text: widget.booth != null
            ? widget.booth!.price.toStringAsFixed(2)
            : '');
    _amenitiesController = TextEditingController(
        text: widget.booth?.amenities.join(', ') ?? '');
    if (widget.booth != null) {
      _type = widget.booth!.type;
      _size = widget.booth!.size;
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _priceController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<OrganizerProvider>();
    final amenities = _amenitiesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    bool success;

    if (_isEdit) {
      success = await provider.updateBooth(
        widget.booth!.id,
        {
          'boothNumber': _numberController.text.trim(),
          'type': _type,
          'size': _size,
          'price': double.tryParse(_priceController.text.trim()) ?? 0,
          'amenities': amenities,
        },
        widget.exhibitionId,
      );
    } else {
      success = await provider.createBooth(
        exhibitionId: widget.exhibitionId,
        boothNumber: _numberController.text.trim(),
        type: _type,
        size: _size,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        amenities: amenities,
        positionX: 0,
        positionY: 0,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEE2E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEdit ? 'Edit Booth' : 'Add Booth',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 16),

              // Booth Number
              _label('Booth Number *'),
              const SizedBox(height: 6),
              _field(
                controller: _numberController,
                hint: 'e.g. A-01',
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Booth number is required'
                    : null,
              ),
              const SizedBox(height: 12),

              // Type & Size row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Type *'),
                        const SizedBox(height: 6),
                        _dropdown(
                          value: _type,
                          items: _types,
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Size *'),
                        const SizedBox(height: 6),
                        _dropdown(
                          value: _size,
                          items: _sizes,
                          onChanged: (v) => setState(() => _size = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Price
              _label('Price (RM) *'),
              const SizedBox(height: 6),
              _field(
                controller: _priceController,
                hint: 'e.g. 1500.00',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Amenities
              _label('Amenities (comma-separated)'),
              const SizedBox(height: 6),
              _field(
                controller: _amenitiesController,
                hint: 'e.g. WiFi, Electricity, Table',
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    _isEdit ? 'Save Changes' : 'Add Booth',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1C1E),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          const TextStyle(color: Color(0xFF6C757D), fontSize: 13),
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF185FA5)),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  Widget _dropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) =>
      DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}