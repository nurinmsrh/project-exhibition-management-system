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
  State<AdminBoothFormScreen> createState() =>
      _AdminBoothFormScreenState();
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
  String _type = 'standard';
  String _status = 'available';
  final List<String> _selectedAmenities = [];
  bool _isLoading = false;
  BoothModel? _booth;

  final List<String> _availableAmenities = [
    'wifi',
    'power',
    'water',
    'storage',
    'lighting',
  ];

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
    super.dispose();
  }

  Future<void> _loadBooth() async {
    final provider = context.read<AdminProvider>();
    await provider.loadBooths(widget.exhibitionId); // load from backend first
    try {
      _booth = provider.booths.firstWhere(
            (b) => b.id == widget.boothId,
      );
      _boothNumberController.text = _booth!.boothNumber;
      _sizeController.text = _booth!.size;
      _priceController.text = _booth!.price.toString();
      _positionXController.text = _booth!.positionX.toString();
      _positionYController.text = _booth!.positionY.toString();
      _widthController.text = _booth!.width.toString();
      _heightController.text = _booth!.height.toString();
      _type = _booth!.type;
      _status = _booth!.status;
      _selectedAmenities.addAll(_booth!.amenities);
      setState(() {});
    } catch (e) {
      // Booth not found
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final posX =
        double.tryParse(_positionXController.text.trim()) ?? 0;
    final posY =
        double.tryParse(_positionYController.text.trim()) ?? 0;
    final w =
        double.tryParse(_widthController.text.trim()) ?? 50;
    final h =
        double.tryParse(_heightController.text.trim()) ?? 50;

    setState(() => _isLoading = true);

    // Always reload fresh booths before checking
    final provider = context.read<AdminProvider>();
    await provider.loadBooths(widget.exhibitionId);

    // Check for exact position conflict
    final conflict = provider.booths.any((b) {
      if (b.id == widget.boothId) return false; // skip self
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
        amenities: _selectedAmenities,
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
          'price':
          double.tryParse(_priceController.text.trim()) ?? 0,
          'amenities': _selectedAmenities,
          'positionX': posX,
          'positionY': posY,
          'width': w,
          'height': h,
          'status': _status,
        },
        widget.exhibitionId,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.boothId == null
              ? 'Booth created!'
              : 'Booth updated!'),
          backgroundColor: const Color(0xFF1D9E75),
        ),
      );
      context.go(
          '/admin/exhibitions/${widget.exhibitionId}/booths');
    } else if (mounted) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.boothId == null ? 'Create Booth' : 'Edit Booth'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(
              '/admin/exhibitions/${widget.exhibitionId}/booths'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _boothNumberController,
                decoration: const InputDecoration(
                  labelText: 'Booth Number (e.g. A-01)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Booth Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ['standard', 'premium']
                    .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.toUpperCase()),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sizeController,
                decoration: const InputDecoration(
                  labelText: 'Size (e.g. 20sqm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.square_foot),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (widget.boothId != null) ...[
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info),
                  ),
                  items: ['available', 'booked', 'unavailable']
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.toUpperCase()),
                  ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _status = value!),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Floor Plan Position',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set X, Y coordinates and size on the floor plan',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _positionXController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Position X',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _positionYController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Position Y',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Width',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Amenities',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAmenities
                    .map((item) => FilterChip(
                  label: Text(item.toUpperCase()),
                  selected: _selectedAmenities.contains(item),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenities.add(item);
                      } else {
                        _selectedAmenities.remove(item);
                      }
                    });
                  },
                  selectedColor: Colors.deepPurple,
                  labelStyle: TextStyle(
                    color: _selectedAmenities.contains(item)
                        ? Colors.white
                        : Colors.black,
                  ),
                ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : Text(
                    widget.boothId == null
                        ? 'Create Booth'
                        : 'Save Changes',
                    style: const TextStyle(fontSize: 16),
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
}