import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel> getUser(String userId) {
    return _firestore
        .collection(FirestoreConstants.users)
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromMap(doc.id, doc.data()!));
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) {
    return _firestore
        .collection(FirestoreConstants.users)
        .doc(userId)
        .update(data);
  }
}
