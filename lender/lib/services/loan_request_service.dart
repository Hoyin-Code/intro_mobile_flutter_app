import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';
import '../models/loan_request_model.dart';

class LoanRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<LoanRequestModel>> getRequestsForLender(String lenderId) {
    return _firestore
        .collection(FirestoreConstants.loanRequests)
        .where('lenderId', isEqualTo: lenderId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => LoanRequestModel.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Stream<List<LoanRequestModel>> getRequestsForBorrower(String borrowerId) {
    return _firestore
        .collection(FirestoreConstants.loanRequests)
        .where('borrowerId', isEqualTo: borrowerId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => LoanRequestModel.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<void> createRequest(LoanRequestModel request) {
    return _firestore
        .collection(FirestoreConstants.loanRequests)
        .add(request.toMap());
  }

  Future<void> updateStatus(String requestId, LoanStatus status) {
    return _firestore
        .collection(FirestoreConstants.loanRequests)
        .doc(requestId)
        .update({'status': status.name});
  }
}
