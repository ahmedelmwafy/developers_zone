import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'waiting_approval_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    final locale = AppLocalization.of(context)!;
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      AppWidgets.showSnackBar(context, locale.translate('fill_all_fields'), type: SnackBarType.warning);
      return;
    }
    final auth = Provider.of<AuthController>(context, listen: false);
    try {
      await auth.register(_emailController.text.trim(), _passwordController.text, _nameController.text.trim());
      if (mounted && auth.currentUser != null) {
        if (auth.currentUser!.isApproved) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WaitingApprovalPage()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.10), blurRadius: 120, spreadRadius: 60)],
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.10), blurRadius: 100, spreadRadius: 40)],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 28),
                    // Icon badge
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.code, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      locale.translate('register'),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locale.translate('join_community'),
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 36),
                    // Name
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: AppWidgets.fieldDecoration(locale.translate('name'), prefixIcon: Icons.person_outline),
                    ),
                    const SizedBox(height: 14),
                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: AppWidgets.fieldDecoration(locale.translate('email'), prefixIcon: Icons.alternate_email),
                    ),
                    const SizedBox(height: 14),
                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: AppWidgets.fieldDecoration(locale.translate('password'), prefixIcon: Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondary, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Password hint
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(locale.translate('password_hint'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AppWidgets.gradientButton(
                      label: locale.translate('register'),
                      onPressed: auth.isLoading ? null : _register,
                      isLoading: auth.isLoading,
                      icon: Icons.person_add_outlined,
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: RichText(
                          text: TextSpan(
                            text: locale.translate('already_have_account'),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            children: [
                              TextSpan(text: locale.translate('sign_in'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
