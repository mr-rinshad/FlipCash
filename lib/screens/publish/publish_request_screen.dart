import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';

class PublishRequestScreen extends StatefulWidget {
  final String? initialExchangeType;

  const PublishRequestScreen({super.key, this.initialExchangeType});

  @override
  State<PublishRequestScreen> createState() => _PublishRequestScreenState();
}

class _PublishRequestScreenState extends State<PublishRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _exchangeType; // 'CASH_TO_DIGITAL' or 'DIGITAL_TO_CASH'
  final _amountController = TextEditingController();
  final _locationController = TextEditingController(text: 'Koramangala 5th Block, near Starbucks');
  final _meetupPrefController = TextEditingController(text: 'Inside Starbucks Cafe (Ground Floor)');
  final _notesController = TextEditingController();

  final List<String> _selectedPayments = ['UPI (Any App)', 'Google Pay', 'PhonePe'];
  int _selectedExpirationMinutes = 120; // 2 hours default
  bool _safetyAgreed = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _exchangeType = widget.initialExchangeType ?? 'CASH_TO_DIGITAL';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _locationController.dispose();
    _meetupPrefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPayments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one preferred payment method'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!_safetyAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to follow public meetup safety guidelines'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to publish a request'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final reqProv = Provider.of<RequestProvider>(context, listen: false);

    final amountVal = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;

    final success = await reqProv.publishRequest(
      userId: user.id,
      exchangeType: _exchangeType,
      amount: amountVal,
      preferredPaymentMethods: _selectedPayments,
      locationName: _locationController.text.trim(),
      latitude: reqProv.userLatitude,
      longitude: reqProv.userLongitude,
      meetupPreference: _meetupPrefController.text.trim(),
      notes: _notesController.text.trim(),
      expirationMinutes: _selectedExpirationMinutes,
      creatorProfile: user,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Availability posted! Nearby peers can now discover you.'),
            ],
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCashToDigital = _exchangeType == 'CASH_TO_DIGITAL';
    final themeColor = isCashToDigital ? AppColors.cashColor : AppColors.digitalColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Publish Availability',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intent Selector Segmented Switch
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Cash to Digital Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _exchangeType = 'CASH_TO_DIGITAL';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isCashToDigital ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isCashToDigital
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.payments_rounded,
                                color: isCashToDigital ? AppColors.cashColor : AppColors.textTertiary,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'I Have Cash',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isCashToDigital ? AppColors.cashColor : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Want UPI/Transfer',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Digital to Cash Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _exchangeType = 'DIGITAL_TO_CASH';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isCashToDigital ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !isCashToDigital
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: !isCashToDigital ? AppColors.digitalColor : AppColors.textTertiary,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'I Need Cash',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: !isCashToDigital ? AppColors.digitalColor : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Can send UPI/Bank',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Amount Section
              Text(
                'Exchange Amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: themeColor,
                ),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      AppConstants.currencySymbol,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: themeColor,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: '5,000',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    color: AppColors.textTertiary,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the exchange amount';
                  }
                  final parsed = double.tryParse(val.replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount greater than 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Quick amount pills
              Wrap(
                spacing: 8,
                children: AppConstants.quickAmounts.map((amt) {
                  final formatted = CurrencyFormatter.format(amt);
                  return ActionChip(
                    label: Text(formatted),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _selectQuickAmount(amt),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Preferred Digital Methods
              Text(
                'Accepted / Preferred Digital Modes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.availablePaymentMethods.map((method) {
                  final isSelected = _selectedPayments.contains(method);
                  return FilterChip(
                    label: Text(method),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primaryDark,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPayments.add(method);
                        } else {
                          _selectedPayments.remove(method);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Meeting Location & Landmark
              Text(
                'Meeting Spot & Landmark',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Area / Neighborhood Landmark',
                  hintText: 'e.g. Indiranagar Metro Station Gate 2',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please provide a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _meetupPrefController,
                decoration: const InputDecoration(
                  labelText: 'Public Venue Preference',
                  hintText: 'e.g. Inside Cafe, Metro Concourse, Food Court',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),

              const SizedBox(height: 20),

              // Expiration Time
              Text(
                'Listing Expiration',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: AppConstants.expirationOptions.entries.map((entry) {
                  final isSelected = _selectedExpirationMinutes == entry.value;
                  return ChoiceChip(
                    label: Text(entry.key),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedExpirationMinutes = entry.value;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Notes / Denomination preferences
              Text(
                'Additional Notes (Optional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Have ₹500 notes. Will only meet in broad daylight at Starbucks.',
                ),
              ),

              const SizedBox(height: 16),

              // Safety Checkbox
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _safetyAgreed,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _safetyAgreed = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'I agree to meet in a well-lit public space, inspect physical currency or digital bank balance directly, and use the 4-digit code.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Publish CTA
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handlePublish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.publish_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Publish Intent to Nearby Peers',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
