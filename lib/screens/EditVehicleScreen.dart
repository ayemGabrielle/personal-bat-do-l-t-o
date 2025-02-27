import 'package:flutter/material.dart';
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
    _plateNumberController = TextEditingController(text: widget.vehicle.plateNumber);
    _sectionController = TextEditingController(text: widget.vehicle.section);
    _nameController = TextEditingController(text: widget.vehicle.name ?? "");
    _addressController = TextEditingController(text: widget.vehicle.address ?? "");
    _areaController = TextEditingController(text: widget.vehicle.area ?? "");
    _selectedStatus = widget.vehicle.status;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      VehicleRecord updatedVehicle = VehicleRecord(
        id: widget.vehicle.id,
        plateNumber: _plateNumberController.text.trim(),
        section: _sectionController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        area: _areaController.text.trim(),
        status: _selectedStatus!,
        dateCreated: widget.vehicle.dateCreated, // Keep original dateCreated
        dateUpdated: DateTime.now(), // Update timestamp
        syncStatus: SyncStatus.PENDING, // Mark as pending sync
      );

      try {
        await ApiService().updateVehicle(widget.vehicle.id, updatedVehicle);
        Navigator.pop(context, true); // Return success
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Vehicle",
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
                          "Edit Vehicle Details",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildTextField(_plateNumberController, "Plate Number", Icons.directions_car),
                        _buildTextField(_sectionController, "Section", Icons.category),
                        _buildTextField(_nameController, "Name", Icons.person),
                        _buildTextField(_addressController, "Address", Icons.location_on),
                        _buildTextField(_areaController, "Area", Icons.map),
                        DropdownButtonFormField<Status>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: "Status",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: Status.values.map((Status status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.toString().split('.').last),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text("Update", style: TextStyle(fontSize: 16, color: Colors.white)),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
      ),
    );
  }
}