import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/exchange_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import 'widgets/quick_stats_banner.dart';
import 'widgets/active_request_card.dart';
import 'widgets/safety_tip_card.dart';
import '../publish/publish_request_screen.dart';
import '../search/search_discovery_screen.dart';
import '../search/widgets/request_detail_sheet.dart';
import '../search/peer_navigation_screen.dart';
import '../profile/user_profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reqProv = Provider.of<RequestProvider>(context, listen: false);
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      reqProv.loadRequests();
      if (authProv.currentUser != null) {
        reqProv.loadUserRequests(authProv.currentUser!.id);
      }
    });
  }

  void _openDetailSheet(ExchangeRequest request) {
    final reqProv = Provider.of<RequestProvider>(context, listen: false);
    final authProv = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RequestDetailSheet(
        request: request,
        userLat: reqProv.userLatitude,
        userLng: reqProv.userLongitude,
        onConnect: () async {
          final match = await reqProv.proposeMatch(
            request: request,
            currentUserId: authProv.currentUser?.id ?? 'guest',
            currentUserProfile: authProv.currentUser,
          );

          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PeerNavigationScreen(
                  match: match,
                  request: request,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final reqProv = Provider.of<RequestProvider>(context);
    final user = auth.currentUser;

    final List<Widget> pages = [
      _buildHomeDashboardView(user, reqProv),
      const SearchDiscoveryScreen(),
      _buildMyRequestsView(user, reqProv),
      const UserProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentNavIndex >= pages.length ? 0 : _currentNavIndex],
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PublishRequestScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Publish Request',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentNavIndex >= pages.length ? 0 : _currentNavIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppColors.primaryLight,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.radar_outlined),
              selectedIcon: Icon(Icons.radar_rounded, color: AppColors.primary),
              label: 'Radar',
            ),
            const NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded, color: AppColors.primary),
              label: 'My Posts',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDashboardView(user, RequestProvider reqProv) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await reqProv.loadRequests();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: user?.avatarUrl != null && user!.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        child: user?.avatarUrl == null || user!.avatarUrl.isEmpty
                            ? Text(user?.initials ?? 'U')
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hi, ${user?.fullName.split(' ')[0] ?? 'Peer'}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (user?.isVerified ?? false) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                reqProv.userLocationName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Trust Score Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user?.trustScore ?? 100}% Trust',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Quick Stats Banner
              QuickStatsBanner(
                totalCashNearby: reqProv.totalCashLiquidityNearby,
                activePeersCount: reqProv.activeRequestsCountNearby,
                trustScore: user?.trustScore ?? 100,
              ),

              const SizedBox(height: 16),

              // Dual Quick Action Cards ("Have Cash" / "Need Cash")
              Row(
                children: [
                  // Have Cash -> Want Digital
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PublishRequestScreen(
                              initialExchangeType: 'CASH_TO_DIGITAL',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cashLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.cashColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.cashColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.payments_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'I Have Cash',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cashColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Deposit cash for UPI bank funds',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Need Cash -> Have Digital
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PublishRequestScreen(
                              initialExchangeType: 'DIGITAL_TO_CASH',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.digitalLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.digitalColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.digitalColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'I Need Cash',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.digitalColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Transfer UPI to get physical notes',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Safety Tip Card
              const SafetyTipCard(),

              const SizedBox(height: 14),

              // Feed Title & Filter Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Nearby Intent (${reqProv.filteredRequests.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentNavIndex = 1; // Open radar
                      });
                    },
                    child: Text(
                      'Radar View',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Feed Filter Chips
              Row(
                children: [
                  _buildTypeChip(
                    label: 'All',
                    isSelected: reqProv.selectedTypeFilter == 'ALL',
                    onTap: () => reqProv.setTypeFilter('ALL'),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeChip(
                    label: '💵 Has Cash',
                    isSelected: reqProv.selectedTypeFilter == 'CASH_TO_DIGITAL',
                    activeColor: AppColors.cashColor,
                    onTap: () => reqProv.setTypeFilter('CASH_TO_DIGITAL'),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeChip(
                    label: '💳 Needs Cash',
                    isSelected: reqProv.selectedTypeFilter == 'DIGITAL_TO_CASH',
                    activeColor: AppColors.digitalColor,
                    onTap: () => reqProv.setTypeFilter('DIGITAL_TO_CASH'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Listings Feed
              if (reqProv.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (reqProv.filteredRequests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 10),
                      Text(
                        'No active requests matching this filter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Be the first in your area to publish your cash exchange request.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ...reqProv.filteredRequests.map((req) {
                  return ActiveRequestCard(
                    request: req,
                    userLat: reqProv.userLatitude,
                    userLng: reqProv.userLongitude,
                    onTap: () => _openDetailSheet(req),
                    onConnect: () => _openDetailSheet(req),
                  );
                }),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyRequestsView(user, RequestProvider reqProv) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Published Requests',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: reqProv.userRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.post_add_rounded, size: 52, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    'No active requests published yet',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublishRequestScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(180, 44),
                    ),
                    child: const Text('Publish Your Intent'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reqProv.userRequests.length,
              itemBuilder: (context, index) {
                final req = reqProv.userRequests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: req.themeLightColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                req.actionTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: req.themeColor,
                                ),
                              ),
                            ),
                            Text(
                              req.formattedAmount,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: req.themeColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req.locationName,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: req.status == 'ACTIVE'
                                    ? AppColors.primaryLight
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                req.status,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: req.status == 'ACTIVE'
                                      ? AppColors.primaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (req.status == 'ACTIVE')
                              OutlinedButton(
                                onPressed: () {
                                  reqProv.cancelRequest(req.id);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.danger),
                                  minimumSize: const Size(0, 32),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: Text(
                                  'Cancel Listing',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.danger),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required bool isSelected,
    Color activeColor = AppColors.primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
