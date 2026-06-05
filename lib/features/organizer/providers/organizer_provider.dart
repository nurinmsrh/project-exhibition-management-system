import 'package:flutter/material.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/models/application_model.dart';
import '../../../data/services/exhibition_service.dart';
import '../../../data/services/booth_service.dart';
import '../../../data/services/application_service.dart';

class OrganizerProvider extends ChangeNotifier {
  // --- State ---
  List<ExhibitionModel> _exhibitions = [];
  List<BoothModel> _booths = [];
  List<ApplicationModel> _applications = [];

  bool _isLoading = false;
  String _errorMessage = '';

  // --- Getters ---
  List<ExhibitionModel> get exhibitions => _exhibitions;
  List<BoothModel> get booths => _booths;
  List<ApplicationModel> get applications => _applications;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // --- Services ---
  final ExhibitionService _exhibitionService = ExhibitionService();
  final BoothService _boothService = BoothService();
  final ApplicationService _applicationService = ApplicationService();

  // ---------------------------------------------------------------
  // EXHIBITIONS
  // ---------------------------------------------------------------

  Future<void> loadExhibitions(String organizerId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      _exhibitions =
      await _exhibitionService.getOrganizerExhibitions(organizerId);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createExhibition({
    required String title,
    required String description,
    required String venue,
    required DateTime startDate,
    required DateTime endDate,
    required String organizerId,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _exhibitionService.createExhibition(
        title: title,
        description: description,
        venue: venue,
        startDate: startDate,
        endDate: endDate,
        organizerId: organizerId,
      );
      await loadExhibitions(organizerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExhibition(
      String id,
      Map<String, dynamic> data,
      String organizerId,
      ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _exhibitionService.updateExhibition(id, data);
      await loadExhibitions(organizerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExhibition(String id, String organizerId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _exhibitionService.deleteExhibition(id);
      await loadExhibitions(organizerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePublish(
      String id,
      bool isPublished,
      String organizerId,
      ) async {
    _errorMessage = '';
    try {
      await _exhibitionService.togglePublish(id, isPublished);
      await loadExhibitions(organizerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------
  // BOOTHS
  // ---------------------------------------------------------------

  Future<void> loadBooths(String exhibitionId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      _booths = await _boothService.getBoothsByExhibition(exhibitionId);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBooth({
    required String exhibitionId,
    required String boothNumber,
    required String type,
    required String size,
    required double price,
    List<String> amenities = const [],
    double positionX = 0,
    double positionY = 0,
    double width = 80,
    double height = 80,
  }) async {
    _errorMessage = '';
    try {
      await _boothService.createBooth(
        exhibitionId: exhibitionId,
        boothNumber: boothNumber,
        type: type,
        size: size,
        price: price,
        amenities: amenities,
        positionX: positionX,
        positionY: positionY,
        width: width,
        height: height,
      );
      await loadBooths(exhibitionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBooth(
      String id,
      Map<String, dynamic> data,
      String exhibitionId,
      ) async {
    _errorMessage = '';
    try {
      await _boothService.updateBooth(id, data);
      await loadBooths(exhibitionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBooth(String id, String exhibitionId) async {
    _errorMessage = '';
    try {
      await _boothService.deleteBooth(id);
      await loadBooths(exhibitionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------
  // APPLICATIONS
  // ---------------------------------------------------------------

  Future<void> loadApplications(String exhibitionId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      _applications =
      await _applicationService.getExhibitionApplications(exhibitionId);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> approveApplication(String id, String exhibitionId) async {
    _errorMessage = '';
    try {
      await _applicationService.updateApplicationStatus(id, 'approved');
      await loadApplications(exhibitionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectApplication(
      String id,
      String exhibitionId,
      String reason,
      ) async {
    _errorMessage = '';
    try {
      await _applicationService.updateApplicationStatus(
        id,
        'rejected',
        reason: reason,
      );
      await loadApplications(exhibitionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelApplication(String id, String exhibitionId) async {
    _errorMessage = '';
    try {
      await _applicationService.cancelApplication(id);
      await loadApplications(exhibitionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}