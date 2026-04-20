// flutter_app/lib/models/dashboard_model.dart
class DashboardStats {
  final int totalApplications;
  final int approvedApplications;
  final int pendingApplications;
  final int rejectedApplications;
  final double approvalRate;
  final double avgProcessingTime;
  final double avgLoanAmount;
  final double totalDisbursed;
  
  DashboardStats({
    required this.totalApplications,
    required this.approvedApplications,
    required this.pendingApplications,
    required this.rejectedApplications,
    required this.approvalRate,
    required this.avgProcessingTime,
    required this.avgLoanAmount,
    required this.totalDisbursed,
  });
  
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalApplications: json['total_applications'] ?? 0,
      approvedApplications: json['approved_applications'] ?? 0,
      pendingApplications: json['pending_applications'] ?? 0,
      rejectedApplications: json['rejected_applications'] ?? 0,
      approvalRate: (json['approval_rate'] ?? 0.0).toDouble(),
      avgProcessingTime: (json['avg_processing_time'] ?? 0.0).toDouble(),
      avgLoanAmount: (json['avg_loan_amount'] ?? 0.0).toDouble(),
      totalDisbursed: (json['total_disbursed'] ?? 0.0).toDouble(),
    );
  }
}

class ChartDataPoint {
  final DateTime date;
  final double value;
  final String? label;
  
  ChartDataPoint({
    required this.date,
    required this.value,
    this.label,
  });
}

// If you still need ChartData for other purposes (keep both)
class ChartData {
  final String label;
  final double value;
  
  ChartData(this.label, this.value);
}
