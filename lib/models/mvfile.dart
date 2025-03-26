import 'dart:convert';
import 'package:intl/intl.dart';

enum SyncStatus { PENDING, SYNCED }

class MVFile {
  String id;
  String section;
  String mvFileNumber;
  String? plateNumber;
  SyncStatus? syncStatus;
  DateTime? dateCreated;
  DateTime? dateUpdated;

  MVFile({
    required this.id,
    required this.section,
    required this.mvFileNumber,
    this.plateNumber,
    this.syncStatus = SyncStatus.PENDING,
    this.dateCreated,  // Now optional
    this.dateUpdated,  // Now optional
  });

  // Convert JSON to MVFile object
  factory MVFile.fromJson(Map<String, dynamic> json) {
    return MVFile(
      id: json['id']?.toString() ?? "UNKNOWN",
      section: json['SECTION']?.toString() ?? "N/A",
      mvFileNumber: json['MVFILENUMBER']?.toString() ?? "N/A",
      plateNumber: json['PLATENUMBER']?.toString(),
      syncStatus: json['syncStatus'] != null
          ? SyncStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['syncStatus'],
              orElse: () => SyncStatus.PENDING,
            )
          : SyncStatus.PENDING,
      dateCreated: json['dateCreated'] != null ? DateTime.tryParse(json['dateCreated'])?.toLocal() : null,
      dateUpdated: json['dateUpdated'] != null ? DateTime.tryParse(json['dateUpdated'])?.toLocal() : null,
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
              (e) => e.toString().split('.').last == map['syncStatus'],
              orElse: () => SyncStatus.PENDING,
            )
          : SyncStatus.PENDING,
      dateCreated: map['dateCreated'] != null ? DateTime.tryParse(map['dateCreated']) : null,
      dateUpdated: map['dateUpdated'] != null ? DateTime.tryParse(map['dateUpdated']) : null,
    );
  }

  // Convert MVFile object to Map (exclude null fields)
  Map<String, dynamic> toMap() {
    final map = {
      'section': section,
      'mvFileNumber': mvFileNumber,
      'plateNumber': plateNumber,
      'syncStatus': syncStatus.toString().split('.').last,
    };

    if (dateCreated != null) map['dateCreated'] = dateCreated!.toIso8601String();
    if (dateUpdated != null) map['dateUpdated'] = dateUpdated!.toIso8601String();

    return map;
  }

  // Convert MVFile object to JSON (exclude null fields)
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'SECTION': section,
      'MVFILENUMBER': mvFileNumber,
      'PLATENUMBER': plateNumber,
      'syncStatus': syncStatus.toString().split('.').last,
    };

    if (dateCreated != null) json['dateCreated'] = dateCreated!.toUtc().toIso8601String();
    if (dateUpdated != null) json['dateUpdated'] = dateUpdated!.toUtc().toIso8601String();

    return json;
  }
}
