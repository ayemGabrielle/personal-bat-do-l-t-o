import 'dart:convert';
import 'package:intl/intl.dart';

enum SyncStatus { PENDING, SYNCED }

class MVFile {
  String id;
  String section;
  String mvFileNumber;
  String plateNumber;
  SyncStatus syncStatus;
  DateTime dateCreated;
  DateTime dateUpdated;

  MVFile({
    required this.id,
    required this.section,
    required this.mvFileNumber,
    required this.plateNumber,
    this.syncStatus = SyncStatus.PENDING,
    required this.dateCreated,
    required this.dateUpdated,
  });

  // Convert JSON to MVFile object
  factory MVFile.fromJson(Map<String, dynamic> json) {
    return MVFile(
      id: json['id']?.toString() ?? "UNKNOWN",
      section: json['SECTION']?.toString() ?? "N/A",
      mvFileNumber: json['MVFILENUMBER']?.toString() ?? "N/A",
      plateNumber: json['PLATENUMBER']?.toString() ?? "N/A",
      syncStatus: json['syncStatus'] != null
          ? SyncStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['syncStatus'],
              orElse: () => SyncStatus.PENDING,
            )
          : SyncStatus.PENDING,
      dateCreated: json['dateCreated'] != null
          ? DateTime.tryParse(json['dateCreated'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      dateUpdated: json['dateUpdated'] != null
          ? DateTime.tryParse(json['dateUpdated'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Convert Map to MVFile object
  factory MVFile.fromMap(Map<String, dynamic> map) {
    return MVFile(
      id: map['id'],
      section: map['section'],
      mvFileNumber: map['mvFileNumber'],
      plateNumber: map['plateNumber'],
      syncStatus: map['syncStatus'] != null
          ? SyncStatus.values.firstWhere(
              (e) => e.toString().split('.').last == map['syncStatus'])
          : SyncStatus.PENDING,
      dateCreated: DateTime.parse(map['dateCreated']),
      dateUpdated: DateTime.parse(map['dateUpdated']),
    );
  }

  // Convert MVFile object to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'section': section,
      'mvFileNumber': mvFileNumber,
      'plateNumber': plateNumber,
      'syncStatus': syncStatus.toString().split('.').last,
      'dateCreated': dateCreated.toIso8601String(),
      'dateUpdated': dateUpdated.toIso8601String(),
    };
  }

  // Convert MVFile object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'SECTION': section,
      'MVFILENUMBER': mvFileNumber,
      'PLATENUMBER': plateNumber,
      'syncStatus': syncStatus.toString().split('.').last,
      'dateCreated': dateCreated.toUtc().toIso8601String(),
      'dateUpdated': dateUpdated.toUtc().toIso8601String(),
    };
  }

  // Get formatted date
  // String get formattedDateUpdated {
  //   final formatter = DateFormat("MMMM d, yyyy hh:mm a"); 
  //   return formatter.format(dateUpdated);
  // }
}
