// flutter_app/lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String? email;
  final String fullName;
  final String? phoneNumber;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    this.email,
    required this.fullName,
    this.phoneNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      email: json['email'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      createdAt: (json['created_at'] as Timestamp).toDate(),
    );
  }
}
