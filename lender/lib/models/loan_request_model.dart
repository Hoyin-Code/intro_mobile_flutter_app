import 'package:cloud_firestore/cloud_firestore.dart';

enum LoanStatus { pending, accepted, rejected, active, returned, cancelled }

class LoanRequestModel {
  final String id;
  final String itemId;
  final String borrowerId;
  final String lenderId;
  final LoanStatus status;
  final Timestamp startDate;
  final Timestamp endDate;
  final double totalPrice;
  final Timestamp createdAt;

  LoanRequestModel({
    required this.id,
    required this.itemId,
    required this.borrowerId,
    required this.lenderId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.createdAt,
  });

  factory LoanRequestModel.fromMap(String id, Map<String, dynamic> map) =>
      LoanRequestModel(
        id: id,
        itemId: map['itemId'],
        borrowerId: map['borrowerId'],
        lenderId: map['lenderId'],
        status: LoanStatus.values.byName(map['status']),
        startDate: map['startDate'] as Timestamp,
        endDate: map['endDate'] as Timestamp,
        totalPrice: (map['totalPrice'] as num).toDouble(),
        createdAt: map['createdAt'] as Timestamp,
      );

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'borrowerId': borrowerId,
        'lenderId': lenderId,
        'status': status.name,
        'startDate': startDate,
        'endDate': endDate,
        'totalPrice': totalPrice,
        'createdAt': createdAt,
      };
}
