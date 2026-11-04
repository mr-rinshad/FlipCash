import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/exchange_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import 'widgets/interactive_radar_map.dart';
import 'widgets/request_detail_sheet.dart';
import '../home/widgets/active_request_card.dart';
import 'peer_navigation_screen.dart';

class SearchDiscoveryScreen extends StatefulWidget {
  const SearchDiscoveryScreen({super.key});

  @override
  State<SearchDiscoveryScreen> createState() => _SearchDiscoveryScreenState();
}

class _SearchDiscoveryScreenState extends State<SearchDiscoveryScreen> {
  bool _isRadarView = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final reqProv = Provider.of<RequestProvider>(context);
    final filtered = reqProv.filteredRequests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Nearby Discovery',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // View Toggle Button (Radar vs List)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              icon: Icon(
                _isRadarView ? Icons.list_rounded : Icons.radar_rounded,
                color: AppColors.primary,
              ),
              onPressed: () {
                setState(() {
                  _isRadarView = !_isRadarView;
                });
              },
              tooltip: _isRadarView ? 'Switch to List View' : 'Switch to Radar View',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => reqProv.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search landmark, neighborhood or amount...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              reqProv.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Exchange Type Filter Chips
                Row(
                  children: [
                    _buildFilterChip(
                      label: 'All Active (${reqProv.activeRequests.length})',
                      isSelected: reqProv.selectedTypeFilter == 'ALL',
                      onSelected: () => reqProv.setTypeFilter('ALL'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: '💵 Has Cash',
                      isSelected: reqProv.selectedTypeFilter == 'CASH_TO_DIGITAL',
                      activeColor: AppColors.cashColor,
                      onSelected: () => reqProv.setTypeFilter('CASH_TO_DIGITAL'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: '💳 Needs Cash',
                      isSelected: reqProv.selectedTypeFilter == 'DIGITAL_TO_CASH',
                      activeColor: AppColors.digitalColor,
                      onSelected: () => reqProv.setTypeFilter('DIGITAL_TO_CASH'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Radius Filter Slider
                Row(
                  children: [
                    const Icon(Icons.radar_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Radius: ${reqProv.selectedRadiusKm.round()} km',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: Slider(
                        value: reqProv.selectedRadiusKm,
                        min: 2,
                        max: 30,
                        divisions: 14,
                        activeColor: AppColors.primary,
                        onChanged: (val) => reqProv.setRadiusFilter(val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Area (Radar Map or List)
          Expanded(
            child: reqProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_off_rounded,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No matching exchange peers nearby',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try increasing the search radius or publish your own request.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _isRadarView
                        ? SingleChildScrollView(
                            child: Column(
                              children: [
                                InteractiveRadarMap(
                                  requests: filtered,
                                  userLat: reqProv.userLatitude,
                                  userLng: reqProv.userLongitude,
                                  onSelectRequest: (req) => _openDetailSheet(req),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Nearby Peers List (${filtered.length})',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final req = filtered[index];
                                    return ActiveRequestCard(
                                      request: req,
                                      userLat: reqProv.userLatitude,
                                      userLng: reqProv.userLongitude,
                                      onTap: () => _openDetailSheet(req),
                                      onConnect: () => _openDetailSheet(req),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final req = filtered[index];
                              return ActiveRequestCard(
                                request: req,
                                userLat: reqProv.userLatitude,
                                userLng: reqProv.userLongitude,
                                onTap: () => _openDetailSheet(req),
                                onConnect: () => _openDetailSheet(req),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color activeColor = AppColors.primary,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : AppColors.surfaceVariant,
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
