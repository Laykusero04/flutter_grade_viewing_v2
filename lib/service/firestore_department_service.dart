import '../models/department.dart';
import 'firebase_service.dart';

class FirestoreDepartmentService {
  static const String _collection = 'departments';

  // Get all departments
  static Future<List<Department>> getAllDepartments() async {
    try {
      final querySnapshot = await FirebaseService.firestore
          .collection(_collection)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Department.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch departments: $e');
    }
  }

  // Get active departments only
  static Future<List<Department>> getActiveDepartments() async {
    try {
      // First try to get departments with isActive = true
      var querySnapshot = await FirebaseService.firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      // If no active departments found, get all departments (for backward compatibility)
      if (querySnapshot.docs.isEmpty) {
        print('No active departments found, getting all departments');
        querySnapshot = await FirebaseService.firestore
            .collection(_collection)
            .orderBy('name')
            .get();
      }

      return querySnapshot.docs
          .map((doc) => Department.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      // If the query fails (e.g., no isActive field), get all departments
      print('Active departments query failed, getting all departments: $e');
      try {
        final querySnapshot = await FirebaseService.firestore
            .collection(_collection)
            .orderBy('name')
            .get();

        return querySnapshot.docs
            .map((doc) => Department.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList();
      } catch (e2) {
        throw Exception('Failed to fetch departments: $e2');
      }
    }
  }

  // Get department by ID
  static Future<Department?> getDepartmentById(String id) async {
    try {
      final doc = await FirebaseService.firestore
          .collection(_collection)
          .doc(id)
          .get();

      if (!doc.exists) return null;

      return Department.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Failed to fetch department: $e');
    }
  }

  // Create new department
  static Future<String> createDepartment(Department department) async {
    try {
      final data = department.toMap();
      data.remove('id'); // Remove id from the data to be stored
      
      final docRef = await FirebaseService.firestore
          .collection(_collection)
          .add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create department: $e');
    }
  }

  // Update department
  static Future<void> updateDepartment(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await FirebaseService.firestore
          .collection(_collection)
          .doc(id)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update department: $e');
    }
  }

  // Delete department
  static Future<void> deleteDepartment(String id) async {
    try {
      await FirebaseService.firestore
          .collection(_collection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete department: $e');
    }
  }
}
