import 'dart:convert';
import 'package:intl/intl.dart';

enum Status { Released, Available, Inactive }
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
  DateTime? statusUpdateDate;

  VehicleRecord({
    required this.id,
    required this.section,
    required this.plateNumber,
    this.name,
    this.address,
    this.area,
    this.status = Status.Available,
    required this.dateCreated,
    required this.dateUpdated,
    this.syncStatus = SyncStatus.PENDING,
    this.statusUpdateDate,
  });

  // Convert JSON to VehicleRecord object
factory VehicleRecord.fromJson(Map<String, dynamic> json) {
  return VehicleRecord(
    id: json['id']?.toString() ?? "UNKNOWN", // Ensures it is a String
    section: json['SECTION']?.toString() ?? "N/A", // Ensures it is a String
    plateNumber: json['PLATENUMBER']?.toString() ?? "N/A", // Ensures it is a String
    name: json['NAME']?.toString(), // Nullable, so no default
    address: json['ADDRESS']?.toString(), // Nullable, so no default
    area: json['AREA']?.toString(), // Nullable, so no default
    status: json['STATUS'] != null
        ? Status.values.firstWhere(
            (e) => e.toString().split('.').last == json['STATUS'],
            orElse: () => Status.Available,
          )
        : Status.Available,
    dateCreated: json['dateCreated'] != null
        ? DateTime.tryParse(json['dateCreated'])?.toLocal() ?? DateTime.now()
        : DateTime.now(),
    dateUpdated: json['dateUpdated'] != null
        ? DateTime.tryParse(json['dateUpdated'])?.toLocal() ?? DateTime.now()
        : DateTime.now(),
    statusUpdateDate: json['statusUpdateDate'] != null
        ? DateTime.tryParse(json['statusUpdateDate'])
        : null,
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
      status: map['status'] != null
        ? Status.values.firstWhere((e) => e.toString().split('.').last == map['status'])
        : Status.Available,
      dateCreated: DateTime.parse(map['dateCreated']),
      dateUpdated: DateTime.parse(map['dateUpdated']),
      statusUpdateDate: map['statusUpdateDate'] != null
          ? DateTime.tryParse(map['statusUpdateDate'])
          : null,

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
      'statusUpdateDate': statusUpdateDate?.toIso8601String(),
    };
  }

  // Format statusUpdateDate in readable PH time format
  String get formattedStatusUpdateDate {
    if (statusUpdateDate == null) return "N/A";
    final formatter = DateFormat("MMMM d, yyyy hh:mm a"); // Example: March 13, 2025 10:30 AM
    return formatter.format(statusUpdateDate!);
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
      'STATUS': status?.toString().split('.').last,
      'statusUpdateDate': statusUpdateDate?.toUtc().toIso8601String(),
    };
  }

  
}
