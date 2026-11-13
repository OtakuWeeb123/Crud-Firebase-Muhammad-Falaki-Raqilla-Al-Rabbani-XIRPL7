import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String type; // 'Pemasukan' atau 'Pengeluaran'
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] ?? 'Pemasukan',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'date': date,
    };
  }
}
