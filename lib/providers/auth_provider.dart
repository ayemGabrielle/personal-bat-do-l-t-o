import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io'; // Import dart:io for InternetAddress
import '../core/connectivity_service.dart'; // Import connectivity checker

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

    bool isOnline = await ConnectivityService().isOnline(); // Check internet

    if (isOnline) {
      // Online login (API request)
      final user = await ApiService().login(username, password);
      if (user != null) {
        _user = user;
        _accountType = user.accountType;
    print("🟡 Received Access Token: ${user.token}"); // Debugging

    await _saveUserToStorage(_user!, user.token); // ✅ Pass token correctly

        print("Login successful. User: ${user.username}, AccountType: ${user.accountType}");
      } else {
        print("Login failed: Invalid credentials");
      }
    } else {
      // Offline login (use stored credentials)
      bool success = await tryOfflineLogin(username);
      if (!success) {
        print("Offline login failed: Invalid credentials");
      }
    }

    _isLoading = false;
    notifyListeners();
  }

Future<void> _saveUserToStorage(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();

    print("🟡 Saving Access Token: $token"); // Debugging

    final userData = jsonEncode({
        "id": user.id,
        "username": user.username,
        "token": token, // ✅ Ensure token is saved correctly
        "accountType": user.accountType,
    });

    await prefs.setString('user', userData);
    await prefs.setString('token', token); // ✅ Store token separately

    print("🟢 Stored User: $userData");
    print("🟢 Stored Token: $token");

    // Verify storage
    final storedUser = prefs.getString('user');
    final storedAccessToken = prefs.getString('token');
    print("🔍 Verification: Read Back User Data: $storedUser");
    print("🔍 Verification: Read Back Token: $storedAccessToken");
}


  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    notifyListeners();
    print("🔴 User logged out.");
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

  Future<bool> tryOfflineLogin(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserData = prefs.getString('user');
    final storedToken = prefs.getString('token'); // ✅ Correct token key

    // Debugging logs
    print("🔵 Retrieved User Data (RAW): $storedUserData");
    print("🔵 Retrieved Token: $storedToken");

    if (storedUserData != null && storedToken != null) {
      try {
        final Map<String, dynamic> storedUser = jsonDecode(storedUserData);

        // Ensure username matches
        if (storedUser['username'] == username) {
          _user = User.fromJson(storedUser);
          _accountType = storedUser['accountType'];
          notifyListeners();
          print("✅ Offline login successful!");
          return true;
        } else {
          print("❌ Username mismatch. Expected: $username, Found: ${storedUser['username']}");
        }
      } catch (e) {
        print("❌ Error decoding user data: $e");
      }
    } else {
      print("❌ No stored credentials found.");
    }
    return false;
  }

  bool hasPermission(String action) {
    if (_accountType == "admin") return true;
    if (_accountType == "limited" && action == "delete") return false;
    if (_accountType == "basic" && ["delete", "edit", "create"].contains(action)) {
      return false;
    }
    return true;
  }

  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // ✅ Retrieves the token correctly
  }

}
