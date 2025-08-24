import '../models/academic_year.dart';
import 'firebase_service.dart';

class FirestoreAcademicYearService {
  static const String _collection = 'academic_years';

  // Get all academic years
  static Future<List<AcademicYear>> getAllAcademicYears() async {
    try {
      final querySnapshot = await FirebaseService.firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AcademicYear.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch academic years: $e');
    }
  }

  // Get active academic year
  static Future<AcademicYear?> getActiveAcademicYear() async {
    try {
      final querySnapshot = await FirebaseService.firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return AcademicYear.fromMap({
        'id': doc.id,
        ...doc.data(),
      });
    } catch (e) {
      throw Exception('Failed to fetch active academic year: $e');
    }
  }

  // Create new academic year
  static Future<String> createAcademicYear(AcademicYear academicYear) async {
    try {
      // Don't include the id in the document data - Firestore generates it automatically
      final data = academicYear.toMap();
      data.remove('id'); // Remove id from the data to be stored
      
      final docRef = await FirebaseService.firestore
          .collection(_collection)
          .add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create academic year: $e');
    }
  }

  // Update academic year
  static Future<void> updateAcademicYear(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await FirebaseService.firestore
          .collection(_collection)
          .doc(id)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update academic year: $e');
    }
  }

  // Delete academic year
  static Future<void> deleteAcademicYear(String id) async {
    try {
      await FirebaseService.firestore
          .collection(_collection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete academic year: $e');
    }
  }

  // Set academic year as active (deactivates others)
  static Future<void> setActiveAcademicYear(String id) async {
    try {
      final batch = FirebaseService.firestore.batch();
      
      // Deactivate all academic years
      final allDocs = await FirebaseService.firestore
          .collection(_collection)
          .get();
      
      for (final doc in allDocs.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      
      // Activate the selected academic year
      batch.update(
        FirebaseService.firestore.collection(_collection).doc(id),
        {'isActive': true, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      );
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set active academic year: $e');
    }
  }

  // Get academic year by ID
  static Future<AcademicYear?> getAcademicYearById(String id) async {
    try {
      final doc = await FirebaseService.firestore
          .collection(_collection)
          .doc(id)
          .get();

      if (!doc.exists) return null;

      return AcademicYear.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Failed to fetch academic year: $e');
    }
  }

  // Clean up academic years with empty id fields (for existing data)
  static Future<void> cleanupInvalidAcademicYears() async {
    try {
      final querySnapshot = await FirebaseService.firestore
          .collection(_collection)
          .get();

      final batch = FirebaseService.firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // If the document has an empty id field, remove it
        if (data.containsKey('id') && (data['id'] == null || data['id'] == '')) {
          final updatedData = Map<String, dynamic>.from(data);
          updatedData.remove('id');
          batch.update(doc.reference, updatedData);
        }
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup academic years: $e');
    }
  }
}
