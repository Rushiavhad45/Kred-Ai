// flutter_app/lib/utils/constants.dart
class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://192.168.0.102:8000';
  // Change for production
  static const String apiVersion = 'v1';
  
  // API Endpoints
  static const String usersEndpoint = '/users/';
  static const String applicationsEndpoint = '/applications/';
  static const String explainEndpoint = '/explain/';
  static const String healthEndpoint = '/health';
  static const String analyticsEndpoint = '/analytics';  // NEW
  
  // App Configuration
  static const String appName = 'Credit Risk Assessment';
  static const String appVersion = '1.0.0';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;   // NEW
  static const double largePadding = 24.0;  // NEW
  static const double defaultRadius = 12.0; // UPDATED
  static const double cardRadius = 16.0;    // NEW
  static const double buttonRadius = 8.0;   // NEW
  
  // Colors - Modern Banking Theme
  static const int primaryColorValue = 0xFF1565C0;       // Deep Blue
  static const int primaryLightColorValue = 0xFF42A5F5;  // Light Blue
  static const int primaryDarkColorValue = 0xFF0D47A1;   // Dark Blue
  static const int secondaryColorValue = 0xFFFF7043;     // Orange
  static const int accentColorValue = 0xFF4CAF50;        // Green
  
  static const int successColorValue = 0xFF4CAF50;
  static const int dangerColorValue = 0xFFF44336;
  static const int warningColorValue = 0xFFFF9800;
  static const int infoColorValue = 0xFF2196F3;
  
  // NEW: Surface colors
  static const int surfaceColorValue = 0xFFFAFAFA;
  static const int cardColorValue = 0xFFFFFFFF;
  static const int backgroundColorValue = 0xFFF5F5F5;
  
  // Risk Thresholds
  static const double lowRiskThreshold = 0.3;
  static const double mediumRiskThreshold = 0.7;
  
  // Form Validation
  static const int minAge = 18;
  static const int maxAge = 100;
  static const double minIncome = 1000.0;
  static const double maxLoanAmount = 1000000.0;
  
  // NEW: Dashboard Constants
  static const int maxRecentApplications = 10;
  static const int chartDataPoints = 30;
  
  // NEW: Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
}
