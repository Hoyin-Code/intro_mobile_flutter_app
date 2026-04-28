import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firestore_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp(
      String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _firestore
        .collection(FirestoreConstants.users)
        .doc(credential.user!.uid)
        .set({
      'name': name,
      'email': email,
      'photoUrl': null,
      'address': null,
      'averageRating': 0.0,
      'totalReviews': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return credential;
  }

  Future<void> signOut() => _auth.signOut();
}
