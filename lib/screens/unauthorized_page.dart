import 'package:flutter/material.dart';
import '../auth.service.dart';

class UnauthorizedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Unauthorized')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('You do not have permission to access this page.'),
            ElevatedButton(
              onPressed: () => AuthService.logout(context),
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
