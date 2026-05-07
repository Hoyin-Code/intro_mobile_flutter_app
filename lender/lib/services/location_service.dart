import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';
import '../models/location_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _locationsRef(String userId) =>
      _firestore
          .collection(FirestoreConstants.users)
          .doc(userId)
          .collection(FirestoreConstants.locations);

  Stream<List<LocationModel>> getLocations(String userId) {
    return _locationsRef(userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => LocationModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<DocumentReference> addLocation(
      String userId, LocationModel location) {
    return _locationsRef(userId).add(location.toMap());
  }

  Future<void> updateLocation(String userId, LocationModel location) {
    return _locationsRef(userId).doc(location.id).update(location.toMap());
  }

  Future<void> deleteLocation(String userId, String locationId) {
    return _locationsRef(userId).doc(locationId).delete();
  }
}
