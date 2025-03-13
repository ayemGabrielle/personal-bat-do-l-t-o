import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_record.dart';
import '../models/user.dart'; // Add this line to import the User model
import 'package:jwt_decoder/jwt_decoder.dart'; // Add this line to import the jwt_decoder package

class ApiService {
  static const String baseUrl = "https://lto-deploy.onrender.com"; // Change to your API URL

  Future<bool> _isOnline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

    Future<void> _savePendingChanges(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingChanges = prefs.getStringList(key) ?? [];
    pendingChanges.add(jsonEncode(data));
    await prefs.setStringList(key, pendingChanges);
  }

  Future<void> _saveOffline(String key, VehicleRecord vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineData = prefs.getStringList(key) ?? [];
    offlineData.add(jsonEncode(vehicle.toJson()));
    await prefs.setStringList(key, offlineData);
  }

  Future<void> _syncPendingChanges() async {
    if (!await _isOnline()) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> pendingCreates = prefs.getStringList("pending_creates") ?? [];
    List<String> pendingUpdates = prefs.getStringList("pending_updates") ?? [];

    for (String item in pendingCreates) {
      VehicleRecord vehicle = VehicleRecord.fromJson(jsonDecode(item));
      await createVehicle(vehicle);
    }
    for (String item in pendingUpdates) {
      Map<String, dynamic> updateData = jsonDecode(item);
      await updateVehicle(updateData["id"], VehicleRecord.fromJson(updateData["vehicle"]));
    }

    await prefs.remove("pending_creates");
    await prefs.remove("pending_updates");
  }

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
  Future<void> createVehicle(VehicleRecord vehicle, {bool offline = true}) async {
    if (await _isOnline()) {
      final response = await http.post(
        Uri.parse('$baseUrl/vehicle-records'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(vehicle.toJson()),
      );
      if (response.statusCode != 201) {
        throw Exception("Failed to create vehicle");
      }
    } else if (offline) {
      await _saveOffline('offline_create', vehicle);
    }
  }


  // 🔄 Update vehicle record (PATCH)
  Future<void> updateVehicle(String id, VehicleRecord vehicle) async {
    if (await _isOnline()) {
      final response = await http.patch(
        Uri.parse('$baseUrl/vehicle-records/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(vehicle.toJson()),
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to update vehicle");
      }
    } else {
      await _savePendingChanges("pending_updates", {"id": id, "vehicle": vehicle.toJson()});
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
