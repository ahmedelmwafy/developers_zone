import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'edit_profile_page.dart';

class IncompleteProfilePage extends StatelessWidget {
  const IncompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final locale = AppLocalization.of(context)!;
    final user = auth.currentUser;
    final completion = auth.profileCompletionPercentage;

    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernBanner(),
              const SizedBox(height: 48),
              Text(
                locale.translate('PROFILE_INCOMPLETE_CAPS'),
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                locale.translate('ARCHITECTURAL_SYNC_REQUIRED'),
                style: AppLocalization.digitalFont(context, 
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                locale
                    .translate('SYNC_PARTIAL_DESC')
                    .replaceFirst('{}', (completion * 100).toInt().toString()),
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              _buildSyncProgress(context, completion, locale),
              const SizedBox(height: 40),
              _buildChecklist(context, user, locale),
              const SizedBox(height: 48),
              _buildActionButtons(context, appProvider, locale),
              const SizedBox(height: 60),
              _buildFooter(context, locale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBanner() {
    return Container(
      width: double.infinity,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF00E5FF)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncProgress(
      BuildContext context, double completion, AppLocalization locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              locale.translate('SYNCHRONIZATION_STATE'),
              style: AppLocalization.digitalFont(context, 
                color: Colors.white.withValues(alpha: 0.1),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '${(completion * 100).toInt()}%',
              style: AppLocalization.digitalFont(context, 
                color: const Color(0xFF00E5FF),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: completion,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklist(
      BuildContext context, UserModel user, AppLocalization locale) {
    final identityComplete =
        user.name.isNotEmpty && user.profileImage.isNotEmpty;
    final techComplete = user.bio.isNotEmpty && user.position.isNotEmpty;
    final githubLinked = user.socialLinks?['github']?.isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          _buildCheckItem(
              context,
              locale.translate('IDENTITY_VERIFICATION'), identityComplete),
          const SizedBox(height: 20),
          _buildCheckItem(
              context,
              locale.translate('TECH_STACK_PORTFOLIO'), techComplete),
          const SizedBox(height: 20),
          _buildCheckItem(
              context,
              locale.translate('REPOSITORY_AUTHORIZATION'), githubLinked),
        ],
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String label, bool isChecked) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isChecked
                  ? const Color(0xFF00E5FF)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: isChecked
              ? const Icon(Icons.check_rounded,
                  color: Color(0xFF00E5FF), size: 12)
              : null,
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: AppLocalization.digitalFont(context, 
            color: isChecked ? Colors.white : Colors.white.withValues(alpha: 0.2),
            fontSize: 14,
            fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, AppProvider appProvider, AppLocalization locale) {
    return Column(
      children: [
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
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                locale.translate('FINISH_SETUP'),
                style: AppLocalization.digitalFont(context, 
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            appProvider.setSeenProfilePrompt(true);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
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
                locale.translate('REMIND_LATER'),
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalization locale) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_rounded,
              size: 12, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: 8),
          Text(
            locale
                .translate('ENCRYPTED_NODE_TRANSFER')
                .replaceFirst('{}', 'v2.0.48-STABLE'),
            style: AppLocalization.digitalFont(context, 
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
