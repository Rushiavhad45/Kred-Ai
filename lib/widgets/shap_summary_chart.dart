// flutter_app/lib/widgets/shap_summary_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/shap_explanation_model.dart';
import '../utils/constants.dart';

class ShapSummaryChart extends StatefulWidget {
  final ShapExplanation explanation;

  const ShapSummaryChart({
    super.key,
    required this.explanation,
  });

  @override
  State<ShapSummaryChart> createState() => _ShapSummaryChartState();
}

class _ShapSummaryChartState extends State<ShapSummaryChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.longAnimationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    
    final sortedFeatures = widget.explanation.sortedFeatures.take(8).toList();
    final maxAbsValue = sortedFeatures.isNotEmpty 
        ? sortedFeatures.map((e) => e.value.absShapValue).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return _buildChart(sortedFeatures, maxAbsValue, isSmallScreen);
              },
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          _buildLegend(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Row(
      children: [
        Icon(
          Icons.bar_chart,
          color: const Color(AppConstants.primaryColorValue),
          size: isSmallScreen ? 20 : 24,
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SHAP Feature Summary',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConstants.primaryColorValue),
                ),
              ),
              Text(
                'Impact of top features on risk prediction',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<MapEntry<String, FeatureContribution>> features, double maxAbsValue, bool isSmallScreen) {
    if (features.isEmpty) {
      return const Center(
        child: Text('No feature data available'),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAbsValue * 1.2,
        minY: -maxAbsValue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            setState(() {
              if (response?.spot != null) {
                _hoveredIndex = response!.spot!.touchedBarGroupIndex;
              } else {
                _hoveredIndex = null;
              }
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            tooltipPadding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (group.x.toInt() >= features.length) return null;
              
              final feature = features[group.x.toInt()];
              final featureName = _formatFeatureName(feature.key);
              return BarTooltipItem(
                '$featureName\n'
                'SHAP Value: ${feature.value.shapValue > 0 ? '+' : ''}${feature.value.shapValue.toStringAsFixed(4)}\n'
                'Feature Value: ${feature.value.featureValue.toStringAsFixed(2)}\n'
                '${feature.value.increasesRisk ? 'Increases' : 'Decreases'} Risk',
                TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isSmallScreen ? 35 : 42,
              interval: maxAbsValue > 0 ? maxAbsValue / 4 : 0.1,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(2),
                style: TextStyle(fontSize: isSmallScreen ? 9 : 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isSmallScreen ? 60 : 80,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index >= 0 && index < features.length) {
                  final name = _formatFeatureName(features[index].key);
                  final displayName = name.length > 8 ? '${name.substring(0, 6)}...' : name;
                  
                  return SizedBox(
                    width: isSmallScreen ? 30 : 40,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 9,
                          fontWeight: _hoveredIndex == index ? FontWeight.bold : FontWeight.normal,
                          color: _hoveredIndex == index ? const Color(AppConstants.primaryColorValue) : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: features.asMap().entries.map((entry) {
          final index = entry.key;
          final shapValue = entry.value.value.shapValue * _animation.value;
          final isIncreasing = entry.value.value.increasesRisk;
          final isHovered = _hoveredIndex == index;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: shapValue,
                color: (isIncreasing
                    ? const Color(AppConstants.dangerColorValue)
                    : const Color(AppConstants.successColorValue))
                    .withOpacity(isHovered ? 1.0 : 0.8),
                width: isSmallScreen ? 14 : 18,
                borderRadius: const BorderRadius.all(Radius.circular(3)),
                gradient: LinearGradient(
                  colors: isIncreasing
                      ? [
                          const Color(AppConstants.dangerColorValue).withOpacity(0.7),
                          const Color(AppConstants.dangerColorValue),
                        ]
                      : [
                          const Color(AppConstants.successColorValue).withOpacity(0.7),
                          const Color(AppConstants.successColorValue),
                        ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 0,
                  color: Colors.grey.shade200,
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: value == 0 
                  ? const Color(AppConstants.primaryColorValue).withOpacity(0.8)
                  : Colors.grey.withOpacity(0.3),
              strokeWidth: value == 0 ? 2 : 0.8,
              dashArray: value == 0 ? null : [5, 5],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 13,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Wrap(
            spacing: isSmallScreen ? 12 : 16,
            runSpacing: 4,
            children: [
              _buildLegendItem(
                'Increases Risk',
                const Color(AppConstants.dangerColorValue),
                isSmallScreen,
              ),
              _buildLegendItem(
                'Decreases Risk',
                const Color(AppConstants.successColorValue),
                isSmallScreen,
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            'Tap on bars to see detailed information',
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 10,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 10 : 12,
          height: isSmallScreen ? 10 : 12,
          margin: EdgeInsets.only(right: isSmallScreen ? 4 : 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
        ),
      ],
    );
  }

  String _formatFeatureName(String featureName) {
    const featureMappings = {
      'person_income': 'Income',
      'loan_amnt': 'Loan Amt',
      'loan_int_rate': 'Int Rate',
      'loan_percent_income': 'L/I Ratio',
      'cb_person_cred_hist_length': 'Credit Hist',
      'age': 'Age',
      'utility_to_income_ratio': 'U/I Ratio',
      'on_time_payments_12m': 'On-time',
      'late_payments_12m': 'Late Pay',
      'digital_engagement_score': 'Digital',
      'credit_risk_score': 'Risk Score',
      'monthly_digital_transactions': 'Digital TX',
      'social_media_activity_score': 'Social',
      'mobile_banking_user': 'Mobile Bank',
      'person_emp_length': 'Employment',
      'monthly_airtime_spend': 'Airtime',
      'avg_calls_per_day': 'Calls/Day',
      'electricity_bill_avg': 'Electric',
      'water_bill_avg': 'Water',
      'financial_inclusion_score': 'Financial',
    };

    return featureMappings[featureName] ?? 
           featureName.replaceAll('_', ' ')
               .split(' ')
               .map((word) => word.isNotEmpty 
                   ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
                   : '')
               .join(' ');
  }
}
