import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/page_entry_animation.dart';
import '../widgets/shimmer_component.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final locale = AppLocalization.of(context)!;
    
    if (_emailController.text.trim().isEmpty) {
      return;
    }

    try {
      await auth.sendPasswordReset(_emailController.text.trim());
      if (mounted) {
        AppWidgets.showToast(context, locale.translate('SUCCESS_TOKEN_SENT'), type: SnackBarType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppWidgets.showToast(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          locale.translate('RECOVER_ACCESS'),
          style: AppLocalization.digitalFont(context, 
            color: const Color(0xFF00E5FF),
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: PageEntryAnimation(
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100),
              
              // Title
              Text(
                locale.translate('RECOVER_ACCESS'),
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                locale.translate('RECOVERY_DESC'),
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              
              const SizedBox(height: 60),

              // Recovery Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.ghostBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TerminalLabel(locale.translate('TERMINAL_AUTH_INPUT')),
                    TextField(
                      controller: _emailController,
                      style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 14),
                      decoration: _terminalInputDecoration(Icons.mail_outline, 'user@devzone.node'),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Action Button
                    _ExecuteButton(
                      onPressed: auth.isLoading ? null : _resetPassword,
                      isLoading: auth.isLoading,
                      label: locale.translate('SEND_RECOVERY_TOKEN'),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Status Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00E5FF),
                            boxShadow: [
                              BoxShadow(color: Color(0xFF00E5FF), blurRadius: 8, spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          locale.translate('ENCRYPTION_NODE_ACTIVE'),
                          style: AppLocalization.digitalFont(context, 
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 80),
              
              // Bottom Diagnostics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DiagnosticItem(
                    label: locale.translate('NETWORK_PROTOCOL'),
                    value: 'ENCRYPTED_NODE_TRANSFER',
                  ),
                  _DiagnosticItem(
                    label: locale.translate('BUILD_VERSION'),
                    value: 'V2.4.0-STABLE',
                    align: CrossAxisAlignment.end,
                  ),
                ],
              ),
              
              const SizedBox(height: 100),
              
              Center(
                child: Text(
                   '© 2024 DEVELOPERS ZONE TERMINAL.\nAUTHORIZED ACCESS ONLY.',
                   textAlign: TextAlign.center,
                   style: AppLocalization.digitalFont(context, 
                     color: Colors.white.withValues(alpha: 0.15),
                     fontSize: 9,
                     fontWeight: FontWeight.w600,
                     letterSpacing: 2,
                     height: 1.8,
                   ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
}

  InputDecoration _terminalInputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 18),
      hintText: hint,
      hintStyle: AppLocalization.digitalFont(context, color: Colors.white.withValues(alpha: 0.2)),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
    );
  }
}

class _TerminalLabel extends StatelessWidget {
  final String text;
  const _TerminalLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppLocalization.digitalFont(context, 
          color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ExecuteButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _ExecuteButton({this.onPressed, this.isLoading = false, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: isLoading
                ? ShimmerComponent.circleShimmer(size: 24)
                : Text(
                    label,
                    style: AppLocalization.digitalFont(context, 
                      color: Colors.black.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DiagnosticItem extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _DiagnosticItem({required this.label, required this.value, this.align = CrossAxisAlignment.start});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: AppLocalization.digitalFont(context, 
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppLocalization.digitalFont(context, 
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
