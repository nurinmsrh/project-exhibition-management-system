import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exhibitor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/models/exhibition_model.dart';
import 'my_applications_screen.dart';

class ApplicationFormScreen extends StatefulWidget {
  final ExhibitionModel exhibition;

  const ApplicationFormScreen({super.key, required this.exhibition});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyDescController = TextEditingController();
  final _exhibitDescController = TextEditingController();
  final List<String> _selectedAdditems = [];

  final List<String> _availableAdditems = [
    'Extra Furniture',
    'Promotional Spot',
    'Extended WiFi',
    'Extra Power Outlets',
    'Display Screen',
    'Storage Space',
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescController.dispose();
    _exhibitDescController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ExhibitorProvider>();
    final authProvider = context.read<AuthProvider>();

    final success = await provider.submitApplication(
      exhibitorId: authProvider.currentUser!.uid,
      exhibitionId: widget.exhibition.id,
      companyName: _companyNameController.text.trim(),
      companyDescription: _companyDescController.text.trim(),
      exhibitDescription: _exhibitDescController.text.trim(),
      additems: List<String>.from(_selectedAdditems),
    );

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.actionError),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF1D9E75), size: 22),
            SizedBox(width: 8),
            Text(
              'Application Submitted!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1C1E),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your application is now pending review. '
              'You will be notified once the organizer reviews it.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Pop dialog
              Navigator.pop(context);
              // Navigate to My Applications, clearing back stack to home
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => ExhibitorProvider(),
                    child: const MyApplicationsScreen(),
                  ),
                ),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF185FA5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('View My Applications'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExhibitorProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Application Form',
          style: TextStyle(
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Exhibition Info ─────────────────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exhibition',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C757D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.exhibition.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Color(0xFF6C757D)),
                        const SizedBox(width: 4),
                        Text(
                          widget.exhibition.venue,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6C757D)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Selected Booths Summary ─────────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Selected Booths',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          '${provider.selectedBooths.length} booth${provider.selectedBooths.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6C757D)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.selectedBooths.map((booth) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCE5FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            booth.boothNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF004085),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFDEE2E6), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Price',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          'RM ${provider.totalSelectedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF185FA5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Company Information ─────────────────────────────
              const _SectionHeader(title: 'Company Information'),
              const SizedBox(height: 10),
              _SectionCard(
                child: Column(
                  children: [
                    _FormField(
                      controller: _companyNameController,
                      label: 'Company Name',
                      hint: 'Enter your company name',
                      icon: Icons.business_outlined,
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: _companyDescController,
                      label: 'Company Description',
                      hint: 'Briefly describe your company',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Exhibit Information ─────────────────────────────
              const _SectionHeader(title: 'Exhibit Information'),
              const SizedBox(height: 10),
              _SectionCard(
                child: _FormField(
                  controller: _exhibitDescController,
                  label: 'What will you showcase?',
                  hint: 'Describe what you plan to exhibit',
                  icon: Icons.storefront_outlined,
                  maxLines: 3,
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 20),

              // ── Additional Items ────────────────────────────────
              const _SectionHeader(title: 'Additional Items'),
              const SizedBox(height: 4),
              const Text(
                'Select any extra items you need (optional)',
                style: TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableAdditems.map((item) {
                    final isSelected = _selectedAdditems.contains(item);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedAdditems.remove(item);
                          } else {
                            _selectedAdditems.add(item);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              item,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6C757D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit Button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isSubmitting ? null : _submit,
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
                  child: provider.isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Submit Application',
                    style: TextStyle(
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

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
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