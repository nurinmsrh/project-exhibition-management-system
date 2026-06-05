class ApplicationModel {
  final String id;
  final String exhibitorId;
  final String exhibitionId;
  final List<String> boothIds;
  final String companyName;
  final String companyDescription;
  final String exhibitDescription;
  final List<String> additems;
  final String status; // pending, approved, rejected, cancelled
  final String rejectionReason;
  final DateTime createdAt;

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
    };
  }
}