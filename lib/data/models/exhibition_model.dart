class ExhibitionModel {
  final String id;
  final String title;
  final String description;
  final String venue;
  final DateTime startDate;
  final DateTime endDate;
  final String organizerId;
  final bool isPublished;
  final String status; // upcoming, ongoing, completed
  final String floorPlanUrl;
  final DateTime createdAt;

  ExhibitionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.startDate,
    required this.endDate,
    required this.organizerId,
    this.isPublished = false,
    this.status = 'upcoming',
    this.floorPlanUrl = '',
    required this.createdAt,
  });

  factory ExhibitionModel.fromMap(Map<String, dynamic> map) {
    return ExhibitionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      venue: map['venue'] ?? '',
      startDate: (map['startDate'] as dynamic).toDate(),
      endDate: (map['endDate'] as dynamic).toDate(),
      organizerId: map['organizerId'] ?? '',
      isPublished: map['isPublished'] ?? false,
      status: map['status'] ?? 'upcoming',
      floorPlanUrl: map['floorPlanUrl'] ?? '',
      createdAt: (map['createdAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'venue': venue,
      'startDate': startDate,
      'endDate': endDate,
      'organizerId': organizerId,
      'isPublished': isPublished,
      'floorPlanUrl': floorPlanUrl,
      'createdAt': createdAt,
    };
  }

  // Computed status — never stored, always derived from dates + isPublished
  String get computedStatus {
    if (!isPublished) return 'unpublished';
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 'upcoming';
    if (now.isAfter(endDate)) return 'completed';
    return 'ongoing';
  }
}