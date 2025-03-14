import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/vehicle_record.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import './CreateVehicleScreen.dart';
import './EditVehicleScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

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
      MaterialPageRoute(
        builder: (context) => EditVehicleScreen(vehicle: vehicle),
      ),
    );

    if (result == true) {
      setState(() {
        _vehicles = ApiService().fetchVehicles(); // Refresh vehicle list
      });
    }
  }

  // void _fetchRecords() async {
  //   try {
  //     await _syncPendingRecords(); // Sync offline data when fetching
  //     List<VehicleRecord> vehicles = await ApiService().fetchVehicles();
  //     setState(() {
  //       _vehicles = Future.value(vehicles);
  //     });
  //     _saveVehiclesToLocal(vehicles); // Save fetched data
  //   } catch (e) {
  //     setState(() {
  //       _vehicles = _loadVehiclesFromLocal();
  //     });
  //   }
  // }

  void _fetchRecords() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("⚠️ No internet connection. Loading from local storage...");
      List<VehicleRecord> localVehicles = await _loadVehiclesFromLocal();

      print("📂 Offline mode: Loaded ${localVehicles.length} vehicles.");
      setState(() {
        _vehicles = Future.value(localVehicles);
      });
    } else {
      try {
        await _syncPendingRecords(); // ✅ Sync offline data
        List<VehicleRecord> vehicles = await ApiService().fetchVehicles();
        print("✅ Fetched ${vehicles.length} records from API.");

        setState(() {
          _vehicles = Future.value(vehicles);
        });

        await _saveVehiclesToLocal(vehicles); // ✅ Save for offline use
      } catch (e) {
        print("❌ API fetch failed: $e. Loading from local storage...");
        List<VehicleRecord> localVehicles = await _loadVehiclesFromLocal();

        print(
          "📂 Fallback: Loaded ${localVehicles.length} vehicles from storage.",
        );
        setState(() {
          _vehicles = Future.value(localVehicles);
        });
      }
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

  Future<void> _syncPendingRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Sync pending deletions
    List<String>? pendingDeletions = prefs.getStringList('pending_deletions');
    if (pendingDeletions != null && pendingDeletions.isNotEmpty) {
      List<String> remainingDeletions = [];

      for (String id in pendingDeletions) {
        try {
          await ApiService().deleteVehicle(id);
        } catch (e) {
          remainingDeletions.add(id); // Keep failed deletions for later sync
        }
      }

      await prefs.setStringList('pending_deletions', remainingDeletions);
    }

    // Sync other pending records (existing logic)
    List<String>? pendingRecords = prefs.getStringList('pending_vehicles');
    if (pendingRecords != null && pendingRecords.isNotEmpty) {
      List<String> remainingRecords = [];

      for (String recordJson in pendingRecords) {
        try {
          VehicleRecord record = VehicleRecord.fromJson(jsonDecode(recordJson));
          await ApiService().createVehicle(record);
        } catch (e) {
          remainingRecords.add(
            recordJson,
          ); // Keep failed records for later sync
        }
      }

      await prefs.setStringList('pending_vehicles', remainingRecords);
    }
  }

  void _deleteRecord(String id) async {
    // Close the vehicle details dialog first
    Navigator.pop(context);

    // Show confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Text(
              "Are you sure you want to delete this vehicle record?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the confirmation dialog

                var connectivityResult =
                    await Connectivity().checkConnectivity();

                // Remove the vehicle from local storage first
                List<VehicleRecord> vehicles = await _loadVehiclesFromLocal();
                vehicles.removeWhere((vehicle) => vehicle.id == id);
                await _saveVehiclesToLocal(vehicles);

                setState(() {
                  _vehicles = Future.value(vehicles); // Update UI immediately
                });

                if (connectivityResult == ConnectivityResult.none) {
                  // No internet: Queue deletion for later sync
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  List<String>? pendingDeletions =
                      prefs.getStringList('pending_deletions') ?? [];
                  pendingDeletions.add(id);
                  await prefs.setStringList(
                    'pending_deletions',
                    pendingDeletions,
                  );

                  print("Vehicle deletion queued for sync: $id");
                } else {
                  // Online: Delete from API immediately
                  try {
                    await ApiService().deleteVehicle(id);
                    print("Vehicle deleted from API: $id");
                  } catch (e) {
                    print(
                      "Failed to delete online, adding to pending queue: $e",
                    );

                    // Store the deletion request for later
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    List<String>? pendingDeletions =
                        prefs.getStringList('pending_deletions') ?? [];
                    pendingDeletions.add(id);
                    await prefs.setStringList(
                      'pending_deletions',
                      pendingDeletions,
                    );
                  }
                }
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
          title: Center(
            child: Text(
              "Vehicle Details",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ), // Bigger text
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
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _editRecord(vehicle),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            textStyle: TextStyle(fontSize: 14),
                          ),
                          icon: Icon(Icons.edit, size: 18, color: Colors.white),
                          label: Text(
                            "Edit",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: 8), // Space between buttons
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteRecord(vehicle.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            textStyle: TextStyle(fontSize: 14),
                          ),
                          icon: Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            "Delete",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16), // Space before Close button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        textStyle: TextStyle(fontSize: 14),
                      ),
                      icon: Icon(Icons.close, size: 18, color: Colors.white),
                      label: Text(
                        "Close",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
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
        Padding(padding: const EdgeInsets.all(8.0), child: Text(value)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("images/LTO-BG-3.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // This removes the back button
          title:
              _isSearching
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
                  : Text(
                    'Vehicle Records',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:
                          24 *
                          MediaQuery.of(
                            context,
                          ).textScaleFactor, // Scalable text
                      fontWeight: FontWeight.bold,
                    ),
                  ),

          backgroundColor: Color(0xFF3b82f6),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
          actions: [
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.white,
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

                      // If no search is performed, display a message
                      if (_searchQuery.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize:
                                MainAxisSize
                                    .min, // Ensures column shrinks to fit
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
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    236,
                                    200,
                                  ),
                                  border: Border.all(
                                    color: const Color.fromARGB(255, 255, 0, 0),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Use the search bar to find a vehicle.\n📝 Note: Type \"All\" to show all records.",
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

                      // Apply filtering based on search query
                      // Apply filtering based on search query
                      List<VehicleRecord> filteredVehicles;
                      if (_searchQuery.toUpperCase() == "ALL") {
                        filteredVehicles = vehicles;
                      } else {
                        filteredVehicles =
                            vehicles.where((vehicle) {
                              return vehicle.plateNumber
                                  .toUpperCase()
                                  .startsWith(_searchQuery);
                            }).toList();
                      }

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
                                    const Color.fromARGB(242, 255, 255, 255),
                                  ),
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        'Plate Number',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18, // Bigger text
                                          color:
                                              Colors.black, // Darker contrast
                                        ),
                                      ),
                                    ),

                                    DataColumn(
                                      label: Text(
                                        'Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18, // Bigger text
                                          color:
                                              Colors.black, // Darker contrast
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
                                                  fontSize: 18,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ), // Adjust font size here
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
                                icon: Icon(
                                  Icons.chevron_left,
                                  color: Colors.blue,
                                ), // Change icon color here
                                onPressed:
                                    _currentPage > 0 ? _goToPreviousPage : null,
                              ),
                              Text(
                                "Page ${_currentPage + 1}",
                                style: TextStyle(
                                  color: Colors.blue,
                                ), // Change text color here
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: Colors.blue,
                                ), // Change icon color here
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
        floatingActionButton: FloatingActionButton(
          onPressed: _createNewRecord,
          backgroundColor: Colors.blue,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // Save vehicle data to local storage
  Future<void> _saveVehiclesToLocal(List<VehicleRecord> vehicles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> vehicleJsonList =
        vehicles
            .map((v) {
              try {
                return jsonEncode(v.toJson()); // ✅ Ensure valid JSON
              } catch (e) {
                print("❌ Error encoding vehicle: $e");
                return ""; // Skip corrupted data
              }
            })
            .where((v) => v.isNotEmpty)
            .toList(); // ✅ Remove empty data

    if (vehicleJsonList.isEmpty) {
      print("⚠️ No valid vehicles to save.");
      return;
    }

    await prefs.setStringList('vehicles', vehicleJsonList);
    print("✅ Saved ${vehicleJsonList.length} vehicles to local storage.");
  }

  // Load vehicles from local storage
  Future<List<VehicleRecord>> _loadVehiclesFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? vehicleJsonList = prefs.getStringList('vehicles');

    if (vehicleJsonList == null || vehicleJsonList.isEmpty) {
      print("⚠️ No saved vehicle data found.");
      return [];
    }

    List<VehicleRecord> vehicles = [];

    for (String json in vehicleJsonList) {
      try {
        VehicleRecord vehicle = VehicleRecord.fromJson(jsonDecode(json));
        vehicles.add(vehicle);
      } catch (e) {
        print("❌ Skipping corrupt record: $e");
      }
    }

    print("✅ Loaded ${vehicles.length} vehicles from storage.");
    return vehicles;
  }
}
