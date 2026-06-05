import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/application_model.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Submit application
  Future<ApplicationModel> submitApplication({
    required String exhibitorId,
    required String exhibitionId,
    required List<String> boothIds,
    required String companyName,
    required String companyDescription,
    required String exhibitDescription,
    List<String> additems = const [],
  }) async {
    try {
      String id = _uuid.v4();
      ApplicationModel application = ApplicationModel(
        id: id,
        exhibitorId: exhibitorId,
        exhibitionId: exhibitionId,
        boothIds: boothIds,
        companyName: companyName,
        companyDescription: companyDescription,
        exhibitDescription: exhibitDescription,
        additems: additems,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('applications')
          .doc(id)
          .set(application.toMap());
      return application;
    } catch (e) {
      rethrow;
    }
  }

  // Get exhibitor's applications
  Future<List<ApplicationModel>> getExhibitorApplications(
      String exhibitorId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('applications')
          .where('exhibitorId', isEqualTo: exhibitorId)
          .get();
      return snapshot.docs
          .map((doc) =>
          ApplicationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get applications for an exhibition (organizer)
  Future<List<ApplicationModel>> getExhibitionApplications(
      String exhibitionId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('applications')
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();
      return snapshot.docs
          .map((doc) =>
          ApplicationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get all applications (admin)
  Future<List<ApplicationModel>> getAllApplications() async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection('applications').get();
      return snapshot.docs
          .map((doc) =>
          ApplicationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Update application status
  Future<void> updateApplicationStatus(
      String id, String status, {String reason = ''}) async {
    try {
      await _firestore.collection('applications').doc(id).update({
        'status': status,
        'rejectionReason': reason,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update application details (exhibitor, pending only)
  Future<void> updateApplication(
      String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('applications').doc(id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Cancel application
  Future<void> cancelApplication(String id) async {
    try {
      await _firestore.collection('applications').doc(id).update({
        'status': 'cancelled',
      });
    } catch (e) {
      rethrow;
    }
  }
}