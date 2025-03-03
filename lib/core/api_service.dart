import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_record.dart';
import '../models/user.dart'; // Add this line to import the User model
import 'package:jwt_decoder/jwt_decoder.dart'; // Add this line to import the jwt_decoder package

class ApiService {
  static const String baseUrl = "http://localhost:3000"; // Change to your API URL

  // Fetch all vehicle records
  Future<List<VehicleRecord>> fetchVehicles() async {
    final response = await http.get(Uri.parse('$baseUrl/vehicle-records'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => VehicleRecord.fromJson(data)).toList();
    } else {
      throw Exception("Failed to load vehicle records");
    }
  }

    // Fetch a single vehicle record by ID
  Future<VehicleRecord?> fetchVehicleById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/vehicle-records/$id'));
    if (response.statusCode == 200) {
      return VehicleRecord.fromJson(json.decode(response.body));
    } else {
      return null; // Handle invalid ID case
    }
  }

    // Create a new vehicle record
Future<void> createVehicle(VehicleRecord vehicle) async {
  final response = await http.post(
    Uri.parse('$baseUrl/vehicle-records'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(vehicle.toJson()),
  );

  if (response.statusCode != 201) {
    throw Exception("Failed to create vehicle");
  }
}

  // 🔄 Update vehicle record (PATCH)
  Future<void> updateVehicle(String id, VehicleRecord vehicle) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vehicle-records/$id'), // Send ID in URL
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(vehicle.toJson()), // Convert to JSON
      );

      if (response.statusCode == 200) {
        print("✅ Vehicle updated successfully!");
      } else {
        print("❌ Failed to update vehicle");
      }
    } catch (error) {
      print("🔥 Error updating vehicle: $error");
      throw Exception("Update failed");
    }
  }


  // Delete a vehicle record by ID
  Future<void> deleteVehicle(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/vehicle-records/$id'));

    if (response.statusCode != 200) {
      throw Exception("Failed to delete vehicle record");
    }
  }

  // Sync offline data
  Future<void> syncOfflineVehicles(List<VehicleRecord> vehicles) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vehicle-records/sync'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(vehicles.map((e) => e.toJson()).toList()),
    );

    if (response.statusCode != 200) {
      throw Exception("Sync failed");
    }
  }

  Future<User?> login(String username, String password) async {
    print("Attempting login for username: $username"); // Logging attempt
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'username': username, 'password': password}),
    );

    print("Response Status Code: ${response.statusCode}"); // Log response code
    // print("Response Body: ${response.body}"); // Log response body

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String token = data['access_token'];

      // Decode JWT to extract user details
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      // print("Decoded JWT: $decodedToken"); // Log decoded JWT

      return User.fromJson({
        'id': decodedToken['sub'], // Extract user ID
        'username': decodedToken['username'], // Extract username
        'token': token, // Store token
        'accountType': decodedToken['accountType'], // Extract account type
      });
    } else {
      print("Login failed: ${response.body}"); // Log failure message
      return null; // Handle invalid login
    }
  }

    // Fetch logged-in user info
Future<User?> getUserInfo(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/users'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  print("Response Body: ${response.body}"); // Debugging

  if (response.statusCode == 200) {
    return User.fromJson(json.decode(response.body));
  } else {
    return null;
  }
}

}
