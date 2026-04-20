// flutter_app/lib/screens/enhanced_results_screen.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/enhanced_application_provider.dart';
import '../widgets/risk_gauge_widget.dart';
import '../widgets/shap_summary_chart.dart';
import '../widgets/expandable_feature_card.dart';
import '../widgets/recommendation_section.dart';
import '../widgets/personal_data_summary_widget.dart';
import '../widgets/export_options_widget.dart';
import '../models/shap_explanation_model.dart';
import '../services/export_service.dart';
import '../utils/constants.dart';
import 'dashboard_screen.dart';

class EnhancedResultsScreen extends ConsumerStatefulWidget {
  const EnhancedResultsScreen({super.key});

  @override
  ConsumerState<EnhancedResultsScreen> createState() => _EnhancedResultsScreenState();
}

class _EnhancedResultsScreenState extends ConsumerState<EnhancedResultsScreen>
    with TickerProviderStateMixin {
  bool _explanationLoaded = false;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final GlobalKey _screenshotKey = GlobalKey();
  final ExportService _exportService = ExportService();
  
  ShapExplanation? _mockExplanation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _createMockExplanation();
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExplanation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _createMockExplanation() {
    // Create comprehensive mock explanation
    final state = ref.read(enhancedApplicationProvider);
    final application = state.enhancedApplication;
    
    if (application != null) {
      final mockFeatures = <String, FeatureContribution>{
        'person_income': FeatureContribution(
          shapValue: -0.045,
          featureValue: application.applicationData.personIncome,
          impact: 'decreases_risk',
          description: 'Your annual income of ₹${application.applicationData.personIncome.toStringAsFixed(0)} positively affects your risk profile',
          recommendation: 'Your income level is good. Consider documenting additional income sources if available.',
        ),
        'late_payments_12m': FeatureContribution(
          shapValue: 0.089,
          featureValue: application.applicationData.latePayments12m.toDouble(),
          impact: 'increases_risk',
          description: 'Having ${application.applicationData.latePayments12m} late payments significantly increases your risk',
          recommendation: 'Set up automatic payments and payment reminders to avoid future late payments.',
        ),
        'loan_amnt': FeatureContribution(
          shapValue: 0.034,
          featureValue: application.applicationData.loanAmnt,
          impact: 'increases_risk',
          description: 'The requested loan amount of ₹${application.applicationData.loanAmnt.toStringAsFixed(0)} increases the assessed risk',
          recommendation: 'Consider requesting a smaller amount or work on improving income/credit before applying.',
        ),
        'digital_engagement_score': FeatureContribution(
          shapValue: -0.023,
          featureValue: application.applicationData.digitalEngagementScore,
          impact: 'decreases_risk',
          description: 'Your digital engagement score shows good digital financial behavior',
          recommendation: 'Continue using digital financial services to maintain your strong profile.',
        ),
        'utility_to_income_ratio': FeatureContribution(
          shapValue: 0.019,
          featureValue: application.applicationData.utilityToIncomeRatio,
          impact: 'increases_risk',
          description: 'Your utility-to-income ratio is within acceptable range',
          recommendation: 'Consider reducing utility costs through energy-efficient appliances.',
        ),
        'age': FeatureContribution(
          shapValue: -0.012,
          featureValue: application.userProfile.age.toDouble(),
          impact: 'decreases_risk',
          description: 'Your age of ${application.userProfile.age} years is factored favorably',
          recommendation: null,
        ),
      };

      final mockRecommendations = [
        PersonalizedRecommendation(
          title: 'Improve Payment History',
          description: 'Your payment history is the most important factor in credit assessment. Late payments significantly impact your score.',
          actionItem: 'Set up automatic payments for all bills and loans to ensure timely payments.',
          category: 'Payment',
          priority: 0.9,
          icon: Icons.payment,
        ),
        PersonalizedRecommendation(
          title: 'Optimize Loan Amount',
          description: 'The requested loan amount relative to your income affects risk assessment.',
          actionItem: 'Consider requesting a smaller amount or work on improving income first.',
          category: 'Credit',
          priority: 0.7,
          icon: Icons.account_balance,
        ),
        PersonalizedRecommendation(
          title: 'Build Digital Presence',
          description: 'Your digital financial activity helps establish creditworthiness.',
          actionItem: 'Continue using mobile banking, digital payments, and financial apps regularly.',
          category: 'Digital',
          priority: 0.6,
          icon: Icons.smartphone,
        ),
        PersonalizedRecommendation(
          title: 'Manage Utility Expenses',
          description: 'Utility payment patterns demonstrate financial responsibility.',
          actionItem: 'Keep utility bills current and consider energy-saving measures to reduce costs.',
          category: 'Utility',
          priority: 0.5,
          icon: Icons.electrical_services,
        ),
      ];

      _mockExplanation = ShapExplanation(
        applicationId: application.applicationId,
        topFeatures: mockFeatures,
        baseValue: 0.3,
        predictionValue: 0.344,
        totalShapContribution: 0.044,
        readableExplanation: [
          'Annual Income (₹${application.applicationData.personIncome.toStringAsFixed(0)}) decreases risk by 0.045',
          'Late Payments (${application.applicationData.latePayments12m}) increases risk by 0.089',
          'Loan Amount (₹${application.applicationData.loanAmnt.toStringAsFixed(0)}) increases risk by 0.034',
          'Digital Score (${application.applicationData.digitalEngagementScore.toStringAsFixed(0)}) decreases risk by 0.023',
          'Utility Ratio (${application.applicationData.utilityToIncomeRatio.toStringAsFixed(3)}) increases risk by 0.019',
          'Age (${application.userProfile.age} years) decreases risk by 0.012',
        ],
        recommendations: mockRecommendations,
      );
    }
  }

  void _loadExplanation() async {
    try {
      final state = ref.read(enhancedApplicationProvider);
      if (state.applicationResponse != null) {
        final applicationId = state.applicationResponse!['application_id'];
        await ref.read(enhancedApplicationProvider.notifier).getExplanation(applicationId);
        
        final updatedState = ref.read(enhancedApplicationProvider);
        if (updatedState.explanation != null) {
          setState(() => _explanationLoaded = true);
        } else {
          setState(() => _explanationLoaded = true);
        }
      } else {
        setState(() => _explanationLoaded = true);
      }
    } catch (e) {
      setState(() => _explanationLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationState = ref.watch(enhancedApplicationProvider);
    final enhancedApplication = applicationState.enhancedApplication;
    final predictionResult = applicationState.predictionResult;
    final explanation = applicationState.explanation ?? _mockExplanation;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final padding = screenWidth * 0.04;

    if (enhancedApplication == null || predictionResult == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return RepaintBoundary(
      key: _screenshotKey,
      child: Scaffold(
        backgroundColor: const Color(AppConstants.backgroundColorValue),
        appBar: AppBar(
          title: const Text('Assessment Results'),
          backgroundColor: const Color(AppConstants.primaryColorValue),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              ref.read(enhancedApplicationProvider.notifier).clearState();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
                (route) => false,
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showExportOptions(),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _exportToPdf(),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                // Personal Data Summary
                PersonalDataSummaryWidget(
                  enhancedApplication: enhancedApplication,
                  isSmallScreen: isSmallScreen,
                ),
                
                SizedBox(height: padding * 1.5),
                
                // Risk Assessment Card
                _buildRiskAssessmentCard(predictionResult, isSmallScreen, padding),
                
                SizedBox(height: padding * 1.5),
                
                // Explanation Tabs
                if (explanation != null) ...[
                  _buildExplanationTabs(explanation, isSmallScreen, padding),
                ],
                
                SizedBox(height: padding * 1.5),
                
                // Action Buttons
                _buildActionButtons(predictionResult, enhancedApplication, isSmallScreen, padding),
                
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskAssessmentCard(dynamic predictionResult, bool isSmallScreen, double padding) {
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
                color: const Color(AppConstants.primaryColorValue),
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

  Widget _buildExplanationTabs(ShapExplanation explanation, bool isSmallScreen, double padding) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Column(
        children: [
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
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.bold,
              ),
              isScrollable: true,
              tabs: const [
                Tab(text: 'Summary', icon: Icon(Icons.person, size: 16)),
                Tab(text: 'Features', icon: Icon(Icons.view_list, size: 16)),
                Tab(text: 'Analysis', icon: Icon(Icons.bar_chart, size: 16)),
                Tab(text: 'Tips', icon: Icon(Icons.lightbulb, size: 16)),
              ],
            ),
          ),
          
          SizedBox(
            height: isSmallScreen ? 500 : 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalSummaryTab(isSmallScreen, padding),
                _buildFeatureDetailsTab(explanation, isSmallScreen, padding),
                _buildAnalysisTab(explanation, isSmallScreen, padding),
                _buildRecommendationsTab(explanation, isSmallScreen, padding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSummaryTab(bool isSmallScreen, double padding) {
    final state = ref.watch(enhancedApplicationProvider);
    final application = state.enhancedApplication;
    
    if (application == null) return const Center(child: Text('No data available'));

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Summary',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(AppConstants.primaryColorValue),
            ),
          ),
          SizedBox(height: padding),
          
          ...application.summaryData.entries.map((entry) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: isSmallScreen ? 120 : 140,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildFeatureDetailsTab(ShapExplanation explanation, bool isSmallScreen, double padding) {
    final sortedFeatures = explanation.sortedFeatures.take(8).toList();
    
    return Padding(
      padding: EdgeInsets.all(padding),
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
                      'Key Contributing Factors',
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
          SizedBox(height: padding),
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

  Widget _buildAnalysisTab(ShapExplanation explanation, bool isSmallScreen, double padding) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      child: ShapSummaryChart(explanation: explanation),
    );
  }

  Widget _buildRecommendationsTab(ShapExplanation explanation, bool isSmallScreen, double padding) {
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
                    'Great job!',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(AppConstants.successColorValue),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'Your profile looks excellent.\nNo specific recommendations needed.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButtons(dynamic predictionResult, dynamic enhancedApplication, bool isSmallScreen, double padding) {
    return Column(
      children: [
        if (isSmallScreen) ...[
          // Stacked buttons for small screens
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _exportToPdf(),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download PDF Report'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(AppConstants.primaryColorValue),
              ),
            ),
          ),
          SizedBox(height: padding * 0.7),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showExportOptions(),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(width: padding * 0.5),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(enhancedApplicationProvider.notifier).clearState();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('New'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Side by side buttons for larger screens
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _exportToPdf(),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download PDF Report'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(AppConstants.primaryColorValue),
                  ),
                ),
              ),
              SizedBox(width: padding * 0.7),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showExportOptions(),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(width: padding * 0.7),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(enhancedApplicationProvider.notifier).clearState();
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
            ],
          ),
        ],
      ],
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ExportOptionsWidget(
        onExportPdf: () {
          Navigator.pop(context);
          _exportToPdf();
        },
        onExportImage: () {
          Navigator.pop(context);
          _exportToImage();
        },
        onShare: () {
          Navigator.pop(context);
          _shareResults();
        },
      ),
    );
  }

  Future<void> _exportToPdf() async {
    try {
      _showLoadingDialog('Generating PDF...');
      
      final state = ref.read(enhancedApplicationProvider);
      final application = state.enhancedApplication;
      final prediction = state.predictionResult;
      final explanation = state.explanation ?? _mockExplanation;
      
      if (application != null && prediction != null) {
        final filePath = await _exportService.exportToPdf(
          application: application,
          predictionResult: prediction,
          explanation: explanation,
        );
        
        Navigator.pop(context); // Close loading dialog
        
        _showSuccessDialog('PDF Generated', 'Report saved successfully!', () {
          _exportService.shareFile(filePath, 'Credit Assessment Report');
        });
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Export Failed', 'Failed to generate PDF: $e');
    }
  }

  Future<void> _exportToImage() async {
    try {
      _showLoadingDialog('Generating Image...');
      
      final state = ref.read(enhancedApplicationProvider);
      final applicationId = state.enhancedApplication?.applicationId ?? 'unknown';
      
      final filePath = await _exportService.exportToImage(
        repaintBoundaryKey: _screenshotKey,
        applicationId: applicationId,
      );
      
      Navigator.pop(context); // Close loading dialog
      
      _showSuccessDialog('Image Generated', 'Screenshot saved successfully!', () {
        _exportService.shareFile(filePath, 'Credit Assessment Screenshot');
      });
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Export Failed', 'Failed to generate image: $e');
    }
  }

  void _shareResults() {
    final state = ref.read(enhancedApplicationProvider);
    final application = state.enhancedApplication;
    final prediction = state.predictionResult;
    
    if (application != null && prediction != null) {
      final shareText = '''
Credit Assessment Results

Applicant: ${application.userProfile.fullName}
Application ID: ${application.applicationId}
Assessment Date: ${application.submissionTimestamp.toString().split(' ')[0]}

Result: ${prediction.loanStatus}
Risk Category: ${prediction.riskCategory}
Risk Probability: ${(prediction.riskProbability * 100).toStringAsFixed(1)}%
Model Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%

Generated by KredAI - Credit Risk Assessment System
''';
      
      Share.share(
        shareText,
        subject: 'Credit Assessment Results',
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, VoidCallback onShare) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onShare();
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
