// flutter_app/lib/widgets/expandable_feature_card.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/shap_explanation_model.dart';
import '../utils/constants.dart';

class ExpandableFeatureCard extends StatefulWidget {
  final String featureName;
  final FeatureContribution contribution;
  final int animationDelay;

  const ExpandableFeatureCard({
    super.key,
    required this.featureName,
    required this.contribution,
    this.animationDelay = 0,
  });

  @override
  State<ExpandableFeatureCard> createState() => _ExpandableFeatureCardState();
}

class _ExpandableFeatureCardState extends State<ExpandableFeatureCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.mediumAnimationDuration,
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Staggered animation
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(  //translatey
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: _buildCard(isSmallScreen),
          ),
        );
      },
    );
  }

  Widget _buildCard(bool isSmallScreen) {
    final shapValue = widget.contribution.shapValue;
    final isRiskIncreasing = widget.contribution.increasesRisk;
    final impactColor = isRiskIncreasing 
        ? const Color(AppConstants.dangerColorValue)
        : const Color(AppConstants.successColorValue);

    return Card(
      elevation: _isExpanded ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        side: BorderSide(
          color: impactColor.withOpacity(0.3),
          width: _isExpanded ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: AppConstants.shortAnimationDuration,
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(impactColor, isSmallScreen),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _isExpanded ? _buildExpandedContent(impactColor, isSmallScreen) : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color impactColor, bool isSmallScreen) {
    final shapValue = widget.contribution.shapValue;
    
    return Row(
      children: [
        // Feature Impact Icon
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: impactColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.contribution.increasesRisk ? Icons.trending_up : Icons.trending_down,
            color: impactColor,
            size: isSmallScreen ? 16 : 20,
          ),
        ),
        
        SizedBox(width: isSmallScreen ? 8 : 12),
        
        // Feature Name and Basic Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatFeatureName(widget.featureName),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Impact: ${shapValue > 0 ? '+' : ''}${shapValue.toStringAsFixed(3)}',
                style: TextStyle(
                  color: impactColor,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
        
        // SHAP Value Bar
        _buildMiniShapBar(shapValue, impactColor, isSmallScreen),
        
        SizedBox(width: isSmallScreen ? 8 : 12),
        
        // Expand Icon
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: AppConstants.shortAnimationDuration,
          child: Icon(
            Icons.expand_more,
            color: Colors.grey[600],
            size: isSmallScreen ? 20 : 24,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniShapBar(double shapValue, Color impactColor, bool isSmallScreen) {
    final maxValue = 0.2; // Adjust based on your typical SHAP value range
    final normalizedValue = (shapValue.abs() / maxValue).clamp(0.0, 1.0);
    
    return Container(
      width: isSmallScreen ? 40 : 60,
      height: isSmallScreen ? 4 : 6,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: normalizedValue,
        child: Container(
          decoration: BoxDecoration(
            color: impactColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(Color impactColor, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(top: isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          
          // Detailed Information
          _buildDetailRow('Feature Value', widget.contribution.featureValue.toStringAsFixed(2), isSmallScreen),
          const SizedBox(height: 8),
          _buildDetailRow('SHAP Contribution', 
            '${widget.contribution.shapValue > 0 ? '+' : ''}${widget.contribution.shapValue.toStringAsFixed(4)}', 
            isSmallScreen),
          const SizedBox(height: 8),
          _buildDetailRow('Risk Impact', 
            widget.contribution.increasesRisk ? 'Increases Risk' : 'Decreases Risk', 
            isSmallScreen, valueColor: impactColor),
          
          if (widget.contribution.description != null) ...[
            const SizedBox(height: 16),
            Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.contribution.description!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isSmallScreen ? 12 : 13,
                height: 1.4,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // SHAP Value Visualization
          _buildShapVisualization(impactColor, isSmallScreen),
          
          if (widget.contribution.recommendation != null) ...[
            const SizedBox(height: 16),
            _buildRecommendationSection(isSmallScreen),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 12 : 13,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildShapVisualization(Color impactColor, bool isSmallScreen) {
    final shapValue = widget.contribution.shapValue;
    final maxAbsValue = 0.2; // Adjust based on your data range
    final normalizedValue = shapValue / maxAbsValue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SHAP Impact Visualization',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: isSmallScreen ? 20 : 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Stack(
            children: [
              // Center line
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 1,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              // SHAP bar
              if (shapValue != 0)
                Positioned(
                  left: shapValue > 0 ? null : 0,
                  right: shapValue < 0 ? null : 0,
                  top: 2,
                  bottom: 2,
                  width: (normalizedValue.abs() * 0.5) * MediaQuery.of(context).size.width * 0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: impactColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Decreases Risk', style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: Colors.grey)),
            Text('Increases Risk', style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(AppConstants.infoColorValue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(AppConstants.infoColorValue).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: const Color(AppConstants.infoColorValue),
                size: isSmallScreen ? 16 : 18,
              ),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Text(
                'Recommendation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 12 : 13,
                  color: const Color(AppConstants.infoColorValue),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            widget.contribution.recommendation!,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              height: 1.3,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFeatureName(String featureName) {
    // Feature name mappings for better readability
    const featureMappings = {
      'person_income': 'Annual Income',
      'loan_amnt': 'Loan Amount',
      'loan_int_rate': 'Interest Rate',
      'loan_percent_income': 'Loan-to-Income Ratio',
      'cb_person_cred_hist_length': 'Credit History Length',
      'age': 'Age',
      'utility_to_income_ratio': 'Utility-to-Income Ratio',
      'on_time_payments_12m': 'On-time Payments (12m)',
      'late_payments_12m': 'Late Payments (12m)',
      'digital_engagement_score': 'Digital Engagement Score',
      'credit_risk_score': 'Credit Risk Score',
      'monthly_digital_transactions': 'Monthly Digital Transactions',
      'social_media_activity_score': 'Social Media Activity',
      'mobile_banking_user': 'Mobile Banking Usage',
      'person_emp_length': 'Employment Length',
      'monthly_airtime_spend': 'Monthly Airtime Spend',
      'avg_calls_per_day': 'Average Calls per Day',
      'electricity_bill_avg': 'Electricity Bill Average',
      'water_bill_avg': 'Water Bill Average',
      'financial_inclusion_score': 'Financial Inclusion Score',
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
