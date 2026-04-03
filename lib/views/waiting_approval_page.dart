import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class WaitingApprovalPage extends StatelessWidget {
  const WaitingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: MediaQuery.of(context).size.width / 2 - 100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.18), blurRadius: 120, spreadRadius: 40)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) => Transform.scale(scale: value, child: child),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.accent.withValues(alpha: 0.3), AppColors.primary.withValues(alpha: 0.2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
                        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 5)],
                      ),
                      child: const Icon(Icons.hourglass_top_rounded, size: 52, color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    locale.translate('waiting_approval_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    locale.translate('waiting_approval_desc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 40),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Text(locale.translate('pending_admin_review'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 220,
                    child: OutlinedButton.icon(
                      onPressed: () => authController.logout(),
                      icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                      label: Text(locale.translate('logout'), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
