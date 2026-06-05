import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/booth_model.dart';

class BoothService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create booth
  Future<BoothModel> createBooth({
    required String exhibitionId,
    required String boothNumber,
    required String type,
    required String size,
    required double price,
    required List<String> amenities,
    required double positionX,
    required double positionY,
    double width = 50,
    double height = 50,
  }) async {
    try {
      String id = _uuid.v4();
      BoothModel booth = BoothModel(
        id: id,
        exhibitionId: exhibitionId,
        boothNumber: boothNumber,
        type: type,
        size: size,
        price: price,
        amenities: amenities,
        positionX: positionX,
        positionY: positionY,
        width: width,
        height: height,
      );
      await _firestore.collection('booths').doc(id).set(booth.toMap());
      return booth;
    } catch (e) {
      rethrow;
    }
  }

  // Get booths for an exhibition
  Future<List<BoothModel>> getBoothsByExhibition(String exhibitionId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('booths')
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();
      return snapshot.docs
          .map((doc) =>
          BoothModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Update booth status
  Future<void> updateBoothStatus(String boothId, String status) async {
    try {
      await _firestore
          .collection('booths')
          .doc(boothId)
          .update({'status': status});
    } catch (e) {
      rethrow;
    }
  }

  // Update booth
  Future<void> updateBooth(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('booths').doc(id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete booth
  Future<void> deleteBooth(String id) async {
    try {
      await _firestore.collection('booths').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}