import 'package:flutter/material.dart';
import 'package:lto_app/core/api_service.dart';
import 'package:lto_app/models/mvfile.dart';
import '../../providers/auth_provider.dart';
import 'Edit-MVfile-Screen.dart';
import 'package:lto_app/screens/MV%20File/mvFile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/mvfile.dart';
import '../../core/api_service.dart';

class MVFileDashboardScreen extends StatefulWidget {
  @override
  _MVFileDashboardScreenState createState() => _MVFileDashboardScreenState();
}

class _MVFileDashboardScreenState extends State<MVFileDashboardScreen> {
  late Future<List<MVFile>> _mvFiles;
  int _currentPage = 0;
  int _rowsPerPage = 15;
  String _searchQuery = "";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mvFiles = Future.value([]); // Initialize with an empty list
    _fetchMVFiles();
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

  // Sync pending MV files - replace with actual implementation
  Future<void> _syncPendingMVFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Sync pending deletions
    List<String>? pendingDeletions = prefs.getStringList('pending_deletions');
    if (pendingDeletions != null && pendingDeletions.isNotEmpty) {
      List<String> remainingDeletions = [];

      for (String id in pendingDeletions) {
        try {
          await ApiService().deleteMVfile(id);
        } catch (e) {
          remainingDeletions.add(id); // Keep failed deletions for later sync
        }
      }

      await prefs.setStringList('pending_deletions', remainingDeletions);
    }

    // Sync pending records
    List<String>? pendingRecords = prefs.getStringList('pending_mv_files');
    if (pendingRecords != null && pendingRecords.isNotEmpty) {
      List<String> remainingRecords = [];

      for (String recordJson in pendingRecords) {
        try {
          MVFile record = MVFile.fromJson(jsonDecode(recordJson));
          // Replace with actual API call to create the record
          _createInAPI();
        } catch (e) {
          remainingRecords.add(recordJson);
        }
      }

      await prefs.setStringList('pending_mv_files', remainingRecords);
    }
  }

  // Simulated API fetch - replace with actual API call
  void _fetchMVFiles() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print(
        "⚠️ No internet connection. Loading MV files from local storage...",
      );
      List<MVFile> localMVFiles = await _loadMVFilesFromLocal();

      print("📂 Offline mode: Loaded ${localMVFiles.length} MV files.");
      setState(() {
        _mvFiles = Future.value(localMVFiles);
      });
    } else {
      try {
        await _syncPendingMVFiles(); // ✅ Sync offline MV file changes
        List<MVFile> mvFiles = await ApiService().fetchMVFiles();
        print("✅ Fetched ${mvFiles.length} MV files from API.");

        setState(() {
          _mvFiles = Future.value(mvFiles);
        });

        await _saveMVFilesToLocal(mvFiles); // ✅ Save for offline use
      } catch (e) {
        print("❌ API fetch failed: $e. Loading from local storage...");
        List<MVFile> localMVFiles = await _loadMVFilesFromLocal();

        print(
          "📂 Fallback: Loaded ${localMVFiles.length} MV files from storage.",
        );
        setState(() {
          _mvFiles = Future.value(localMVFiles);
        });
      }
    }
  }

  void _createInAPI() async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateMVFileScreen()),
    );

    if (result == true) {
      setState(() {
        _mvFiles = Future.value(ApiService().fetchMVFiles());
      });
    }
  }

  Future<void> deleteMVfile(MVFile mvFile) async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete thi  s MV file?"),
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

                // Remove the MV file from local storage first
                List<MVFile> mvFiles = await _loadMVFilesFromLocal();
                mvFiles.removeWhere((file) => file.id == mvFile.id);
                await _saveMVFilesToLocal(mvFiles);

                setState(() {
                  _mvFiles = Future.value(mvFiles); // Update UI immediately
                });

                if (connectivityResult == ConnectivityResult.none) {
                  // No internet: Queue deletion for later sync
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  List<String>? pendingDeletions =
                      prefs.getStringList('pending_deletions') ?? [];
                  pendingDeletions.add(mvFile.id);
                  await prefs.setStringList(
                    'pending_deletions',
                    pendingDeletions,
                  );

                  print("MV file deletion queued for sync: ${mvFile.id}");
                } else {
                  // Online: Delete from API
                  try {
                    await ApiService().deleteMVfile(mvFile.id);
                    print("MV file deleted from API: ${mvFile.id}");
                  } catch (e) {
                    print(
                      "Failed to delete online, adding to pending queue: $e",
                    );

                    // Store deletion request for later sync
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    List<String>? pendingDeletions =
                        prefs.getStringList('pending_deletions') ?? [];
                    pendingDeletions.add(mvFile.id);
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

  void _showMVFileDetails(MVFile mvFile) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("MV File Details"),
          content: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(color: Colors.grey, width: 1),
              columnWidths: {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
              children: [
                _buildTableRow("ID", mvFile.id),
                _buildTableRow("Section", mvFile.section),
                _buildTableRow("MV File Number", mvFile.mvFileNumber),
                _buildTableRow("Plate Number", mvFile.plateNumber ?? 'N/A'),
                _buildTableRow("Created", mvFile.dateCreated.toString()),
                _buildTableRow("Updated", mvFile.dateUpdated.toString()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                editRecord(mvFile);
              },
              child: Text("Edit"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteMVfile(mvFile);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void editRecord(MVFile mv_file) async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMVFileScreen(mvFile: mv_file),
      ),
    );

    if (result == true) {
      setState(() {
        _mvFiles = ApiService().fetchMVFiles(); // Refresh vehicle list
      });
    }
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

  // Save MV files to local storage
  Future<void> _saveMVFilesToLocal(List<MVFile> mvFiles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> mvFileJsonList =
        mvFiles
            .map((v) {
              try {
                return jsonEncode(v.toJson());
              } catch (e) {
                print("❌ Error encoding MV file: $e");
                return "";
              }
            })
            .where((v) => v.isNotEmpty)
            .toList();

    if (mvFileJsonList.isEmpty) {
      print("⚠️ No valid MV files to save.");
      return;
    }

    await prefs.setStringList('mv_files', mvFileJsonList);
    print("✅ Saved ${mvFileJsonList.length} MV files to local storage.");
  }

  // Load MV files from local storage
  Future<List<MVFile>> _loadMVFilesFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? mvFileJsonList = prefs.getStringList('mv_files');

    if (mvFileJsonList == null || mvFileJsonList.isEmpty) {
      print("⚠️ No saved MV file data found.");
      return [];
    }

    List<MVFile> mvFiles = [];

    for (String json in mvFileJsonList) {
      try {
        MVFile mvFile = MVFile.fromJson(jsonDecode(json));
        mvFiles.add(mvFile);
      } catch (e) {
        print("❌ Skipping corrupt record: $e");
      }
    }

    print("✅ Loaded ${mvFiles.length} MV files from storage.");
    return mvFiles;
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
          automaticallyImplyLeading: false,
          title:
              _isSearching
                  ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: "Search by MV File Number or Plate...",
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 16),
                      border: InputBorder.none,
                    ),
                    onChanged: _updateSearchQuery,
                  )
                  : Text(
                    'MV File Records',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24 * MediaQuery.of(context).textScaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          backgroundColor: Color(0xFF3b82f6),
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
                child: FutureBuilder<List<MVFile>>(
                  future: _mvFiles,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else {
                      List<MVFile> mvFiles = snapshot.data ?? [];

                      if (_searchQuery.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "images/app_icon.png",
                                width: 200,
                                height: 200,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "MV FILE RECORDS DASHBOARD",
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 255, 236, 200),
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Use the search bar to find an MV File.\n📝 Note: Type \"All\" to show all records.",
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

                      List<MVFile> filteredMVFiles =
                          _searchQuery.toUpperCase() == "ALL"
                              ? mvFiles
                              : mvFiles.where((mvFile) {
                                return mvFile.mvFileNumber
                                        .toUpperCase()
                                        .contains(_searchQuery) ||
                                    (mvFile.plateNumber?.toUpperCase().contains(
                                          _searchQuery,
                                        ) ??
                                        false);
                              }).toList();

                      if (filteredMVFiles.isEmpty) {
                        return Center(child: Text("No results found."));
                      }

                      int startIndex = _currentPage * _rowsPerPage;
                      int endIndex = startIndex + _rowsPerPage;
                      endIndex =
                          endIndex > filteredMVFiles.length
                              ? filteredMVFiles.length
                              : endIndex;
                      List<MVFile> paginatedMVFiles = filteredMVFiles.sublist(
                        startIndex,
                        endIndex,
                      );

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: paginatedMVFiles.length,
                              itemBuilder: (context, index) {
                                MVFile mvFile = paginatedMVFiles[index];
                                return GestureDetector(
                                  onTap:
                                      () => _showMVFileDetails(
                                        mvFile,
                                      ), // Opens the details dialog
                                  child: Card(
                                    elevation: 2,
                                    margin: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "MV File: ${mvFile.mvFileNumber}",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "Plate Number: ${mvFile.plateNumber ?? 'N/A'}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_left,
                                  color: Colors.blue,
                                ),
                                onPressed:
                                    _currentPage > 0 ? _goToPreviousPage : null,
                              ),
                              Text(
                                "Page ${_currentPage + 1}",
                                style: TextStyle(color: Colors.blue),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: Colors.blue,
                                ),
                                onPressed:
                                    (_currentPage + 1) * _rowsPerPage <
                                            filteredMVFiles.length
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
          onPressed: _createInAPI,
          backgroundColor: Colors.blue,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
