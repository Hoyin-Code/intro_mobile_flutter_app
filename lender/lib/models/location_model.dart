import 'package:cloud_firestore/cloud_firestore.dart';

import 'address_model.dart';

class LocationModel {
  final String id;
  final String label;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final GeoPoint location;

  const LocationModel({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.location,
  });

  factory LocationModel.fromMap(String id, Map<String, dynamic> map) =>
      LocationModel(
        id: id,
        label: map['label'] as String,
        street: map['street'] as String,
        city: map['city'] as String,
        postalCode: map['postalCode'] as String,
        country: map['country'] as String,
        location: map['location'] as GeoPoint,
      );

  Map<String, dynamic> toMap() => {
        'label': label,
        'street': street,
        'city': city,
        'postalCode': postalCode,
        'country': country,
        'location': location,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LocationModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  Address toAddress() => Address(
        street: street,
        city: city,
        postalCode: postalCode,
        country: country,
        location: location,
      );
}
