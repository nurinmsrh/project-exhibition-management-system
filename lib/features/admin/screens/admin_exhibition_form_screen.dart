import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/exhibition_model.dart';

class AdminExhibitionFormScreen extends StatefulWidget {
  final String? exhibitionId;

  const AdminExhibitionFormScreen({super.key, this.exhibitionId});

  @override
  State<AdminExhibitionFormScreen> createState() =>
      _AdminExhibitionFormScreenState();
}

class _AdminExhibitionFormScreenState
    extends State<AdminExhibitionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  ExhibitionModel? _exhibition;

  @override
  void initState() {
    super.initState();
    if (widget.exhibitionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadExhibition();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _loadExhibition() async {
    final provider = context.read<AdminProvider>();
    await provider.loadExhibitions();
    try {
      _exhibition = provider.exhibitions.firstWhere(
            (e) => e.id == widget.exhibitionId,
      );
      _titleController.text = _exhibition!.title;
      _descriptionController.text = _exhibition!.description;
      _venueController.text = _exhibition!.venue;
      _startDate = _exhibition!.startDate;
      _endDate = _exhibition!.endDate;
      setState(() {});
    } catch (e) {
      // Exhibition not found
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF185FA5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1C1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<AdminProvider>();
    bool success;

    if (widget.exhibitionId == null) {
      success = await provider.createExhibition(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        venue: _venueController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        organizerId: 'admin',
      );
    } else {
      success = await provider.updateExhibition(
        widget.exhibitionId!,
        {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'venue': _venueController.text.trim(),
          'startDate': _startDate,
          'endDate': _endDate,
        },
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.exhibitionId == null
              ? 'Exhibition created!'
              : 'Exhibition updated!'),
          backgroundColor: const Color(0xFF1D9E75),
        ),
      );
      context.go('/admin/exhibitions');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
      const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
      prefixIcon:
      Icon(icon, size: 18, color: const Color(0xFF6C757D)),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
        borderSide:
        const BorderSide(color: Color(0xFF185FA5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDC3545)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
            color: Color(0xFFDC3545), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6C757D),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.exhibitionId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: Color(0xFF185FA5)),
          onPressed: () => context.go('/admin/exhibitions'),
        ),
        title: Text(
          isEditing ? 'Edit Exhibition' : 'Create Exhibition',
          style: const TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: Color(0xFF6C757D)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEditing
                            ? 'Update the details of this exhibition event.'
                            : 'Fill in the details to create a new exhibition event.',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C757D)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Exhibition details card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: const Color(0xFFDEE2E6)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exhibition Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Exhibition Title'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'e.g. Tech Innovators Expo 2025',
                        icon: Icons.event_outlined,
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Description'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'Describe the exhibition...',
                        icon: Icons.description_outlined,
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Venue'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _venueController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'e.g. Kuala Lumpur Convention Centre',
                        icon: Icons.location_on_outlined,
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Venue is required'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dates card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: const Color(0xFFDEE2E6)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Duration',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Start Date'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _pickDate(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFDEE2E6)),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: Color(0xFF6C757D)),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(_startDate),
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1A1C1E)),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right,
                                size: 18,
                                color: Color(0xFF6C757D)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('End Date'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _pickDate(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFDEE2E6)),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: Color(0xFF6C757D)),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(_endDate),
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1A1C1E)),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right,
                                size: 18,
                                color: Color(0xFF6C757D)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    const Color(0xFF185FA5).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    isEditing
                        ? 'Save Changes'
                        : 'Create Exhibition',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}