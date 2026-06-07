import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/booth_model.dart';

class AdminBoothFormScreen extends StatefulWidget {
  final String exhibitionId;
  final String? boothId;

  const AdminBoothFormScreen({
    super.key,
    required this.exhibitionId,
    this.boothId,
  });

  @override
  State<AdminBoothFormScreen> createState() => _AdminBoothFormScreenState();
}

class _AdminBoothFormScreenState extends State<AdminBoothFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _boothNumberController = TextEditingController();
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();
  final _positionXController = TextEditingController(text: '0');
  final _positionYController = TextEditingController(text: '0');
  final _widthController = TextEditingController(text: '50');
  final _heightController = TextEditingController(text: '50');
  final _descriptionController = TextEditingController();

  // Amenity input controllers
  final _amenityNameController = TextEditingController();
  final _amenityPriceController = TextEditingController();

  String _type = 'standard';
  String _status = 'available';
  final List<BoothAmenity> _amenities = [];
  bool _isLoading = false;
  BoothModel? _booth;

  @override
  void initState() {
    super.initState();
    if (widget.boothId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadBooth();
      });
    }
  }

  @override
  void dispose() {
    _boothNumberController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _positionXController.dispose();
    _positionYController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _descriptionController.dispose();
    _amenityNameController.dispose();
    _amenityPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadBooth() async {
    final provider = context.read<AdminProvider>();
    await provider.loadBooths(widget.exhibitionId);
    try {
      _booth = provider.booths.firstWhere((b) => b.id == widget.boothId);
      _boothNumberController.text = _booth!.boothNumber;
      _sizeController.text = _booth!.size;
      _priceController.text = _booth!.price.toString();
      _positionXController.text = _booth!.positionX.toString();
      _positionYController.text = _booth!.positionY.toString();
      _widthController.text = _booth!.width.toString();
      _heightController.text = _booth!.height.toString();
      _descriptionController.text = _booth!.description;
      _type = _booth!.type;
      _status = _booth!.status;
      _amenities.addAll(_booth!.amenities);
      setState(() {});
    } catch (e) {
      // Booth not found
    }
  }

  void _addAmenity() {
    final name = _amenityNameController.text.trim();
    final price = double.tryParse(_amenityPriceController.text.trim());
    if (name.isEmpty || price == null || price < 0) return;
    if (_amenities.any((a) => a.name.toLowerCase() == name.toLowerCase())) return;
    setState(() {
      _amenities.add(BoothAmenity(name: name, price: price));
      _amenityNameController.clear();
      _amenityPriceController.clear();
    });

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amenity name'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
      return;
    }
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
      return;
    }
    // Check duplicate
    if (_amenities.any((a) => a.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amenity already added'),
          backgroundColor: Color(0xFFEF9F27),
        ),
      );
      return;
    }

    setState(() {
      _amenities.add(BoothAmenity(name: name, price: price));
      _amenityNameController.clear();
      _amenityPriceController.clear();
    });
  }

  void _removeAmenity(int index) {
    setState(() => _amenities.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final posX = double.tryParse(_positionXController.text.trim()) ?? 0;
    final posY = double.tryParse(_positionYController.text.trim()) ?? 0;
    final w = double.tryParse(_widthController.text.trim()) ?? 50;
    final h = double.tryParse(_heightController.text.trim()) ?? 50;

    setState(() => _isLoading = true);

    final provider = context.read<AdminProvider>();
    await provider.loadBooths(widget.exhibitionId);

    final conflict = provider.booths.any((b) {
      if (b.id == widget.boothId) return false;
      return b.positionX == posX && b.positionY == posY;
    });

    if (conflict) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'A booth already exists at this position. Please choose different coordinates.'),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
      }
      return;
    }

    bool success;

    if (widget.boothId == null) {
      success = await provider.createBooth(
        exhibitionId: widget.exhibitionId,
        boothNumber: _boothNumberController.text.trim(),
        type: _type,
        size: _sizeController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        amenities: _amenities.map((a) => a.toMap()).toList(),
        positionX: posX,
        positionY: posY,
        width: w,
        height: h,
      );
    } else {
      success = await provider.updateBooth(
        widget.boothId!,
        {
          'boothNumber': _boothNumberController.text.trim(),
          'type': _type,
          'size': _sizeController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0,
          'amenities': _amenities.map((a) => a.toMap()).toList(),
          'positionX': posX,
          'positionY': posY,
          'width': w,
          'height': h,
          'status': _status,
          'description': _descriptionController.text.trim(),
        },
        widget.exhibitionId,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.boothId == null
              ? 'Booth created successfully'
              : 'Booth updated successfully'),
          backgroundColor: const Color(0xFF1D9E75),
        ),
      );
      context.go('/admin/exhibitions/${widget.exhibitionId}/booths');
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
    final isEdit = widget.boothId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          isEdit ? 'Edit Booth' : 'Create Booth',
          style: const TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF185FA5)),
          onPressed: () => context
              .go('/admin/exhibitions/${widget.exhibitionId}/booths'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Booth Details ───────────────────────────────────
              const _SectionHeader(title: 'Booth Details'),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  children: [
                    _Field(
                      controller: _boothNumberController,
                      label: 'Booth Number',
                      hint: 'e.g. A1, B2',
                      icon: Icons.tag,
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    // Type dropdown
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: _dropdownDecoration('Type'),
                      items: ['standard', 'premium', 'corner', 'island']
                          .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                            t[0].toUpperCase() + t.substring(1)),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _sizeController,
                      label: 'Size',
                      hint: 'e.g. 3x3m',
                      icon: Icons.straighten,
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _priceController,
                      label: 'Base Price (RM)',
                      hint: 'e.g. 500',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _descriptionController,
                      label: 'Description (optional)',
                      hint: 'Additional details about this booth',
                      icon: Icons.notes,
                      maxLines: 2,
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: _dropdownDecoration('Status'),
                        items: ['available', 'unavailable']
                            .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                              s[0].toUpperCase() + s.substring(1)),
                        ))
                            .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Position & Size ─────────────────────────────────
              const _SectionHeader(title: 'Floor Plan Position & Size'),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: _positionXController,
                            label: 'Position X',
                            hint: '0',
                            icon: Icons.swap_horiz,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            controller: _positionYController,
                            label: 'Position Y',
                            hint: '0',
                            icon: Icons.swap_vert,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: _widthController,
                            label: 'Width (px)',
                            hint: '50',
                            icon: Icons.width_normal,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            controller: _heightController,
                            label: 'Height (px)',
                            hint: '50',
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Amenities ───────────────────────────────────────
              const _SectionHeader(title: 'Amenities'),
              const SizedBox(height: 4),
              const Text(
                'Add amenities with their individual prices',
                style: TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
              ),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _Field(
                            controller: _amenityNameController,
                            label: 'Amenity Name',
                            hint: 'e.g. WiFi',
                            icon: Icons.star_outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _Field(
                            controller: _amenityPriceController,
                            label: 'Price (RM)',
                            hint: 'e.g. 20',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ElevatedButton(
                            onPressed: _addAmenity,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF185FA5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                            ),
                            child: const Icon(Icons.add, size: 18),
                          ),
                        ),
                      ],
                    ),
                    if (_amenities.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFDEE2E6), height: 1),
                      const SizedBox(height: 10),
                      // Amenity list
                      ..._amenities.asMap().entries.map((entry) {
                        final index = entry.key;
                        final amenity = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                            border:
                            Border.all(color: const Color(0xFFDEE2E6)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 14, color: Color(0xFF185FA5)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  amenity.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1C1E),
                                  ),
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
                                onTap: () => _removeAmenity(index),
                                child: const Icon(Icons.close,
                                    size: 16, color: Color(0xFFDC3545)),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      // Total amenity price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total amenity price',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF6C757D)),
                          ),
                          Text(
                            'RM ${_amenities.fold(0.0, (sum, a) => sum + a.price).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1C1E),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No amenities added yet',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF6C757D)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Save Button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    const Color(0xFF185FA5).withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    isEdit ? 'Save Changes' : 'Create Booth',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
      const TextStyle(fontSize: 13, color: Color(0xFF6C757D)),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1C1E),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: child,
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1C1E)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle:
        const TextStyle(fontSize: 13, color: Color(0xFF6C757D)),
        labelStyle:
        const TextStyle(fontSize: 13, color: Color(0xFF6C757D)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF6C757D)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDC3545)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDC3545)),
        ),
      ),
    );
  }
}