import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lto_app/models/mvfile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';

class EditMVFileScreen extends StatefulWidget {
  final MVFile mvFile;

  EditMVFileScreen({required this.mvFile});

  @override
  _EditMVFileScreenState createState() => _EditMVFileScreenState();
}

class _EditMVFileScreenState extends State<EditMVFileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _sectionController;
  late TextEditingController _mvFileNumberController;
  late TextEditingController _plateNumberController;

@override
void initState() {
  super.initState();
  _listenForConnectivityChanges();

    _sectionController = TextEditingController(text: widget.mvFile.section);
    _mvFileNumberController = TextEditingController(
      text: widget.mvFile.mvFileNumber,
    );
    _plateNumberController = TextEditingController(
      text: widget.mvFile.plateNumber,
    );
    _syncPendingEdits();

    Connectivity().onConnectivityChanged.listen((connectivityResult) async {
      if (connectivityResult != ConnectivityResult.none) {
        print("🌐 Internet restored! Attempting to sync...");
        await _syncPendingEdits();
      }
    });
  }

  void _listenForConnectivityChanges() {
  Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
    if (results.any((result) => result != ConnectivityResult.none)) {
      _syncPendingEdits();
    }
  });
}

  Future<bool> _isOnline() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}


  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      MVFile updatedMVFile = MVFile(
        id: widget.mvFile.id,
        section: _sectionController.text.trim().toUpperCase(),
        mvFileNumber: _mvFileNumberController.text.trim().toUpperCase(),
        plateNumber: _plateNumberController.text.trim().toUpperCase(),
      );

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await ApiService().updateMVFile(widget.mvFile.id, updatedMVFile);
          _showSuccessDialog();
        } catch (error) {
          _showErrorSnackbar(error.toString());
        }
      } else {
        await _savePendingEdit(updatedMVFile);
        _showSuccessDialog(isOffline: true);
      }
    }
  }

  Future<void> _savePendingEdit(MVFile mvFile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pendingEdits =
        prefs.getStringList('pending_mvfile_updates') ?? [];

    // Remove any existing edit for this ID before adding a new one
    pendingEdits.removeWhere((item) {
      Map<String, dynamic> existing = jsonDecode(item);
      return existing["id"] == mvFile.id;
    });

    // Save the new edit with the ID included
    pendingEdits.add(jsonEncode({"id": mvFile.id, "mvFile": mvFile.toJson()}));
    await prefs.setStringList('pending_mvfile_updates', pendingEdits);

    print("📌 Saved pending edit for MVFile ${mvFile.id}");
  }

Future<void> _syncPendingEdits() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? pendingEdits = prefs.getStringList('pending_mvfile_updates');

  if (pendingEdits == null || pendingEdits.isEmpty) {
    print("✅ No pending MVFile edits to sync.");
    return;
  }

  print("🔄 Attempting to sync ${pendingEdits.length} pending edits...");

  if (!(await _isOnline())) {
    print("⚠️ Still offline, cannot sync pending edits.");
    return;
  }

  List<String> unsyncedEdits = [];

  for (String json in pendingEdits) {
    Map<String, dynamic> data = jsonDecode(json);
    String id = data["id"];
    MVFile mvFile = MVFile.fromJson(data["mvFile"]);

    try {
      await ApiService().updateMVFile(id, mvFile);
      print("✅ Synced MVFile ${mvFile.id}");
    } catch (e) {
      print("❌ Failed to sync MVFile ${mvFile.id}: $e");
      unsyncedEdits.add(json); // Keep unsynced edits
    }
  }

  await prefs.setStringList('pending_mvfile_updates', unsyncedEdits);
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
                ? "MV File edit saved offline. It will be synced when online."
                : "MV File record has been updated successfully.",
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
          "Edit MV File",
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
                          "Edit MV File",
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
        validator: validator,
      ),
    );
  }
}
