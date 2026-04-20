// flutter_app/lib/models/prediction_result_model.dart
class PredictionResult {
  final String loanStatus;
  final double riskProbability;
  final String riskCategory;
  final double confidence;
  final String predictionTimestamp;
  final String modelVersion;

  PredictionResult({
    required this.loanStatus,
    required this.riskProbability,
    required this.riskCategory,
    required this.confidence,
    required this.predictionTimestamp,
    required this.modelVersion,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      loanStatus: json['loan_status'],
      riskProbability: json['risk_probability'].toDouble(),
      riskCategory: json['risk_category'],
      confidence: json['confidence'].toDouble(),
      predictionTimestamp: json['prediction_timestamp'],
      modelVersion: json['model_version'],
    );
  }

  bool get isApproved => loanStatus == 'Approved';
  
  // Color get statusColor {
  //   switch (riskCategory) {
  //     case 'Low Risk':
  //       return const Color(AppConstants.successColorValue);
  //     case 'Medium Risk':
  //       return const Color(AppConstants.warningColorValue);
  //     case 'High Risk':
  //       return const Color(AppConstants.dangerColorValue);
  //     default:
  //       return Colors.grey;
  //   }
  // }
}
