import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';
import '../models/item_model.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ItemModel>> getItems() {
    return _firestore
        .collection(FirestoreConstants.items)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<ItemModel>> getItemsByOwner(String ownerId) {
    return _firestore
        .collection(FirestoreConstants.items)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<void> addItem(ItemModel item) {
    return _firestore
        .collection(FirestoreConstants.items)
        .add(item.toMap());
  }

  Future<void> updateItem(ItemModel item) {
    return _firestore
        .collection(FirestoreConstants.items)
        .doc(item.id)
        .update(item.toMap());
  }

  Future<void> deleteItem(String itemId) {
    return _firestore
        .collection(FirestoreConstants.items)
        .doc(itemId)
        .delete();
  }

  Future<void> updateAvailability(String itemId, {required bool isAvailable}) {
    return _firestore
        .collection(FirestoreConstants.items)
        .doc(itemId)
        .update({'isAvailable': isAvailable});
  }
}
