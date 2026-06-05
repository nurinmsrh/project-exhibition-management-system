import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/exhibition_model.dart';

class ExhibitionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create exhibition
  Future<ExhibitionModel> createExhibition({
    required String title,
    required String description,
    required String venue,
    required DateTime startDate,
    required DateTime endDate,
    required String organizerId,
  }) async {
    try {
      String id = _uuid.v4();
      ExhibitionModel exhibition = ExhibitionModel(
        id: id,
        title: title,
        description: description,
        venue: venue,
        startDate: startDate,
        endDate: endDate,
        organizerId: organizerId,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('exhibitions')
          .doc(id)
          .set(exhibition.toMap());
      return exhibition;
    } catch (e) {
      rethrow;
    }
  }

  // Get all published exhibitions (for guest/exhibitor)
  Future<List<ExhibitionModel>> getPublishedExhibitions() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('exhibitions')
          .where('isPublished', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) =>
          ExhibitionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get all exhibitions (admin)
  Future<List<ExhibitionModel>> getAllExhibitions() async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection('exhibitions').get();
      return snapshot.docs
          .map((doc) =>
          ExhibitionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get organizer's exhibitions
  Future<List<ExhibitionModel>> getOrganizerExhibitions(
      String organizerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('exhibitions')
          .where('organizerId', isEqualTo: organizerId)
          .get();
      return snapshot.docs
          .map((doc) =>
          ExhibitionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Update exhibition
  Future<void> updateExhibition(
      String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('exhibitions').doc(id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete exhibition
  Future<void> deleteExhibition(String id) async {
    try {
      await _firestore.collection('exhibitions').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Toggle publish status (admin)
  Future<void> togglePublish(String id, bool isPublished) async {
    try {
      await _firestore
          .collection('exhibitions')
          .doc(id)
          .update({'isPublished': isPublished});
    } catch (e) {
      rethrow;
    }
  }

  // Get reserved booth count for an exhibition
  Future<int> getReservedBoothCount(String exhibitionId) async {
    try {
      final snapshot = await _firestore
          .collection('booths')
          .where('exhibitionId', isEqualTo: exhibitionId)
          .where('status', whereIn: ['booked', 'reserved'])
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getTotalBoothCount(String exhibitionId) async {
    try {
      final snapshot = await _firestore
          .collection('booths')
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}