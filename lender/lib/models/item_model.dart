import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_model.dart';

enum ItemCondition { newItem, likeNew, good, fair, poor }

class ItemModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final List<String> photoUrls;
  final String category;
  final ItemCondition condition;
  final double pricePerDay;
  final bool isAvailable;
  final Address address;
  final String? locationLabel;
  final double averageRating;
  final int totalReviews;
  final Timestamp createdAt;

  ItemModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.photoUrls,
    required this.category,
    required this.condition,
    required this.pricePerDay,
    required this.isAvailable,
    required this.address,
    this.locationLabel,
    required this.averageRating,
    required this.totalReviews,
    required this.createdAt,
  });
  // todo: add cloudinary for images
  factory ItemModel.fromMap(String id, Map<String, dynamic> map) => ItemModel(
    id: id,
    ownerId: map['ownerId'],
    title: map['title'],
    description: map['description'],
    photoUrls: List<String>.from(map['photoUrls']),
    category: map['category'],
    condition: ItemCondition.values.byName(map['condition']),
    pricePerDay: (map['pricePerDay'] as num).toDouble(),
    isAvailable: map['isAvailable'] as bool,
    address: Address.fromMap(map['address'] as Map<String, dynamic>),
    locationLabel: map['locationLabel'] as String?,
    averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
    totalReviews: (map['totalReviews'] as int?) ?? 0,
    createdAt: map['createdAt'] as Timestamp,
  );

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'title': title,
    'description': description,
    'photoUrls': photoUrls,
    'category': category,
    'condition': condition.name,
    'pricePerDay': pricePerDay,
    'isAvailable': isAvailable,
    'address': address.toMap(),
    if (locationLabel != null) 'locationLabel': locationLabel,
    'averageRating': averageRating,
    'totalReviews': totalReviews,
    'createdAt': createdAt,
  };
}
