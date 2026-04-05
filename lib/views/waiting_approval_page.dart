import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'edit_profile_page.dart';

class WaitingApprovalPage extends StatefulWidget {
  const WaitingApprovalPage({super.key});

  @override
  State<WaitingApprovalPage> createState() => _WaitingApprovalPageState();
}

class _WaitingApprovalPageState extends State<WaitingApprovalPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final authController = Provider.of<AuthController>(context, listen: false);
    await authController.refreshUser();

    if (mounted) {
      if (authController.currentUser?.isApproved == true) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => _isRefreshing = false);
        AppWidgets.showSnackBar(
          context,
          AppLocalization.of(context)!.translate('VERIFICATION_PENDING'),
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthController>(context).currentUser;
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 60),
                  _buildMainStatus(locale, user?.isBanned ?? false),
                  const SizedBox(height: 48),
                  _buildDetailsCard(
                      user?.uid.substring(0, 8).toUpperCase() ?? '8842-AX',
                      locale),
                  const SizedBox(height: 48),
                  _buildActionButtons(locale, user?.isBanned ?? false),
                  const SizedBox(height: 60),
                  _buildSecurityLogs(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.terminal_rounded,
                  color: Colors.black, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Obsidian.Dev',
              style: AppLocalization.digitalFont(
                context,
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_outline_rounded,
              color: Colors.white.withValues(alpha: 0.5), size: 20),
        ),
      ],
    );
  }

  Widget _buildMainStatus(AppLocalization locale, bool isBanned) {
    final statusColor =
        isBanned ? const Color(0xFFFF3D00) : const Color(0xFF00E5FF);
    return Column(
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.2).animate(
            CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: statusColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          isBanned
              ? locale.translate('PROTOCOL_VIOLATION')
              : locale.translate('REVIEWING_NODE_CREDENTIALS'),
          textAlign: TextAlign.center,
          style: AppLocalization.digitalFont(
            context,
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 48),
        Text(
          isBanned
              ? locale.translate('ACCESS_REVOKED')
              : locale.translate('ACCESS_PENDING'),
          style: AppLocalization.digitalFont(
            context,
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isBanned
              ? locale.translate('BANNED_DESC')
              : locale.translate('ACCESS_PENDING_DESC'),
          textAlign: TextAlign.center,
          style: AppLocalization.digitalFont(
            context,
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(String nodeId, AppLocalization locale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailItem(
              locale.translate('NODE_ID_LABEL'), 'DEV-ZONE-$nodeId'),
          const SizedBox(height: 24),
          _buildDetailItem(locale.translate('QUEUE_POSITION'),
              locale.translate('QUEUE_POSITION_VALUE')),
          const SizedBox(height: 24),
          _buildDetailItem(locale.translate('AVG_REVIEW_TIME'),
              locale.translate('AVG_REVIEW_TIME_VALUE')),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppLocalization.digitalFont(
            context,
            color: const Color(0xFF00E5FF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppLocalization.digitalFont(
            context,
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalization locale, bool isBanned) {
    return Column(
      children: [
        if (isBanned) ...[
          GestureDetector(
            onTap: () {
              AppWidgets.showSnackBar(
                context,
                locale.translate('contact_support_init'),
                type: SnackBarType.success,
              );
            },
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3D00),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFFF3D00).withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Center(
                child: Text(
                  locale.translate('CONTACT_SUPPORT'),
                  style: AppLocalization.digitalFont(
                    context,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          GestureDetector(
            onTap: _isRefreshing ? null : _handleRefresh,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
              ),
              child: Center(
                child: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Color(0xFF00E5FF), strokeWidth: 3))
                    : Text(
                        locale.translate('REFRESH_STATUS'),
                        style: AppLocalization.digitalFont(
                          context,
                          color: const Color(0xFF00E5FF),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00E5FF)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  locale.translate('COMPLETE_PROFILE_CAPS'),
                  style: AppLocalization.digitalFont(
                    context,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final authController =
                Provider.of<AuthController>(context, listen: false);
            await authController.logout();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: Text(
                locale.translate('LOGOUT_SESSION'),
                style: AppLocalization.digitalFont(
                  context,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityLogs() {
    return Column(
      children: [
        Text(
          AppLocalization.of(context)!.translate('SECURITY_LOGS'),
          style: AppLocalization.digitalFont(
            context,
            color: Colors.white.withValues(alpha: 0.2),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        _buildLogRow('[SYS] INITIALIZING_ENCRYPTION_HANDSHAKE...', 'OK',
            const Color(0xFF00E5FF)),
        const SizedBox(height: 8),
        _buildLogRow('[USER] VERIFYING_COMMITS_IDENTITY...', 'OK',
            const Color(0xFF00E5FF)),
        const SizedBox(height: 8),
        _buildLogRow('[AUTH] WAITING_FOR_SIG_AUTHORIZATION...', 'PENDING',
            const Color(0xFFFFD740)),
      ],
    );
  }

  Widget _buildLogRow(String text, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.sourceCodePro(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          status,
          style: GoogleFonts.sourceCodePro(
            color: statusColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
