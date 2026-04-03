import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'waiting_approval_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigate(AuthController auth) {
    if (!mounted || auth.currentUser == null) return;
    if (auth.currentUser!.isApproved) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WaitingApprovalPage()));
    }
  }

  void _login() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    try {
      await auth.login(_emailController.text.trim(), _passwordController.text);
      _navigate(auth);
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

  void _signInWithGoogle() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    try {
      await auth.signInWithGoogle();
      _navigate(auth);
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(context, e.toString(), type: SnackBarType.error);
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
          // Background glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 120, spreadRadius: 60)],
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.08), blurRadius: 100, spreadRadius: 40)],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo + brand
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 2)],
                              ),
                              padding: const EdgeInsets.all(2.5),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.code, size: 40, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ShaderMask(
                              shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                              child: const Text(
                                'Developers Zone',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        locale.translate('login'),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locale.translate('welcome_back'),
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 32),
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
                      const SizedBox(height: 28),
                      AppWidgets.gradientButton(
                        label: locale.translate('login'),
                        onPressed: auth.isLoading ? null : _login,
                        isLoading: auth.isLoading,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(locale.translate('or'), style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Google Sign-In
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: auth.isLoading ? null : _signInWithGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 28, color: AppColors.textPrimary),
                          label: Text(locale.translate('google_sign_in'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: RichText(
                            text: TextSpan(
                              text: locale.translate('dont_have_account'),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: locale.translate('register'),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
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
          ),
        ],
      ),
    );
  }
}
