import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/booth_model.dart';

class BoothService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<BoothModel> createBooth({
    required String exhibitionId,
    required String boothNumber,
    required String type,
    required double price,
    required List<Map<String, dynamic>> amenities,
    required double positionX,
    required double positionY,
  }) async {
    try {
      String id = _uuid.v4();
      BoothModel booth = BoothModel(
        id: id,
        exhibitionId: exhibitionId,
        boothNumber: boothNumber,
        type: type,
        price: price,
        amenities: amenities.map((a) => BoothAmenity.fromMap(a)).toList(),
        positionX: positionX,
        positionY: positionY,
      );
      await _firestore.collection('booths').doc(id).set(booth.toMap());
      return booth;
    } catch (e) {
      rethrow;
    }
  }

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

  Future<void> updateBooth(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('booths').doc(id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBooth(String id) async {
    try {
      await _firestore.collection('booths').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}