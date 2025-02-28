import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/vehicle_record.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import './CreateVehicleScreen.dart'; // Add this import
import './EditVehicleScreen.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Add this import

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<VehicleRecord>> _vehicles;
  int _currentPage = 0;
  int _rowsPerPage = 15;
  String _searchQuery = "";
  int _currentSortColumn = 0;
  bool _isAscending = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vehicles = Future.value([]); // Initialize with an empty list
    _fetchRecords();
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toUpperCase();
      _currentPage = 0;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = "";
        _searchController.clear();
      }
    });
  }

  void _goToNextPage() {
    setState(() {
      _currentPage++;
    });
  }

  void _goToPreviousPage() {
    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
      }
    });
  }

  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/login');
    
  }

void _createNewRecord() async {
  bool? result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => CreateVehicleScreen()),
  );

  if (result == true) {
    setState(() {
      _vehicles = ApiService().fetchVehicles(); // Refresh vehicle list
    });
  }
}


void _editRecord(VehicleRecord vehicle) async {
  bool? result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => EditVehicleScreen(vehicle: vehicle)),
  );

  if (result == true) {
    setState(() {
      _vehicles = ApiService().fetchVehicles(); // Refresh vehicle list
    });
  }
}

void _fetchRecords() async {
  try {
    List<VehicleRecord> vehicles = await ApiService().fetchVehicles();
    setState(() {
      _vehicles = Future.value(vehicles);
    });
    _saveVehiclesToLocal(vehicles); // Save fetched data
  } catch (e) {
    // Load from local storage if API fails
    setState(() {
      _vehicles = _loadVehiclesFromLocal();
    });
  }
}




  void _deleteRecord(String id) {
    // Show confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this vehicle record?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                ApiService().deleteVehicle(id).then((_) {
                  setState(() {
                    _vehicles = ApiService().fetchVehicles(); // Refresh list after delete
                  });
                  Navigator.pop(context);
                });
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showVehicleDetails(VehicleRecord vehicle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFFE8F0FE),
          title: Center(
            child: Text("Vehicle Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          content: SingleChildScrollView(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: Colors.grey, width: 1),
                columnWidths: {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
                children: [
                  _buildTableRow("Plate Number", vehicle.plateNumber),
                  _buildTableRow("Section", vehicle.section),
                  _buildTableRow("Name", vehicle.name ?? 'N/A'),
                  _buildTableRow("Address", vehicle.address ?? 'N/A'),
                  _buildTableRow("Area", vehicle.area ?? 'N/A'),
                  _buildTableRow("Status", vehicle.status.toString().split('.').last),
                  _buildTableRow("Created", vehicle.dateCreated.toString()),
                  _buildTableRow("Updated", vehicle.dateUpdated.toString()),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: "Search by Plate Number...",
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 16),
                  border: InputBorder.none,
                ),
                onChanged: _updateSearchQuery,
              )
            : Text("Vehicle Records"),
        backgroundColor: Color(0xFF3b82f6), titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
                child: FutureBuilder<List<VehicleRecord>>(
                  future: _vehicles,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else {
                      List<VehicleRecord> vehicles = snapshot.data ?? [];

                      // If no search is performed, display a message
                      if (_searchQuery.isEmpty) {
                        return Center(child: Text("Use the search bar to find a vehicle."));
                      }

                      // Apply filtering based on search query
                      List<VehicleRecord> filteredVehicles = vehicles.where((vehicle) {
                        return vehicle.plateNumber.toUpperCase().startsWith(_searchQuery);
                      }).toList();

                      if (filteredVehicles.isEmpty) {
                        return Center(child: Text("No results found."));
                      }

                      int startIndex = _currentPage * _rowsPerPage;
                      int endIndex = startIndex + _rowsPerPage;
                      endIndex = endIndex > filteredVehicles.length ? filteredVehicles.length : endIndex;
                      List<VehicleRecord> paginatedVehicles = filteredVehicles.sublist(startIndex, endIndex);

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                              child: DataTable(
                                sortColumnIndex: _currentSortColumn,
                                sortAscending: _isAscending,
                                headingRowColor: MaterialStateProperty.all(Color(0xFFE8F0FE)),
                                columns: [
                                  DataColumn(label: Text('Plate Number', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3b82f6)))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3b82f6)))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3b82f6)))),
                                ],
                                rows: paginatedVehicles.map((vehicle) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(vehicle.plateNumber),
                                        onTap: () => _showVehicleDetails(vehicle),
                                      ),
                                      DataCell(Text(vehicle.status.toString().split('.').last)),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit, color: Colors.green),
                                              onPressed: () => _editRecord(vehicle),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteRecord(vehicle.id),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left),
                              onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                            ),
                            Text("Page ${_currentPage + 1}"),
                            IconButton(
                              icon: Icon(Icons.chevron_right),
                              onPressed: (_currentPage + 1) * _rowsPerPage < filteredVehicles.length ? _goToNextPage : null,
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewRecord,
        backgroundColor: Color(0xFF3b82f6),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

      // Save vehicle data to local storage
    Future<void> _saveVehiclesToLocal(List<VehicleRecord> vehicles) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> vehicleJsonList = vehicles.map((v) => jsonEncode(v.toJson())).toList();
      await prefs.setStringList('vehicles', vehicleJsonList);
    }

    // Load vehicles from local storage
    Future<List<VehicleRecord>> _loadVehiclesFromLocal() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? vehicleJsonList = prefs.getStringList('vehicles');
      
      if (vehicleJsonList != null) {
        return vehicleJsonList.map((json) => VehicleRecord.fromJson(jsonDecode(json))).toList();
      } else {
        return [];
      }
    }

}
