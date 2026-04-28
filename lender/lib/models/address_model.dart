import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Address {
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final GeoPoint location;

  Address({
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.location,
  });

  factory Address.fromMap(Map<String, dynamic> map) => Address(
        street: map['street'],
        city: map['city'],
        postalCode: map['postalCode'],
        country: map['country'],
        location: map['location'],
      );

  Map<String, dynamic> toMap() => {
        'street': street,
        'city': city,
        'postalCode': postalCode,
        'country': country,
        'location': location,
      };

  LatLng get latLng => LatLng(location.latitude, location.longitude);
}
