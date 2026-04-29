import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final Address? address;
  final double averageRating;
  final int totalReviews;
  final Timestamp createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.address,
    required this.averageRating,
    required this.totalReviews,
    required this.createdAt,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) => UserModel(
    id: id,
    name: map['name'],
    email: map['email'],
    photoUrl: map['photoUrl'],
    address: map['address'] != null
        ? Address.fromMap(map['address'] as Map<String, dynamic>)
        : null,
    averageRating: (map['averageRating'] as num).toDouble(),
    totalReviews: map['totalReviews'] as int,
    createdAt: map['createdAt'] as Timestamp,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'address': address?.toMap(),
    'averageRating': averageRating,
    'totalReviews': totalReviews,
    'createdAt': createdAt,
  };
  // TODO: add field for multiple addresses so you can choose what location a new item has
}
