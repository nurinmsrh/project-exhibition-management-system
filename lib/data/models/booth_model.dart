class BoothAmenity {
  final String name;
  final double price;

  BoothAmenity({required this.name, required this.price});

  factory BoothAmenity.fromMap(Map<String, dynamic> map) {
    return BoothAmenity(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
  };
}

class BoothModel {
  final String id;
  final String exhibitionId;
  final String boothNumber;
  final String type;
  final double price;
  final String status;
  final List<BoothAmenity> amenities;
  final double positionX;
  final double positionY;
  final String description;
  final bool isPublished;

  static const double boothDisplaySize = 20.0;

  BoothModel({
    required this.id,
    required this.exhibitionId,
    required this.boothNumber,
    required this.type,
    required this.price,
    this.status = 'available',
    this.amenities = const [],
    this.positionX = 0,
    this.positionY = 0,
    this.description = '',
    this.isPublished = true,
  });

  factory BoothModel.fromMap(Map<String, dynamic> map) {
    List<BoothAmenity> amenities = [];
    final raw = map['amenities'];
    if (raw != null && raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          amenities.add(BoothAmenity.fromMap(item));
        } else if (item is String) {
          amenities.add(BoothAmenity(name: item, price: 0));
        }
      }
    }

    return BoothModel(
      id: map['id'] ?? '',
      exhibitionId: map['exhibitionId'] ?? '',
      boothNumber: map['boothNumber'] ?? '',
      type: map['type'] ?? 'standard',
      price: (map['price'] ?? 0).toDouble(),
      status: map['status'] ?? 'available',
      amenities: amenities,
      positionX: (map['positionX'] ?? 0).toDouble(),
      positionY: (map['positionY'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      isPublished: map['isPublished'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exhibitionId': exhibitionId,
      'boothNumber': boothNumber,
      'type': type,
      'price': price,
      'status': status,
      'amenities': amenities.map((a) => a.toMap()).toList(),
      'positionX': positionX,
      'positionY': positionY,
      'description': description,
      'isPublished': isPublished,
    };
  }
}