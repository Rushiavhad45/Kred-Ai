// flutter_app/lib/screens/user_profile_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/user_profile_model.dart';
import '../utils/constants.dart';
import '../utils/data_validator.dart';
import 'application_form_screen.dart';

class UserProfileFormScreen extends ConsumerStatefulWidget {
  const UserProfileFormScreen({super.key});

  @override
  ConsumerState<UserProfileFormScreen> createState() =>
      _UserProfileFormScreenState();
}

class _UserProfileFormScreenState
    extends ConsumerState<UserProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Form Controllers
  final _personalControllers = {
    'fullName': TextEditingController(),
    'phoneNumber': TextEditingController(),
    'emailAddress': TextEditingController(),
    'panNumber': TextEditingController(),
    'aadharNumber': TextEditingController(),
    'occupation': TextEditingController(),
    'employerName': TextEditingController(),
  };

  final _addressControllers = {
    'streetAddress': TextEditingController(),
    'city': TextEditingController(),
    'state': TextEditingController(),
    'postalCode': TextEditingController(),
    'workAddress': TextEditingController(),
  };

  DateTime? _selectedDateOfBirth;
  bool _consentDataProcessing = false;
  bool _consentCreditCheck = false;

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Puducherry', 'Chandigarh', 'Dadra and Nagar Haveli', 'Daman and Diu',
    'Lakshadweep', 'Ladakh', 'Jammu and Kashmir'
  ];

  @override
  void dispose() {
    _personalControllers.values.forEach((controller) => controller.dispose());
    _addressControllers.values.forEach((controller) => controller.dispose());
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Metrics
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

    final padding = screenWidth * 0.04;
    final fontScale = screenWidth / 400; // Scales font size proportionally

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Personal Information',
          style: TextStyle(fontSize: 18 * fontScale),
        ),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        actions: [
          // Language Switcher
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: 'Change Language',
            onSelected: (locale) async {
              await context.setLocale(locale);
              setState(() {});
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: const Locale('en'),
                child: Row(
                  children: [
                    const Text('🇺🇸'),
                    const SizedBox(width: 8),
                    Text('English', style: TextStyle(fontSize: 14 * fontScale)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: const Locale('hi'),
                child: Row(
                  children: [
                    const Text('🇮🇳'),
                    const SizedBox(width: 8),
                    Text('हिन्दी', style: TextStyle(fontSize: 14 * fontScale)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isSmallScreen ? 80 : 90),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStepIcon(0, Icons.person, 'Personal', fontScale),
                    _buildStepIcon(1, Icons.home, 'Address', fontScale),
                    _buildStepIcon(2, Icons.verified_user, 'Consent', fontScale),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4.0),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / 3,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Form(
            key: _formKey,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildPersonalInfoPage(isSmallScreen, padding, fontScale),
                _buildAddressInfoPage(isSmallScreen, padding, fontScale),
                _buildConsentPage(isSmallScreen, padding, fontScale),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text('previous'.tr(), style: TextStyle(fontSize: 14 * fontScale)),
                ),
              ),
            if (_currentPage > 0) SizedBox(width: padding),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_currentPage < 2) {
                    if (_validateCurrentPage()) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  } else {
                    _submitUserProfile();
                  }
                },
                icon: Icon(
                  _currentPage < 2 ? Icons.arrow_forward : Icons.check,
                  size: 20 * fontScale,
                ),
                label: Text(
                  _currentPage < 2 ? 'next'.tr() : 'Continue to Application',
                  style: TextStyle(fontSize: 14 * fontScale),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step Icon Builder
  Widget _buildStepIcon(int index, IconData icon, String label, double fontScale) {
    final isActive = _currentPage == index;
    return Column(
      children: [
        CircleAvatar(
          radius: 22 * fontScale,
          backgroundColor:
              isActive ? Colors.white : Colors.white.withOpacity(0.3),
          child: Icon(
            icon,
            color: isActive
                ? const Color(AppConstants.primaryColorValue)
                : Colors.white,
            size: 20 * fontScale,
          ),
        ),
        SizedBox(height: 6 * fontScale),
        Text(
          label,
          style: TextStyle(
            fontSize: 12 * fontScale,
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Personal Info Page
  Widget _buildPersonalInfoPage(bool isSmallScreen, double padding, double fontScale) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Basic Information', fontScale),
          SizedBox(height: padding),

          _buildTextField(
            controller: _personalControllers['fullName']!,
            label: 'Full Name *',
            icon: Icons.person,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Please enter your name'
                : null,
            fontScale: fontScale,
          ),
          SizedBox(height: padding * 0.7),

          _buildTextField(
            controller: _personalControllers['phoneNumber']!,
            label: 'Phone Number *',
            icon: Icons.phone,
            prefixText: '+91 ',
            keyboardType: TextInputType.phone,
            formatter: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10)
            ],
            validator: (v) => v == null || v.length != 10
                ? 'Please enter a valid 10-digit number'
                : null,
            fontScale: fontScale,
          ),
          SizedBox(height: padding * 0.7),

          _buildTextField(
            controller: _personalControllers['emailAddress']!,
            label: 'Email Address *',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter valid email' : null,
            fontScale: fontScale,
          ),
          SizedBox(height: padding * 0.7),

          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.now().subtract(const Duration(days: 365 * 25)),
                firstDate:
                    DateTime.now().subtract(const Duration(days: 365 * 100)),
                lastDate:
                    DateTime.now().subtract(const Duration(days: 365 * 18)),
              );
              if (date != null) {
                setState(() {
                  _selectedDateOfBirth = date;
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date of Birth *',
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedDateOfBirth != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!)
                    : 'Select your date of birth',
                style: TextStyle(
                  fontSize: 14 * fontScale,
                  color:
                      _selectedDateOfBirth != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
          SizedBox(height: padding),

          _buildSectionTitle('Additional Information', fontScale),
          SizedBox(height: padding * 0.7),

          _buildTextField(
            controller: _personalControllers['occupation']!,
            label: 'Occupation',
            icon: Icons.work,
            fontScale: fontScale,
          ),
          SizedBox(height: padding * 0.7),

          _buildTextField(
            controller: _personalControllers['employerName']!,
            label: 'Employer Name',
            icon: Icons.business,
            fontScale: fontScale,
          ),
        ],
      ),
    );
  }

  // Address Info Page
  Widget _buildAddressInfoPage(bool isSmallScreen, double padding, double fontScale) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Address Information', fontScale),
          SizedBox(height: padding),

          _buildTextField(
            controller: _addressControllers['streetAddress']!,
            label: 'Street Address *',
            icon: Icons.home,
            maxLines: 2,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your address' : null,
            fontScale: fontScale,
          ),
          SizedBox(height: padding * 0.7),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _addressControllers['city']!,
                  label: 'City *',
                  icon: Icons.location_city,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your city' : null,
                  fontScale: fontScale,
                ),
              ),
              SizedBox(width: padding * 0.5),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'State *',
                    prefixIcon: const Icon(Icons.map),
                  ),
                  items: _indianStates.map((state) {
                    return DropdownMenuItem(
                      value: state,
                      child: Text(state, style: TextStyle(fontSize: 14 * fontScale)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _addressControllers['state']!.text = value ?? '';
                  },
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Select your state' : null,
                ),
              ),
            ],
          ),
          SizedBox(height: padding * 0.7),

          _buildTextField(
            controller: _addressControllers['postalCode']!,
            label: 'Postal Code *',
            icon: Icons.local_post_office,
            keyboardType: TextInputType.number,
            formatter: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6)
            ],
            validator: (v) => v == null || v.length != 6
                ? 'Enter a valid 6-digit postal code'
                : null,
            fontScale: fontScale,
          ),
        ],
      ),
    );
  }

  // Consent Page
  Widget _buildConsentPage(bool isSmallScreen, double padding, double fontScale) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Consent & Privacy', fontScale),
          SizedBox(height: padding),

          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.privacy_tip, color: Colors.blue.shade700),
                      SizedBox(width: 8),
                      Text(
                        'Privacy Notice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * fontScale,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: padding * 0.5),
                  Text(
                    'We take your privacy seriously. Your information will be used solely for credit assessment purposes.',
                    style: TextStyle(fontSize: 13 * fontScale),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: padding),

          CheckboxListTile(
            value: _consentDataProcessing,
            onChanged: (value) {
              setState(() {
                _consentDataProcessing = value ?? false;
              });
            },
            title: Text('Data Processing Consent *',
                style: TextStyle(fontSize: 14 * fontScale)),
            subtitle: Text(
              'I consent to data processing for credit assessment.',
              style: TextStyle(fontSize: 12 * fontScale),
            ),
            activeColor: const Color(AppConstants.primaryColorValue),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _consentCreditCheck,
            onChanged: (value) {
              setState(() {
                _consentCreditCheck = value ?? false;
              });
            },
            title: Text('Credit Check Consent *',
                style: TextStyle(fontSize: 14 * fontScale)),
            subtitle: Text(
              'I authorize the credit assessment and understand this may affect my score.',
              style: TextStyle(fontSize: 12 * fontScale),
            ),
            activeColor: const Color(AppConstants.primaryColorValue),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatter,
    int maxLines = 1,
    String? Function(String?)? validator,
    required double fontScale,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20 * fontScale),
        prefixText: prefixText,
      ),
      keyboardType: keyboardType,
      inputFormatters: formatter,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(fontSize: 14 * fontScale),
    );
  }

  Widget _buildSectionTitle(String title, double fontScale) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20 * fontScale,
        fontWeight: FontWeight.bold,
        color: const Color(AppConstants.primaryColorValue),
      ),
    );
  }

  bool _validateCurrentPage() {
    if (_currentPage == 0) {
      return _personalControllers['fullName']!.text.trim().isNotEmpty &&
          _personalControllers['phoneNumber']!.text.trim().length == 10 &&
          _personalControllers['emailAddress']!.text.trim().contains('@') &&
          _selectedDateOfBirth != null;
    } else if (_currentPage == 1) {
      return _addressControllers['streetAddress']!.text.trim().isNotEmpty &&
          _addressControllers['city']!.text.trim().isNotEmpty &&
          _addressControllers['state']!.text.trim().isNotEmpty &&
          _addressControllers['postalCode']!.text.trim().length == 6;
    }
    return true;
  }

  void _submitUserProfile() {
    if (_formKey.currentState!.validate() &&
        _consentDataProcessing &&
        _consentCreditCheck) {
      final userProfile = UserProfileModel(
        fullName: _personalControllers['fullName']!.text.trim(),
        dateOfBirth: _selectedDateOfBirth!,
        phoneNumber: _personalControllers['phoneNumber']!.text.trim(),
        emailAddress: _personalControllers['emailAddress']!.text.trim(),
        streetAddress: _addressControllers['streetAddress']!.text.trim(),
        city: _addressControllers['city']!.text.trim(),
        state: _addressControllers['state']!.text.trim(),
        postalCode: _addressControllers['postalCode']!.text.trim(),
        occupation: _personalControllers['occupation']!.text.trim().isNotEmpty
            ? _personalControllers['occupation']!.text.trim()
            : null,
        employerName: _personalControllers['employerName']!.text.trim().isNotEmpty
            ? _personalControllers['employerName']!.text.trim()
            : null,
        consentForDataProcessing: _consentDataProcessing,
        consentForCreditCheck: _consentCreditCheck,
        consentTimestamp: DateTime.now(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ApplicationFormScreen(userProfile: userProfile),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields and provide consent'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
