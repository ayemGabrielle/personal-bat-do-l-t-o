import 'package:flutter/material.dart';
import 'package:lto_app/screens/MV%20File/mvf-dashboard.dart';
import 'package:provider/provider.dart';
import 'screens/Vehicle Records/basic_screen.dart';
import 'screens/Vehicle Records/limited_screen.dart';
import 'screens/login_screen.dart';
import 'screens/Vehicle Records/dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/MV File/mvf-basic-screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider()..loadUser(),
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LTO Vehicle Records',
          theme: ThemeData(primarySwatch: Colors.blue),
          initialRoute: '/login',
          onGenerateRoute: (settings) {
            if (!authProvider.isAuthenticated) {
              return MaterialPageRoute(builder: (context) => LoginScreen());
            }

            switch (settings.name) {
              case '/admin-dashboard':
                return _guardedRoute(context, authProvider, 'admin', DashboardScreen());
              case '/basic-dashboard':
                return _guardedRoute(context, authProvider, 'basic', BasicScreen());
              case '/limited-dashboard':
                return _guardedRoute(context, authProvider, 'limited', LimitedScreen());
              case '/mvf-dashboard':
                return _guardedRoute(context, authProvider, 'mvfileadmin', MVFileDashboardScreen());
              case '/mvf-basic-dashboard':
                return _guardedRoute(context, authProvider, 'mvfilebasic', MVFileBasicDashboardScreen());
              default:
                return MaterialPageRoute(builder: (context) => LoginScreen());
            }
          },
        );
      },
    );
  }

  // Helper function for role-based routing
  MaterialPageRoute? _guardedRoute(
      BuildContext context, AuthProvider authProvider, String requiredRole, Widget screen) {
    if (authProvider.accountType == requiredRole) {
      return MaterialPageRoute(builder: (context) => screen);
    } else {
      return MaterialPageRoute(
        builder: (context) => UnauthorizedScreen(),
      );
    }
  }
}

// Unauthorized access screen
class UnauthorizedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.red),
            SizedBox(height: 20),
            Text("Unauthorized Access", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("You don't have permission to view this page."),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text("Go to Login"),
            ),
          ],
        ),
      ),
    );
  }
}
