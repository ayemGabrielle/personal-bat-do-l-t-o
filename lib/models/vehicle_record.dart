import 'dart:convert';
import 'package:intl/intl.dart';

enum Status { Released, Available }
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
  DateTime? parsedStatusUpdateDate = json['statusUpdateDate'] != null
      ? DateTime.tryParse(json['statusUpdateDate']) // No .toLocal()
      : null;

  return VehicleRecord(
    id: json['id'] ?? "", 
    section: json['SECTION'],
    plateNumber: json['PLATENUMBER'],
    name: json['NAME'],
    address: json['ADDRESS'],
    area: json['AREA'],
    status: Status.values.firstWhere(
      (e) => e.toString().split('.').last == json['STATUS'],
      orElse: () => Status.Available,
    ),
    dateCreated: DateTime.tryParse(json['dateCreated'] ?? '') ?? DateTime.now(),
    dateUpdated: DateTime.tryParse(json['dateUpdated'] ?? '') ?? DateTime.now(),
    syncStatus: SyncStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json['syncStatus'],
      orElse: () => SyncStatus.PENDING,
    ),
    statusUpdateDate: parsedStatusUpdateDate, 
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
      statusUpdateDate: DateTime.parse(map['statusUpdateDate']),
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
      'STATUS': status.toString().split('.').last,
      'dateCreated': dateCreated.toIso8601String(),
      'dateUpdated': dateUpdated.toIso8601String(),
      'syncStatus': syncStatus.toString().split('.').last,
      'statusUpdateDate': statusUpdateDate?.toIso8601String(), // Store in ISO format
      'formattedStatusUpdateDate': formattedStatusUpdateDate, // Human-readable format
    };
  }

  
}
