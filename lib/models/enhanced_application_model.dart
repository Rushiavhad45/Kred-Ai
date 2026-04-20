// flutter_app/lib/models/enhanced_application_model.dart
import 'application_model.dart';
import 'user_profile_model.dart';

class EnhancedApplicationModel {
  final UserProfileModel userProfile;
  final ApplicationModel applicationData;
  final DateTime submissionTimestamp;
  final String applicationId;

  EnhancedApplicationModel({
    required this.userProfile,
    required this.applicationData,
    required this.submissionTimestamp,
    required this.applicationId,
  });

  // Combine user profile data with application data for API submission
  Map<String, dynamic> toCompleteJson() {
    final Map<String, dynamic> combinedData = {
      ...userProfile.toJson(),
      ...applicationData.toJson(),
      'submission_timestamp': submissionTimestamp.toIso8601String(),
      'application_id': applicationId,
    };
    
    // Override age with calculated age from date of birth for consistency
    combinedData['age'] = userProfile.age;
    
    return combinedData;
  }

  // Create from separate models
  factory EnhancedApplicationModel.create({
    required UserProfileModel userProfile,
    required ApplicationModel applicationData,
    String? customApplicationId,
  }) {
    return EnhancedApplicationModel(
      userProfile: userProfile,
      applicationData: applicationData,
      submissionTimestamp: DateTime.now(),
      applicationId: customApplicationId ?? _generateApplicationId(),
    );
  }

  static String _generateApplicationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'APP_${timestamp}_${(timestamp % 10000).toString().padLeft(4, '0')}';
  }

  // Validate complete application
  bool get isValid {
    return userProfile.isValid && _isApplicationDataValid();
  }

  bool _isApplicationDataValid() {
    return applicationData.personIncome > 0 &&
           applicationData.age > 0 &&
           applicationData.loanAmnt > 0 &&
           applicationData.loanIntRate > 0;
  }

  // Get summary for display
  Map<String, String> get summaryData {
    return {
      'Full Name': userProfile.fullName,
      'Age': '${userProfile.age} years',
      'Phone': userProfile.phoneNumber,
      'Email': userProfile.emailAddress,
      'City': '${userProfile.city}, ${userProfile.state}',
      'Annual Income': '₹${applicationData.personIncome.toStringAsFixed(0)}',
      'Employment Length': '${applicationData.personEmpLength} years',
      'Loan Amount': '₹${applicationData.loanAmnt.toStringAsFixed(0)}',
      'Interest Rate': '${applicationData.loanIntRate}%',
      'Loan Purpose': applicationData.loanIntent ?? 'Not specified',
      'Credit History': '${applicationData.cbPersonCredHistLength} years',
      'Application ID': applicationId,
      'Submission Date': submissionTimestamp.toString().split(' ')[0],
    };
  }

  @override
  String toString() {
    return 'EnhancedApplicationModel(applicationId: $applicationId, applicant: ${userProfile.fullName}, loanAmount: ₹${applicationData.loanAmnt})';
  }
}
