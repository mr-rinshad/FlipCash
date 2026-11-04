import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/exchange_request.dart';
import '../../models/user_profile.dart';
import '../../models/safety_report.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAdminData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.darkSlate,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.accentMint,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'FlipCash Admin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: () {
              admin.loadAdminData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: 'Sign Out Admin',
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Text(
                'Listings (${admin.allRequests.length})',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Tab(
              child: Text(
                'Users (${admin.allUsers.length})',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reports',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (admin.pendingReportsCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${admin.pendingReportsCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // KPI Metric Cards Row
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Active Volume',
                          value: CurrencyFormatter.format(admin.totalActiveVolume),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Active Posts',
                          value: '${admin.activeListingsCount}',
                          color: AppColors.cashColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Pending Issues',
                          value: '${admin.pendingReportsCount}',
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs view
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListingsTab(admin),
                      _buildUsersTab(admin),
                      _buildReportsTab(admin),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildListingsTab(AdminProvider admin) {
    if (admin.allRequests.isEmpty) {
      return const Center(child: Text('No listings found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: admin.allRequests.length,
      itemBuilder: (context, index) {
        final req = admin.allRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: req.themeColor,
                        ),
                      ),
                    ),
                    Text(
                      req.formattedAmount,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: req.themeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'User: ${req.userProfile?.fullName ?? req.userId}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  'Location: ${req.locationName}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Status: ${req.status}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: req.status == 'ACTIVE' ? AppColors.success : AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {
                        admin.deleteListing(req.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Listing removed by moderator')),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                      label: Text(
                        'Remove',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTab(AdminProvider admin) {
    if (admin.allUsers.isEmpty) {
      return const Center(child: Text('No users registered'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: admin.allUsers.length,
      itemBuilder: (context, index) {
        final u = admin.allUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null,
              child: u.avatarUrl.isEmpty ? Text(u.initials) : null,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    u.fullName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (u.isAdmin) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.darkSlate,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '${u.email} • Trust: ${u.trustScore}% • ⭐ ${u.rating.toStringAsFixed(1)}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: u.isAdmin
                ? null
                : IconButton(
                    icon: Icon(
                      u.isBanned ? Icons.block_flipped : Icons.check_circle_outline,
                      color: u.isBanned ? AppColors.danger : AppColors.success,
                    ),
                    tooltip: u.isBanned ? 'Unban User' : 'Ban User',
                    onPressed: () {
                      admin.toggleUserBan(u.id, !u.isBanned);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            u.isBanned
                                ? 'User unbanned successfully'
                                : 'User suspended from platform',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab(AdminProvider admin) {
    if (admin.allReports.isEmpty) {
      return const Center(child: Text('No safety reports reported'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: admin.allReports.length,
      itemBuilder: (context, index) {
        final rep = admin.allReports[index];
        final isPending = rep.status == 'PENDING';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPending ? AppColors.dangerLight : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rep.status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPending ? AppColors.danger : AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Text(
                      'Report #${rep.id.substring(0, 5)}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rep.reason,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rep.details,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          admin.resolveReport(rep.id, 'Dismissed - insufficient evidence');
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Dismiss'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          admin.resolveReport(rep.id, 'Actioned - User warned & listing removed');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Resolve'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
