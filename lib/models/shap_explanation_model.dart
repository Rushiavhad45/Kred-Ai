// flutter_app/lib/models/shap_explanation_model.dart
import 'package:flutter/material.dart';

class FeatureContribution {
  final double shapValue;
  final double featureValue;
  final String impact;
  final String? description;
  final String? recommendation;

  FeatureContribution({
    required this.shapValue,
    required this.featureValue,
    required this.impact,
    this.description,
    this.recommendation,
  });

  factory FeatureContribution.fromJson(Map<String, dynamic> json) {
    return FeatureContribution(
      shapValue: json['shap_value'].toDouble(),
      featureValue: json['feature_value'].toDouble(),
      impact: json['impact'],
      description: json['description'],
      recommendation: json['recommendation'],
    );
  }
  
  bool get increasesRisk => impact == 'increases_risk';
  
  double get absShapValue => shapValue.abs();
}

class PersonalizedRecommendation {
  final String title;
  final String description;
  final String actionItem;
  final String category;
  final double priority;
  final IconData icon;

  PersonalizedRecommendation({
    required this.title,
    required this.description,
    required this.actionItem,
    required this.category,
    required this.priority,
    required this.icon,
  });

  factory PersonalizedRecommendation.fromJson(Map<String, dynamic> json) {
    return PersonalizedRecommendation(
      title: json['title'],
      description: json['description'],
      actionItem: json['action_item'],
      category: json['category'],
      priority: json['priority'].toDouble(),
      icon: _getIconFromCategory(json['category']),
    );
  }

  static IconData _getIconFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'payment':
        return Icons.payment;
      case 'income':
        return Icons.attach_money;
      case 'credit':
        return Icons.credit_score;
      case 'digital':
        return Icons.smartphone;
      case 'utility':
        return Icons.electrical_services;
      default:
        return Icons.lightbulb;
    }
  }
}

class ShapExplanation {
  final String applicationId;
  final Map<String, FeatureContribution> topFeatures;
  final double baseValue;
  final double predictionValue;
  final double totalShapContribution;
  final List<String> readableExplanation;
  final List<PersonalizedRecommendation> recommendations;

  ShapExplanation({
    required this.applicationId,
    required this.topFeatures,
    required this.baseValue,
    required this.predictionValue,
    required this.totalShapContribution,
    required this.readableExplanation,
    this.recommendations = const [],
  });

  factory ShapExplanation.fromJson(Map<String, dynamic> json) {
    Map<String, FeatureContribution> features = {};
    
    if (json['top_features'] != null) {
      json['top_features'].forEach((key, value) {
        features[key] = FeatureContribution.fromJson(value);
      });
    }

    List<PersonalizedRecommendation> recs = [];
    if (json['recommendations'] != null) {
      recs = (json['recommendations'] as List)
          .map((rec) => PersonalizedRecommendation.fromJson(rec))
          .toList();
    }
    
    return ShapExplanation(
      applicationId: json['application_id'],
      topFeatures: features,
      baseValue: json['base_value'].toDouble(),
      predictionValue: json['prediction_value'].toDouble(),
      totalShapContribution: json['total_shap_contribution'].toDouble(),
      readableExplanation: List<String>.from(json['readable_explanation'] ?? []),
      recommendations: recs,
    );
  }

  List<MapEntry<String, FeatureContribution>> get sortedFeatures {
    return topFeatures.entries.toList()
      ..sort((a, b) => b.value.absShapValue.compareTo(a.value.absShapValue));
  }
}
