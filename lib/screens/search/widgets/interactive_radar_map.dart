import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/location_helper.dart';
import '../../../models/exchange_request.dart';

class InteractiveRadarMap extends StatefulWidget {
  final List<ExchangeRequest> requests;
  final double userLat;
  final double userLng;
  final Function(ExchangeRequest) onSelectRequest;

  const InteractiveRadarMap({
    super.key,
    required this.requests,
    required this.userLat,
    required this.userLng,
    required this.onSelectRequest,
  });

  @override
  State<InteractiveRadarMap> createState() => _InteractiveRadarMapState();
}

class _InteractiveRadarMapState extends State<InteractiveRadarMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  ExchangeRequest? _selectedRequest;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    if (widget.requests.isNotEmpty) {
      _selectedRequest = widget.requests.first;
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveRadarMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedRequest == null && widget.requests.isNotEmpty) {
      _selectedRequest = widget.requests.first;
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Radar Screen Canvas
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 320,
          decoration: BoxDecoration(
            color: const Color(0xFF0A101D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accentMint.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkSlate.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Animated Custom Painter Radar
                AnimatedBuilder(
                  animation: _sweepController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(double.infinity, 320),
                      painter: _RadarPainter(
                        sweepAngle: _sweepController.value * 2 * math.pi,
                      ),
                    );
                  },
                ),

                // Radar Scale HUD info
                Positioned(
                  top: 14,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentMint,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'P2P LIVE PROXIMITY RADAR',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentMint,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 14,
                  right: 16,
                  child: Text(
                    'Radius: 10 km',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                    ),
                  ),
                ),

                // Center Beacon (User Location)
                const Center(
                  child: _UserBeaconWidget(),
                ),

                // Peer Blip Pins placed based on relative angle & distance
                LayoutBuilder(
                  builder: (context, constraints) {
                    final centerX = constraints.maxWidth / 2;
                    final centerY = constraints.maxHeight / 2;
                    final maxRadiusPx = math.min(centerX, centerY) - 30;

                    return Stack(
                      children: widget.requests.map((req) {
                        final distKm = req.distanceFrom(widget.userLat, widget.userLng);
                        // Normalize distance (max radius mapped to 12 km)
                        final normalizedDist = (distKm / 12.0).clamp(0.18, 0.95);
                        final radiusPx = normalizedDist * maxRadiusPx;

                        // Calculate angle from user coords to req coords
                        final dLat = req.latitude - widget.userLat;
                        final dLon = req.longitude - widget.userLng;
                        final angle = math.atan2(dLat, dLon);

                        final x = centerX + radiusPx * math.cos(angle) - 16;
                        final y = centerY - radiusPx * math.sin(angle) - 16;

                        final isSelected = _selectedRequest?.id == req.id;

                        return Positioned(
                          left: x,
                          top: y,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRequest = req;
                              });
                            },
                            child: _PeerBlipWidget(
                              request: req,
                              isSelected: isSelected,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Selected Peer Quick Action Card
        if (_selectedRequest != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _selectedRequest!.themeLightColor,
                  backgroundImage: _selectedRequest!.userProfile?.avatarUrl != null
                      ? NetworkImage(_selectedRequest!.userProfile!.avatarUrl)
                      : null,
                  child: _selectedRequest!.userProfile?.avatarUrl == null
                      ? Icon(_selectedRequest!.iconData, color: _selectedRequest!.themeColor)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _selectedRequest!.userProfile?.fullName ?? 'Nearby Peer',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            LocationHelper.formatDistance(
                              _selectedRequest!.distanceFrom(widget.userLat, widget.userLng),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedRequest!.actionTitle} • ${_selectedRequest!.formattedAmount}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedRequest!.themeColor,
                        ),
                      ),
                      Text(
                        _selectedRequest!.locationName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => widget.onSelectRequest(_selectedRequest!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRequest!.themeColor,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Meet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;

  _RadarPainter({required this.sweepAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 24;

    final gridPaint = Paint()
      ..color = AppColors.accentMint.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw 3 concentric range rings
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, (maxRadius / 3) * i, gridPaint);
    }

    // Draw crosshair axes
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      gridPaint,
    );

    // Draw rotating radar beam
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          AppColors.accentMint.withOpacity(0.35),
          AppColors.accentMint.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
        transform: GradientRotation(sweepAngle - (math.pi / 2)),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle;
  }
}

class _UserBeaconWidget extends StatelessWidget {
  const _UserBeaconWidget();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.2),
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.primary, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.8),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeerBlipWidget extends StatelessWidget {
  final ExchangeRequest request;
  final bool isSelected;

  const _PeerBlipWidget({
    required this.request,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = request.isCashToDigital ? AppColors.cashColor : AppColors.digitalColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 36 : 28,
      height: isSelected ? 36 : 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isSelected ? 0.9 : 0.4),
            blurRadius: isSelected ? 12 : 6,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          request.iconData,
          size: isSelected ? 18 : 14,
          color: Colors.white,
        ),
      ),
    );
  }
}
