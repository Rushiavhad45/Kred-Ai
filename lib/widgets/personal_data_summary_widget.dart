// flutter_app/lib/widgets/personal_data_summary_widget.dart
import 'package:flutter/material.dart';
import '../models/enhanced_application_model.dart';
import '../utils/constants.dart';

class PersonalDataSummaryWidget extends StatelessWidget {
  final EnhancedApplicationModel enhancedApplication;
  final bool isSmallScreen;

  const PersonalDataSummaryWidget({
    super.key,
    required this.enhancedApplication,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final userProfile = enhancedApplication.userProfile;
    final applicationData = enhancedApplication.applicationData;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: isSmallScreen ? 24 : 30,
                  backgroundColor: const Color(AppConstants.primaryColorValue),
                  child: Text(
                    userProfile.fullName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile.fullName,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Application ID: ${enhancedApplication.applicationId}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.successColorValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(AppConstants.successColorValue).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 14,
                        color: const Color(AppConstants.successColorValue),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: const Color(AppConstants.successColorValue),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Personal Info Grid
            if (isSmallScreen) 
              _buildVerticalLayout()
            else 
              _buildHorizontalLayout(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        _buildInfoSection('Personal Information', [
          _buildInfoItem(Icons.person, 'Age', '${enhancedApplication.userProfile.age} years'),
          _buildInfoItem(Icons.phone, 'Phone', enhancedApplication.userProfile.phoneNumber),
          _buildInfoItem(Icons.email, 'Email', enhancedApplication.userProfile.emailAddress),
        ]),
        const SizedBox(height: 16),
        _buildInfoSection('Address', [
          _buildInfoItem(Icons.home, 'City', '${enhancedApplication.userProfile.city}, ${enhancedApplication.userProfile.state}'),
          _buildInfoItem(Icons.mail, 'PIN Code', enhancedApplication.userProfile.postalCode),
        ]),
        const SizedBox(height: 16),
        _buildInfoSection('Financial Details', [
          _buildInfoItem(Icons.currency_rupee, 'Income', '₹${enhancedApplication.applicationData.personIncome.toStringAsFixed(0)}'),
          _buildInfoItem(Icons.account_balance_wallet, 'Loan Amount', '₹${enhancedApplication.applicationData.loanAmnt.toStringAsFixed(0)}'),
        ]),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInfoSection('Personal Information', [
            _buildInfoItem(Icons.person, 'Age', '${enhancedApplication.userProfile.age} years'),
            _buildInfoItem(Icons.phone, 'Phone', enhancedApplication.userProfile.phoneNumber),
            _buildInfoItem(Icons.email, 'Email', enhancedApplication.userProfile.emailAddress),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoSection('Address', [
            _buildInfoItem(Icons.home, 'City', '${enhancedApplication.userProfile.city}, ${enhancedApplication.userProfile.state}'),
            _buildInfoItem(Icons.mail, 'PIN Code', enhancedApplication.userProfile.postalCode),
            if (enhancedApplication.userProfile.occupation != null)
              _buildInfoItem(Icons.work, 'Occupation', enhancedApplication.userProfile.occupation!),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoSection('Financial Details', [
            _buildInfoItem(Icons.currency_rupee, 'Income', '₹${enhancedApplication.applicationData.personIncome.toStringAsFixed(0)}'),
            _buildInfoItem(Icons.account_balance_wallet, 'Loan Amount', '₹${enhancedApplication.applicationData.loanAmnt.toStringAsFixed(0)}'),
            _buildInfoItem(Icons.work_history, 'Experience', '${enhancedApplication.applicationData.personEmpLength} years'),
          ]),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.primaryColorValue),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 14 : 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
