import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _accountType; // Changed from role to accountType

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get accountType => _accountType; // Updated getter

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    final user = await ApiService().login(username, password);
    if (user != null) {
      _user = user;
      _accountType = user.accountType; // Assuming API returns accountType

      await _saveUserToStorage(user, _accountType!); // Save user and accountType
    } else {
      print("Login failed: Invalid credentials");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveUserToStorage(User user, String accountType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
    await prefs.setString('accountType', accountType); // Save accountType separately
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('accountType'); // Clear accountType on logout
    _user = null;
    _accountType = null;
    notifyListeners();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final storedAccountType = prefs.getString('accountType');

    if (userData != null) {
      _user = User.fromJson(jsonDecode(userData));
      _accountType = storedAccountType; // Load accountType from storage
    }

    notifyListeners();
  }

  // Helper function to check permissions
  bool hasPermission(String action) {
    if (_accountType == "admin") return true; // Admin has full access
    if (_accountType == "limited" && action == "delete") return false; // Limited cannot delete
    if (_accountType == "basic" && (action == "delete" || action == "edit" || action == "create")) {
      return false; // Basic cannot edit, create, or delete
    }
    return true; // Allow other actions
  }

}
