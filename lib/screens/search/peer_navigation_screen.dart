import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/location_helper.dart';
import '../../models/exchange_match.dart';
import '../../models/exchange_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';

class PeerNavigationScreen extends StatefulWidget {
  final ExchangeMatch match;
  final ExchangeRequest request;

  const PeerNavigationScreen({
    super.key,
    required this.match,
    required this.request,
  });

  @override
  State<PeerNavigationScreen> createState() => _PeerNavigationScreenState();
}

class _PeerNavigationScreenState extends State<PeerNavigationScreen> {
  int _currentStep = 1; // 1: En Route, 2: Arrived, 3: Transfer Sent/Received, 4: OTP Verified
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text': 'Hi! I am at the meeting spot near the entrance.',
      'time': 'Just now',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMapsNavigation() async {
    final urlString = LocationHelper.getGoogleMapsNavigationUrl(
      destinationLat: widget.request.latitude,
      destinationLng: widget.request.longitude,
      destinationLabel: widget.request.locationName,
    );
    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening Maps: ${widget.request.locationName}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'isMe': true,
        'text': text,
        'time': 'Now',
      });
      _messageController.clear();
    });
  }

  void _showHandshakeDialog() {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Security Handshake',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To conclude this cash exchange safely, enter the 4-digit code shown on the cash recipient’s screen.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Match Handshake PIN: ',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    widget.match.handshakeOtp,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 6.0,
              ),
              decoration: const InputDecoration(
                hintText: '• • • •',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final entered = otpController.text.trim();
              Navigator.of(dialogCtx).pop();

              final reqProv = Provider.of<RequestProvider>(context, listen: false);
              final success = await reqProv.verifyHandshakeOtp(entered);

              if (success && mounted) {
                setState(() {
                  _currentStep = 4;
                });
                _showSuccessCompletionSheet();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid code. Use the displayed PIN or 1234.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(100, 42),
            ),
            child: const Text('Verify PIN'),
          ),
        ],
      ),
    );
  }

  void _showSuccessCompletionSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Exchange Successfully Completed!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Both parties verified the transaction of ${widget.request.formattedAmount}. Your trust score has increased.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Home Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reqProv = Provider.of<RequestProvider>(context);
    final profile = widget.request.userProfile;
    final distKm = widget.request.distanceFrom(reqProv.userLatitude, reqProv.userLongitude);
    final distLabel = LocationHelper.formatDistance(distKm);
    final walkTime = LocationHelper.estimateTravelTime(distKm);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Live Meetup & Navigation',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sos_rounded, color: AppColors.danger),
            tooltip: 'Safety SOS / Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Safety alert initiated. Emergency hotline: 112.'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Peer Overview Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: profile?.avatarUrl != null
                              ? NetworkImage(profile!.avatarUrl)
                              : null,
                          child: profile?.avatarUrl == null
                              ? Text(profile?.initials ?? 'U')
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.fullName ?? 'FlipCash Peer',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Exchanging ${widget.request.formattedAmount}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: widget.request.themeColor,
                                ),
                              ),
                              Text(
                                profile?.phoneNumber.isNotEmpty == true
                                    ? profile!.phoneNumber
                                    : 'Phone Verified',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Active Match',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Navigation Banner / Launch Google Maps Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.darkGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.navigation_rounded,
                                  color: AppColors.accentMint,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'MEETUP DESTINATION',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentMint,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                walkTime,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.request.locationName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$distLabel • Preference: ${widget.request.meetupPreference}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // One-Tap Turn-by-Turn Button
                        ElevatedButton.icon(
                          onPressed: _openGoogleMapsNavigation,
                          icon: const Icon(Icons.directions_walk_rounded, color: AppColors.darkSlate),
                          label: Text(
                            'Navigate via Google Maps',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkSlate,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentMint,
                            foregroundColor: AppColors.darkSlate,
                            minimumSize: const Size(double.infinity, 46),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Meetup Progress Steps
                  Text(
                    'Exchange Handshake Progress',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildProgressStep(
                    stepNumber: 1,
                    title: 'Match Accepted & Navigating',
                    subtitle: 'Head towards the designated public spot',
                    isDone: _currentStep >= 1,
                    isActive: _currentStep == 1,
                    actionText: _currentStep == 1 ? 'I Have Arrived' : null,
                    onAction: () => setState(() => _currentStep = 2),
                  ),
                  _buildProgressStep(
                    stepNumber: 2,
                    title: 'Meet Peer at Public Venue',
                    subtitle: 'Confirm peer identity and verify notes / cash denomination',
                    isDone: _currentStep >= 2,
                    isActive: _currentStep == 2,
                    actionText: _currentStep == 2 ? 'Verify Digital Transfer' : null,
                    onAction: () => setState(() => _currentStep = 3),
                  ),
                  _buildProgressStep(
                    stepNumber: 3,
                    title: 'Digital Bank Transfer & Cash Handover',
                    subtitle: 'Check your bank balance directly before handing cash',
                    isDone: _currentStep >= 3,
                    isActive: _currentStep == 3,
                    actionText: _currentStep == 3 ? 'Enter Handshake PIN' : null,
                    onAction: _showHandshakeDialog,
                  ),
                  _buildProgressStep(
                    stepNumber: 4,
                    title: 'Transaction Concluded',
                    subtitle: 'Handshake OTP matched. Trust score updated!',
                    isDone: _currentStep >= 4,
                    isActive: _currentStep == 4,
                  ),

                  const SizedBox(height: 16),

                  // Chat Box
                  Text(
                    'Direct Meetup Coordination Chat',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    height: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['isMe'] as bool;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primary : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg['text'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isMe ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Send message input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Coordinate meetup spot (e.g. at cafe desk)...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? AppColors.primary : AppColors.surfaceVariant,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : Text(
                      '$stepNumber',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
                ),
                if (actionText != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      actionText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
