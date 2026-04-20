// flutter_app/lib/providers/application_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';
import '../models/application_model.dart';
import '../models/prediction_result_model.dart';
import '../models/shap_explanation_model.dart';

// API Service Provider
final apiServiceProvider = Provider((ref) => ApiService());

// Application State
class ApplicationState {
  final bool isLoading;
  final ApplicationModel? currentApplication;
  final Map<String, dynamic>? applicationResponse;
  final PredictionResult? predictionResult;
  final ShapExplanation? explanation;
  final String? error;

  ApplicationState({
    this.isLoading = false,
    this.currentApplication,
    this.applicationResponse,
    this.predictionResult,
    this.explanation,
    this.error,
  });

  ApplicationState copyWith({
    bool? isLoading,
    ApplicationModel? currentApplication,
    Map<String, dynamic>? applicationResponse,
    PredictionResult? predictionResult,
    ShapExplanation? explanation,
    String? error,
  }) {
    return ApplicationState(
      isLoading: isLoading ?? this.isLoading,
      currentApplication: currentApplication ?? this.currentApplication,
      applicationResponse: applicationResponse ?? this.applicationResponse,
      predictionResult: predictionResult ?? this.predictionResult,
      explanation: explanation ?? this.explanation,
      error: error ?? this.error,
    );
  }
}

// Application Provider
class ApplicationNotifier extends StateNotifier<ApplicationState> {
  final ApiService _apiService;

  ApplicationNotifier(this._apiService) : super(ApplicationState());

  Future<void> submitApplication(ApplicationModel application) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.submitApplication(application);
      final predictionResult = PredictionResult.fromJson(response['prediction_result']);
      
      state = state.copyWith(
        isLoading: false,
        currentApplication: application,
        applicationResponse: response,
        predictionResult: predictionResult,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

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
        error: e.toString(),
      );
    }
  }

  void clearState() {
    state = ApplicationState();
  }
}

final applicationProvider = StateNotifierProvider<ApplicationNotifier, ApplicationState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ApplicationNotifier(apiService);
});
