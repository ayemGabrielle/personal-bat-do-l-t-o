import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle_record.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'vehicles.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE vehicles(id TEXT PRIMARY KEY, plateNumber TEXT, section TEXT, name TEXT, address TEXT, area TEXT, status TEXT, syncStatus TEXT)",
        );
      },
    );
  }

  Future<void> insertVehicle(VehicleRecord vehicle) async {
    final db = await database;
    await db.insert('vehicles', vehicle.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<VehicleRecord>> getUnsyncedVehicles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vehicles', where: "syncStatus = ?", whereArgs: ['PENDING']);
    return List.generate(maps.length, (i) => VehicleRecord.fromMap(maps[i]));
  }

  Future<void> updateSyncStatus(String id, String syncStatus) async {
    final db = await database;
    await db.update('vehicles', {'syncStatus': syncStatus}, where: "id = ?", whereArgs: [id]);
  }
}
