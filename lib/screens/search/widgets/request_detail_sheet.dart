import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/location_helper.dart';
import '../../../models/exchange_request.dart';

class RequestDetailSheet extends StatelessWidget {
  final ExchangeRequest request;
  final double userLat;
  final double userLng;
  final VoidCallback onConnect;

  const RequestDetailSheet({
    super.key,
    required this.request,
    required this.userLat,
    required this.userLng,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final distKm = request.distanceFrom(userLat, userLng);
    final distLabel = LocationHelper.formatDistance(distKm);
    final walkTime = LocationHelper.estimateTravelTime(distKm);
    final profile = request.userProfile;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Peer Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: profile?.avatarUrl != null
                    ? NetworkImage(profile!.avatarUrl)
                    : null,
                child: profile?.avatarUrl == null
                    ? Text(
                        profile?.initials ?? 'U',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile?.fullName ?? 'FlipCash Peer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (profile?.isVerified ?? false) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          '${(profile?.rating ?? 5.0).toStringAsFixed(1)} (${profile?.totalReviews ?? 0} reviews)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${profile?.trustScore ?? 100}% Trust',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Main Deal Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: request.themeLightColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: request.themeColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      request.isCashToDigital
                          ? 'Physical Cash to Hand Over'
                          : 'Digital Funds to Send You',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: request.themeColor,
                      ),
                    ),
                    Text(
                      request.formattedAmount,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: request.themeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  request.actionSubheading,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Location details
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.locationName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distance: $distLabel',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Est: $walkTime',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (request.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Note: "${request.notes}"',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Action Button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConnect();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: request.themeColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handshake_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Accept & Start Live Meetup',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
