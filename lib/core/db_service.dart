import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/vehicle_record.dart';

class DBService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    var directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, "lto_app.db");
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute("""
          CREATE TABLE vehicleRecords (
            id TEXT PRIMARY KEY,
            SECTION TEXT,
            PLATENUMBER TEXT UNIQUE,
            NAME TEXT,
            ADDRESS TEXT,
            AREA TEXT,
            STATUS TEXT,
            dateCreated TEXT,
            dateUpdated TEXT,
            syncStatus TEXT
          )
        """);
      },
    );
  }

  // Insert vehicle
  Future<void> insertVehicle(VehicleRecord record) async {
    final db = await database;
    await db.insert("vehicleRecords", record.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Fetch offline records
  Future<List<VehicleRecord>> fetchOfflineVehicles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query("vehicleRecords");
    return List.generate(maps.length, (i) => VehicleRecord.fromJson(maps[i]));
  }
}
