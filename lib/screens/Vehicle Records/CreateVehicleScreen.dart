import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/vehicle_record.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateVehicleScreen extends StatefulWidget {
  @override
  _CreateVehicleScreenState createState() => _CreateVehicleScreenState();
}

class _CreateVehicleScreenState extends State<CreateVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  Status _selectedStatus = Status.Available;
  List<VehicleRecord> _vehicleRecords =
      []; // Define the list to store vehicle records

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      VehicleRecord newVehicle = VehicleRecord(
        id: "", // ID assigned by backend
        plateNumber: _plateNumberController.text.trim(),
        section: _sectionController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        area: _areaController.text.trim(),
        status: _selectedStatus,
        dateCreated: DateTime.now(),
        dateUpdated: DateTime.now(),
      );

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Device is online - send to API
        try {
          await ApiService().createVehicle(newVehicle);
          _showSuccessDialog();
        } catch (error) {
          _showErrorSnackbar(error.toString());
        }
      } else {
        // Device is offline - save to local storage
        await _savePendingRecord(newVehicle);
        _showSuccessDialog(isOffline: true);
      }
    }
  }

Future<void> _savePendingRecord(VehicleRecord vehicle) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? pendingRecords = prefs.getStringList('pending_vehicles') ?? [];

  // Assign a temporary ID (if empty) for tracking
  if (vehicle.id == null || vehicle.id!.isEmpty) {
    vehicle.id = "local_${DateTime.now().millisecondsSinceEpoch}";
  }

  pendingRecords.add(jsonEncode(vehicle.toJson()));
  await prefs.setStringList('pending_vehicles', pendingRecords);

  // ✅ Show new record in the UI immediately
  setState(() {
    _vehicleRecords.add(vehicle);
  });

  print("✅ Vehicle saved offline with temp ID: ${vehicle.id}");
}

  Future<void> _syncPendingRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? pendingRecords = prefs.getStringList('pending_vehicles');

    if (pendingRecords != null && pendingRecords.isNotEmpty) {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        List<VehicleRecord> vehicles =
            pendingRecords
                .map((json) => VehicleRecord.fromJson(jsonDecode(json)))
                .toList();

        for (var vehicle in vehicles) {
          try {
            await ApiService().createVehicle(vehicle);
          } catch (e) {
            print("Error syncing record: $e");
          }
        }

        await prefs.remove('pending_vehicles'); // Clear after syncing
      }
    }
  }

  void _showSuccessDialog({bool isOffline = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success"),
          content: Text(
            isOffline
                ? "Vehicle saved offline. It will be synced when online."
                : "Vehicle record has been added successfully.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context, true); // Return success
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
  void initState() {
    super.initState();
    _syncPendingRecords(); // Try syncing pending records when screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add New Vehicle",
          style: TextStyle(
            color: Colors.white,
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
                          "Register New Vehicle",
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
                              "Save",
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
