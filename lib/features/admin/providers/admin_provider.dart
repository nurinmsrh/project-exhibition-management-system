import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/models/application_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/exhibition_service.dart';
import '../../../data/services/booth_service.dart';
import '../../../data/services/application_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ExhibitionService _exhibitionService = ExhibitionService();
  final BoothService _boothService = BoothService();
  final ApplicationService _applicationService = ApplicationService();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  List<ExhibitionModel> _exhibitions = [];
  List<ExhibitionModel> _filteredExhibitions = [];
  List<BoothModel> _booths = [];
  List<ApplicationModel> _applications = [];
  List<ApplicationModel> _filteredApplications = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<UserModel> get users => _filteredUsers;
  List<ExhibitionModel> get exhibitions => _filteredExhibitions;
  List<BoothModel> get booths => _booths;
  List<ApplicationModel> get applications => _filteredApplications;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // ─── USERS ───────────────────────────────────────────────

  Future<bool> updateUserStatus(String uid, bool isActive) async {
    try {
      await _authService.updateUserStatus(uid, isActive);
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _authService.getAllUsers();
      _filteredUsers = _users;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void searchUsers(String query) {
    _filteredUsers = _users.where((u) {
      return u.name.toLowerCase().contains(query.toLowerCase()) ||
          u.email.toLowerCase().contains(query.toLowerCase()) ||
          u.role.toLowerCase().contains(query.toLowerCase());
    }).toList();
    notifyListeners();
  }

  Future<bool> deleteUser(String uid) async {
    try {
      await _authService.deleteUser(uid);
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── EXHIBITIONS ─────────────────────────────────────────
  Future<void> loadExhibitions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _exhibitions = await _exhibitionService.getAllExhibitions();
      _filteredExhibitions = _exhibitions;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void searchExhibitions(String query) {
    _filteredExhibitions = _exhibitions.where((e) {
      return e.title.toLowerCase().contains(query.toLowerCase()) ||
          e.venue.toLowerCase().contains(query.toLowerCase());
    }).toList();
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
    try {
      await _exhibitionService.createExhibition(
        title: title,
        description: description,
        venue: venue,
        startDate: startDate,
        endDate: endDate,
        organizerId: organizerId,
      );
      await loadExhibitions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExhibition(
      String id, Map<String, dynamic> data) async {
    try {
      await _exhibitionService.updateExhibition(id, data);
      await loadExhibitions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExhibition(String id) async {
    try {
      await _exhibitionService.deleteExhibition(id);
      await loadExhibitions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePublish(String id, bool isPublished) async {
    try {
      await _exhibitionService.togglePublish(id, isPublished);
      await loadExhibitions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── BOOTHS ──────────────────────────────────────────────

  Future<void> loadAllBooths() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('booths')
          .get();
      _booths = snapshot.docs
          .map((doc) => BoothModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // Load booths for a specific exhibition (used by booth screens)
  Future<void> loadBooths(String exhibitionId) async {
    _isLoading = true;
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
    required List<String> amenities,
    required double positionX,
    required double positionY,
    double width = 50,
    double height = 50,
  }) async {
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

  Future<bool> updateBooth(String id, Map<String, dynamic> data,
      String exhibitionId) async {
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

  // ─── APPLICATIONS ────────────────────────────────────────
  Future<void> loadApplications() async {
    _isLoading = true;
    notifyListeners();
    try {
      _applications = await _applicationService.getAllApplications();
      _filteredApplications = _applications;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void searchApplications(String query) {
    _filteredApplications = _applications.where((a) {
      return a.companyName.toLowerCase().contains(query.toLowerCase()) ||
          a.status.toLowerCase().contains(query.toLowerCase());
    }).toList();
    notifyListeners();
  }

  void filterApplicationsByStatus(String status) {
    if (status == 'all') {
      _filteredApplications = _applications;
    } else {
      _filteredApplications =
          _applications.where((a) => a.status == status).toList();
    }
    notifyListeners();
  }

  Future<bool> updateApplicationStatus(
      String id, String status, {String reason = ''}) async {
    try {
      await _applicationService.updateApplicationStatus(
          id, status, reason: reason);
      await loadApplications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelApplication(String id) async {
    try {
      await _applicationService.cancelApplication(id);
      await loadApplications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}