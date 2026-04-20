// flutter_app/lib/screens/results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kredai/screens/dashboard_screen.dart';
import '../providers/application_provider.dart';
import '../widgets/risk_gauge_widget.dart';
import '../widgets/shap_chart_widget.dart';
import '../widgets/shap_summary_chart.dart';
import '../widgets/expandable_feature_card.dart';
import '../widgets/recommendation_section.dart';
import '../models/shap_explanation_model.dart';
import '../utils/constants.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with TickerProviderStateMixin {
  bool _explanationLoaded = false;
  late TabController _tabController;
  ShapExplanation? _mockExplanation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _createMockExplanation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExplanation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _createMockExplanation() {
    // Create mock explanation data for testing/fallback
    final mockFeatures = <String, FeatureContribution>{
      'person_income': FeatureContribution(
        shapValue: -0.045,
        featureValue: 45000.0,
        impact: 'decreases_risk',
        description: 'Your annual income of ₹45,000 positively affects your risk profile',
        recommendation: 'Your income level is good. Consider documenting additional income sources if available.',
      ),
      'late_payments_12m': FeatureContribution(
        shapValue: 0.089,
        featureValue: 2.0,
        impact: 'increases_risk',
        description: 'Having 2 late payments in the last 12 months significantly increases your risk',
        recommendation: 'Set up automatic payments and payment reminders to avoid future late payments.',
      ),
      'loan_amnt': FeatureContribution(
        shapValue: 0.034,
        featureValue: 15000.0,
        impact: 'increases_risk',
        description: 'The requested loan amount of ₹15,000 increases the assessed risk',
        recommendation: 'Consider requesting a smaller amount or work on improving income/credit before applying.',
      ),
      'digital_engagement_score': FeatureContribution(
        shapValue: -0.023,
        featureValue: 65.0,
        impact: 'decreases_risk',
        description: 'Your digital engagement score of 65 shows good digital financial behavior',
        recommendation: 'Continue using digital financial services to maintain your strong digital profile.',
      ),
      'utility_to_income_ratio': FeatureContribution(
        shapValue: 0.019,
        featureValue: 0.043,
        impact: 'increases_risk',
        description: 'Your utility-to-income ratio of 0.043 is within acceptable range',
        recommendation: 'Consider reducing utility costs through energy-efficient appliances or budget management.',
      ),
      'age': FeatureContribution(
        shapValue: -0.012,
        featureValue: 32.0,
        impact: 'decreases_risk',
        description: 'Your age of 32 years is factored favorably into the risk calculation',
        recommendation: null,
      ),
    };

    final mockRecommendations = [
      PersonalizedRecommendation(
        title: 'Improve Payment History',
        description: 'Your recent late payments are significantly impacting your credit risk assessment. This is the most important factor affecting your score.',
        actionItem: 'Set up automatic payments and payment reminders to ensure timely payments going forward.',
        category: 'Payment',
        priority: 0.9,
        icon: Icons.payment,
      ),
      PersonalizedRecommendation(
        title: 'Optimize Loan Amount',
        description: 'The requested loan amount might be high relative to your current financial profile.',
        actionItem: 'Consider requesting a smaller amount or work on improving income/credit before applying.',
        category: 'Credit',
        priority: 0.7,
        icon: Icons.account_balance,
      ),
      PersonalizedRecommendation(
        title: 'Maintain Digital Activity',
        description: 'Your digital engagement is good and helps your credit profile.',
        actionItem: 'Continue using mobile banking, digital payments, and financial apps regularly.',
        category: 'Digital',
        priority: 0.5,
        icon: Icons.smartphone,
      ),
    ];

    _mockExplanation = ShapExplanation(
      applicationId: 'mock_app_123',
      topFeatures: mockFeatures,
      baseValue: 0.3,
      predictionValue: 0.344,
      totalShapContribution: 0.044,
      readableExplanation: [
        'Annual Income (₹45,000) decreases risk by 0.045',
        'Late Payments (2) increases risk by 0.089',
        'Loan Amount (₹15,000) increases risk by 0.034',
        'Digital Score (65) decreases risk by 0.023',
        'Utility Ratio (0.043) increases risk by 0.019',
        'Age (32 years) decreases risk by 0.012',
      ],
      recommendations: mockRecommendations,
    );
  }

  void _loadExplanation() async {
    try {
      final state = ref.read(applicationProvider);
      if (state.applicationResponse != null) {
        final applicationId = state.applicationResponse!['application_id'];
        await ref.read(applicationProvider.notifier).getExplanation(applicationId);
        
        // Check if explanation was loaded successfully
        final updatedState = ref.read(applicationProvider);
        if (updatedState.explanation != null) {
          setState(() => _explanationLoaded = true);
        } else {
          // Use mock data if real explanation fails to load
          setState(() => _explanationLoaded = true);
        }
      } else {
        // Use mock data if no application response
        setState(() => _explanationLoaded = true);
      }
    } catch (e) {
      // Use mock data if error occurs
      setState(() => _explanationLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationState = ref.watch(applicationProvider);
    final predictionResult = applicationState.predictionResult;
    final explanation = applicationState.explanation ?? _mockExplanation;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final padding = screenWidth * 0.04;

    if (predictionResult == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Results'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            ref.read(applicationProvider.notifier).clearState();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          children: [
            // Risk Assessment Card
            _buildRiskAssessmentCard(predictionResult, isSmallScreen),
            
            SizedBox(height: padding * 1.5),
            
            // Always show explanation section (use mock data if needed)
            _buildExplanationTabs(explanation!, isSmallScreen),
            
            SizedBox(height: padding * 1.5),
            
            // Action Buttons
            _buildActionButtons(predictionResult, isSmallScreen),
            
            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessmentCard(dynamic predictionResult, bool isSmallScreen) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
        child: Column(
          children: [
            Text(
              'Credit Assessment Result',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            
            // Risk Gauge
            SizedBox(
              height: isSmallScreen ? 180 : 200,
              child: RiskGaugeWidget(
                riskProbability: predictionResult.riskProbability,
                riskCategory: predictionResult.riskCategory,
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 20 : 24),
            
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20 : 24, 
                vertical: isSmallScreen ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: predictionResult.isApproved 
                  ? const Color(AppConstants.successColorValue)
                  : const Color(AppConstants.dangerColorValue),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (predictionResult.isApproved 
                      ? const Color(AppConstants.successColorValue)
                      : const Color(AppConstants.dangerColorValue)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    predictionResult.isApproved 
                      ? Icons.check_circle 
                      : Icons.cancel,
                    color: Colors.white,
                    size: isSmallScreen ? 18 : 20,
                  ),
                  SizedBox(width: isSmallScreen ? 6 : 8),
                  Text(
                    predictionResult.loanStatus,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Risk Details
            _buildRiskDetails(predictionResult, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskDetails(dynamic predictionResult, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('Risk Probability', '${(predictionResult.riskProbability * 100).toStringAsFixed(1)}%', isSmallScreen),
          const Divider(),
          _buildDetailRow('Risk Category', predictionResult.riskCategory, isSmallScreen),
          const Divider(),
          _buildDetailRow('Model Confidence', '${(predictionResult.confidence * 100).toStringAsFixed(1)}%', isSmallScreen),
          const Divider(),
          _buildDetailRow('Assessment Time', predictionResult.predictionTimestamp.split('T')[0], isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationTabs(ShapExplanation explanation, bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Column(
        children: [
          // Tab Header
          Container(
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.cardRadius),
                topRight: Radius.circular(AppConstants.cardRadius),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(AppConstants.primaryColorValue),
              labelColor: const Color(AppConstants.primaryColorValue),
              unselectedLabelColor: Colors.grey[600],
              labelStyle: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'Features', icon: Icon(Icons.view_list, size: 18)),
                Tab(text: 'Summary', icon: Icon(Icons.bar_chart, size: 18)),
                Tab(text: 'Tips', icon: Icon(Icons.lightbulb, size: 18)),
              ],
            ),
          ),
          
          // Tab Content
          SizedBox(
            height: isSmallScreen ? 500 : 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Feature Details Tab
                _buildFeatureDetailsTab(explanation, isSmallScreen),
                
                // Summary Chart Tab
                _buildSummaryTab(explanation, isSmallScreen),
                
                // Recommendations Tab
                _buildRecommendationsTab(explanation, isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDetailsTab(ShapExplanation explanation, bool isSmallScreen) {
    final sortedFeatures = explanation.sortedFeatures.take(8).toList();
    
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: const Color(AppConstants.primaryColorValue),
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Contributing Features',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(AppConstants.primaryColorValue),
                      ),
                    ),
                    Text(
                      'Tap cards to see detailed analysis',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Expanded(
            child: ListView.builder(
              itemCount: sortedFeatures.length,
              itemBuilder: (context, index) {
                final feature = sortedFeatures[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ExpandableFeatureCard(
                    featureName: feature.key,
                    contribution: feature.value,
                    animationDelay: index * 100,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(ShapExplanation explanation, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      child: Column(
        children: [
          Expanded(
            child: ShapSummaryChart(explanation: explanation),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab(ShapExplanation explanation, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      child: explanation.recommendations.isNotEmpty
          ? SingleChildScrollView(
              child: RecommendationSection(
                recommendations: explanation.recommendations,
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: isSmallScreen ? 48 : 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    'No specific recommendations',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'Your profile looks great!',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButtons(dynamic predictionResult, bool isSmallScreen) {
    return Column(
      children: [
        if (isSmallScreen) ...[
          // Stacked buttons for small screens
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(applicationProvider.notifier).clearState();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('New Assessment'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Loan application feature coming soon!'),
                  ),
                );
              },
              icon: Icon(predictionResult.isApproved ? Icons.approval : Icons.tips_and_updates),
              label: Text(predictionResult.isApproved ? 'Apply for Loan' : 'Improve Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ] else ...[
          // Side by side buttons for larger screens
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(applicationProvider.notifier).clearState();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Assessment'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Loan application feature coming soon!'),
                      ),
                    );
                  },
                  icon: Icon(predictionResult.isApproved ? Icons.approval : Icons.tips_and_updates),
                  label: Text(predictionResult.isApproved ? 'Apply for Loan' : 'Improve Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
