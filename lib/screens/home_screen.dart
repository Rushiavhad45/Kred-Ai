// flutter_app/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import 'user_profile_form_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.longAnimationDuration,
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isSmallScreen = width < 600;
    final padding = width * 0.06;

    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColorValue),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: isSmallScreen ? 20 : 40,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: isSmallScreen ? height * 0.05 : height * 0.08),
                    
                    // App Logo and Title
                    _buildHeader(width, isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? height * 0.06 : height * 0.08),
                    
                    // Feature Cards
                    _buildFeatureCards(width, isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? height * 0.08 : height * 0.10),
                    
                    // Action Buttons
                    _buildActionButtons(context, authState, width, isSmallScreen),
                    
                    SizedBox(height: height * 0.05),
                    
                    // Footer Information
                    _buildFooter(width, isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double width, bool isSmallScreen) {
    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: AppConstants.longAnimationDuration,
      child: SlideAnimation(
        verticalOffset: 50,
        child: FadeInAnimation(
          child: Column(
            children: [
              // App Logo
              Container(
                width: isSmallScreen ? width * 0.25 : width * 0.2,
                height: isSmallScreen ? width * 0.25 : width * 0.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(AppConstants.primaryColorValue),
                      const Color(AppConstants.primaryLightColorValue),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(AppConstants.primaryColorValue).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance,
                  size: isSmallScreen ? width * 0.12 : width * 0.1,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 20 : 24),
              
              // App Title
              Text(
                'KredAI',
                style: TextStyle(
                  fontSize: isSmallScreen ? width * 0.08 : width * 0.07,
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConstants.primaryColorValue),
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 8 : 12),
              
              // Subtitle
              Text(
                'AI-Powered Credit Assessment',
                style: TextStyle(
                  fontSize: isSmallScreen ? width * 0.04 : width * 0.035,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: isSmallScreen ? 4 : 8),
              
              Text(
                'For the Underbanked Population',
                style: TextStyle(
                  fontSize: isSmallScreen ? width * 0.035 : width * 0.03,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCards(double width, bool isSmallScreen) {
    final features = [
      {
        'icon': Icons.psychology,
        'title': 'AI Analysis',
        'description': 'Advanced ML algorithms for accurate risk assessment',
        'color': const Color(AppConstants.primaryColorValue),
      },
      {
        'icon': Icons.security,
        'title': 'Secure & Private',
        'description': 'Bank-grade security with data protection compliance',
        'color': const Color(AppConstants.successColorValue),
      },
      {
        'icon': Icons.insights,
        'title': 'Explainable AI',
        'description': 'Transparent decision-making with SHAP explanations',
        'color': const Color(AppConstants.infoColorValue),
      },
    ];

    return AnimationLimiter(
      child: Column(
        children: features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: AppConstants.longAnimationDuration,
            child: SlideAnimation(
              verticalOffset: 30,
              child: FadeInAnimation(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: (feature['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          feature['icon'] as IconData,
                          size: isSmallScreen ? width * 0.06 : width * 0.05,
                          color: feature['color'] as Color,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 16 : 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature['title'] as String,
                              style: TextStyle(
                                fontSize: isSmallScreen ? width * 0.04 : width * 0.035,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              feature['description'] as String,
                              style: TextStyle(
                                fontSize: isSmallScreen ? width * 0.035 : width * 0.03,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AuthState authState, double width, bool isSmallScreen) {
    return AnimationConfiguration.staggeredList(
      position: 3,
      duration: AppConstants.longAnimationDuration,
      child: SlideAnimation(
        verticalOffset: 30,
        child: FadeInAnimation(
          child: Column(
            children: [
              // Primary Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (authState.isAuthenticated) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfileFormScreen(),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.rocket_launch,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  label: Text(
                    'Start Credit Assessment',
                    style: TextStyle(
                      fontSize: isSmallScreen ? width * 0.04 : width * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColorValue),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 16 : 20,
                      horizontal: isSmallScreen ? 24 : 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 16 : 20),
              
              // Secondary Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.dashboard,
                    size: isSmallScreen ? 18 : 20,
                  ),
                  label: Text(
                    'Go to Dashboard',
                    style: TextStyle(
                      fontSize: isSmallScreen ? width * 0.04 : width * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(AppConstants.primaryColorValue),
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 16 : 20,
                      horizontal: isSmallScreen ? 24 : 32,
                    ),
                    side: const BorderSide(
                      color: Color(AppConstants.primaryColorValue),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(double width, bool isSmallScreen) {
    return AnimationConfiguration.staggeredList(
      position: 4,
      duration: AppConstants.longAnimationDuration,
      child: SlideAnimation(
        verticalOffset: 30,
        child: FadeInAnimation(
          child: Column(
            children: [
              Divider(
                color: Colors.grey[300],
                thickness: 1,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user,
                    size: isSmallScreen ? 16 : 18,
                    color: const Color(AppConstants.successColorValue),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Secure • Private • Compliant',
                    style: TextStyle(
                      fontSize: isSmallScreen ? width * 0.03 : width * 0.025,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isSmallScreen ? 8 : 12),
              
              Text(
                '© 2025 KredAI. Empowering financial inclusion through AI.',
                style: TextStyle(
                  fontSize: isSmallScreen ? width * 0.025 : width * 0.022,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: isSmallScreen ? 4 : 8),
              
              Text(
                'Version ${AppConstants.appVersion}',
                style: TextStyle(
                  fontSize: isSmallScreen ? width * 0.025 : width * 0.022,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
