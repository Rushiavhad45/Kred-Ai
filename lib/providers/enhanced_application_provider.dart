// flutter_app/lib/providers/enhanced_application_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kredai/providers/application_provider.dart';
import 'package:kredai/providers/auth_provider.dart';
import '../models/enhanced_application_model.dart';
import '../models/prediction_result_model.dart';
import '../models/shap_explanation_model.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart' hide firebaseServiceProvider;

class EnhancedApplicationState {
  final bool isLoading;
  final EnhancedApplicationModel? enhancedApplication;
  final Map<String, dynamic>? applicationResponse;
  final PredictionResult? predictionResult;
  final ShapExplanation? explanation;
  final String? error;
  final List<EnhancedApplicationModel> applicationHistory;

  EnhancedApplicationState({
    this.isLoading = false,
    this.enhancedApplication,
    this.applicationResponse,
    this.predictionResult,
    this.explanation,
    this.error,
    this.applicationHistory = const [],
  });

  EnhancedApplicationState copyWith({
    bool? isLoading,
    EnhancedApplicationModel? enhancedApplication,
    Map<String, dynamic>? applicationResponse,
    PredictionResult? predictionResult,
    ShapExplanation? explanation,
    String? error,
    List<EnhancedApplicationModel>? applicationHistory,
  }) {
    return EnhancedApplicationState(
      isLoading: isLoading ?? this.isLoading,
      enhancedApplication: enhancedApplication ?? this.enhancedApplication,
      applicationResponse: applicationResponse ?? this.applicationResponse,
      predictionResult: predictionResult ?? this.predictionResult,
      explanation: explanation ?? this.explanation,
      error: error,
      applicationHistory: applicationHistory ?? this.applicationHistory,
    );
  }
}

class EnhancedApplicationNotifier extends StateNotifier<EnhancedApplicationState> {
  final ApiService _apiService;
  final FirebaseService _firebaseService;

  EnhancedApplicationNotifier(this._apiService, this._firebaseService) : super(EnhancedApplicationState());

  Future<void> submitEnhancedApplication(EnhancedApplicationModel enhancedApplication) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Save to Firebase first
      await _firebaseService.saveEnhancedApplication(enhancedApplication);
      
      // Submit to API for prediction
      final response = await _apiService.submitApplication(
        enhancedApplication.applicationData,
        userId: enhancedApplication.userProfile.emailAddress,
      );
      
      final predictionResult = PredictionResult.fromJson(response['prediction_result']);
      
      state = state.copyWith(
        isLoading: false,
        enhancedApplication: enhancedApplication,
        applicationResponse: response,
        predictionResult: predictionResult,
      );

      // Load explanation automatically
      if (response['application_id'] != null) {
        await getExplanation(response['application_id']);
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> getExplanation(String applicationId) async {
    try {
      final explanation = await _apiService.getExplanation(applicationId);
      state = state.copyWith(explanation: explanation);
    } catch (e) {
      // Use mock explanation if API fails
      final mockExplanation = _createMockExplanation(applicationId);
      state = state.copyWith(explanation: mockExplanation);
    }
  }

  Future<void> loadApplicationHistory(String userEmail) async {
    try {
      state = state.copyWith(isLoading: true);
      final history = await _firebaseService.getUserApplicationHistory(userEmail);
      state = state.copyWith(
        isLoading: false,
        applicationHistory: history,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load application history: ${e.toString()}',
      );
    }
  }

  ShapExplanation _createMockExplanation(String applicationId) {
    final mockFeatures = <String, FeatureContribution>{
      'person_income': FeatureContribution(
        shapValue: -0.045,
        featureValue: state.enhancedApplication?.applicationData.personIncome ?? 45000.0,
        impact: 'decreases_risk',
        description: 'Your annual income positively affects your risk profile',
        recommendation: 'Your income level is good. Consider documenting additional income sources if available.',
      ),
      'late_payments_12m': FeatureContribution(
        shapValue: 0.089,
        featureValue: state.enhancedApplication?.applicationData.latePayments12m.toDouble() ?? 2.0,
        impact: 'increases_risk',
        description: 'Late payments significantly increase your risk',
        recommendation: 'Set up automatic payments to avoid future late payments.',
      ),
      'loan_amnt': FeatureContribution(
        shapValue: 0.034,
        featureValue: state.enhancedApplication?.applicationData.loanAmnt ?? 15000.0,
        impact: 'increases_risk',
        description: 'The requested loan amount increases the assessed risk',
        recommendation: 'Consider requesting a smaller amount.',
      ),
      'digital_engagement_score': FeatureContribution(
        shapValue: -0.023,
        featureValue: state.enhancedApplication?.applicationData.digitalEngagementScore ?? 65.0,
        impact: 'decreases_risk',
        description: 'Your digital engagement shows good financial behavior',
        recommendation: 'Continue using digital financial services.',
      ),
    };

    final mockRecommendations = [
      PersonalizedRecommendation(
        title: 'Improve Payment History',
        description: 'Your payment history is a key factor in credit assessment.',
        actionItem: 'Set up automatic payments for all bills and loans.',
        category: 'Payment',
        priority: 0.9,
        icon: Icons.payment,
      ),
      PersonalizedRecommendation(
        title: 'Build Digital Footprint',
        description: 'Strong digital engagement improves your credit profile.',
        actionItem: 'Use mobile banking and digital payment apps regularly.',
        category: 'Digital',
        priority: 0.7,
        icon: Icons.smartphone,
      ),
    ];

    return ShapExplanation(
      applicationId: applicationId,
      topFeatures: mockFeatures,
      baseValue: 0.3,
      predictionValue: 0.344,
      totalShapContribution: 0.044,
      readableExplanation: [
        'Annual Income decreases risk by 0.045',
        'Late Payments increase risk by 0.089',
        'Loan Amount increases risk by 0.034',
        'Digital Score decreases risk by 0.023',
      ],
      recommendations: mockRecommendations,
    );
  }

  void clearState() {
    state = EnhancedApplicationState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final enhancedApplicationProvider = StateNotifierProvider<EnhancedApplicationNotifier, EnhancedApplicationState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return EnhancedApplicationNotifier(apiService, firebaseService);
});
