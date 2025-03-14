import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../models/vehicle_record.dart';

class EditVehicleScreen extends StatefulWidget {
  final VehicleRecord vehicle;

  EditVehicleScreen({required this.vehicle});

  @override
  _EditVehicleScreenState createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _plateNumberController;
  late TextEditingController _sectionController;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _areaController;
  Status? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _plateNumberController = TextEditingController(
      text: widget.vehicle.plateNumber,
    );
    _sectionController = TextEditingController(text: widget.vehicle.section);
    _nameController = TextEditingController(text: widget.vehicle.name ?? "");
    _addressController = TextEditingController(
      text: widget.vehicle.address ?? "",
    );
    _areaController = TextEditingController(text: widget.vehicle.area ?? "");
    _selectedStatus = widget.vehicle.status;

  _syncPendingEdits();

  // Improved listener: runs immediately on reconnection
  Connectivity().onConnectivityChanged.listen((connectivityResult) async {
    if (connectivityResult != ConnectivityResult.none) {
      print("🌐 Internet restored! Attempting to sync...");
      await _syncPendingEdits();
    }
    });
  }

void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    DateTime? newStatusUpdateDate = widget.vehicle.status == _selectedStatus
        ? widget.vehicle.statusUpdateDate // Keep the existing date if no change
        : (_selectedStatus == Status.Released ? DateTime.now() : null); // Set new date only if changed to Released

    VehicleRecord updatedVehicle = VehicleRecord(
      id: widget.vehicle.id,
      plateNumber: _plateNumberController.text.trim(),
      section: _sectionController.text.trim(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      area: _areaController.text.trim(),
      status: _selectedStatus!,
      dateCreated: widget.vehicle.dateCreated,
      dateUpdated: DateTime.now(),
      statusUpdateDate: newStatusUpdateDate,
    );

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await ApiService().updateVehicle(widget.vehicle.id, updatedVehicle);
        _showSuccessDialog();
      } catch (error) {
        _showErrorSnackbar(error.toString());
      }
    } else {
      await _savePendingEdit(updatedVehicle);
      _showSuccessDialog(isOffline: true);
    }
  }
}

  // Future<void> _savePendingEdit(VehicleRecord vehicle) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String>? pendingEdits =
  //       prefs.getStringList('pending_vehicle_edits') ?? [];
  //   pendingEdits.add(jsonEncode(vehicle.toJson()));

  //   await prefs.setStringList('pending_vehicle_edits', pendingEdits);
  //   print("📌 Saved pending edit for vehicle ${vehicle.id}");
  // }

Future<void> _savePendingEdit(VehicleRecord vehicle) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? pendingEdits = prefs.getStringList('pending_vehicle_edits') ?? [];

  String vehicleJson = jsonEncode(vehicle.toJson());
  pendingEdits.add(vehicleJson);

  await prefs.setStringList('pending_vehicle_edits', pendingEdits);
  print("📌 Saved pending edit: $vehicleJson");  // Debugging line
}




  // Future<void> _syncPendingEdits() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String>? pendingEdits = prefs.getStringList('pending_vehicle_edits');

  //   if (pendingEdits != null && pendingEdits.isNotEmpty) {
  //     print("🔄 Attempting to sync ${pendingEdits.length} pending edits...");

  //     var connectivityResult = await Connectivity().checkConnectivity();
  //     if (connectivityResult != ConnectivityResult.none) {
  //       List<VehicleRecord> vehicles =
  //           pendingEdits
  //               .map((json) => VehicleRecord.fromJson(jsonDecode(json)))
  //               .toList();

  //       for (var vehicle in vehicles) {
  //         try {
  //           await ApiService().updateVehicle(vehicle.id, vehicle);
  //           print("✅ Successfully synced vehicle ${vehicle.id}");
  //         } catch (e) {
  //           print("❌ Error syncing vehicle ${vehicle.id}: $e");
  //         }
  //       }

  //       await prefs.remove('pending_vehicle_edits');
  //       print("✅ All pending edits cleared");
  //     } else {
  //       print("⚠️ Still offline, cannot sync pending edits.");
  //     }
  //   } else {
  //     print("✅ No pending edits to sync.");
  //   }
  // }


Future<void> _syncPendingEdits() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? pendingEdits = prefs.getStringList('pending_vehicle_edits');

  if (pendingEdits == null || pendingEdits.isEmpty) {
    print("✅ No pending edits to sync.");
    return;
  }

  print("🔄 Attempting to sync ${pendingEdits.length} pending edits...");

  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    print("⚠️ Still offline, cannot sync pending edits.");
    return;
  }

  List<String> unsyncedEdits = [];

  for (String json in pendingEdits) {
    VehicleRecord vehicle = VehicleRecord.fromJson(jsonDecode(json));
    try {
      await ApiService().updateVehicle(vehicle.id, vehicle);
      print("✅ Synced vehicle ${vehicle.id}");
    } catch (e) {
      print("❌ Failed to sync vehicle ${vehicle.id}: $e");
      unsyncedEdits.add(json); // Keep failed syncs
    }
  }

  // Only remove successfully synced edits
  await prefs.setStringList('pending_vehicle_edits', unsyncedEdits);
  print(unsyncedEdits.isEmpty ? "✅ All edits synced!" : "🔄 Some edits still pending.");
}



  void _showSuccessDialog({bool isOffline = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success"),
          content: Text(
            isOffline
                ? "Vehicle edit saved offline. It will be synced when online."
                : "Vehicle record has been updated successfully.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Error: $message")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Vehicle",
          style: TextStyle(
            color: const Color.fromRGBO(255, 255, 255, 1),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.indigo],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Edit Vehicle Details",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          _plateNumberController,
                          "Plate Number",
                          Icons.directions_car,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter Plate Number";
                            }
                            if (value.length != 6) {
                              return "Plate Number must be exactly 6 characters";
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          _sectionController,
                          "Section",
                          Icons.category,
                        ),
                        _buildTextField(_nameController, "Name", Icons.person),
                        _buildTextField(
                          _addressController,
                          "Address",
                          Icons.location_on,
                        ),
                        _buildTextField(_areaController, "Area", Icons.map),
                        DropdownButtonFormField<Status>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: "Status",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items:
                              Status.values.map((Status status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status.toString().split('.').last,
                                  ),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedStatus = newValue!;
                            });
                          },
                        ),
                        
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Update",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: validator, // Use the passed validator function
      ),
    );
  }
}
