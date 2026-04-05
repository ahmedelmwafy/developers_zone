import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/auth_controller.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'waiting_approval_page.dart';
import '../widgets/page_entry_animation.dart';
import '../widgets/shimmer_component.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigate(AuthController auth) {
    if (!mounted || auth.currentUser == null) {
      return;
    }
    if (auth.currentUser!.isApproved) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WaitingApprovalPage()));
    }
  }

  void _register() async {
    final locale = AppLocalization.of(context)!;
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordController.text != _confirmPasswordController.text) {
      AppWidgets.showSnackBar(
          context, locale.translate('fill_all_fields_or_password_mismatch'),
          type: SnackBarType.warning);
      return;
    }
    final auth = Provider.of<AuthController>(context, listen: false);
    try {
      await auth.register(_emailController.text.trim(),
          _passwordController.text, _nameController.text.trim());
      _navigate(auth);
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(context, e.toString(),
            type: SnackBarType.error);
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
        AppWidgets.showSnackBar(context, e.toString(),
            type: SnackBarType.error);
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
        AppWidgets.showSnackBar(context, e.toString(),
            type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: PageEntryAnimation(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // Top Bar: Obsidian Core
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.terminal_rounded,
                              color: Color(0xFF00E5FF), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          locale.translate('OBSIDIAN_CORE'),
                          style: AppLocalization.digitalFont(
                            context,
                            color: const Color(0xFF00E5FF),
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 100),

                    // Status Chip
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
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
                                  BoxShadow(
                                      color: Color(0xFF00E5FF),
                                      blurRadius: 8,
                                      spreadRadius: 1),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              locale.translate('LIVE_CONNECTION_SECURE'),
                              style: AppLocalization.digitalFont(
                                context,
                                color: Colors.white.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Headline
                    Center(
                      child: Text(
                        locale.translate('JOIN_THE_CORE'),
                        textAlign: TextAlign.center,
                        style: AppLocalization.digitalFont(
                          context,
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          locale.translate('CREATE_ELITE_PROFILE'),
                          textAlign: TextAlign.center,
                          style: AppLocalization.digitalFont(
                            context,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Form
                    _TerminalLabel(locale.translate('DISPLAY_NAME')),
                    _TerminalInput(
                        controller: _nameController, hint: 'e.g. Neo_Operator'),

                    const SizedBox(height: 32),

                    _TerminalLabel(locale.translate('EMAIL_ADDRESS_CAPS')),
                    _TerminalInput(
                        controller: _emailController,
                        hint: 'dev@obsidian.io',
                        keyboardType: TextInputType.emailAddress),

                    const SizedBox(height: 32),

                    _TerminalLabel(locale.translate('ACCESS_KEY')),
                    _TerminalInput(
                        controller: _passwordController,
                        hint: '••••••••••••',
                        obscureText: true),

                    const SizedBox(height: 32),

                    _TerminalLabel(locale.translate('CONFIRM_ACCESS_KEY')),
                    _TerminalInput(
                        controller: _confirmPasswordController,
                        hint: '••••••••••••',
                        obscureText: true),

                    const SizedBox(height: 48),

                    // Initialize Button
                    _InitializeButton(
                      onPressed: _register,
                    ),

                    const SizedBox(height: 40),

                    // Auth Divider
                    Center(
                      child: Text(
                        locale.translate('OR_AUTHENTICATE_WITH'),
                        style: AppLocalization.digitalFont(
                          context,
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Social Row
                    Row(
                      children: [
                        Expanded(
                            child: _SocialButton(
                          icon: FontAwesomeIcons.google,
                          label: locale.translate('GOOGLE'),
                          onPressed: _signInWithGoogle,
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _SocialButton(
                          icon: FontAwesomeIcons.github,
                          label: locale.translate('GITHUB'),
                          onPressed: _signInWithGitHub,
                        )),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // Login Link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            style: AppLocalization.digitalFont(
                              context,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                  text: locale.translate('ALREADY_OPERATOR')),
                              TextSpan(
                                text: locale.translate('LOGIN'),
                                style: AppLocalization.digitalFont(
                                  context,
                                  color: const Color(0xFF00E5FF),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),

                    // Footer Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _FooterLink(locale.translate('PRIVACY_PROTOCOL')),
                        _FooterLink(locale.translate('TERMS_CONDITIONS')),
                        _FooterLink(locale.translate('VERSION_STABLE')),
                      ],
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            if (auth.isLoading)
              const ShimmerComponent(
                width: double.infinity,
                height: 4,
                borderRadius: 0,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppLocalization.digitalFont(context, 
          color: const Color(0xFF00E5FF),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _TerminalInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _TerminalInput({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppLocalization.digitalFont(context, 
              color: Colors.white.withValues(alpha: 0.1), fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00E5FF))),
        ),
      ),
    );
  }
}

class _InitializeButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _InitializeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0ED2F7).withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
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
            child: Text(
              locale.translate('INITIALIZE_ACCOUNT'),
              style: AppLocalization.digitalFont(context, 
                color: const Color(0xFF006064),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon as FaIconData?,
                  color: Colors.white.withValues(alpha: 0.8), size: 18),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppLocalization.digitalFont(context, 
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppLocalization.digitalFont(context, 
        color: Colors.white.withValues(alpha: 0.2),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

