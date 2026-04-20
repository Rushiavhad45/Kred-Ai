// flutter_app/lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_card_widget.dart';
import '../widgets/analytics_chart_widget.dart';
import '../utils/constants.dart';
import '../models/dashboard_model.dart';
import 'package:kredai/widgets/app_drawer.dart';
import 'user_profile_form_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.mediumAnimationDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
    final dashboardState = ref.watch(dashboardProvider);   
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isSmallScreen = width < 600;
    final padding = width * 0.04;
    final spacing = height * 0.02;

    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColorValue),
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardProvider.notifier).refreshData(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: dashboardState.isLoading
                    ? _buildLoadingState(width, spacing, isSmallScreen)
                    : dashboardState.error != null
                        ? _buildErrorState(dashboardState.error!, width, spacing, isSmallScreen)
                        : _buildDashboardContent(
                            dashboardState, width, height, spacing, isSmallScreen),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileFormScreen()),
        ),
        backgroundColor: const Color(AppConstants.secondaryColorValue),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isSmallScreen ? 'New' : 'New Assessment',
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(double width, double spacing, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: spacing * 3),
          const CircularProgressIndicator(),
          SizedBox(height: spacing),
          Text(
            'Loading dashboard data...',
            style: TextStyle(
              fontSize: isSmallScreen ? width * 0.04 : width * 0.045,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, double width, double spacing, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: spacing * 2),
          Icon(
            Icons.error_outline,
            size: isSmallScreen ? 48 : 64,
            color: const Color(AppConstants.dangerColorValue),
          ),
          SizedBox(height: spacing),
          Text(
            'Error loading data',
            style: TextStyle(
              fontSize: isSmallScreen ? width * 0.045 : width * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: spacing * 0.5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.1),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? width * 0.035 : width * 0.04, 
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: spacing * 1.5),
          ElevatedButton.icon(
            onPressed: () => ref.read(dashboardProvider.notifier).refreshData(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 32,
                vertical: isSmallScreen ? 12 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    DashboardState state, double width, double height, double spacing, bool isSmallScreen) {
    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(width, spacing, isSmallScreen),
          SizedBox(height: spacing * 1.5),
          if (state.stats != null) ...[
            _buildQuickStats(state.stats!, width, spacing, isSmallScreen),
            SizedBox(height: spacing * 1.5),
          ],
          _buildQuickActions(width, spacing, isSmallScreen),
          SizedBox(height: spacing * 1.5),
          if (state.applicationTrends.isNotEmpty) ...[
            ApplicationTrendsChart(data: state.applicationTrends),
            SizedBox(height: spacing),
          ],
          if (state.riskDistribution.isNotEmpty) ...[
            RiskDistributionChart(data: state.riskDistribution),
            SizedBox(height: spacing),
          ],
          SizedBox(height: height * 0.12), // Extra spacing for FAB
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(double width, double spacing, bool isSmallScreen) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay;
    }

    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: AppConstants.mediumAnimationDuration,
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          child: Card(
            elevation: isSmallScreen ? 4 : 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? width * 0.04 : width * 0.05),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(AppConstants.primaryColorValue).withOpacity(0.1),
                    const Color(AppConstants.primaryLightColorValue).withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  greetingIcon,
                                  size: isSmallScreen ? 20 : 24,
                                  color: const Color(AppConstants.primaryColorValue),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  greeting,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? width * 0.045 : width * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(AppConstants.primaryColorValue),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing * 0.3),
                            Text(
                              'Welcome to KredAI',
                              style: TextStyle(
                                fontSize: isSmallScreen ? width * 0.04 : width * 0.045,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: spacing * 0.2),
                            Text(
                              'AI-powered Credit Assessment System',
                              style: TextStyle(
                                fontSize: isSmallScreen ? width * 0.035 : width * 0.04,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? width * 0.03 : width * 0.035),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: isSmallScreen ? width * 0.07 : width * 0.08,
                          color: const Color(AppConstants.primaryColorValue),
                        ),
                      ),
                    ],
                  ),
                  if (!isSmallScreen) ...[
                    SizedBox(height: spacing * 0.5),
                    Divider(color: Colors.grey[300]),
                    SizedBox(height: spacing * 0.3),
                  ] else 
                    SizedBox(height: spacing * 0.4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: isSmallScreen ? width * 0.032 : width * 0.035,
                          color: Colors.grey[500],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.successColorValue).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Online',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: const Color(AppConstants.successColorValue),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(DashboardStats stats, double width, double spacing, bool isSmallScreen) {
    final crossAxisCount = isSmallScreen ? 2 : 4;
    final childAspectRatio = isSmallScreen ? 1.1 : 1.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Statistics',
          style: TextStyle(
            fontSize: isSmallScreen ? width * 0.04 : width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: spacing * 0.7),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing * 0.7,
          crossAxisSpacing: spacing * 0.7,
          childAspectRatio: childAspectRatio,
          children: [
            AnimationConfiguration.staggeredGrid(
              position: 0,
              duration: AppConstants.mediumAnimationDuration,
              columnCount: crossAxisCount,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: DashboardCard(
                    title: 'Total Applications',
                    value: NumberFormat('#,##0').format(stats.totalApplications),
                    subtitle: 'All time',
                    icon: Icons.assignment,
                    color: const Color(AppConstants.primaryColorValue),
                    animationIndex: 0,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ),
            ),
            AnimationConfiguration.staggeredGrid(
              position: 1,
              duration: AppConstants.mediumAnimationDuration,
              columnCount: crossAxisCount,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: DashboardCard(
                    title: 'Approved',
                    value: NumberFormat('#,##0').format(stats.approvedApplications),
                    subtitle: '${(stats.approvalRate * 100).toStringAsFixed(1)}% rate',
                    icon: Icons.check_circle,
                    color: const Color(AppConstants.successColorValue),
                    animationIndex: 1,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ),
            ),
            AnimationConfiguration.staggeredGrid(
              position: 2,
              duration: AppConstants.mediumAnimationDuration,
              columnCount: crossAxisCount,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: DashboardCard(
                    title: 'Pending',
                    value: NumberFormat('#,##0').format(stats.pendingApplications),
                    subtitle: 'Under review',
                    icon: Icons.hourglass_empty,
                    color: const Color(AppConstants.warningColorValue),
                    animationIndex: 2,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ),
            ),
            AnimationConfiguration.staggeredGrid(
              position: 3,
              duration: AppConstants.mediumAnimationDuration,
              columnCount: crossAxisCount,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: DashboardCard(
                    title: isSmallScreen ? 'Disbursed' : 'Total Disbursed',
                    value: '₹${NumberFormat('#,##,##0').format(stats.totalDisbursed ~/ 100000)}L',
                    subtitle: 'Approved amount',
                    icon: Icons.account_balance_wallet,
                    color: const Color(AppConstants.secondaryColorValue),
                    animationIndex: 3,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(double width, double spacing, bool isSmallScreen) {
    final crossAxisCount = isSmallScreen ? 2 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isSmallScreen ? width * 0.04 : width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: spacing * 0.7),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing * 0.7,
          crossAxisSpacing: spacing * 0.7,
          childAspectRatio: isSmallScreen ? 1.0 : 1.1,
          children: [
            AnimationConfiguration.staggeredGrid(
              position: 0,
              duration: AppConstants.mediumAnimationDuration,
              columnCount: crossAxisCount,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: QuickActionCard(
                    title: isSmallScreen ? 'New Assessment' : 'New Application',
                    icon: Icons.add_circle_outline,
                    color: const Color(AppConstants.primaryColorValue),
                    animationIndex: 0,
                    isSmallScreen: isSmallScreen,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UserProfileFormScreen()),
                    ),
                  ),
                ),
              ),
            ),
            AnimationConfiguration.staggeredGrid(
              position: 1,
              duration: AppConstants.mediumAnimationDuration,
              columnCount: crossAxisCount,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: QuickActionCard(
                    title: isSmallScreen ? 'Search' : 'Search Applications',
                    icon: Icons.search,
                    color: const Color(AppConstants.infoColorValue),
                    animationIndex: 1,
                    isSmallScreen: isSmallScreen,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search feature coming soon!')),
                      );
                    },
                  ),
                ),
              ),
            ),
            AnimationConfiguration.staggeredGrid(
              position: 2,
              duration: AppConstants.mediumAnimationDuration,
              columnCount: crossAxisCount,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: QuickActionCard(
                    title: 'Reports',
                    icon: Icons.bar_chart,
                    color: const Color(AppConstants.successColorValue),
                    animationIndex: 2,
                    isSmallScreen: isSmallScreen,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reports feature coming soon!')),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (!isSmallScreen) // Show additional actions on larger screens
              AnimationConfiguration.staggeredGrid(
                position: 3,
                duration: AppConstants.mediumAnimationDuration,
                columnCount: crossAxisCount,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: QuickActionCard(
                      title: 'Analytics',
                      icon: Icons.analytics,
                      color: const Color(AppConstants.warningColorValue),
                      animationIndex: 3,
                      isSmallScreen: isSmallScreen,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Analytics feature coming soon!')),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Enhanced Dashboard Card Widget with responsiveness
class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int animationIndex;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.animationIndex,
    required this.onTap,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Card(
      elevation: isSmallScreen ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.05,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? screenWidth * 0.03 : screenWidth * 0.032,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
