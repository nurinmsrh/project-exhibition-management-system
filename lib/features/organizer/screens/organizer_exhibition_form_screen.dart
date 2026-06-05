// lib/features/organizer/screens/organizer_exhibition_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/organizer_provider.dart';
import '../../../data/models/exhibition_model.dart';

class OrganizerExhibitionFormScreen extends StatefulWidget {
  final String organizerId;
  final ExhibitionModel? exhibition; // null = create mode, non-null = edit mode

  const OrganizerExhibitionFormScreen({
    super.key,
    required this.organizerId,
    this.exhibition,
  });

  @override
  State<OrganizerExhibitionFormScreen> createState() =>
      _OrganizerExhibitionFormScreenState();
}

class _OrganizerExhibitionFormScreenState
    extends State<OrganizerExhibitionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _venueController;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.exhibition != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.exhibition?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.exhibition?.description ?? '');
    _venueController =
        TextEditingController(text: widget.exhibition?.venue ?? '');
    _startDate = widget.exhibition?.startDate;
    _endDate = widget.exhibition?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF185FA5),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date if it's before the new start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates.'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<OrganizerProvider>();
    bool success;

    if (_isEditMode) {
      success = await provider.updateExhibition(
        widget.exhibition!.id,
        {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'venue': _venueController.text.trim(),
          'startDate': _startDate!.toIso8601String(),
          'endDate': _endDate!.toIso8601String(),
        },
        widget.organizerId,
      );
    } else {
      success = await provider.createExhibition(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        venue: _venueController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        organizerId: widget.organizerId,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Exhibition updated successfully.'
                : 'Exhibition created successfully.',
          ),
          backgroundColor: const Color(0xFF1D9E75),
        ),
      );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          _isEditMode ? 'Edit Exhibition' : 'Create Exhibition',
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Title ---
              _buildLabel('Title *'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _titleController,
                hint: 'e.g. Tech Expo 2025',
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // --- Description ---
              _buildLabel('Description *'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Describe the exhibition...',
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Venue ---
              _buildLabel('Venue *'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _venueController,
                hint: 'e.g. KLCC Convention Centre',
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Venue is required' : null,
              ),
              const SizedBox(height: 16),

              // --- Date Pickers ---
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Start Date *'),
                        const SizedBox(height: 6),
                        _DatePickerField(
                          date: _startDate,
                          hint: 'Select date',
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('End Date *'),
                        const SizedBox(height: 6),
                        _DatePickerField(
                          date: _endDate,
                          hint: 'Select date',
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                height: 48,
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
                    _isEditMode ? 'Save Changes' : 'Create Exhibition',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1C1E),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF6C757D), fontSize: 14),
          filled: true,
          fillColor: Colors.white,
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );
}

// --- Date Picker Field Widget ---
class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.date,
    required this.hint,
    required this.onTap,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDEE2E6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Color(0xFF185FA5)),
            const SizedBox(width: 8),
            Text(
              date != null ? _fmt(date!) : hint,
              style: TextStyle(
                fontSize: 13,
                color: date != null
                    ? const Color(0xFF1A1C1E)
                    : const Color(0xFF6C757D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}