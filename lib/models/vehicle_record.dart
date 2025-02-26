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
      id: json['id'],
      section: json['SECTION'],
      plateNumber: json['PLATENUMBER'],
      name: json['NAME'],
      address: json['ADDRESS'],
      area: json['AREA'],
      status: json['STATUS'] == "RELEASED" ? Status.RELEASED : Status.UNRELEASED,
      dateCreated: DateTime.parse(json['dateCreated']),
      dateUpdated: DateTime.parse(json['dateUpdated']),
      syncStatus: json['syncStatus'] == "SYNCED" ? SyncStatus.SYNCED : SyncStatus.PENDING,
    );
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
