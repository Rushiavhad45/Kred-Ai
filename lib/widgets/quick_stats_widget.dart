// flutter_app/lib/widgets/quick_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/constants.dart';
import '../models/dashboard_model.dart';
import 'package:intl/intl.dart';

class QuickStatsWidget extends StatelessWidget {
  final DashboardStats stats;

  const QuickStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'त्वरित आंकड़े',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        AnimationLimiter(
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppConstants.defaultPadding,
            crossAxisSpacing: AppConstants.defaultPadding,
            childAspectRatio: 1.2,
            children: [
              AnimationConfiguration.staggeredGrid(
                position: 0,
                duration: AppConstants.mediumAnimationDuration,
                columnCount: 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildStatCard(
                      context,
                      title: 'कुल आवेदन',
                      value: stats.totalApplications.toString(),
                      subtitle: 'सभी समय का कुल',
                      icon: Icons.assignment,
                      color: const Color(AppConstants.primaryColorValue),
                    ),
                  ),
                ),
              ),
              AnimationConfiguration.staggeredGrid(
                position: 1,
                duration: AppConstants.mediumAnimationDuration,
                columnCount: 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildStatCard(
                      context,
                      title: 'स्वीकृत',
                      value: stats.approvedApplications.toString(),
                      subtitle: '${(stats.approvalRate * 100).toStringAsFixed(1)}% दर',
                      icon: Icons.check_circle,
                      color: const Color(AppConstants.successColorValue),
                    ),
                  ),
                ),
              ),
              AnimationConfiguration.staggeredGrid(
                position: 2,
                duration: AppConstants.mediumAnimationDuration,
                columnCount: 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildStatCard(
                      context,
                      title: 'लंबित',
                      value: stats.pendingApplications.toString(),
                      subtitle: 'समीक्षाधीन',
                      icon: Icons.hourglass_empty,
                      color: const Color(AppConstants.warningColorValue),
                    ),
                  ),
                ),
              ),
              AnimationConfiguration.staggeredGrid(
                position: 3,
                duration: AppConstants.mediumAnimationDuration,
                columnCount: 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildStatCard(
                      context,
                      title: 'कुल वितरित',
                      value: '₹${NumberFormat('#,##,###').format(stats.totalDisbursed)}',
                      subtitle: 'स्वीकृत ऋण राशि',
                      icon: Icons.account_balance_wallet,
                      color: const Color(AppConstants.secondaryColorValue),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  const MiniStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (trend != null)
                    Text(
                      trend!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatisticsTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const StatisticsTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: backgroundColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: backgroundColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: backgroundColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
