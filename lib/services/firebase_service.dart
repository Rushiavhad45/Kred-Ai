// flutter_app/lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kredai/models/application_model.dart';
import '../models/enhanced_application_model.dart';
import '../models/user_profile_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String applicationsCollection = 'enhanced_applications';
  static const String userProfilesCollection = 'user_profiles';
  static const String usersCollection = 'users';
  static const String auditLogCollection = 'audit_logs';

  // Create user method (required by auth_provider)
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection(usersCollection).doc(user.userId).set({
        'user_id': user.userId,
        'email': user.email,
        'full_name': user.fullName,
        'phone_number': user.phoneNumber,
        'created_at': user.createdAt,
        'updated_at': FieldValue.serverTimestamp(),
      } as Map<String, Object?>);

      await _logAction(
        'user_created',
        user.email ?? user.userId,
        {'user_id': user.userId},
      );
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> saveEnhancedApplication(EnhancedApplicationModel application) async {
    try {
      final docRef = _firestore.collection(applicationsCollection).doc(application.applicationId);
      
      await docRef.set({
        ...application.toCompleteJson().map((key, value) => MapEntry(key, value as Object?)),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'status': 'submitted',
      });

      // Save user profile separately for quick access
      await _saveUserProfile(application.userProfile);
      
      // Log the action
      await _logAction(
        'application_submitted',
        application.userProfile.emailAddress,
        {'application_id': application.applicationId},
      );

    } catch (e) {
      throw Exception('Failed to save application: $e');
    }
  }

  Future<void> _saveUserProfile(UserProfileModel userProfile) async {
    try {
      final docRef = _firestore.collection(userProfilesCollection).doc(userProfile.emailAddress);
      
      await docRef.set({
        ...userProfile.toJson().map((key, value) => MapEntry(key, value as Object?)),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      print('Warning: Failed to save user profile: $e');
    }
  }

  Future<List<EnhancedApplicationModel>> getUserApplicationHistory(String userEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection(applicationsCollection)
          .where('email_address', isEqualTo: userEmail)
          .orderBy('created_at', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _parseEnhancedApplication(data);
      }).toList();

    } catch (e) {
      throw Exception('Failed to load application history: $e');
    }
  }

  Future<EnhancedApplicationModel?> getApplicationById(String applicationId) async {
    try {
      final doc = await _firestore.collection(applicationsCollection).doc(applicationId).get();
      
      if (doc.exists) {
        return _parseEnhancedApplication(doc.data()!);
      }
      return null;
      
    } catch (e) {
      throw Exception('Failed to load application: $e');
    }
  }

  Future<void> updateApplicationStatus(String applicationId, String status, Map<String, dynamic>? additionalData) async {
    try {
      final updateData = <String, Object?>{
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      if (additionalData != null) {
        updateData.addAll(additionalData.map((key, value) => MapEntry(key, value as Object?)));
      }

      await _firestore.collection(applicationsCollection).doc(applicationId).update(updateData);
      
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  Future<UserProfileModel?> getUserProfile(String userEmail) async {
    try {
      final doc = await _firestore.collection(userProfilesCollection).doc(userEmail).get();
      
      if (doc.exists) {
        return UserProfileModel.fromJson(doc.data()!);
      }
      return null;
      
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  Future<void> _logAction(String action, String userEmail, Map<String, dynamic> details) async {
    try {
      await _firestore.collection(auditLogCollection).add({
        'action': action,
        'user_email': userEmail,
        'details': details.map((key, value) => MapEntry(key, value as Object?)),
        'timestamp': FieldValue.serverTimestamp(),
        'ip_address': 'mobile_app',
      });
    } catch (e) {
      print('Warning: Failed to log action: $e');
    }
  }

  // Add to firebase_service.dart for testing
Future<void> testConnection() async {
  try {
    await _firestore.collection('test').doc('connection').set({
      'timestamp': FieldValue.serverTimestamp(),
      'message': 'Connection successful!',
    });
    print('✅ Firebase connection successful!');
  } catch (e) {
    print('❌ Firebase connection failed: $e');
  }
}


  EnhancedApplicationModel _parseEnhancedApplication(Map<String, dynamic> data) {
    // Parse user profile
    final userProfile = UserProfileModel(
      fullName: data['full_name'] ?? '',
      dateOfBirth: DateTime.parse(data['date_of_birth']),
      phoneNumber: data['phone_number'] ?? '',
      emailAddress: data['email_address'] ?? '',
      streetAddress: data['street_address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postal_code'] ?? '',
      country: data['country'] ?? 'India',
      panNumber: data['pan_number'],
      aadharNumber: data['aadhar_number'],
      occupation: data['occupation'],
      employerName: data['employer_name'],
      workAddress: data['work_address'],
      consentForDataProcessing: data['consent_data_processing'] ?? false,
      consentForCreditCheck: data['consent_credit_check'] ?? false,
      consentTimestamp: DateTime.parse(data['consent_timestamp']),
      preferredLanguage: data['preferred_language'],
    );

    // Parse application data
    final applicationData = ApplicationModel(
      personIncome: data['person_income']?.toDouble() ?? 0.0,
      personEmpLength: data['person_emp_length']?.toDouble() ?? 0.0,
      age: data['age'] ?? 0,
      loanAmnt: data['loan_amnt']?.toDouble() ?? 0.0,
      loanIntRate: data['loan_int_rate']?.toDouble() ?? 0.0,
      loanIntent: data['loan_intent'],
      cbPersonCredHistLength: data['cb_person_cred_hist_length']?.toDouble() ?? 0.0,
      cbPersonDefaultOnFile: data['cb_person_default_on_file'] ?? 0,
      estimatedMonthlyIncome: data['estimated_monthly_income']?.toDouble(),
      monthlyAirtimeSpend: data['monthly_airtime_spend']?.toDouble() ?? 0.0,
      monthlyDataUsageGb: data['monthly_data_usage_gb']?.toDouble() ?? 0.0,
      avgCallsPerDay: data['avg_calls_per_day']?.toDouble() ?? 0.0,
      avgSmsPerDay: data['avg_sms_per_day']?.toDouble() ?? 0.0,
      digitalWalletUsage: data['digital_wallet_usage'] ?? 0,
      monthlyDigitalTransactions: data['monthly_digital_transactions']?.toDouble() ?? 0.0,
      avgTransactionAmount: data['avg_transaction_amount']?.toDouble() ?? 0.0,
      socialMediaActivityScore: data['social_media_activity_score']?.toDouble() ?? 0.0,
      mobileBankingUser: data['mobile_banking_user'] ?? 0,
      digitalEngagementScore: data['digital_engagement_score']?.toDouble() ?? 0.0,
      financialInclusionScore: data['financial_inclusion_score']?.toDouble() ?? 0.0,
      electricityBillAvg: data['electricity_bill_avg']?.toDouble() ?? 0.0,
      waterBillAvg: data['water_bill_avg']?.toDouble() ?? 0.0,
      gasBillAvg: data['gas_bill_avg']?.toDouble() ?? 0.0,
      totalUtilityExpense: data['total_utility_expense']?.toDouble() ?? 0.0,
      utilityToIncomeRatio: data['utility_to_income_ratio']?.toDouble() ?? 0.0,
      onTimePayments12m: data['on_time_payments_12m'] ?? 0,
      latePayments12m: data['late_payments_12m'] ?? 0,
      creditRiskScore: data['credit_risk_score']?.toDouble(),
    );

    return EnhancedApplicationModel(
      userProfile: userProfile,
      applicationData: applicationData,
      submissionTimestamp: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      applicationId: data['application_id'] ?? '',
    );
  }
}

final firebaseServiceProvider = Provider((ref) => FirebaseService());
