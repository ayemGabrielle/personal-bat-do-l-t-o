import 'database_helper.dart';
import 'api_service.dart';
import 'connectivity_service.dart';
import '../models/vehicle_record.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();

  Future<void> syncPendingData() async {
    if (await _connectivityService.isOnline()) {
      List<VehicleRecord> unsyncedVehicles = await _dbHelper.getUnsyncedVehicles();

      for (var vehicle in unsyncedVehicles) {
        try {
          await _apiService.updateVehicle(vehicle.id, vehicle);
          await _dbHelper.updateSyncStatus(vehicle.id, 'SYNCED'); // Mark as synced
        } catch (error) {
          print("Sync failed: $error");
        }
      }
    }
  }

  void monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncPendingData();
      }
    });
  }
}
