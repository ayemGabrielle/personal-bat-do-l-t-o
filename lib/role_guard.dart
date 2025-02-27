import 'package:flutter/material.dart';
import 'secure_storage_service.dart';
import 'screens/unauthorized_page.dart';

Future<bool> checkUserRole(String requiredRole) async {
  String? userRole = await SecureStorageService.getUserRole();
  return userRole == requiredRole;
}

Route<dynamic>? roleBasedRouteGuard(
  RouteSettings settings, 
  Widget page, 
  String requiredRole
) {
  return MaterialPageRoute(
    builder: (context) => FutureBuilder<bool>(
      future: checkUserRole(requiredRole),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            return page; // User has the correct role
          } else {
            return UnauthorizedPage(); // Redirect to Unauthorized Page
          }
        }
        return const Center(child: CircularProgressIndicator()); // Loading
      },
    ),
  );
}
