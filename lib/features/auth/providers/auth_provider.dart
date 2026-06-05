import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  String get userRole => _currentUser?.role ?? '';

  // Load user from saved session
  Future<void> loadUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        _currentUser = await _authService.getUserData(user.uid);
        notifyListeners();
      }
    } catch (e) {
      _currentUser = null;
      notifyListeners();
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String company = '',
    String phone = '',
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
        company: company,
        phone: phone,
      );

      await _saveRole(role);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final credential = await _authService.login(
        email: email,
        password: password,
      );

      if (credential == null) {
        _errorMessage = 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = credential;
      await _saveRole(_currentUser!.role);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    await _clearRole();
    _currentUser = null;
    notifyListeners();
  }

  // Save role to shared preferences
  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
  }

  // Clear role from shared preferences
  Future<void> _clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');
  }
}