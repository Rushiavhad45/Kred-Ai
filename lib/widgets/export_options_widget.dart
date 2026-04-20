// flutter_app/lib/widgets/export_options_widget.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ExportOptionsWidget extends StatelessWidget {
  final VoidCallback onExportPdf;
  final VoidCallback onExportImage;
  final VoidCallback onShare;

  const ExportOptionsWidget({
    super.key,
    required this.onExportPdf,
    required this.onExportImage,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Text(
            'Export & Share Options',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          _buildExportOption(
            icon: Icons.picture_as_pdf,
            title: 'Download PDF Report',
            subtitle: 'Complete assessment report with all details',
            color: const Color(AppConstants.dangerColorValue),
            onTap: onExportPdf,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildExportOption(
            icon: Icons.image,
            title: 'Export as Image',
            subtitle: 'Quick screenshot of assessment results',
            color: const Color(AppConstants.infoColorValue),
            onTap: onExportImage,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildExportOption(
            icon: Icons.share,
            title: 'Share Summary',
            subtitle: 'Share basic results via text message',
            color: const Color(AppConstants.successColorValue),
            onTap: onShare,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: isSmallScreen ? 24 : 28,
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
