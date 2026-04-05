import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'waiting_approval_page.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _maintainSession = true;

  @override
  void dispose() {
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
        AppWidgets.showSnackBar(context, e.toString(), type: SnackBarType.error);
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

  void _signInWithGitHub() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    try {
      await auth.signInWithGitHub();
      _navigate(auth);
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background subtle grid/texture could be added here
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Top Bar: Logo & Lang
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
                            ),
                            child: const Icon(Icons.terminal_rounded, color: Color(0xFF00E5FF), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.translate('DEVELOPERS'),
                                style: AppLocalization.digitalFont(context, 
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                locale.translate('ZONE'),
                                style: AppLocalization.digitalFont(context, 
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Language Switcher
                      GestureDetector(
                        onTap: () {
                          final provider = Provider.of<AppProvider>(context, listen: false);
                          final next = provider.locale.languageCode == 'en' ? 'ar' : 'en';
                          provider.setLocale(Locale(next));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.language, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                locale.translate('EN_AR'),
                                style: AppLocalization.digitalFont(context, 
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(width: 10),
                        Text(
                          locale.translate('ELITE_NODE_ACTIVE'),
                          style: AppLocalization.digitalFont(context, 
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Hero Text
                  Text(
                    locale.translate('HERO_TITLE'),
                    textAlign: TextAlign.center,
                    style: AppLocalization.digitalFont(context, 
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      locale.translate('HERO_SUBTITLE'),
                      textAlign: TextAlign.center,
                      style: AppLocalization.digitalFont(context, 
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          value: '2.4M+',
                          label: locale.translate('COMMITS_TODAY'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          value: '99.9%',
                          label: locale.translate('UPTIME_SLA'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Login Card
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locale.translate('INITIALIZE_SESSION'),
                                    style: AppLocalization.digitalFont(context, 
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    locale.translate('AUTH_METHOD_SUB'),
                                    style: AppLocalization.digitalFont(context, 
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.grid_view_rounded,
                                color: Colors.white.withOpacity(0.1), size: 40),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Social Row
                        Row(
                          children: [
                            Expanded(child: _SocialButton(
                              icon: FontAwesomeIcons.google,
                              label: locale.translate('GOOGLE'),
                              onPressed: _signInWithGoogle,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _SocialButton(
                              icon: FontAwesomeIcons.github,
                              label: locale.translate('GITHUB'),
                              onPressed: _signInWithGitHub,
                            )),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Center(
                          child: Text(
                            locale.translate('OR_VIA_TERMINAL'),
                            style: AppLocalization.digitalFont(context, 
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Email Field
                        _TerminalLabel(locale.translate('EMAIL_ADDRESS_CAPS')),
                        TextField(
                          controller: _emailController,
                          style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 14),
                          decoration: _terminalInputDecoration(Icons.mail_outline, locale.translate('email_hint')),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Password Field
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             _TerminalLabel(locale.translate('ACCESS_KEY_CAPS')),
                             GestureDetector(
                               onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                               child: Text(
                                 locale.translate('FORGOT_CAPS'),
                                 style: AppLocalization.digitalFont(context, 
                                   color: Colors.white.withOpacity(0.4),
                                   fontSize: 10,
                                   fontWeight: FontWeight.w700,
                                   letterSpacing: 1.1,
                                 ),
                               ),
                             ),
                          ],
                        ),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 14),
                          decoration: _terminalInputDecoration(Icons.lock_outline, '••••••••••••', 
                             suffix: GestureDetector(
                               onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                               child: Icon(
                                 _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                 color: Colors.white.withOpacity(0.3),
                                 size: 18,
                               ),
                             )
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Maintain Session
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _maintainSession,
                                onChanged: (v) => setState(() => _maintainSession = v ?? true),
                                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                activeColor: const Color(0xFF00E5FF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              locale.translate('MAINTAIN_SESSION'),
                              style: AppLocalization.digitalFont(context, 
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Execute Login Button
                        _ExecuteLoginButton(
                          onPressed: auth.isLoading ? null : _login,
                          isLoading: auth.isLoading,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Create Account Footer
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.6), fontSize: 14),
                              children: [
                                TextSpan(text: locale.translate('NEW_OPERATOR')),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                    child: Text(
                                      locale.translate('CREATE_ACCOUNT'),
                                      style: AppLocalization.digitalFont(context, color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Bottom Nav
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _BottomNavLink(locale.translate('DOCUMENTATION')),
                      _BottomNavLink(locale.translate('API_STATUS')),
                      _BottomNavLink(locale.translate('PRIVACY_PROTOCOL')),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _terminalInputDecoration(IconData icon, String hint, {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 18),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.2)),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.ghostBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppLocalization.digitalFont(context, 
              color: const Color(0xFF00E5FF),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppLocalization.digitalFont(context, 
              color: Colors.white.withOpacity(0.4),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final dynamic icon; 
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon as FaIconData, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppLocalization.digitalFont(context, 
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
          color: Colors.white.withOpacity(0.7),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ExecuteLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ExecuteLoginButton({this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
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
            color: const Color(0xFF00E5FF).withOpacity(0.3),
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
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    locale.translate('EXECUTE_LOGIN'),
                    style: AppLocalization.digitalFont(context, 
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavLink extends StatelessWidget {
  final String text;
  const _BottomNavLink(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppLocalization.digitalFont(context, 
        color: Colors.white.withOpacity(0.3),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

