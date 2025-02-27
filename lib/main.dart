import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/basic_screen.dart';
import 'screens/limited_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/EditVehicleScreen.dart'; // Import the edit screen
import 'providers/auth_provider.dart';
import 'models/vehicle_record.dart'; // Import the VehicleRecord model

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vehicle Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/admin-dashboard': (context) => DashboardScreen(),
        '/basic-dashboard': (context) => BasicScreen(),
        '/limited-dashboard': (context) => LimitedScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/edit-vehicle') {
          final vehicle = settings.arguments as VehicleRecord;
          return MaterialPageRoute(
            builder: (context) => EditVehicleScreen(vehicle: vehicle),
          );
        }
        return null; // Handle unknown routes
      },
    );
  }
}
