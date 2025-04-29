import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'screens/MV File/mvf-dashboard.dart';
import 'screens/Vehicle Records/dashboard_screen.dart';
import 'screens/Vehicle Records/basic_screen.dart';
import 'screens/Vehicle Records/limited_screen.dart';
import '../screens/login_screen.dart';
import 'screens/MV File/mvf-basic-screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  AuthGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 🔄 Show loading indicator while checking authentication
    if (authProvider.isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🔹 Debugging print
    print("🔍 AuthGuard Check: isAuthenticated = ${authProvider.isAuthenticated}");
    print("🔍 AuthGuard Check: Account Type = ${authProvider.accountType}");

    if (!authProvider.isAuthenticated) {
      return LoginScreen(); // Redirect to login if not authenticated
    }

    // Redirect based on account type
    switch (authProvider.accountType) {
      case "admin":
        return DashboardScreen();
      case "limited":
        return LimitedScreen();
      case "basic":
        return BasicScreen();
      case "mvfileadmin":
        return MVFileDashboardScreen();
      case "mvfilebasic":
        return MVFileBasicDashboardScreen();
      default:
        return LoginScreen();
    }
  }
}
