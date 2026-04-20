// flutter_app/lib/widgets/enhanced_application_form_widget.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/application_model.dart';
import '../models/user_profile_model.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class EnhancedApplicationFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final UserProfileModel userProfile;
  final VoidCallback onVoiceInput;
  final bool isListening;
  final bool isSmallScreen;
  final Function(ApplicationModel) onSubmit;

  const EnhancedApplicationFormWidget({
    super.key,
    required this.formKey,
    required this.userProfile,
    required this.onVoiceInput,
    required this.isListening,
    required this.isSmallScreen,
    required this.onSubmit,
  });

  @override
  State<EnhancedApplicationFormWidget> createState() => _EnhancedApplicationFormWidgetState();
}

class _EnhancedApplicationFormWidgetState extends State<EnhancedApplicationFormWidget> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Speech to text
  stt.SpeechToText? _speech;
  bool _speechAvailable = false;
  bool _localListening = false;

  // Form controllers
  final _personalControllers = {
    'income': TextEditingController(),
    'empLength': TextEditingController(),
  };

  final _loanControllers = {
    'amount': TextEditingController(),
    'intRate': TextEditingController(),
    'purpose': TextEditingController(),
  };

  final _creditControllers = {
    'histLength': TextEditingController(),
    'defaultFile': TextEditingController(),
  };

  final _alternativeControllers = {
    'monthlyIncome': TextEditingController(),
    'airtimeSpend': TextEditingController(),
    'dataUsage': TextEditingController(),
    'callsPerDay': TextEditingController(),
    'smsPerDay': TextEditingController(),
    'digitalTransactions': TextEditingController(),
    'transactionAmount': TextEditingController(),
    'socialMediaScore': TextEditingController(),
    'digitalScore': TextEditingController(),
    'financialScore': TextEditingController(),
  };

  final _utilityControllers = {
    'electricBill': TextEditingController(),
    'waterBill': TextEditingController(),
    'gasBill': TextEditingController(),
    'onTimePayments': TextEditingController(),
    'latePayments': TextEditingController(),
  };

  // Dropdown values
  String? _selectedLoanIntent;
  int _digitalWalletUsage = 0;
  int _mobileBankingUser = 0;
  int _defaultOnFile = 0;

  final List<String> _loanIntents = [
    'personal',
    'education',
    'medical',
    'venture',
    'homeimprovement',
    'debtconsolidation',
  ];

  // Business rule: multiplier for max loan relative to declared annual income
  static const double _loanIncomeMultiplier = 5; // loan <= income * 5
  static const double _loanHardCap = 8000000; // ₹8,000,000 (80 lakh)

  // Flag to track if user manually edited monthly income
  bool _monthlyEdited = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeWithUserData();
    _setupIncomeListener();
  }

  void _initializeSpeech() async {
    _speech ??= stt.SpeechToText();
    try {
      _speechAvailable = await _speech!.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _localListening = false;
            });
          }
        },
        onError: (error) {
          setState(() {
            _localListening = false;
          });
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  void _initializeWithUserData() {
    // Pre-populate with user profile data where applicable
    _personalControllers['empLength']!.text = '0';
    // Age is auto-calculated from user profile
  }

  void _setupIncomeListener() {
    // Listen to annual income changes to auto-fill monthly income
    _personalControllers['income']!.addListener(() {
      final annualText = _personalControllers['income']!.text;
      final annual = double.tryParse(annualText.replaceAll(',', ''));
      if (!_monthlyEdited && annual != null) {
        final monthly = annual / 12;
        _alternativeControllers['monthlyIncome']!.text = monthly.toStringAsFixed(0);
        setState(() {});
      }
    });
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

  Future<void> _startListeningToController(TextEditingController controller) async {
    _speech ??= stt.SpeechToText();

    if (!_speechAvailable) {
      _initializeSpeech();
    }

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('speech_unavailable'.tr())),
      );
      return;
    }

    if (!_localListening) {
      setState(() => _localListening = true);
      try {
        await _speech!.listen(
          localeId: _localeIdForSpeech(),
          onResult: (result) {
            if (result.finalResult) {
              setState(() => _localListening = false);
              final recognized = result.recognizedWords;
              final numeric = _extractNumericFromSpeech(recognized);
              if (numeric.isNotEmpty) {
                controller.text = numeric;
              } else {
                controller.text = recognized;
              }
            } else {
              final recognized = result.recognizedWords;
              final numeric = _extractNumericFromSpeech(recognized);
              if (numeric.isNotEmpty) controller.text = numeric;
            }
          },
        );
      } catch (e) {
        setState(() {
          _localListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('speech_unavailable'.tr())),
        );
      }
    } else {
      try {
        await _speech!.stop();
      } catch (_) {}
      setState(() => _localListening = false);
    }
  }

  String _extractNumericFromSpeech(String s) {
    final digitsOnly = RegExp(r'[\d,.]+');
    final match = digitsOnly.firstMatch(s);
    if (match != null) {
      final raw = match.group(0) ?? '';
      return raw.replaceAll(',', '');
    }
    final fallback = s.replaceAll(RegExp(r'[^0-9]'), '');
    return fallback;
  }

  @override
  void dispose() {
    _personalControllers.values.forEach((c) => c.dispose());
    _loanControllers.values.forEach((c) => c.dispose());
    _creditControllers.values.forEach((c) => c.dispose());
    _alternativeControllers.values.forEach((c) => c.dispose());
    _utilityControllers.values.forEach((c) => c.dispose());
    _pageController.dispose();
    try {
      if (_speech != null) {
        _speech!.stop();
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).size.width * 0.04;

    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(padding),
          
          // Form Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildPersonalFinancePage(padding),
                _buildLoanDetailsPage(padding),
                _buildCreditHistoryPage(padding),
                _buildAlternativeDataPage(padding),
                _buildUtilityDataPage(padding),
              ],
            ),
          ),
          
          // Navigation Buttons
          _buildNavigationButtons(padding),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final isActive = _currentPage >= index;
              final icons = [
                Icons.person_outline,
                Icons.account_balance_wallet_outlined,
                Icons.credit_score_outlined,
                Icons.smartphone_outlined,
                Icons.home_outlined,
              ];
              final labels = [
                'step_personal'.tr(),
                'step_loan'.tr(),
                'Credit',
                'step_data'.tr(),
                'Utility',
              ];
              
              return InkWell(
                onTap: () {
                  _pageController.jumpToPage(index);
                  setState(() {
                    _currentPage = index;
                  });
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: widget.isSmallScreen ? 16 : 20,
                      backgroundColor: isActive
                          ? const Color(AppConstants.primaryColorValue)
                          : Colors.grey[300],
                      child: Icon(
                        icons[index],
                        size: widget.isSmallScreen ? 16 : 20,
                        color: isActive ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: widget.isSmallScreen ? 10 : 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? const Color(AppConstants.primaryColorValue)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: padding * 0.5),
          LinearProgressIndicator(
            value: (_currentPage + 1) / 5,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(AppConstants.primaryColorValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalFinancePage(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('personal_info'.tr()),
          SizedBox(height: padding),
          
          // Display user info
          Card(
            color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: const Color(AppConstants.primaryColorValue)),
                      SizedBox(width: 8),
                      Text(
                        'personal_info'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color(AppConstants.primaryColorValue),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: padding * 0.5),
                  _buildInfoRow('Name', widget.userProfile.fullName),
                  _buildInfoRow('age'.tr(), '${widget.userProfile.age} years'),
                  _buildInfoRow('Location', '${widget.userProfile.city}, ${widget.userProfile.state}'),
                ],
              ),
            ),
          ),
          
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'annual_income'.tr(),
            tooltipKey: 'tooltip_income',
            child: _buildSliderWithValue(
              label: 'annual_income'.tr(),
              min: 50000,
              max: 2000000,
              step: 5000,
              controller: _personalControllers['income']!,
              prefix: '₹',
              validator: _validateIncome,
            ),
          ),
          
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'employment_length'.tr(),
            tooltipKey: 'tooltip_emp_length',
            child: _buildSliderWithValue(
              label: 'employment_length'.tr(),
              min: 0,
              max: 40,
              step: 1,
              controller: _personalControllers['empLength']!,
              validator: _validateEmploymentLength,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetailsPage(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('loan_details'.tr()),
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'loan_amount'.tr(),
            tooltipKey: 'tooltip_loan_amount',
            child: _buildSliderWithValue(
              label: 'loan_amount'.tr(),
              min: 10000,
              max: _loanHardCap,
              step: 5000,
              controller: _loanControllers['amount']!,
              prefix: '₹',
              validator: _validateLoanAmount,
            ),
          ),
          
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'interest_rate'.tr(),
            tooltipKey: 'tooltip_interest',
            child: _buildSliderWithValue(
              label: 'interest_rate'.tr(),
              min: 5,
              max: 36,
              step: 0.5,
              controller: _loanControllers['intRate']!,
              suffix: '%',
              validator: Validators.validateInterestRate,
            ),
          ),
          
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'loan_purpose'.tr(),
            tooltipKey: 'loan_purpose_helper',
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'loan_purpose'.tr(),
                helperText: 'loan_purpose_helper'.tr(),
              ),
              items: _loanIntents
                  .map((intent) => DropdownMenuItem(
                        value: intent,
                        child: Text(intent
                            .replaceAll('homeimprovement', 'home improvement')
                            .replaceAll('debtconsolidation', 'debt consolidation')
                            .toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedLoanIntent = value),
              validator: (value) => value == null ? 'please_select'.tr() : null,
            ),
          ),
          
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'credit_history_length'.tr(),
            tooltipKey: 'tooltip_credit_history',
            child: _buildSliderWithValue(
              label: 'credit_history_length'.tr(),
              min: 0,
              max: 30,
              step: 1,
              controller: _creditControllers['histLength']!,
              validator: Validators.validateCreditHistory,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditHistoryPage(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Credit History'),
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'credit_history_length'.tr(),
            tooltipKey: 'tooltip_credit_history',
            child: _buildSliderWithValue(
              label: 'credit_history_length'.tr(),
              min: 0,
              max: 30,
              step: 1,
              controller: _creditControllers['histLength']!,
              validator: Validators.validateCreditHistory,
            ),
          ),
          
          SizedBox(height: padding * 0.7),
          
          _buildSwitchField(
            value: _defaultOnFile == 1,
            label: 'Previous Default on File',
            subtitle: 'Have you ever defaulted on a loan?',
            onChanged: (value) {
              setState(() => _defaultOnFile = value ? 1 : 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeDataPage(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('alternative_data'.tr()),
          Text(
            'This information helps us better assess your creditworthiness',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: widget.isSmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'estimated_monthly_income'.tr(),
            tooltipKey: 'tooltip_est_month_income',
            child: _buildSliderWithValue(
              label: 'estimated_monthly_income'.tr(),
              min: 3000,
              max: 100000,
              step: 500,
              controller: _alternativeControllers['monthlyIncome']!,
              prefix: '₹',
              onChanged: () => _monthlyEdited = true,
            ),
          ),
          
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'phone_bills'.tr(),
            tooltipKey: 'tooltip_phone_bills',
            child: _buildSliderWithValue(
              label: 'phone_bills'.tr(),
              min: 0,
              max: 5000,
              step: 50,
              controller: _alternativeControllers['airtimeSpend']!,
              prefix: '₹',
            ),
          ),
          
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'data_usage_gb'.tr(),
            tooltipKey: 'tooltip_data_usage',
            child: _buildSliderWithValue(
              label: 'data_usage_gb'.tr(),
              min: 0,
              max: 100,
              step: 1,
              controller: _alternativeControllers['dataUsage']!,
            ),
          ),
          
          SizedBox(height: padding),
          
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: Text('digital_wallet'.tr()),
                  subtitle: Text('digital_wallet_helper'.tr()),
                  value: _digitalWalletUsage == 1,
                  onChanged: (value) => setState(() => _digitalWalletUsage = value ? 1 : 0),
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  title: Text('mobile_banking'.tr()),
                  subtitle: Text('mobile_banking_helper'.tr()),
                  value: _mobileBankingUser == 1,
                  onChanged: (value) => setState(() => _mobileBankingUser = value ? 1 : 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityDataPage(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('utility_bills'.tr()),
          Text(
            'Your utility payment patterns help us understand your financial behavior',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: widget.isSmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(height: padding),
          
          _buildLabeledFieldWithTooltip(
            label: 'electric_bill'.tr(),
            tooltipKey: 'tooltip_electric',
            child: _buildSliderWithValue(
              label: 'electric_bill'.tr(),
              min: 0,
              max: 10000,
              step: 100,
              controller: _utilityControllers['electricBill']!,
              prefix: '₹',
            ),
          ),
          
          SizedBox(height: padding),
          
          Row(
            children: [
              Expanded(
                child: _buildLabeledFieldWithTooltip(
                  label: 'water_bill'.tr(),
                  tooltipKey: 'tooltip_water',
                  child: _buildSliderWithValue(
                    label: 'water_bill'.tr(),
                    min: 0,
                    max: 5000,
                    step: 50,
                    controller: _utilityControllers['waterBill']!,
                    prefix: '₹',
                  ),
                ),
              ),
              SizedBox(width: padding * 0.5),
              Expanded(
                child: _buildLabeledFieldWithTooltip(
                  label: 'gas_bill'.tr(),
                  tooltipKey: 'tooltip_gas',
                  child: _buildSliderWithValue(
                    label: 'gas_bill'.tr(),
                    min: 0,
                    max: 5000,
                    step: 50,
                    controller: _utilityControllers['gasBill']!,
                    prefix: '₹',
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: padding),
          
          _buildSectionTitle('payment_history_12m'.tr()),
          SizedBox(height: padding * 0.5),
          
          Row(
            children: [
              Expanded(
                child: _buildLabeledFieldWithTooltip(
                  label: 'on_time_payments'.tr(),
                  tooltipKey: 'tooltip_on_time',
                  child: _buildSliderWithValue(
                    label: 'on_time_payments'.tr(),
                    min: 0,
                    max: 12,
                    step: 1,
                    controller: _utilityControllers['onTimePayments']!,
                  ),
                ),
              ),
              SizedBox(width: padding * 0.5),
              Expanded(
                child: _buildLabeledFieldWithTooltip(
                  label: 'late_payments'.tr(),
                  tooltipKey: 'tooltip_late',
                  child: _buildSliderWithValue(
                    label: 'late_payments'.tr(),
                    min: 0,
                    max: 12,
                    step: 1,
                    controller: _utilityControllers['latePayments']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
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
                label: Text('previous'.tr()),
              ),
            ),
          if (_currentPage > 0) SizedBox(width: padding),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (_currentPage < 4) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _submitApplication();
                }
              },
              icon: Icon(_currentPage < 4 ? Icons.arrow_forward : Icons.send),
              label: Text(_currentPage < 4 ? 'next'.tr() : 'submit_app'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledFieldWithTooltip({
    required String label,
    required String tooltipKey,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label, 
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Tooltip(
              message: tooltipKey.tr(),
              preferBelow: true,
              child: Icon(
                Icons.info_outline, 
                color: Colors.grey[600], 
                size: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(AppConstants.primaryColorValue),
      ),
    );
  }

  Widget _buildSliderWithValue({
    required String label,
    required double min,
    required double max,
    required double step,
    required TextEditingController controller,
    String? prefix,
    String? suffix,
    String? Function(String?)? validator,
    VoidCallback? onChanged,
  }) {
    final parsed = double.tryParse(controller.text.replaceAll(',', '')) ?? min;
    final currentValue = parsed.clamp(min, max);
    final divisions = (step > 0) ? ((max - min) / step).round() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            labelText: label,
            prefixText: prefix,
            suffixText: suffix,
            suffixIcon: IconButton(
              icon: Icon(_localListening ? Icons.mic : Icons.mic_none),
              onPressed: () => _startListeningToController(controller),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            if (onChanged != null) onChanged();
            setState(() {});
          },
        ),
        Slider(
          value: currentValue,
          min: min,
          max: max,
          divisions: divisions,
          label: "${prefix ?? ''}${currentValue.toStringAsFixed(step < 1 ? 1 : 0)}${suffix ?? ''}",
          onChanged: (value) {
            setState(() {
              if (step < 1) {
                controller.text = value.toStringAsFixed(1);
              } else {
                controller.text = value.round().toString();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchField({
    required bool value,
    required String label,
    required String subtitle,
    required Function(bool) onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label),
        subtitle: Text(subtitle),
        activeColor: const Color(AppConstants.primaryColorValue),
      ),
    );
  }

  /// Validators
  String? _validateIncome(String? value) {
    final base = Validators.validateIncome(value);
    if (base != null) return base;
    return null;
  }

  String? _validateEmploymentLength(String? value) {
    final base = Validators.validateEmploymentLength(value);
    if (base != null) return base;

    // Additional business rule: employment length should be <= (age - 16)
    final age = widget.userProfile.age;
    final empText = value ?? '';
    final empLen = double.tryParse(empText) ?? -1;

    if (age > 0 && empLen >= 0) {
      final maxAllowedEmp = (age - 16).toInt();
      if (empLen > maxAllowedEmp) {
        return 'emp_length_invalid'.tr(args: [maxAllowedEmp.toString()]);
      }
    }
    return null;
  }

  String? _validateLoanAmount(String? value) {
    final base = Validators.validateLoanAmount(value);
    if (base != null) return base;

    final incomeText = _personalControllers['income']!.text;
    final loanText = value ?? '';
    final income = double.tryParse(incomeText.replaceAll(',', '')) ?? 0;
    final loan = double.tryParse(loanText.replaceAll(',', '')) ?? 0;

    double computedMax = income * _loanIncomeMultiplier;
    if (computedMax > _loanHardCap) computedMax = _loanHardCap;

    if (loan > computedMax) {
      return 'loan_max_exceeded'.tr(args: [computedMax.toStringAsFixed(0)]);
    }

    return null;
  }

  void _submitApplication() async {
    if (widget.formKey.currentState!.validate()) {
      final applicationData = ApplicationModel(
        personIncome: double.parse(_personalControllers['income']!.text),
        personEmpLength: double.parse(_personalControllers['empLength']!.text),
        age: widget.userProfile.age,
        loanAmnt: double.parse(_loanControllers['amount']!.text),
        loanIntRate: double.parse(_loanControllers['intRate']!.text),
        loanIntent: _selectedLoanIntent,
        cbPersonCredHistLength: double.parse(_creditControllers['histLength']!.text),
        cbPersonDefaultOnFile: _defaultOnFile,
        estimatedMonthlyIncome: double.tryParse(_alternativeControllers['monthlyIncome']!.text),
        monthlyAirtimeSpend: double.tryParse(_alternativeControllers['airtimeSpend']!.text) ?? 0,
        monthlyDataUsageGb: double.tryParse(_alternativeControllers['dataUsage']!.text) ?? 0,
        avgCallsPerDay: double.tryParse(_alternativeControllers['callsPerDay']!.text) ?? 0,
        avgSmsPerDay: double.tryParse(_alternativeControllers['smsPerDay']!.text) ?? 0,
        digitalWalletUsage: _digitalWalletUsage,
        mobileBankingUser: _mobileBankingUser,
        monthlyDigitalTransactions: double.tryParse(_alternativeControllers['digitalTransactions']!.text) ?? 0,
        avgTransactionAmount: double.tryParse(_alternativeControllers['transactionAmount']!.text) ?? 0,
        socialMediaActivityScore: double.tryParse(_alternativeControllers['socialMediaScore']!.text) ?? 0,
        digitalEngagementScore: double.tryParse(_alternativeControllers['digitalScore']!.text) ?? 0,
        financialInclusionScore: double.tryParse(_alternativeControllers['financialScore']!.text) ?? 0,
        electricityBillAvg: double.tryParse(_utilityControllers['electricBill']!.text) ?? 0,
        waterBillAvg: double.tryParse(_utilityControllers['waterBill']!.text) ?? 0,
        gasBillAvg: double.tryParse(_utilityControllers['gasBill']!.text) ?? 0,
        totalUtilityExpense: 0, // Will be calculated
        utilityToIncomeRatio: 0, // Will be calculated  
        onTimePayments12m: int.tryParse(_utilityControllers['onTimePayments']!.text) ?? 0,
        latePayments12m: int.tryParse(_utilityControllers['latePayments']!.text) ?? 0,
      );

      widget.onSubmit(applicationData);
    }
  }
}
