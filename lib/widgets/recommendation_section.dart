// flutter_app/lib/widgets/recommendation_section.dart
import 'package:flutter/material.dart';
import '../models/shap_explanation_model.dart';
import '../utils/constants.dart';

class RecommendationSection extends StatefulWidget {
  final List<PersonalizedRecommendation> recommendations;

  const RecommendationSection({
    super.key,
    required this.recommendations,
  });

  @override
  State<RecommendationSection> createState() => _RecommendationSectionState();
}

class _RecommendationSectionState extends State<RecommendationSection>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800 + (widget.recommendations.length * 100)),
      vsync: this,
    );

    _itemAnimations = List.generate(
      widget.recommendations.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.8),
            (0.6 + (index * 0.1)).clamp(0.1, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
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
    final isSmallScreen = screenWidth < 600;

    if (widget.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort recommendations by priority
    final sortedRecommendations = List<PersonalizedRecommendation>.from(widget.recommendations)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 20),
            ...sortedRecommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final recommendation = entry.value;
              if (index < _itemAnimations.length) {
                return AnimatedBuilder(
                  animation: _itemAnimations[index],
                  builder: (context, child) {
                    final animationValue = _itemAnimations[index].value.clamp(0.0, 1.0);
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - animationValue)),
                      child: Opacity(
                        opacity: animationValue,
                        child: _buildRecommendationCard(recommendation, index, isSmallScreen),
                      ),
                    );
                  },
                );
              } else {
                return _buildRecommendationCard(recommendation, index, isSmallScreen);
              }
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: const Color(AppConstants.infoColorValue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.psychology,
            color: const Color(AppConstants.infoColorValue),
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalized Recommendations',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConstants.primaryColorValue),
                ),
              ),
              Text(
                'Actions to improve your credit profile',
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

  Widget _buildRecommendationCard(PersonalizedRecommendation recommendation, int index, bool isSmallScreen) {
    final priorityColor = _getPriorityColor(recommendation.priority);
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRecommendationDetails(recommendation),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: priorityColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getPriorityText(recommendation.priority),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 10 : 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category
                  Expanded(
                    child: Text(
                      recommendation.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    recommendation.icon,
                    color: priorityColor,
                    size: isSmallScreen ? 18 : 20,
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                recommendation.title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                recommendation.description,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    size: isSmallScreen ? 14 : 16,
                    color: priorityColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      recommendation.actionItem,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: priorityColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(double priority) {
    if (priority >= 0.8) {
      return const Color(AppConstants.dangerColorValue);
    } else if (priority >= 0.6) {
      return const Color(AppConstants.warningColorValue);
    } else {
      return const Color(AppConstants.infoColorValue);
    }
  }

  String _getPriorityText(double priority) {
    if (priority >= 0.8) {
      return 'HIGH';
    } else if (priority >= 0.6) {
      return 'MED';
    } else {
      return 'LOW';
    }
  }

  void _showRecommendationDetails(PersonalizedRecommendation recommendation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenWidth * 0.9 : 400,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        recommendation.icon,
                        color: _getPriorityColor(recommendation.priority),
                        size: isSmallScreen ? 24 : 28,
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Text(
                          recommendation.title,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(recommendation.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 15,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        Text(
                          recommendation.description,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Text(
                          'Action Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 15,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        Text(
                          recommendation.actionItem,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            height: 1.5,
                            color: _getPriorityColor(recommendation.priority),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
