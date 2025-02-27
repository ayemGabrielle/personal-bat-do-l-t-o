import 'dart:convert';

enum Status { RELEASED, UNRELEASED }
enum SyncStatus { PENDING, SYNCED }

class VehicleRecord {
  String id;
  String section;
  String plateNumber;
  String? name;
  String? address;
  String? area;
  Status? status;
  DateTime dateCreated;
  DateTime dateUpdated;
  SyncStatus syncStatus;

  VehicleRecord({
    required this.id,
    required this.section,
    required this.plateNumber,
    this.name,
    this.address,
    this.area,
    this.status = Status.UNRELEASED,
    required this.dateCreated,
    required this.dateUpdated,
    this.syncStatus = SyncStatus.PENDING,
  });

// Convert JSON to VehicleRecord object
factory VehicleRecord.fromJson(Map<String, dynamic> json) {
  return VehicleRecord(
    id: json['id'] ?? "",  // Avoid null errors
    section: json['SECTION'],
    plateNumber: json['PLATENUMBER'],
    name: json['NAME'],
    address: json['ADDRESS'],
    area: json['AREA'],
    status: Status.values.firstWhere(
      (e) => e.toString().split('.').last == json['STATUS'],
      orElse: () => Status.UNRELEASED, // Default value
    ),
    dateCreated: DateTime.tryParse(json['dateCreated'] ?? '') ?? DateTime.now(),
    dateUpdated: DateTime.tryParse(json['dateUpdated'] ?? '') ?? DateTime.now(),
    syncStatus: SyncStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json['syncStatus'],
      orElse: () => SyncStatus.PENDING, // Default value
    ),
  );
}


  factory VehicleRecord.fromMap(Map<String, dynamic> map) {
    return VehicleRecord(
      id: map['id'],
      plateNumber: map['plateNumber'],
      section: map['section'],
      name: map['name'],
      address: map['address'],
      area: map['area'],
      status: map['status'],
      dateCreated: DateTime.parse(map['dateCreated']),
      dateUpdated: DateTime.parse(map['dateUpdated']),
      syncStatus: map['syncStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'section': section,
      'name': name,
      'address': address,
      'area': area,
      'status': status,
      'syncStatus': syncStatus,
    };
  }


  // Convert VehicleRecord object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'SECTION': section,
      'PLATENUMBER': plateNumber,
      'NAME': name,
      'ADDRESS': address,
      'AREA': area,
      'STATUS': status.toString().split('.').last,
      'dateCreated': dateCreated.toIso8601String(),
      'dateUpdated': dateUpdated.toIso8601String(),
      'syncStatus': syncStatus.toString().split('.').last,
    };
  }
}
