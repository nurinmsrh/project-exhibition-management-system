import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exhibitor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/services/booth_service.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final ApplicationModel application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  // Local mutable copy of application so UI reflects saves
  late ApplicationModel _application;

  // Edit controllers
  late final TextEditingController _companyNameController;
  late final TextEditingController _companyDescController;
  late final TextEditingController _exhibitDescController;

  // Amenity selection for edit mode
  late List<String> _selectedAmenityNames;

  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Booths resolved from boothIds
  final BoothService _boothService = BoothService();
  List<BoothModel> _resolvedBooths = [];
  bool _isLoadingBooths = true;

  // Available amenities derived from resolved booths
  List<BoothAmenity> get _availableAmenities {
    final Map<String, BoothAmenity> unique = {};
    for (final booth in _resolvedBooths) {
      for (final amenity in booth.amenities) {
        unique[amenity.name] = amenity;
      }
    }
    return unique.values.toList();
  }

  @override
  void initState() {
    super.initState();
    _application = widget.application;
    _companyNameController =
        TextEditingController(text: _application.companyName);
    _companyDescController =
        TextEditingController(text: _application.companyDescription);
    _exhibitDescController =
        TextEditingController(text: _application.exhibitDescription);
    _selectedAmenityNames = List<String>.from(_application.additems);
    _loadBooths();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescController.dispose();
    _exhibitDescController.dispose();
    super.dispose();
  }

  Future<void> _loadBooths() async {
    try {
      final allBooths = await _boothService
          .getBoothsByExhibition(_application.exhibitionId);

      final resolved = _application.boothIds.map((id) {
        return allBooths.firstWhere(
              (b) => b.id == id,
          orElse: () => BoothModel(
            id: id,
            exhibitionId: _application.exhibitionId,
            boothNumber: id,
            type: '',
            price: 0,
          ),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _resolvedBooths = resolved;
          _isLoadingBooths = false;

          // If boothsPrice was never saved (old data), calculate it now
          // from resolved booth data so price summary shows correctly
          if (_application.boothsPrice == 0 && resolved.isNotEmpty) {
            final calculatedBoothsPrice =
            resolved.fold(0.0, (sum, b) => sum + b.price);

            // Recalculate amenities price from current additems
            double calculatedAmenitiesPrice = 0;
            final amenityMap = {
              for (final b in resolved)
                for (final a in b.amenities) a.name: a.price
            };
            for (final name in _application.additems) {
              calculatedAmenitiesPrice += amenityMap[name] ?? 0;
            }

            _application = ApplicationModel(
              id: _application.id,
              exhibitorId: _application.exhibitorId,
              exhibitionId: _application.exhibitionId,
              boothIds: _application.boothIds,
              companyName: _application.companyName,
              companyDescription: _application.companyDescription,
              exhibitDescription: _application.exhibitDescription,
              additems: _application.additems,
              status: _application.status,
              rejectionReason: _application.rejectionReason,
              createdAt: _application.createdAt,
              boothsPrice: calculatedBoothsPrice,
              amenitiesPrice: calculatedAmenitiesPrice,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBooths = false);
    }
  }

  // ── Save edits ────────────────────────────────────────────────
  Future<void> _saveEdits() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ExhibitorProvider>();

    // Recalculate amenities price based on new selection
    double newAmenitiesPrice = 0;
    for (final amenity in _availableAmenities) {
      if (_selectedAmenityNames.contains(amenity.name)) {
        newAmenitiesPrice += amenity.price;
      }
    }

    final updatedData = {
      'companyName': _companyNameController.text.trim(),
      'companyDescription': _companyDescController.text.trim(),
      'exhibitDescription': _exhibitDescController.text.trim(),
      'additems': _selectedAmenityNames,
      'amenitiesPrice': newAmenitiesPrice, // update stored price
    };

    final success = await provider.updateApplication(
        _application.id, updatedData);

    if (!mounted) return;

    if (success) {
      setState(() {
        _application = ApplicationModel(
          id: _application.id,
          exhibitorId: _application.exhibitorId,
          exhibitionId: _application.exhibitionId,
          boothIds: _application.boothIds,
          companyName: _companyNameController.text.trim(),
          companyDescription: _companyDescController.text.trim(),
          exhibitDescription: _exhibitDescController.text.trim(),
          additems: List<String>.from(_selectedAmenityNames),
          status: _application.status,
          rejectionReason: _application.rejectionReason,
          createdAt: _application.createdAt,
          boothsPrice: _application.boothsPrice,
          amenitiesPrice: newAmenitiesPrice, // use recalculated price
        );
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application updated successfully'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.actionError),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    }
  }

  // ── Cancel application ────────────────────────────────────────
  Future<void> _cancelApplication() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Cancel Application',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1C1E),
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this application? '
              'This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Application',
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
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<ExhibitorProvider>();
    final uid = context.read<AuthProvider>().currentUser!.uid;

    final success =
    await provider.cancelApplication(_application.id, uid);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application cancelled'),
          backgroundColor: Color(0xFF6C757D),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.actionError),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    }
  }

  // ── Discard edits ─────────────────────────────────────────────
  void _discardEdits() {
    setState(() {
      _companyNameController.text = _application.companyName;
      _companyDescController.text = _application.companyDescription;
      _exhibitDescController.text = _application.exhibitDescription;
      _selectedAmenityNames = List<String>.from(_application.additems);
      _isEditing = false;
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  Color _statusBg(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFF3CD);
      case 'approved':
        return const Color(0xFFD4EDDA);
      case 'rejected':
        return const Color(0xFFFCEBEB);
      case 'cancelled':
        return const Color(0xFFE9ECEF);
      default:
        return const Color(0xFFE9ECEF);
    }
  }

  Color _statusText(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF856404);
      case 'approved':
        return const Color(0xFF155724);
      case 'rejected':
        return const Color(0xFF721C24);
      case 'cancelled':
        return const Color(0xFF495057);
      default:
        return const Color(0xFF495057);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty_outlined;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.block_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Awaiting organizer review';
      case 'approved':
        return 'Your booth has been confirmed';
      case 'rejected':
        return 'Your application was not accepted';
      case 'cancelled':
        return 'This application has been cancelled';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExhibitorProvider>();
    final status = _application.status;
    final isPending = status == 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Application Detail',
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
        actions: [
          if (isPending && !_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Color(0xFF185FA5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _discardEdits,
              child: const Text(
                'Discard',
                style: TextStyle(
                  color: Color(0xFF6C757D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status Banner ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon(status),
                        size: 18, color: _statusText(status)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _statusText(status),
                          ),
                        ),
                        Text(
                          _statusDescription(status),
                          style: TextStyle(
                              fontSize: 12, color: _statusText(status)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Rejection reason
              if (status == 'rejected' &&
                  _application.rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                        const Color(0xFFDC3545).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejection Reason',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF721C24),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _application.rejectionReason,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF721C24)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Booths Applied ────────────────────────────────
              // ── Booths Applied ────────────────────────────────────────
              const _SectionHeader(title: 'Booths Applied'),
              const SizedBox(height: 10),
              _InfoCard(
                child: _isLoadingBooths
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(
                        color: Color(0xFF185FA5)),
                  ),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store_outlined,
                            size: 15, color: Color(0xFF6C757D)),
                        const SizedBox(width: 6),
                        Text(
                          '${_resolvedBooths.length} booth${_resolvedBooths.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1C1E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _resolvedBooths.map((booth) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9ECEF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Booth ${booth.boothNumber}  RM ${booth.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF495057),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Color(0xFFDEE2E6), height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Submitted',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF6C757D))),
                        Text(
                          _formatDate(_application.createdAt),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1C1E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

// ── Price Summary (frozen snapshot) ──────────────────────
              const _SectionHeader(title: 'Price Summary'),
              const SizedBox(height: 10),
              _InfoCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Booth(s) subtotal',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF6C757D))),
                        Text(
                          'RM ${_application.boothsPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF1A1C1E)),
                        ),
                      ],
                    ),
                    if (_application.amenitiesPrice > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amenities subtotal',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF6C757D))),
                          Text(
                            'RM ${_application.amenitiesPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1A1C1E)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFDEE2E6), height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Paid',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          'RM ${_application.totalPrice.toStringAsFixed(2)}',
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

              // ── Company Information ───────────────────────────
              const _SectionHeader(title: 'Company Information'),
              const SizedBox(height: 10),
              _InfoCard(
                child: Column(
                  children: [
                    _isEditing
                        ? _EditField(
                      controller: _companyNameController,
                      label: 'Company Name',
                      icon: Icons.business_outlined,
                      validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Required'
                          : null,
                    )
                        : _ReadOnlyRow(
                      label: 'Company Name',
                      value: _application.companyName,
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                        color: Color(0xFFDEE2E6), height: 1),
                    const SizedBox(height: 12),
                    _isEditing
                        ? _EditField(
                      controller: _companyDescController,
                      label: 'Company Description',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Required'
                          : null,
                    )
                        : _ReadOnlyRow(
                      label: 'Company Description',
                      value: _application.companyDescription,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Exhibit Information ───────────────────────────
              const _SectionHeader(title: 'Exhibit Information'),
              const SizedBox(height: 10),
              _InfoCard(
                child: _isEditing
                    ? _EditField(
                  controller: _exhibitDescController,
                  label: 'What will you showcase?',
                  icon: Icons.storefront_outlined,
                  maxLines: 3,
                  validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? 'Required'
                      : null,
                )
                    : _ReadOnlyRow(
                  label: 'Exhibit Description',
                  value: _application.exhibitDescription,
                ),
              ),
              const SizedBox(height: 20),

              // ── Amenities ─────────────────────────────────────
              const _SectionHeader(title: 'Amenities'),
              const SizedBox(height: 10),
              _InfoCard(
                child: _isLoadingBooths
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(
                        color: Color(0xFF185FA5)),
                  ),
                )
                    : _isEditing
                // Edit mode — show all available amenities as checkboxes
                    ? _availableAmenities.isEmpty
                    ? const Text(
                  'No amenities available for these booths.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6C757D)),
                )
                    : Column(
                  children: _availableAmenities.map((amenity) {
                    final isSelected = _selectedAmenityNames
                        .contains(amenity.name);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedAmenityNames
                                .remove(amenity.name);
                          } else {
                            _selectedAmenityNames
                                .add(amenity.name);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                            bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFCCE5FF)
                              : const Color(0xFFF8F9FA),
                          borderRadius:
                          BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF185FA5)
                                : const Color(0xFFDEE2E6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_box
                                  : Icons
                                  .check_box_outline_blank,
                              size: 18,
                              color: isSelected
                                  ? const Color(0xFF185FA5)
                                  : const Color(0xFF6C757D),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                amenity.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? const Color(
                                      0xFF004085)
                                      : const Color(
                                      0xFF1A1C1E),
                                ),
                              ),
                            ),
                            Text(
                              '+ RM ${amenity.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF185FA5)
                                    : const Color(0xFF6C757D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )
                // View mode — show only selected amenities
                    : _application.additems.isEmpty
                    ? const Text(
                  'No amenities requested',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6C757D)),
                )
                    : Column(
                  children: _application.additems.map((name) {
                    // Try to find price from resolved booths
                    final amenity =
                    _availableAmenities.firstWhere(
                          (a) => a.name == name,
                      orElse: () =>
                          BoothAmenity(name: name, price: 0),
                    );
                    return Container(
                      margin:
                      const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCE5FF),
                        borderRadius:
                        BorderRadius.circular(8),
                        border: Border.all(
                            color:
                            const Color(0xFF185FA5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box,
                              size: 18,
                              color: Color(0xFF185FA5)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF004085),
                              ),
                            ),
                          ),
                          if (amenity.price > 0)
                            Text(
                              'RM ${amenity.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF185FA5),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // ── Action Buttons ────────────────────────────────
              if (_isEditing) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                    provider.isSubmitting ? null : _saveEdits,
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
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else if (isPending || status == 'approved') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: provider.isSubmitting
                        ? null
                        : _cancelApplication,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC3545),
                      side: const BorderSide(color: Color(0xFFDC3545)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: provider.isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Color(0xFFDC3545), strokeWidth: 2),
                    )
                        : Text(
                        isPending
                            ? 'Cancel Application'
                            : 'Cancel Booking',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
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

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

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

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6C757D))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF1A1C1E))),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _EditField({
    required this.controller,
    required this.label,
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
        labelStyle:
        const TextStyle(fontSize: 13, color: Color(0xFF6C757D)),
        prefixIcon:
        Icon(icon, size: 18, color: const Color(0xFF6C757D)),
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