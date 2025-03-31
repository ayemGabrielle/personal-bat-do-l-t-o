import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_record.dart';
import '../models/user.dart'; // Add this line to import the User model
import '../models/mvfile.dart'; // Add this line to import the MVFile model
import 'package:jwt_decoder/jwt_decoder.dart'; // Add this line to import the jwt_decoder package

class ApiService {
  static const String baseUrl = "https://lto-deploy.onrender.com"; // Change to your API URL
  // static const String baseUrl = "http://localhost:3000"; // Change to your API URL
ApiService() {
  Connectivity().onConnectivityChanged.listen((result) {
    if (result != ConnectivityResult.none) {
      print("object");
      _syncPendingChanges();
    }
  });
}

  // Add the _isOnline method here
  Future<bool> _isOnline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
// Future<void> _syncPendingChanges() async {
//   if (!await _isOnline()) return;

//   final prefs = await SharedPreferences.getInstance();
//   List<String> pendingUpdates = prefs.getStringList("pending_updates") ?? [];

//   if (pendingUpdates.isEmpty) return;

//   for (int i = pendingUpdates.length - 1; i >= 0; i--) {
//     Map<String, dynamic> updateData = jsonDecode(pendingUpdates[i]);
//     String id = updateData["id"];
//     VehicleRecord vehicle = VehicleRecord.fromJson(updateData["vehicle"]);

//     try {
//       await updateVehicleOnline(id, vehicle); // Sync with server
//       pendingUpdates.removeAt(i); // Remove successfully synced item
//       await prefs.setStringList("pending_updates", pendingUpdates);
//       print("Synced update for vehicle: $id");
//     } catch (e) {
//       print("Failed to sync update for vehicle $id: $e");
//     }
//   }
// }

//   Future<bool> _isOnline() async {
//     var connectivityResult = await Connectivity().checkConnectivity();
//     return connectivityResult != ConnectivityResult.none;
//   }

Future<void> _syncPendingChanges() async {
  if (!await _isOnline()) return;

  final prefs = await SharedPreferences.getInstance();
  List<String> pendingCreates = prefs.getStringList("pending_creates") ?? [];
  List<String> pendingUpdates = prefs.getStringList("pending_updates") ?? [];

  // Sync create vehicle records
  for (String item in pendingCreates.toList()) {
    VehicleRecord vehicle = VehicleRecord.fromJson(jsonDecode(item));
    try {
      await createVehicle(vehicle, offline: false);  // Syncing create
      pendingCreates.remove(item); // Remove after success
      await prefs.setStringList("pending_creates", pendingCreates);
      print("Synced create for vehicle: ${vehicle.id}");
    } catch (e) {
      print("Failed to sync create vehicle ${vehicle.id}: $e");
    }
  }

  // Sync updates
  for (String item in pendingUpdates.toList()) {
    Map<String, dynamic> updateData = jsonDecode(item);
    String id = updateData["id"];
    VehicleRecord vehicle = VehicleRecord.fromJson(updateData["vehicle"]);

    try {
      await updateVehicleOnline(id, vehicle);  // Syncing updates
      pendingUpdates.remove(item); // Remove after success
      await prefs.setStringList("pending_updates", pendingUpdates);
      print("Synced update for vehicle: $id");
    } catch (e) {
      print("Failed to sync update for vehicle $id: $e");
    }
  }

  // Clear if necessary
  await prefs.remove("pending_creates");
  await prefs.remove("pending_updates");
}


// DO NOT REMOVE THISSSSSSSSSSSs
// Future<void> _savePendingChanges(String key, Map<String, dynamic> data) async {
//   final prefs = await SharedPreferences.getInstance();
//   List<String> pendingChanges = prefs.getStringList(key) ?? [];
//   pendingChanges.add(jsonEncode(data));
//   await prefs.setStringList(key, pendingChanges);
// }

Future<void> _savePendingChanges(String key, Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> pendingChanges = prefs.getStringList(key) ?? [];

  // If it's an update, ensure previous changes for the same ID are replaced
  if (key == "pending_updates") {
    pendingChanges.removeWhere((item) {
      Map<String, dynamic> existing = jsonDecode(item);
      return existing["id"] == data["id"];
    });
  }

  pendingChanges.add(jsonEncode(data));
  await prefs.setStringList(key, pendingChanges);
}




//offline save data
Future<void> _saveOffline(String key, VehicleRecord vehicle) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> offlineData = prefs.getStringList(key) ?? [];
  
  final encoded = jsonEncode(vehicle.toJson());
  print("Saving offline: $encoded"); // Debug log
  
  offlineData.add(encoded);
  await prefs.setStringList(key, offlineData);
}

Future<List<VehicleRecord>> fetchVehicles() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");

  final response = await http.get(
    Uri.parse('$baseUrl/vehicle-records'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => VehicleRecord.fromJson(data)).toList();
  } else {
    throw Exception("Failed to load vehicle records");
  }
}

Future<MVFile?> fetchMVFileById(String id) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");

  final response = await http.get(
    Uri.parse('$baseUrl/mv-files/$id'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    return MVFile.fromJson(json.decode(response.body));
  } else {
    return null; // Handle invalid ID case
  }
}


Future<List<MVFile>> fetchMVFiles() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");

  final response = await http.get(
    Uri.parse('$baseUrl/mv-files'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => MVFile.fromJson(data)).toList();
  } else {
    throw Exception("Failed to load MV files");
  }
}


  // Define the _syncPendingChanges method DO NOT REMOVE THISSSSS
// Future<void> _syncPendingChanges() async {
//   if (!await _isOnline()) return;

//   final prefs = await SharedPreferences.getInstance();
//   List<String> pendingCreates = prefs.getStringList("pending_creates") ?? [];

//   for (String item in pendingCreates.toList()) {
//     VehicleRecord vehicle = VehicleRecord.fromJson(jsonDecode(item));
//     try {
//       await createVehicle(vehicle, offline: false); // Force online sync
//       pendingCreates.remove(item);
//       await prefs.setStringList("pending_creates", pendingCreates);
//     } catch (e) {
//       print("Error syncing vehicle: $e");
//     }
//   }

//   await prefs.remove("pending_creates");
// }

// Future<void> _syncPendingChanges() async {
//   if (!await _isOnline()) return;

//   final prefs = await SharedPreferences.getInstance();
  
//   // Sync pending creations
//   List<String> pendingCreates = prefs.getStringList("pending_creates") ?? [];
//   for (String item in pendingCreates.toList()) {
//     VehicleRecord vehicle = VehicleRecord.fromJson(jsonDecode(item));
//     try {
//       await createVehicle(vehicle, offline: false);
//       pendingCreates.remove(item);
//       await prefs.setStringList("pending_creates", pendingCreates);
//     } catch (e) {
//       print("Error syncing vehicle: $e");
//     }
//   }

//   // Sync pending updates
//   List<String> pendingUpdates = prefs.getStringList("pending_updates") ?? [];
//   for (String item in pendingUpdates.toList()) {
//     Map<String, dynamic> updateData = jsonDecode(item);
//     String id = updateData["id"];
//     VehicleRecord vehicle = VehicleRecord.fromJson(updateData["vehicle"]);

//     try {
//       await updateVehicle(id, vehicle);
//       pendingUpdates.remove(item);
//       await prefs.setStringList("pending_updates", pendingUpdates);
//     } catch (e) {
//       print("Error syncing update for vehicle $id: $e");
//     }
//   }

//   await prefs.remove("pending_creates");
//   await prefs.remove("pending_updates");
// }






Future<void> updateVehicleOnline(String id, VehicleRecord vehicle) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");

  final response = await http.patch(
    Uri.parse('$baseUrl/vehicle-records/$id'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(vehicle.toJson()),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to update vehicle online");
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
// Create a new vehicle record
// Future<void> createVehicle(VehicleRecord vehicle, {bool offline = true}) async {
//   if (await _isOnline()) {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/vehicle-records'),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(vehicle.toJson()),
//       );

//       if (response.statusCode != 201) {
//         throw Exception("Failed to create vehicle");
//       }
//     } catch (e) {
//       // If there’s an error (like internet disconnecting mid-request), save offline
//       if (offline) {
//         await _savePendingChanges("pending_creates", vehicle.toJson());
//       }
//     }
//   } else if (offline) {
//     await _savePendingChanges("pending_creates", vehicle.toJson()); 
//   }
// }

Future<void> createVehicle(VehicleRecord vehicle, {bool offline = true}) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");

  if (await _isOnline()) {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vehicle-records'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception("Failed to create vehicle online");
      } else {
        print("Vehicle created online: ${vehicle.id}");
      }
    } catch (e) {
      print("Error creating vehicle online: $e");
      if (offline) await _storeCreateLocally(vehicle);
    }
  } else {
    await _storeCreateLocally(vehicle);
  }
}



Future<void> _storeCreateLocally(VehicleRecord vehicle) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> pendingCreates = prefs.getStringList("pending_creates") ?? [];

  // Generate a temporary local ID if needed
  vehicle.id ??= DateTime.now().millisecondsSinceEpoch.toString();

  pendingCreates.add(jsonEncode(vehicle.toJson()));
  await prefs.setStringList("pending_creates", pendingCreates);

  print("Vehicle stored offline for later syncing: ${vehicle.id}");
}


Future<void> createMvFile(MVFile mvFile, {bool offline = true}) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");

  if (await _isOnline()) {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mv-files'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(mvFile.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception("Failed to create MvFile online");
      } else {
        print("MvFile created online: ${mvFile.id}");
      }
    } catch (e) {
      print("Error creating MvFile online: $e");
      if (offline) await _storeMvFileCreateLocally(mvFile);
    }
  } else {
    await _storeMvFileCreateLocally(mvFile);
  }
}

Future<void> _storeMvFileCreateLocally(MVFile mvFile) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> pendingCreates = prefs.getStringList("pending_mvfiles") ?? [];

  mvFile.id ??= DateTime.now().millisecondsSinceEpoch.toString(); // Assign temporary ID if needed

  pendingCreates.add(jsonEncode(mvFile.toJson()));
  await prefs.setStringList("pending_mvfiles", pendingCreates);

  print("MvFile stored offline for later syncing: ${mvFile.id}");
}

Future<void> deleteMVfile(String id) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");

  if (token == null) {
    throw Exception("Authentication token not found");
  }

  final response = await http.delete(
    Uri.parse('$baseUrl/mv-files/$id'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to delete MV File Record");
  } else {
    print("MV File Record deleted successfully: $id");
  }
}


  // 🔄 Update vehicle record (PATCH)
  // Future<void> updateVehicle(String id, VehicleRecord vehicle) async {
  //   if (await _isOnline()) {
  //     final response = await http.patch(
  //       Uri.parse('$baseUrl/vehicle-records/$id'),
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(vehicle.toJson()),
  //     );
  //     if (response.statusCode != 200) {
  //       throw Exception("Failed to update vehicle");
  //     }
  //   } else {
  //     await _savePendingChanges("pending_updates", {"id": id, "vehicle": vehicle.toJson()});
  //   }
  // }

Future<void> updateVehicle(String id, VehicleRecord vehicle) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");

  if (token == null) {
    throw Exception("Authentication token not found");
  }

  if (await _isOnline()) {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vehicle-records/$id'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update vehicle");
      } else {
        print("Vehicle updated successfully: $id");
      }
    } catch (e) {
      print("Error updating vehicle online: $e");
      await _storeUpdateLocally(id, vehicle); // Save locally if the request fails
    }
  } else {
    await _storeUpdateLocally(id, vehicle);
  }
}

Future<void> updateMVFile(String id, MVFile mv_file) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");

  if (token == null) {
    throw Exception("Authentication token not found");
  }

  if (await _isOnline()) {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/mv-files/$id'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(mv_file.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update MVFile");
      } else {
        print("✅ MVFile updated successfully: $id");
      }
    } catch (e) {
      print("❌ Error updating MVFile online: $e");
      await _storeMVFileUpdateLocally(id, mv_file); // Save locally if request fails
    }
  } else {
    await _storeMVFileUpdateLocally(id, mv_file);
  }
}



Future<void> _storeUpdateLocally(String id, VehicleRecord vehicle) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> pendingUpdates = prefs.getStringList("pending_updates") ?? [];

  // Remove previous updates for the same vehicle
  pendingUpdates.removeWhere((item) {
    Map<String, dynamic> existing = jsonDecode(item);
    return existing["id"] == id;
  });

  // Save new update
  pendingUpdates.add(jsonEncode({"id": id, "vehicle": vehicle.toJson()}));
  await prefs.setStringList("pending_updates", pendingUpdates);

  print("Vehicle update stored offline for syncing later: $id");
}

Future<void> _storeMVFileUpdateLocally(String id, MVFile mvFile) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> pendingUpdates = prefs.getStringList("pending_mvfile_updates") ?? [];

  // Remove previous updates for the same MVFile
  pendingUpdates.removeWhere((item) {
    Map<String, dynamic> existing = jsonDecode(item);
    return existing["id"] == id;
  });

  // Save new update
  pendingUpdates.add(jsonEncode({"id": id, "mvFile": mvFile.toJson()}));
  await prefs.setStringList("pending_mvfile_updates", pendingUpdates);

  print("📌 MVFile update stored offline for syncing later: $id");
}




// Delete a vehicle record by ID with Authorization Token
Future<void> deleteVehicle(String id) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");

  if (token == null) {
    throw Exception("Authentication token not found");
  }

  final response = await http.delete(
    Uri.parse('$baseUrl/vehicle-records/$id'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to delete vehicle record");
  } else {
    print("Vehicle deleted successfully: $id");
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
  final response = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({'username': username, 'password': password}),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final String token = data['access_token'];

    // Store token in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("jwt_token", token);

    // Decode JWT
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    return User.fromJson({
      'id': decodedToken['sub'],
      'username': decodedToken['username'],
      'token': token,
      'accountType': decodedToken['accountType'],
    });
  } else {
    return null;
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
