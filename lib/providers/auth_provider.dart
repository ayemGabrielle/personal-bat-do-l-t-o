import 'package:crypto/crypto.dart';
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


  //login fix with offline first
Future<void> login(String username, String password) async {
  _isLoading = true;
  notifyListeners();

  // Debug Internet Check
  print("🔍 Checking internet connection...");
  bool isOnline = await ConnectivityService().isOnline();
  print("🌐 Internet status: $isOnline");

  if (isOnline) {
    print("🌍 Internet available. Attempting online login...");

    final user = await ApiService().login(username, password);
    if (user != null) {
      _user = user;
      _accountType = user.accountType;
      await _saveUserToStorage(_user!, user.token, password);
      print("✅ Online login successful.");
      _isLoading = false;
      notifyListeners();
      return;
    } else {
      print("❌ Online login failed. Checking offline credentials...");
    }
  } else {
    print("⚠️ No internet detected. Trying offline login...");
  }

  // Offline Login Fallback
  bool offlineSuccess = await tryOfflineLogin(username, password);
  if (offlineSuccess) {
    print("✅ Logged in offline.");
  } else {
    print("❌ No stored credentials found. Offline login failed.");
  }

  _isLoading = false;
  notifyListeners();
}




  // Future<void> login(String username, String password) async {
  //   _isLoading = true;
  //   notifyListeners();

  //   bool isOnline = await ConnectivityService().isOnline(); // Check internet


  //   if (isOnline) {
  //     // Online login (API request)
  //     final user = await ApiService().login(username, password);
  //     if (user != null) {
  //       _user = user;
  //       _accountType = user.accountType;
  //   // print("🟡 Received Access Token: ${user.token}"); // Debugging

  //   await _saveUserToStorage(_user!, user.token, password); // ✅ Pass token correctly

  //       print("Login successful");
  //     } else {
  //       print("Login failed: Invalid credentials");
  //     }
  //   } else {
  //     // Offline login (use stored credentials)

  //     bool success = await tryOfflineLogin(username, password);
  //     if (!success) {
  //       print("Offline login failed: Invalid credentials");
  //     }
  //   }

  //   _isLoading = false;
  //   notifyListeners();

  // }






Future<void> _saveUserToStorage(User user, String token, String password) async {
  final prefs = await SharedPreferences.getInstance();

  // Hash the password before storing it
  String hashedPassword = sha256.convert(utf8.encode(password)).toString();

  final userData = jsonEncode({
    "id": user.id,
    "username": user.username,
    "password": hashedPassword, // ✅ Now includes hashed password
    "accountType": user.accountType,
  });

  await prefs.setString('user', userData);
  await prefs.setString('token', token);

  // print("🟢 Stored User: $userData");
}


Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();

  // Preserve user data but remove authentication token
  final storedUserData = prefs.getString('user');
  if (storedUserData != null) {
    final Map<String, dynamic> userJson = jsonDecode(storedUserData);

    // Keep only username and accountType for offline login
    final updatedUserData = jsonEncode({
      "id": userJson["id"],
      "username": userJson["username"],
      "password": userJson["password"],  // ✅ Keep the hashed password
      "accountType": userJson["accountType"],
    });

    await prefs.setString('user', updatedUserData);
    print("🟡 Preserving user data for offline login");
  }

  // Remove only the access token to force re-authentication online
  await prefs.remove('token');

  _user = null;
  _accountType = null;
  notifyListeners();

  print("🔴 User logged out. Credentials saved for offline login.");
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

// fixed offline login
Future<bool> tryOfflineLogin(String username, String password) async {
  final prefs = await SharedPreferences.getInstance();
  final storedUserData = prefs.getString('user');

  if (storedUserData != null) {
    try {
      final Map<String, dynamic> storedUser = jsonDecode(storedUserData);
      String hashedInputPassword = sha256.convert(utf8.encode(password)).toString();

      if (storedUser['username'] == username && storedUser['password'] == hashedInputPassword) {
        _user = User.fromJson(storedUser);
        _accountType = storedUser['accountType'];
        notifyListeners();
        print("✅ Offline login successful!");
        return true;
      } else {
        print("❌ Incorrect username or password.");
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