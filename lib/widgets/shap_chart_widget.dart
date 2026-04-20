// flutter_app/lib/widgets/shap_chart_widget.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/shap_explanation_model.dart';
import '../utils/constants.dart';

class ShapChartWidget extends StatelessWidget {
  final ShapExplanation explanation;

  const ShapChartWidget({
    super.key,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final features = explanation.topFeatures.entries.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Impact Analysis',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.4,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:
                  features.map((f) => f.value.shapValue.abs()).reduce((a, b) => a > b ? a : b) * 1.2,
              minY:
                  -features.map((f) => f.value.shapValue.abs()).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.shade600,
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipBorderRadius: BorderRadius.circular(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final feature = features[group.x.toInt()];
                    return BarTooltipItem(
                      '${_formatFeatureName(feature.key)}\n'
                      'Impact: ${feature.value.shapValue > 0 ? '+' : ''}${feature.value.shapValue.toStringAsFixed(3)}\n'
                      'Value: ${feature.value.featureValue.toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, _) => Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 64,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index >= 0 && index < features.length) {
                        final name = _formatFeatureName(features[index].key);
                        return RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            name.length > 15 ? '${name.substring(0, 12)}...' : name,
                            style: const TextStyle(fontSize: 9),
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
                final shapValue = entry.value.value.shapValue;
                final isIncreasing = shapValue > 0;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: shapValue,
                      color: isIncreasing
                          ? const Color(AppConstants.dangerColorValue).withOpacity(0.85)
                          : const Color(AppConstants.successColorValue).withOpacity(0.85),
                      width: 20,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 0,
                        color: Colors.grey.shade300,
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
                    color: value == 0 ? Colors.black : Colors.grey.withOpacity(0.3),
                    strokeWidth: value == 0 ? 1.5 : 0.5,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Increases Risk', const Color(AppConstants.dangerColorValue)),
            const SizedBox(width: 24),
            _buildLegendItem('Decreases Risk', const Color(AppConstants.successColorValue)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatFeatureName(String featureName) {
    return featureName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
        .join(' ');
  }
}
