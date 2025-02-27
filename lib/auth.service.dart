import 'package:flutter/material.dart';
import 'package:lto_app/secure_storage_service.dart';

class AuthService {
  static Future<void> handleLogin(BuildContext context, String accountType) async {
    // Save user role securely
    await SecureStorageService.saveUserRole(accountType);

    // Navigate based on the user role
    if (accountType == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else if (accountType == 'limited') {
      Navigator.pushReplacementNamed(context, '/limited-dashboard');
    } else if (accountType == 'basic') {
      Navigator.pushReplacementNamed(context, '/basic-dashboard');
    } else {
      // If the role is not valid, go to login page
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  static Future<void> logout(BuildContext context) async {
    await SecureStorageService.clearUserRole();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
