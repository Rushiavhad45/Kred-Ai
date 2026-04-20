// flutter_app/lib/widgets/analytics_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_model.dart';
import '../utils/constants.dart';

class ApplicationTrendsChart extends StatelessWidget {
  final List<ChartDataPoint> data;

  const ApplicationTrendsChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: const Color(AppConstants.primaryColorValue),
                  size: isSmallScreen ? 18 : 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Application Trends',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 18,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.successColorValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Last 30 Days',
                    style: TextStyle(
                      color: const Color(AppConstants.successColorValue),
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Chart
            SizedBox(
              height: isSmallScreen ? 180 : 240,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 7,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 && value.toInt() < data.length) {
                            final date = data[value.toInt()].date;
                            return Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isSmallScreen ? 9 : 11,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        reservedSize: 35,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isSmallScreen ? 9 : 11,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries
                          .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(AppConstants.primaryColorValue),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(AppConstants.primaryColorValue).withOpacity(0.25),
                            const Color(AppConstants.primaryColorValue).withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiskDistributionChart extends StatelessWidget {
  final List<ChartDataPoint> data;

  const RiskDistributionChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: const Color(AppConstants.primaryColorValue),
                  size: isSmallScreen ? 18 : 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Risk Distribution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 18,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Chart
            SizedBox(
              height: isSmallScreen ? 180 : 220,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {}),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: isSmallScreen ? 30 : 45,
                  sections: data.asMap().entries.map((entry) {
                    final colors = [
                      const Color(AppConstants.successColorValue),
                      const Color(AppConstants.warningColorValue),
                      const Color(AppConstants.dangerColorValue),
                    ];
                    return PieChartSectionData(
                      color: colors[entry.key % colors.length],
                      value: entry.value.value,
                      title: '${entry.value.value.toInt()}%',
                      radius: isSmallScreen ? 50 : 65,
                      titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Legend
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: data.asMap().entries.map((entry) {
                final colors = [
                  const Color(AppConstants.successColorValue),
                  const Color(AppConstants.warningColorValue),
                  const Color(AppConstants.dangerColorValue),
                ];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[entry.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.value.label ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: isSmallScreen ? 11 : 13,
                          ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
