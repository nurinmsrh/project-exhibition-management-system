import 'package:flutter/material.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/models/application_model.dart';
import '../../../data/services/exhibition_service.dart';
import '../../../data/services/booth_service.dart';
import '../../../data/services/application_service.dart';

class ExhibitorProvider extends ChangeNotifier {
  final ExhibitionService _exhibitionService = ExhibitionService();
  final BoothService _boothService = BoothService();
  final ApplicationService _applicationService = ApplicationService();

  // ─── Exhibitions ───────────────────────────────────────────────
  List<ExhibitionModel> _exhibitions = [];
  List<ExhibitionModel> _filteredExhibitions = [];
  bool _isLoadingExhibitions = false;
  String _exhibitionsError = '';

  List<ExhibitionModel> get exhibitions => _filteredExhibitions;
  bool get isLoadingExhibitions => _isLoadingExhibitions;
  String get exhibitionsError => _exhibitionsError;

  // ─── Booths ────────────────────────────────────────────────────
  List<BoothModel> _booths = [];
  bool _isLoadingBooths = false;
  String _boothsError = '';

  List<BoothModel> get booths => _booths;
  bool get isLoadingBooths => _isLoadingBooths;
  String get boothsError => _boothsError;

  // ─── Booth selection ───────────────────────────────────────────
  final List<BoothModel> _selectedBooths = [];
  List<BoothModel> get selectedBooths => List.unmodifiable(_selectedBooths);
  List<String> get selectedBoothIds =>
      _selectedBooths.map((b) => b.id).toList();

  // ─── Selected amenities ────────────────────────────────────────
  // Stores amenity names the exhibitor opted into
  final List<String> _selectedAmenityNames = [];
  List<String> get selectedAmenityNames =>
      List.unmodifiable(_selectedAmenityNames);

  /// Unique amenities across all selected booths (with prices)
  List<BoothAmenity> get selectedBoothsAmenities {
    final Map<String, BoothAmenity> unique = {};
    for (final booth in _selectedBooths) {
      for (final amenity in booth.amenities) {
        unique[amenity.name] = amenity;
      }
    }
    return unique.values.toList();
  }

  /// Total price of selected amenities
  double get selectedAmenitiesPrice {
    double total = 0;
    for (final amenity in selectedBoothsAmenities) {
      if (_selectedAmenityNames.contains(amenity.name)) {
        total += amenity.price;
      }
    }
    return total;
  }

  /// Base price of selected booths only
  double get selectedBoothsBasePrice =>
      _selectedBooths.fold(0.0, (sum, b) => sum + b.price);

  /// Grand total = booth base prices + selected amenity prices
  double get totalSelectedPrice =>
      selectedBoothsBasePrice + selectedAmenitiesPrice;

  // ─── My Applications ───────────────────────────────────────────
  List<ApplicationModel> _applications = [];
  bool _isLoadingApplications = false;
  String _applicationsError = '';

  List<ApplicationModel> get applications => _applications;
  bool get isLoadingApplications => _isLoadingApplications;
  String get applicationsError => _applicationsError;

  // ─── Action state ──────────────────────────────────────────────
  bool _isSubmitting = false;
  String _actionError = '';
  String _actionSuccess = '';

  bool get isSubmitting => _isSubmitting;
  String get actionError => _actionError;
  String get actionSuccess => _actionSuccess;

  // ─── Search & filter ───────────────────────────────────────────
  String _searchQuery = '';
  String _statusFilter = 'all';

  // ══════════════════════════════════════════════════════════════════
  // LOAD METHODS
  // ══════════════════════════════════════════════════════════════════

  Future<void> loadExhibitions() async {
    _isLoadingExhibitions = true;
    _exhibitionsError = '';
    notifyListeners();

    try {
      _exhibitions = await _exhibitionService.getPublishedExhibitions();
      _applyFilters();
    } catch (e) {
      _exhibitionsError = e.toString();
    }

    _isLoadingExhibitions = false;
    notifyListeners();
  }

  Future<void> loadBoothsForExhibition(String exhibitionId) async {
    _isLoadingBooths = true;
    _boothsError = '';
    _booths = [];
    _selectedBooths.clear();
    _selectedAmenityNames.clear();
    notifyListeners();

    try {
      _booths = await _boothService.getBoothsByExhibition(exhibitionId);
    } catch (e) {
      _boothsError = e.toString();
    }

    _isLoadingBooths = false;
    notifyListeners();
  }

  Future<void> loadApplications(String exhibitorId) async {
    _isLoadingApplications = true;
    _applicationsError = '';
    notifyListeners();

    try {
      _applications =
      await _applicationService.getExhibitorApplications(exhibitorId);
    } catch (e) {
      _applicationsError = e.toString();
    }

    _isLoadingApplications = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  // SEARCH & FILTER
  // ══════════════════════════════════════════════════════════════════

  void searchExhibitions(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByStatus(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredExhibitions = _exhibitions.where((e) {
      final matchesSearch =
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.venue.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _statusFilter == 'all' || e.computedStatus == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  // ══════════════════════════════════════════════════════════════════
  // BOOTH SELECTION
  // ══════════════════════════════════════════════════════════════════

  void toggleBoothSelection(BoothModel booth) {
    if (booth.status != 'available') return;
    final idx = _selectedBooths.indexWhere((b) => b.id == booth.id);
    if (idx >= 0) {
      _selectedBooths.removeAt(idx);
      // Remove amenities that no longer belong to any selected booth
      _cleanUpAmenities();
    } else {
      _selectedBooths.add(booth);
    }
    notifyListeners();
  }

  bool isBoothSelected(String boothId) =>
      _selectedBooths.any((b) => b.id == boothId);

  void clearSelectedBooths() {
    _selectedBooths.clear();
    _selectedAmenityNames.clear();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  // AMENITY SELECTION
  // ══════════════════════════════════════════════════════════════════

  void toggleAmenitySelection(String amenityName) {
    if (_selectedAmenityNames.contains(amenityName)) {
      _selectedAmenityNames.remove(amenityName);
    } else {
      _selectedAmenityNames.add(amenityName);
    }
    notifyListeners();
  }

  bool isAmenitySelected(String amenityName) =>
      _selectedAmenityNames.contains(amenityName);

  /// Remove selected amenities that no longer exist in any selected booth
  void _cleanUpAmenities() {
    final available = selectedBoothsAmenities.map((a) => a.name).toSet();
    _selectedAmenityNames.removeWhere((name) => !available.contains(name));
  }

  // ══════════════════════════════════════════════════════════════════
  // BOOTH COLOR
  // ══════════════════════════════════════════════════════════════════

  Color boothColor(BoothModel booth) {
    if (isBoothSelected(booth.id)) return const Color(0xFF185FA5);
    switch (booth.status) {
      case 'available':
        return const Color(0xFF1D9E75);
      case 'booked':
      case 'reserved':
      case 'unavailable':
      default:
        return const Color(0xFFDC3545);
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════════════

  Future<bool> submitApplication({
    required String exhibitorId,
    required String exhibitionId,
    required String companyName,
    required String companyDescription,
    required String exhibitDescription,
  }) async {
    if (_selectedBooths.isEmpty) {
      _actionError = 'Please select at least one booth.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _actionError = '';
    _actionSuccess = '';
    notifyListeners();

    try {
      final boothIds = _selectedBooths.map((b) => b.id).toList();

      await _applicationService.submitApplication(
        exhibitorId: exhibitorId,
        exhibitionId: exhibitionId,
        boothIds: boothIds,
        companyName: companyName,
        companyDescription: companyDescription,
        exhibitDescription: exhibitDescription,
        additems: List<String>.from(_selectedAmenityNames),
      );

      for (final booth in _selectedBooths) {
        await _boothService.updateBoothStatus(booth.id, 'reserved');
      }

      _actionSuccess = 'Application submitted successfully!';
      _selectedBooths.clear();
      _selectedAmenityNames.clear();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateApplication(
      String applicationId, Map<String, dynamic> data) async {
    _isSubmitting = true;
    _actionError = '';
    _actionSuccess = '';
    notifyListeners();

    try {
      await _applicationService.updateApplication(applicationId, data);
      _actionSuccess = 'Application updated successfully!';

      if (_applications.isNotEmpty) {
        await loadApplications(_applications.first.exhibitorId);
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelApplication(
      String applicationId, String exhibitorId) async {
    _isSubmitting = true;
    _actionError = '';
    _actionSuccess = '';
    notifyListeners();

    try {
      await _applicationService.cancelApplication(applicationId);
      _actionSuccess = 'Application cancelled.';
      await loadApplications(exhibitorId);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════

  void clearActionMessages() {
    _actionError = '';
    _actionSuccess = '';
    notifyListeners();
  }
}