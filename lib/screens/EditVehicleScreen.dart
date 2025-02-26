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
      appBar: AppBar(title: Text("Edit Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _plateNumberController,
                  decoration: InputDecoration(labelText: "Plate Number"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter Plate Number" : null,
                ),
                TextFormField(
                  controller: _sectionController,
                  decoration: InputDecoration(labelText: "Section"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter Section" : null,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: "Address"),
                ),
                TextFormField(
                  controller: _areaController,
                  decoration: InputDecoration(labelText: "Area"),
                ),
                DropdownButtonFormField<Status>(
                  value: _selectedStatus,
                  decoration: InputDecoration(labelText: "Status"),
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
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text("Update"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
