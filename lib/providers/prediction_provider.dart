// flutter_app/lib/providers/prediction_provider.dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kredai/providers/application_provider.dart';
import '../services/api_service.dart';
import '../models/prediction_result_model.dart';
import '../models/shap_explanation_model.dart';

// Prediction State
class PredictionState {
  final bool isLoading;
  final PredictionResult? result;
  final ShapExplanation? explanation;
  final String? error;
  final List<PredictionResult> history;

  PredictionState({
    this.isLoading = false,
    this.result,
    this.explanation,
    this.error,
    this.history = const [],
  });

  PredictionState copyWith({
    bool? isLoading,
    PredictionResult? result,
    ShapExplanation? explanation,
    String? error,
    List<PredictionResult>? history,
  }) {
    return PredictionState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      explanation: explanation ?? this.explanation,
      error: error,
      history: history ?? this.history,
    );
  }
}

// Prediction Notifier
class PredictionNotifier extends StateNotifier<PredictionState> {
  final ApiService _apiService;

  PredictionNotifier(this._apiService) : super(PredictionState());

  // Get prediction result
  Future<void> getPrediction(String applicationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // In a real app, you'd fetch the prediction by application ID
      // For now, we'll simulate this
      await Future.delayed(const Duration(seconds: 1));
      
      // This would typically come from the API
      // state = state.copyWith(
      //   isLoading: false,
      //   result: predictionResult,
      // );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Get explanation for a prediction
  Future<void> getExplanation(String applicationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final explanation = await _apiService.getExplanation(applicationId);
      
      state = state.copyWith(
        isLoading: false,
        explanation: explanation,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load explanation: ${e.toString()}',
      );
    }
  }

  // Add prediction to history
  void addToHistory(PredictionResult result) {
    final newHistory = [...state.history, result];
    state = state.copyWith(history: newHistory);
  }

  // Clear prediction state
  void clearPrediction() {
    state = state.copyWith(
      result: null,
      explanation: null,
      error: null,
    );
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get risk color based on probability
  Color getRiskColor(double riskProbability) {
    if (riskProbability <= 0.3) {
      return const Color(0xFF4CAF50); // Green - Low Risk
    } else if (riskProbability <= 0.7) {
      return const Color(0xFFFF9800); // Orange - Medium Risk
    } else {
      return const Color(0xFFF44336); // Red - High Risk
    }
  }

  // Get risk description
  String getRiskDescription(double riskProbability) {
    if (riskProbability <= 0.3) {
      return 'Low Risk - Excellent creditworthiness';
    } else if (riskProbability <= 0.7) {
      return 'Medium Risk - Acceptable creditworthiness with some concerns';
    } else {
      return 'High Risk - Significant creditworthiness concerns';
    }
  }

  // Format risk probability as percentage
  String formatRiskPercentage(double riskProbability) {
    return '${(riskProbability * 100).toStringAsFixed(1)}%';
  }
}

// Prediction Provider
final predictionProvider = StateNotifierProvider<PredictionNotifier, PredictionState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PredictionNotifier(apiService);
});

// Helper providers
final currentPredictionProvider = Provider<PredictionResult?>((ref) {
  return ref.watch(predictionProvider).result;
});

final predictionHistoryProvider = Provider<List<PredictionResult>>((ref) {
  return ref.watch(predictionProvider).history;
});

final explanationProvider = Provider<ShapExplanation?>((ref) {
  return ref.watch(predictionProvider).explanation;
});

final predictionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(predictionProvider).isLoading;
});

// Risk assessment helpers
final riskColorProvider = Provider.family<Color, double>((ref, riskProbability) {
  return ref.read(predictionProvider.notifier).getRiskColor(riskProbability);
});

final riskDescriptionProvider = Provider.family<String, double>((ref, riskProbability) {
  return ref.read(predictionProvider.notifier).getRiskDescription(riskProbability);
});
