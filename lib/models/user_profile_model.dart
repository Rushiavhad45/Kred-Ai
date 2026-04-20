// flutter_app/lib/models/user_profile_model.dart
import 'package:flutter/material.dart';

class UserProfileModel {
  // Basic Personal Information (KYC Compliant)
  final String fullName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String emailAddress;
  
  // Address Information
  final String streetAddress;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  
  // Additional Identity Information
  final String? panNumber;
  final String? aadharNumber;
  final String? occupation;
  final String? employerName;
  final String? workAddress;
  
  // Consent and Privacy
  final bool consentForDataProcessing;
  final bool consentForCreditCheck;
  final DateTime consentTimestamp;
  final String? preferredLanguage;

  UserProfileModel({
    required this.fullName,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.emailAddress,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'India',
    this.panNumber,
    this.aadharNumber,
    this.occupation,
    this.employerName,
    this.workAddress,
    required this.consentForDataProcessing,
    required this.consentForCreditCheck,
    required this.consentTimestamp,
    this.preferredLanguage,
  });

  // Age calculation
  int get age {
    final now = DateTime.now();
    int calculatedAge = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  // Full address as single string
  String get fullAddress {
    return '$streetAddress, $city, $state $postalCode, $country';
  }

  // Data validation
  bool get isValid {
    return fullName.isNotEmpty &&
           phoneNumber.length >= 10 &&
           emailAddress.contains('@') &&
           streetAddress.isNotEmpty &&
           city.isNotEmpty &&
           state.isNotEmpty &&
           postalCode.isNotEmpty &&
           consentForDataProcessing &&
           consentForCreditCheck;
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'phone_number': phoneNumber,
      'email_address': emailAddress,
      'street_address': streetAddress,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'pan_number': panNumber,
      'aadhar_number': aadharNumber,
      'occupation': occupation,
      'employer_name': employerName,
      'work_address': workAddress,
      'consent_data_processing': consentForDataProcessing,
      'consent_credit_check': consentForCreditCheck,
      'consent_timestamp': consentTimestamp.toIso8601String(),
      'preferred_language': preferredLanguage,
      'calculated_age': age,
    };
  }

  // Create from JSON
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      fullName: json['full_name'] ?? '',
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      phoneNumber: json['phone_number'] ?? '',
      emailAddress: json['email_address'] ?? '',
      streetAddress: json['street_address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? 'India',
      panNumber: json['pan_number'],
      aadharNumber: json['aadhar_number'],
      occupation: json['occupation'],
      employerName: json['employer_name'],
      workAddress: json['work_address'],
      consentForDataProcessing: json['consent_data_processing'] ?? false,
      consentForCreditCheck: json['consent_credit_check'] ?? false,
      consentTimestamp: DateTime.parse(json['consent_timestamp']),
      preferredLanguage: json['preferred_language'],
    );
  }

  // Create a copy with modifications
  UserProfileModel copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? emailAddress,
    String? streetAddress,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? panNumber,
    String? aadharNumber,
    String? occupation,
    String? employerName,
    String? workAddress,
    bool? consentForDataProcessing,
    bool? consentForCreditCheck,
    DateTime? consentTimestamp,
    String? preferredLanguage,
  }) {
    return UserProfileModel(
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      panNumber: panNumber ?? this.panNumber,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      occupation: occupation ?? this.occupation,
      employerName: employerName ?? this.employerName,
      workAddress: workAddress ?? this.workAddress,
      consentForDataProcessing: consentForDataProcessing ?? this.consentForDataProcessing,
      consentForCreditCheck: consentForCreditCheck ?? this.consentForCreditCheck,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  @override
  String toString() {
    return 'UserProfileModel(fullName: $fullName, age: $age, city: $city, state: $state)';
  }
}
