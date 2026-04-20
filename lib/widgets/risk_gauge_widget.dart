// flutter_app/lib/widgets/risk_gauge_widget.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../utils/constants.dart';

class RiskGaugeWidget extends StatelessWidget {
  final double riskProbability;
  final String riskCategory;

  const RiskGaugeWidget({
    super.key,
    required this.riskProbability,
    required this.riskCategory,
  });

  @override
  Widget build(BuildContext context) {
    Color gaugeColor;
    IconData gaugeIcon;
    
    if (riskProbability <= AppConstants.lowRiskThreshold) {
      gaugeColor = const Color(AppConstants.successColorValue);
      gaugeIcon = Icons.check_circle;
    } else if (riskProbability <= AppConstants.mediumRiskThreshold) {
      gaugeColor = const Color(AppConstants.warningColorValue);
      gaugeIcon = Icons.warning;
    } else {
      gaugeColor = const Color(AppConstants.dangerColorValue);
      gaugeIcon = Icons.error;
    }

    return CircularPercentIndicator(
      radius: 80.0,
      lineWidth: 12.0,
      percent: riskProbability,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            gaugeIcon,
            size: 32,
            color: gaugeColor,
          ),
          const SizedBox(height: 8),
          Text(
            '${(riskProbability * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: gaugeColor,
            ),
          ),
          Text(
            'Risk',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      progressColor: gaugeColor,
      backgroundColor: Colors.grey[300]!,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 1200,
    );
  }
}
