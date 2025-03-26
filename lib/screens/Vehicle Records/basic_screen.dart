import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/vehicle_record.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import 'CreateVehicleScreen.dart'; // Add this import
import 'EditVehicleScreen.dart'; // Add this import

class BasicScreen extends StatefulWidget {
  @override
  _BasicScreenState createState() => _BasicScreenState();
}

class _BasicScreenState extends State<BasicScreen> {
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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _logout(); // Proceed with logout
              },
              child: Text("Logout", style: TextStyle(color: Colors.red)),
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
          title: Center(
            child: Text(
              "Vehicle Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
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
                  _buildTableRow(
                    "Status",
                    vehicle.status.toString().split('.').last,
                  ),
                  _buildTableRow("Created", vehicle.dateCreated.toString()),
                  _buildTableRow("Updated", vehicle.dateUpdated.toString()),
                  _buildTableRow(
                    "Status Updated",
                    vehicle.formattedStatusUpdateDate,
                  ),
                ],
              ),
            ),
          ),
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
        Padding(padding: const EdgeInsets.all(8.0), child: Text(value)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    hintText: "Search by Plate Number...",
                    hintStyle: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: _updateSearchQuery,
                )
                : Text(
                  'Vehicle Records',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
        backgroundColor: Color(0xFF3b82f6),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: _confirmLogout,
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

                    // Hide table until search is performed
                    if (_searchQuery.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, // Ensures column shrinks to fit
                          children: [
                            // Extra spacing at the top
                            SizedBox(height: 40), // Adjust as needed
                            // Logo & Text
                            Image.asset(
                              "images/app_icon.png",
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "BATANGAS DISTRICT OFFICE REPLACEMENT PLATE",
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(
                              height: 20,
                            ), // Spacing between text and note
                            // Note Container
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 236, 200),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 255, 0, 0),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Use the search bar to find a vehicle.",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    List<VehicleRecord> filteredVehicles =
                        vehicles.where((vehicle) {
                          return vehicle.plateNumber.toUpperCase().startsWith(
                            _searchQuery,
                          );
                        }).toList();

                    if (filteredVehicles.isEmpty) {
                      return Center(child: Text("No results found."));
                    }

                    int startIndex = _currentPage * _rowsPerPage;
                    int endIndex = startIndex + _rowsPerPage;
                    endIndex =
                        endIndex > filteredVehicles.length
                            ? filteredVehicles.length
                            : endIndex;
                    List<VehicleRecord> paginatedVehicles = filteredVehicles
                        .sublist(startIndex, endIndex);

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width,
                              ),
                              child: DataTable(
                                sortColumnIndex: _currentSortColumn,
                                sortAscending: _isAscending,
                                headingRowColor: MaterialStateProperty.all(
                                  Color(0xFFE8F0FE),
                                ),
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      'Plate Number',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            20, // Increased header font size
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            20, // Increased header font size
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                                rows:
                                    paginatedVehicles.map((vehicle) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              vehicle.plateNumber,
                                              style: TextStyle(
                                                fontSize: 20,
                                              ), // Increased cell text font size
                                            ),
                                            onTap:
                                                () => _showVehicleDetails(
                                                  vehicle,
                                                ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    vehicle.status ==
                                                            Status.Released
                                                        ? const Color.fromARGB(
                                                          255,
                                                          187,
                                                          247,
                                                          209,
                                                        )
                                                        : const Color.fromARGB(
                                                          255,
                                                          254,
                                                          216,
                                                          171,
                                                        ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      50,
                                                    ), // Creates an oval shape
                                              ),
                                              child: Text(
                                                vehicle.status
                                                    .toString()
                                                    .split('.')
                                                    .last,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      vehicle.status ==
                                                              Status.Released
                                                          ? Color.fromARGB(
                                                            255,
                                                            38,
                                                            115,
                                                            67,
                                                          )
                                                          : Color.fromARGB(
                                                            255,
                                                            148,
                                                            32,
                                                            26,
                                                          ),
                                                ),
                                              ),
                                            ),
                                            onTap:
                                                () => _showVehicleDetails(
                                                  vehicle,
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
                              onPressed:
                                  _currentPage > 0 ? _goToPreviousPage : null,
                            ),
                            Text("Page ${_currentPage + 1}"),
                            IconButton(
                              icon: Icon(Icons.chevron_right),
                              onPressed:
                                  (_currentPage + 1) * _rowsPerPage <
                                          filteredVehicles.length
                                      ? _goToNextPage
                                      : null,
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
    );
  }

  // Save vehicle data to local storage
  Future<void> _saveVehiclesToLocal(List<VehicleRecord> vehicles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> vehicleJsonList =
        vehicles.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList('vehicles', vehicleJsonList);
  }

  // Load vehicles from local storage
  Future<List<VehicleRecord>> _loadVehiclesFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? vehicleJsonList = prefs.getStringList('vehicles');

    if (vehicleJsonList != null) {
      return vehicleJsonList
          .map((json) => VehicleRecord.fromJson(jsonDecode(json)))
          .toList();
    } else {
      return [];
    }
  }
}
