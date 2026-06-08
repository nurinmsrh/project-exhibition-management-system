import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String exhibitorId;
  final String exhibitionId;
  final List<String> boothIds;
  final String companyName;
  final String companyDescription;
  final String exhibitDescription;
  final List<String> additems;
  final String status;
  final String rejectionReason;
  final DateTime createdAt;

  // Price snapshot at time of submission — never changes after submit
  final double boothsPrice;
  final double amenitiesPrice;

  double get totalPrice => boothsPrice + amenitiesPrice;

  ApplicationModel({
    required this.id,
    required this.exhibitorId,
    required this.exhibitionId,
    required this.boothIds,
    required this.companyName,
    required this.companyDescription,
    required this.exhibitDescription,
    this.additems = const [],
    this.status = 'pending',
    this.rejectionReason = '',
    required this.createdAt,
    this.boothsPrice = 0,
    this.amenitiesPrice = 0,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    return ApplicationModel(
      id: map['id'] ?? '',
      exhibitorId: map['exhibitorId'] ?? '',
      exhibitionId: map['exhibitionId'] ?? '',
      boothIds: List<String>.from(map['boothIds'] ?? []),
      companyName: map['companyName'] ?? '',
      companyDescription: map['companyDescription'] ?? '',
      exhibitDescription: map['exhibitDescription'] ?? '',
      additems: List<String>.from(map['additems'] ?? []),
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'] ?? '',
      createdAt: (map['createdAt'] as dynamic).toDate(),
      boothsPrice: (map['boothsPrice'] ?? 0).toDouble(),
      amenitiesPrice: (map['amenitiesPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exhibitorId': exhibitorId,
      'exhibitionId': exhibitionId,
      'boothIds': boothIds,
      'companyName': companyName,
      'companyDescription': companyDescription,
      'exhibitDescription': exhibitDescription,
      'additems': additems,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
      'boothsPrice': boothsPrice,
      'amenitiesPrice': amenitiesPrice,
    };
  }
}