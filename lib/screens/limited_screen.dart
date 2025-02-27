import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/vehicle_record.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import './CreateVehicleScreen.dart'; // Add this import
import './EditVehicleScreen.dart'; // Add this import

class LimitedScreen extends StatefulWidget {
  @override
  _LimitedScreenState createState() => _LimitedScreenState();
}

class _LimitedScreenState extends State<LimitedScreen> {
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
    _vehicles = ApiService().fetchVehicles();
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

void _fetchRecords() {
  setState(() {
    _vehicles = ApiService().fetchVehicles();
  });
}



  void _showVehicleDetails(VehicleRecord vehicle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
              child: Text("Close", style: TextStyle(fontSize: 16)),
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
            : Text("Vehicle Dashboard"),
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
                    List<VehicleRecord> vehicles = snapshot.data!;
                    List<VehicleRecord> filteredVehicles = vehicles.where((vehicle) {
                      return vehicle.plateNumber.toUpperCase().startsWith(_searchQuery);
                    }).toList();

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
}
