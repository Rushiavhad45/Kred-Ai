// flutter_app/lib/models/application_model.dart
class ApplicationModel {
  // Personal Information
  final double personIncome;
  final double personEmpLength;
  final int age;
  
  // Loan Information
  final double loanAmnt;
  final double loanIntRate;
  final String? loanIntent;
  
  // Credit History
  final double cbPersonCredHistLength;
  final int cbPersonDefaultOnFile;
  
  // Alternative Data
  final double? estimatedMonthlyIncome;
  final double monthlyAirtimeSpend;
  final double monthlyDataUsageGb;
  final double avgCallsPerDay;
  final double avgSmsPerDay;
  final int digitalWalletUsage;
  final double monthlyDigitalTransactions;
  final double avgTransactionAmount;
  final double socialMediaActivityScore;
  final int mobileBankingUser;
  final double digitalEngagementScore;
  final double financialInclusionScore;
  
  // Utility Bills
  final double electricityBillAvg;
  final double waterBillAvg;
  final double gasBillAvg;
  final double totalUtilityExpense;
  final double utilityToIncomeRatio;
  final int onTimePayments12m;
  final int latePayments12m;
  
  final double? creditRiskScore;

  ApplicationModel({
    required this.personIncome,
    required this.personEmpLength,
    required this.age,
    required this.loanAmnt,
    required this.loanIntRate,
    this.loanIntent,
    required this.cbPersonCredHistLength,
    this.cbPersonDefaultOnFile = 0,
    this.estimatedMonthlyIncome,
    this.monthlyAirtimeSpend = 0,
    this.monthlyDataUsageGb = 0,
    this.avgCallsPerDay = 0,
    this.avgSmsPerDay = 0,
    this.digitalWalletUsage = 0,
    this.monthlyDigitalTransactions = 0,
    this.avgTransactionAmount = 0,
    this.socialMediaActivityScore = 0,
    this.mobileBankingUser = 0,
    this.digitalEngagementScore = 0,
    this.financialInclusionScore = 0,
    this.electricityBillAvg = 0,
    this.waterBillAvg = 0,
    this.gasBillAvg = 0,
    this.totalUtilityExpense = 0,
    this.utilityToIncomeRatio = 0,
    this.onTimePayments12m = 0,
    this.latePayments12m = 0,
    this.creditRiskScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'person_income': personIncome,
      'person_emp_length': personEmpLength,
      'age': age,
      'loan_amnt': loanAmnt,
      'loan_int_rate': loanIntRate,
      'loan_intent': loanIntent,
      'cb_person_cred_hist_length': cbPersonCredHistLength,
      'cb_person_default_on_file': cbPersonDefaultOnFile,
      'estimated_monthly_income': estimatedMonthlyIncome,
      'monthly_airtime_spend': monthlyAirtimeSpend,
      'monthly_data_usage_gb': monthlyDataUsageGb,
      'avg_calls_per_day': avgCallsPerDay,
      'avg_sms_per_day': avgSmsPerDay,
      'digital_wallet_usage': digitalWalletUsage,
      'monthly_digital_transactions': monthlyDigitalTransactions,
      'avg_transaction_amount': avgTransactionAmount,
      'social_media_activity_score': socialMediaActivityScore,
      'mobile_banking_user': mobileBankingUser,
      'digital_engagement_score': digitalEngagementScore,
      'financial_inclusion_score': financialInclusionScore,
      'electricity_bill_avg': electricityBillAvg,
      'water_bill_avg': waterBillAvg,
      'gas_bill_avg': gasBillAvg,
      'total_utility_expense': totalUtilityExpense,
      'utility_to_income_ratio': utilityToIncomeRatio,
      'on_time_payments_12m': onTimePayments12m,
      'late_payments_12m': latePayments12m,
      'credit_risk_score': creditRiskScore,
    };
  }
}
