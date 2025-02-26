import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/vehicle_record.dart';

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
  Status _selectedStatus = Status.PENDING;

  void _submitForm() {
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

      ApiService().createVehicle(newVehicle).then((_) {
        Navigator.pop(context, true); // Return success
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error")),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add New Vehicle")),
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
                  child: Text("Save"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
