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
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Booth',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1C1E),
          ),
        ),
        content: Text(
          'Delete booth "${booth.boothNumber}"? This cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6C757D))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC3545),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
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
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined,
                size: 48, color: Color(0xFF6C757D)),
            SizedBox(height: 12),
            Text(
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
            // ── Floor Plan ──────────────────────────────
            _FloorPlan(booths: booths),

            // ── Booth List ──────────────────────────────
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

// ─────────────────────────────────────────────────────────────────
// Floor Plan
// ─────────────────────────────────────────────────────────────────

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
        return const Color(0xFF1D9E75);
    }
  }

  @override
  Widget build(BuildContext context) {
    double maxX = 100;
    double maxY = 100;
    for (final b in booths) {
      if (b.positionX + b.width > maxX) maxX = b.positionX + b.width;
      if (b.positionY + b.height > maxY) maxY = b.positionY + b.height;
    }

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
          const SizedBox(height: 12),
          // Canvas
          SizedBox(
            height: 300,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: SizedBox(
                  width: maxX + 24,
                  height: maxY + 24,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          border:
                          Border.all(color: const Color(0xFFDEE2E6)),
                        ),
                      ),
                      ...booths.map((b) => Positioned(
                        left: b.positionX,
                        top: b.positionY,
                        child: Container(
                          width: b.width,
                          height: b.height,
                          decoration: BoxDecoration(
                            color: _boothColor(b.status),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Center(
                            child: Text(
                              b.boothNumber,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

// ─────────────────────────────────────────────────────────────────
// Booth List Tile
// ─────────────────────────────────────────────────────────────────

class _BoothListTile extends StatelessWidget {
  final BoothModel booth;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BoothListTile({
    required this.booth,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusBg(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFFD4EDDA);
      case 'booked':
        return const Color(0xFFFCEBEB);
      case 'reserved':
        return const Color(0xFFFFF3CD);
      case 'unavailable':
        return const Color(0xFFE9ECEF);
      default:
        return const Color(0xFFE9ECEF);
    }
  }

  Color _statusText(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF155724);
      case 'booked':
        return const Color(0xFF721C24);
      case 'reserved':
        return const Color(0xFF856404);
      case 'unavailable':
        return const Color(0xFF495057);
      default:
        return const Color(0xFF495057);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Booth ${booth.boothNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBg(booth.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booth.status[0].toUpperCase() +
                        booth.status.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusText(booth.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(
                    icon: Icons.category_outlined, label: booth.type),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.straighten, label: booth.size),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.attach_money,
                    label: 'RM ${booth.price.toStringAsFixed(2)}'),
              ],
            ),
            if (booth.amenities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: booth.amenities.map((a) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9ECEF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${a.name}  RM ${a.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF495057)),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(color: Color(0xFFDEE2E6), height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      size: 15, color: Color(0xFF185FA5)),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF185FA5)),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 15, color: Color(0xFFDC3545)),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFFDC3545)),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Booth Form Sheet
// ─────────────────────────────────────────────────────────────────

class _BoothFormSheet extends StatefulWidget {
  final String exhibitionId;
  final BoothModel? booth;

  const _BoothFormSheet({required this.exhibitionId, this.booth});

  @override
  State<_BoothFormSheet> createState() => _BoothFormSheetState();
}

class _BoothFormSheetState extends State<_BoothFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _priceController = TextEditingController();
  final _positionXController = TextEditingController(text: '0');
  final _positionYController = TextEditingController(text: '0');
  final _widthController = TextEditingController(text: '80');
  final _heightController = TextEditingController(text: '80');
  final _amenityNameController = TextEditingController();
  final _amenityPriceController = TextEditingController();
  final List<BoothAmenity> _amenities = [];

  String _type = 'Standard';
  String _size = 'Small (3x3m)';
  bool _isSubmitting = false;
  bool get _isEdit => widget.booth != null;

  final List<String> _types = ['Standard', 'Premium', 'Corner', 'Island'];
  final List<String> _sizes = [
    'Small (3x3m)',
    'Medium (4x4m)',
    'Large (5x5m)',
    'Extra Large (6x6m)',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _numberController.text = widget.booth!.boothNumber;
      _priceController.text = widget.booth!.price.toString();
      _positionXController.text = widget.booth!.positionX.toString();
      _positionYController.text = widget.booth!.positionY.toString();
      _widthController.text = widget.booth!.width.toString();
      _heightController.text = widget.booth!.height.toString();
      _type = widget.booth!.type;
      _size = widget.booth!.size;
      _amenities.addAll(widget.booth!.amenities);
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _priceController.dispose();
    _positionXController.dispose();
    _positionYController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _amenityNameController.dispose();
    _amenityPriceController.dispose();
    super.dispose();
  }

  void _addAmenity() {
    final name = _amenityNameController.text.trim();
    final price = double.tryParse(_amenityPriceController.text.trim());
    if (name.isEmpty || price == null || price < 0) return;
    if (_amenities.any((a) => a.name.toLowerCase() == name.toLowerCase())) {
      return;
    }
    setState(() {
      _amenities.add(BoothAmenity(name: name, price: price));
      _amenityNameController.clear();
      _amenityPriceController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<OrganizerProvider>();
    bool success;

    final posX =
        double.tryParse(_positionXController.text.trim()) ?? 0;
    final posY =
        double.tryParse(_positionYController.text.trim()) ?? 0;
    final w = double.tryParse(_widthController.text.trim()) ?? 80;
    final h = double.tryParse(_heightController.text.trim()) ?? 80;

    if (_isEdit) {
      success = await provider.updateBooth(
        widget.booth!.id,
        {
          'boothNumber': _numberController.text.trim(),
          'type': _type,
          'size': _size,
          'price': double.tryParse(_priceController.text.trim()) ?? 0,
          'amenities': _amenities.map((a) => a.toMap()).toList(),
          'positionX': posX,
          'positionY': posY,
          'width': w,
          'height': h,
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
        amenities: _amenities.map((a) => a.toMap()).toList(),
        positionX: posX,
        positionY: posY,
        width: w,
        height: h,
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
              _label('Base Price (RM) *'),
              const SizedBox(height: 6),
              _field(
                controller: _priceController,
                hint: 'e.g. 1500.00',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Price is required';
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Position & Size
              _label('Position & Size'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _positionXController,
                      hint: 'X',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      controller: _positionYController,
                      hint: 'Y',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      controller: _widthController,
                      hint: 'W',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      controller: _heightController,
                      hint: 'H',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Amenities
              _label('Amenities'),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _field(
                      controller: _amenityNameController,
                      hint: 'Name e.g. WiFi',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _field(
                      controller: _amenityPriceController,
                      hint: 'Price RM',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addAmenity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                    ),
                    child: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
              if (_amenities.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._amenities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final amenity = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border:
                      Border.all(color: const Color(0xFFDEE2E6)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            amenity.name,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A1C1E)),
                          ),
                        ),
                        Text(
                          'RM ${amenity.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF185FA5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(
                                  () => _amenities.removeAt(index)),
                          child: const Icon(Icons.close,
                              size: 16, color: Color(0xFFDC3545)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
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
                    elevation: 0,
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w600),
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
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
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
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
        ),
      );
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF6C757D)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6C757D))),
      ],
    );
  }
}