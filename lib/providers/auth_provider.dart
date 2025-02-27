import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _accountType;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get accountType => _accountType;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    final user = await ApiService().login(username, password);
    if (user != null) {
      _user = user;
      _accountType = user.accountType;

      await _saveUserToStorage(user); // Save user with accountType
      print("Login successful. User: ${user.username}, AccountType: ${user.accountType}");
    } else {
      print("Login failed: Invalid credentials");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    _user = null;
    _accountType = null;
    notifyListeners();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');

    if (userData != null) {
      _user = User.fromJson(jsonDecode(userData));
      _accountType = _user?.accountType;
    }

    notifyListeners();
  }

  bool hasPermission(String action) {
    if (_accountType == "admin") return true;
    if (_accountType == "limited" && action == "delete") return false;
    if (_accountType == "basic" && ["delete", "edit", "create"].contains(action)) {
      return false;
    }
    return true;
  }
}
