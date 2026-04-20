// flutter_app/lib/providers/dashboard_provider.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kredai/providers/application_provider.dart';
import 'dart:math';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';

class DashboardState {
  final bool isLoading;
  final DashboardStats? stats;
  final List<ChartDataPoint> applicationTrends;
  final List<ChartDataPoint> riskDistribution;
  final String? error;

  DashboardState({
    this.isLoading = false,
    this.stats,
    this.applicationTrends = const [],
    this.riskDistribution = const [],
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardStats? stats,
    List<ChartDataPoint>? applicationTrends,
    List<ChartDataPoint>? riskDistribution,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      applicationTrends: applicationTrends ?? this.applicationTrends,
      riskDistribution: riskDistribution ?? this.riskDistribution,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiService _apiService;

  DashboardNotifier(this._apiService) : super(DashboardState()) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      final stats = _generateSampleStats();
      final trends = _generateApplicationTrends();
      final riskDist = _generateRiskDistribution();

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        applicationTrends: trends,
        riskDistribution: riskDist,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Add the missing refreshData method
  void refreshData() {
    loadDashboardData();
  }

  DashboardStats _generateSampleStats() {
    final random = Random();
    final total = 150 + random.nextInt(100);
    final approved = (total * (0.6 + random.nextDouble() * 0.2)).round();
    final rejected = (total * (0.2 + random.nextDouble() * 0.15)).round();
    final pending = total - approved - rejected;

    return DashboardStats(
      totalApplications: total,
      approvedApplications: approved,
      pendingApplications: pending,
      rejectedApplications: rejected,
      approvalRate: approved / total,
      avgProcessingTime: 2.5 + random.nextDouble() * 2,
      avgLoanAmount: 25000 + random.nextDouble() * 50000,
      totalDisbursed: approved * (30000 + random.nextDouble() * 40000),
    );
  }

  List<ChartDataPoint> _generateApplicationTrends() {
    final random = Random();
    final now = DateTime.now();
    final trends = <ChartDataPoint>[];
    
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final value = 5.0 + random.nextDouble() * 20;
      trends.add(ChartDataPoint(date: date, value: value));
    }
    
    return trends;
  }

  List<ChartDataPoint> _generateRiskDistribution() {
    return [
      ChartDataPoint(date: DateTime.now(), value: 45, label: 'Low Risk'),
      ChartDataPoint(date: DateTime.now(), value: 35, label: 'Medium Risk'),
      ChartDataPoint(date: DateTime.now(), value: 20, label: 'High Risk'),
    ];
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DashboardNotifier(apiService);
});
