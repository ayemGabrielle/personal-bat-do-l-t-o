import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  final Color primaryColor = Color(0xFF3b82f6); // Tailwind Blue-500

  void _login() async {
    setState(() => _isLoading = true); // Show loading state

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.login(_usernameController.text, _passwordController.text);

    setState(() => _isLoading = false); // Hide loading state

    if (authProvider.isAuthenticated) {
      String? accountType = authProvider.accountType;
      if (accountType == "admin") {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (accountType == "basic") {
        Navigator.pushReplacementNamed(context, '/basic-dashboard');
      } else if (accountType == "limited") {
        Navigator.pushReplacementNamed(context, '/limited-dashboard');
      }  else if (accountType == "mvfileadmin") {
        Navigator.pushReplacementNamed(context, '/mvf-dashboard'); 
      } else if (accountType == "mvfilebasic") {
        Navigator.pushReplacementNamed(context, '/limited-dashboard'); 
      } else {
        print("Unknown account type: $accountType");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown account type. Contact support.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid username or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "images/LTO_bg_image.jpg",
            fit: BoxFit.cover,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Welcome Back",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: "Username",
                          prefixIcon: Icon(Icons.person, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          // Add a suffix icon that toggles password visibility:
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off : Icons.visibility,
                              color: primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureText,
                      ),
                      SizedBox(height: 20),
                      if (_isLoading)
                        CircularProgressIndicator()
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text("Login", style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
