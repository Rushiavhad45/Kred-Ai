// flutter_app/lib/screens/application_form_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/application_model.dart';
import '../models/user_profile_model.dart';
import '../models/enhanced_application_model.dart';
import '../providers/enhanced_application_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
// import '../widgets/enhanced_application_form_widget.dart';
import 'package:kredai/widgets/application_form_widget.dart';
import 'enhanced_results_screen.dart';

class ApplicationFormScreen extends ConsumerStatefulWidget {
  final UserProfileModel userProfile;

  const ApplicationFormScreen({
    super.key,
    required this.userProfile,
  });

  @override
  ConsumerState<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends ConsumerState<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    
    if (!available) {
      print('Speech to text not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationState = ref.watch(enhancedApplicationProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final padding = screenWidth * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showExitConfirmation(),
        ),
        actions: [
          // Language Switcher
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: 'Change Language',
            onSelected: (locale) async {
              await context.setLocale(locale);
              _initializeSpeech();
              setState(() {});
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: const Locale('en'),
                child: Row(
                  children: [
                    const Text('🇺🇸'),
                    const SizedBox(width: 8),
                    const Text('English'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('hi'),
                child: Row(
                  children: [
                    const Text('🇮🇳'),
                    const SizedBox(width: 8),
                    const Text('हिन्दी'),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 16),
                SizedBox(width: 4),
                Text(
                  widget.userProfile.fullName.split(' ').first,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // User Profile Summary Banner
          _buildUserSummaryBanner(isSmallScreen, padding),
          
          // Application Form
          Expanded(
            child: EnhancedApplicationFormWidget(
              formKey: _formKey,
              userProfile: widget.userProfile,
              onVoiceInput: _startListening,
              isListening: _isListening,
              isSmallScreen: isSmallScreen,
              onSubmit: _submitApplication,
            ),
          ),
          
          // Loading Indicator
          if (applicationState.isLoading)
            Container(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  const LinearProgressIndicator(),
                  SizedBox(height: padding * 0.5),
                  Text(
                    'Processing your application...',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: const Color(AppConstants.primaryColorValue),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserSummaryBanner(bool isSmallScreen, double padding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryColorValue).withOpacity(0.1),
            const Color(AppConstants.primaryLightColorValue).withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(AppConstants.primaryColorValue).withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 24 : 30,
            backgroundColor: const Color(AppConstants.primaryColorValue),
            child: Text(
              widget.userProfile.fullName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userProfile.fullName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'age'.tr() + ': ${widget.userProfile.age} years • ${widget.userProfile.city}, ${widget.userProfile.state}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  widget.userProfile.phoneNumber,
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
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(AppConstants.successColorValue),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _localeIdForSpeech() {
    final code = context.locale.languageCode;
    switch (code) {
      case 'hi':
        return 'hi_IN';
      case 'bn':
        return 'bn_IN';
      case 'ta':
        return 'ta_IN';
      case 'te':
        return 'te_IN';
      case 'mr':
        return 'mr_IN';
      case 'en':
      default:
        return 'en_US';
    }
  }

  void _startListening() async {
    if (!_isListening && _speech.isAvailable) {
      setState(() => _isListening = true);
      
      await _speech.listen(
        localeId: _localeIdForSpeech(),
        onResult: (result) {
          setState(() {
            if (result.finalResult) {
              _isListening = false;
            }
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
      );
    }
  }

  void _submitApplication(ApplicationModel applicationData) async {
    if (_formKey.currentState!.validate()) {
      // Check authentication first
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Authenticating..."),
              ],
            ),
          ),
        );
        
        try {
          await FirebaseAuth.instance.signInAnonymously();
          Navigator.pop(context); // Close loading dialog
        } catch (e) {
          Navigator.pop(context); // Close loading dialog
          _showErrorDialog('Authentication failed: $e');
          return;
        }
      }

      final enhancedApplication = EnhancedApplicationModel.create(
        userProfile: widget.userProfile,
        applicationData: applicationData,
      );

      await ref.read(enhancedApplicationProvider.notifier)
          .submitEnhancedApplication(enhancedApplication);

      final state = ref.read(enhancedApplicationProvider);
      
      if (state.error == null && state.enhancedApplication != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EnhancedResultsScreen(),
          ),
        );
      } else {
        _showErrorDialog(state.error ?? 'error_message'.tr());
      }
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Application?'),
        content: Text(
          'Your progress will be lost. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit form
            },
            child: Text(
              'Exit',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Application Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
