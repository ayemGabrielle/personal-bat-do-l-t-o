import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/mvfile.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateMVFileScreen extends StatefulWidget {
  @override
  _CreateMVFileScreenState createState() => _CreateMVFileScreenState();
}

class _CreateMVFileScreenState extends State<CreateMVFileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mvFileNumberController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  List<MVFile> _mvFiles = []; // List to store MVFile records

void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    MVFile newMVFile = MVFile(
      id: "",
      mvFileNumber: _mvFileNumberController.text.trim(),
      plateNumber: _plateNumberController.text.trim(),
      section: _sectionController.text.trim(),
      dateCreated: DateTime.now(),
      dateUpdated: DateTime.now(),
    ); // ❌ Remove id field entirely

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      // Device is online - send to API
      try {
        await ApiService().createMvFile(newMVFile);
        _showSuccessDialog();
      } catch (error) {
        _showErrorSnackbar(error.toString());
      }
    } else {
      // Device is offline - save to local storage
      await _savePendingRecord(newMVFile);
      _showSuccessDialog(isOffline: true);
    }
  }
}


  Future<void> _savePendingRecord(MVFile mvFile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? pendingRecords = prefs.getStringList('pending_mvfiles') ?? [];

    // Assign a temporary ID (if empty) for tracking
    if (mvFile.id.isEmpty) {
      mvFile.id = "local_${DateTime.now().millisecondsSinceEpoch}";
    }

    pendingRecords.add(jsonEncode(mvFile.toJson()));
    await prefs.setStringList('pending_mvfiles', pendingRecords);

    // ✅ Show new record in the UI immediately
    setState(() {
      _mvFiles.add(mvFile);
    });

    print("✅ MV File saved offline with temp ID: ${mvFile.id}");
  }

  Future<void> _syncPendingRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? pendingRecords = prefs.getStringList('pending_mvfiles');

    if (pendingRecords != null && pendingRecords.isNotEmpty) {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        List<MVFile> mvFiles = pendingRecords
            .map((json) => MVFile.fromJson(jsonDecode(json)))
            .toList();

        for (var mvFile in mvFiles) {
          try {
            await ApiService().createMvFile(mvFile);
          } catch (e) {
            print("Error syncing record: $e");
          }
        }

        await prefs.remove('pending_mvfiles'); // Clear after syncing
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
                ? "MV File saved offline. It will be synced when online."
                : "MV File record has been added successfully.",
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
          "Add MV File",
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
                          "Register New MV File",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          _mvFileNumberController,
                          "MV File Number",
                          Icons.insert_drive_file,
                        ),
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
