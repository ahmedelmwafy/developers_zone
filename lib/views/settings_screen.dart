import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'splash_screen.dart';
import 'admin_dashboard_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthController>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _bioController.text = user.bio;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthController>(context, listen: false);
    final user = auth.currentUser!;
    
    try {
      final updated = user.copyWith(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
      );
      await auth.updateProfile(updated);
      if (mounted) {
        AppWidgets.showSnackBar(context, 'Profile records synchronized successfully.', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAdminCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2979FF).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF2979FF), size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Dashboard', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Access core system controls', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
            ],
          ),
          _OutlineButton(
            label: 'INITIALIZE',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminDashboardPage())),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final user = auth.currentUser;
    final locale = AppLocalization.of(context)!;

    if (user == null) {
      return const Scaffold(backgroundColor: Color(0xFF0D0D0D), body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    _buildHeroHeader(),
                    const SizedBox(height: 40),
                    
                    if (user.isAdmin) ...[
                      _SectionTitle(icon: Icons.admin_panel_settings_outlined, title: 'Administrative Protocols'),
                      _buildAdminCard(context),
                      const SizedBox(height: 48),
                    ],
                    
                    _SectionTitle(icon: Icons.person_outline_rounded, title: 'Account Management'),
                    _buildAccountCard(user),
                    
                    const SizedBox(height: 48),
                    
                    _SectionTitle(icon: Icons.shield_outlined, title: 'Security Suite'),
                    _buildSecurityCard(),
                    
                    const SizedBox(height: 48),
                    
                    _SectionTitle(icon: Icons.tune_rounded, title: 'Zone Preferences'),
                    _buildPreferencesCard(),
                    
                    const SizedBox(height: 60),
                    
                    _buildLogoutButton(auth, locale),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.person_search_rounded, color: Color(0xFF00E5FF), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'DEVELOPERS ZONE',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF00E5FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Icon(Icons.help_outline_rounded, color: Colors.white.withOpacity(0.3), size: 24),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                'CORE CONFIG',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'System Preferences',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Modify your identity parameters and security protocols for the zone.',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white10,
                    backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
                    child: user.profileImage.isEmpty ? const Icon(Icons.person, size: 30, color: Colors.white24) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFF0D0D0D), size: 14),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${user.name.toLowerCase().replaceAll(' ', '_')}',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Level 7 Contributor',
                    style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _TerminalField(label: 'DISPLAY NAME', controller: _nameController),
          const SizedBox(height: 24),
          _TerminalField(label: 'EMAIL UPDATE', controller: _emailController),
          const SizedBox(height: 24),
          _TerminalField(label: 'SYSTEM MANIFEST (BIO)', controller: _bioController, isMultiline: true),
          const SizedBox(height: 32),
          _SyncButton(onPressed: _updateProfile, isLoading: _isLoading),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _SecurityItem(
            title: 'Access Credentials',
            subtitle: 'Last rotated 42 days ago',
            trailing: _OutlineButton(label: 'CHANGE KEY', onPressed: () {}),
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          _SecurityItem(
            title: '2FA Protocols',
            subtitle: 'Biometric & TOTP authentication',
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeColor: const Color(0xFF00E5FF),
              activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildLanguageSwitcher(),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          const _PreferenceToggle(icon: Icons.terminal_rounded, title: 'Terminal Logs', value: true),
          const _PreferenceToggle(icon: Icons.hub_outlined, title: 'Node Syncs', value: true),
          const _PreferenceToggle(icon: Icons.gavel_rounded, title: 'Governance', value: false),
          const _PreferenceToggle(icon: Icons.alternate_email_rounded, title: 'Direct Comms', value: true),
          const _PreferenceToggle(icon: Icons.security_rounded, title: 'Vulnerability Alerts', value: true),
          const _PreferenceToggle(icon: Icons.show_chart_rounded, title: 'System Metrics', value: false),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.language_rounded, color: Colors.white.withOpacity(0.3), size: 20),
              const SizedBox(width: 12),
              Text('Language', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const _LangChip(label: 'EN', isActive: true),
                const _LangChip(label: 'AR', isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AuthController auth, AppLocalization locale) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          await auth.logout();
          if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
        },
        child: Text(
          'LOGOUT SESSION',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFFF5252),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.3), size: 18),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isMultiline;
  const _TerminalField({required this.label, required this.controller, this.isMultiline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF00E5FF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: isMultiline ? 4 : 1,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 0.5)),
          ),
        ),
      ],
    );
  }
}

class _SyncButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  const _SyncButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF006064), strokeWidth: 2))
              : Text(
                  'SYNC PROFILE DATA',
                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFF006064), fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
          ),
        ),
      ),
    );
  }
}

class _SecurityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  const _SecurityItem({required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ],
          ),
          trailing,
        ],
      ),
    );
  }
}

class _PreferenceToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  const _PreferenceToggle({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.3), size: 18),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 14))),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: value ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.1)),
            ),
            child: value ? const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 12) : null,
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _OutlineButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isActive;
  const _LangChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00E5FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: isActive ? const Color(0xFF0D0D0D) : Colors.white.withOpacity(0.3),
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
