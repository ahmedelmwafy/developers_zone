import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'splash_screen.dart';
import 'admin_dashboard_page.dart';
import 'network_page.dart';
import 'policy_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _positionController = TextEditingController();
  final _companyController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _imageController = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user =
        Provider.of<AuthController>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _bioController.text = user.bio;
      _positionController.text = user.position;
      _companyController.text = user.company;
      _cityController.text = user.city;
      _countryController.text = user.country;
      _selectedBirthDate = user.birthDate;
      _selectedGender = user.gender;
      _imageController.text = user.profileImage;

      if (user.socialLinks != null) {
        _githubController.text = user.socialLinks!['github'] ?? '';
        _linkedinController.text = user.socialLinks!['linkedin'] ?? '';
        _portfolioController.text = user.socialLinks!['portfolio'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _positionController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _portfolioController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthController>(context, listen: false);
    final user = auth.currentUser!;

    if (_nameController.text.trim().isEmpty) {
      AppWidgets.showSnackBar(context, 'Name field is required.', type: SnackBarType.error);
      setState(() => _isLoading = false);
      return;
    }
    if (_positionController.text.trim().isEmpty) {
      AppWidgets.showSnackBar(context, 'Professional title is required.', type: SnackBarType.error);
      setState(() => _isLoading = false);
      return;
    }
    if (_bioController.text.trim().isEmpty) {
      AppWidgets.showSnackBar(context, 'Manifest bio is required.', type: SnackBarType.error);
      setState(() => _isLoading = false);
      return;
    }
    if (_selectedBirthDate == null) {
      AppWidgets.showSnackBar(context, 'Birth date record is required.', type: SnackBarType.error);
      setState(() => _isLoading = false);
      return;
    }
    if (_selectedGender == null) {
      AppWidgets.showSnackBar(context, 'Gender designation is required.', type: SnackBarType.error);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final updated = user.copyWith(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        position: _positionController.text.trim(),
        company: _companyController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        birthDate: _selectedBirthDate,
        gender: _selectedGender,
        profileImage: _imageController.text.trim(),
        socialLinks: {
          'github': _githubController.text.trim(),
          'linkedin': _linkedinController.text.trim(),
          'portfolio': _portfolioController.text.trim(),
        },
      );
      await auth.updateProfile(updated);
      if (mounted) {
        AppWidgets.showSnackBar(
            context, 'Profile records synchronized successfully.',
            type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(context, e.toString(),
            type: SnackBarType.error);
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
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Color(0xFF2979FF), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Dashboard',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text('Access core system controls',
                          style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
      return const Scaffold(
          backgroundColor: Color(0xFF0D0D0D),
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00E5FF))));
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
                      _SectionTitle(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Administrative Protocols'),
                      _buildAdminCard(context),
                      const SizedBox(height: 48),
                    ],
                    _SectionTitle(
                        icon: Icons.person_outline_rounded,
                        title: 'Account Management'),
                    _buildAccountCard(user, locale),
                    const SizedBox(height: 48),
                    _SectionTitle(
                        icon: Icons.shield_outlined, title: 'Security Suite'),
                    _buildSecurityCard(locale),
                    const SizedBox(height: 48),
                    _SectionTitle(
                        icon: Icons.tune_rounded, title: 'Zone Preferences'),
                    _buildPreferencesCard(locale),
                    const SizedBox(height: 48),
                    _SectionTitle(
                        icon: Icons.gavel_rounded,
                        title: locale.translate('legal').toUpperCase()),
                    _buildLegalCard(locale),
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
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Color(0xFF00E5FF)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.person_search_rounded,
                      color: Color(0xFF00E5FF), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DEVELOPERS ZONE',
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF00E5FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.help_outline_rounded,
              color: Colors.white.withOpacity(0.3), size: 24),
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
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF), shape: BoxShape.circle)),
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

  Widget _buildAccountCard(UserModel user, AppLocalization locale) {
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
                    backgroundImage: _imageController.text.isNotEmpty
                        ? NetworkImage(_imageController.text)
                        : user.profileImage.isNotEmpty
                            ? NetworkImage(user.profileImage)
                            : null,
                    child: (_imageController.text.isEmpty &&
                            user.profileImage.isEmpty)
                        ? const Icon(Icons.person,
                            size: 30, color: Colors.white24)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF0D0D0D), size: 14),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${user.name.toLowerCase().replaceAll(' ', '_')}',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${user.position.isEmpty ? 'New' : user.position} Contributor',
                      style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.4), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _TerminalField(
              label: locale.translate('name').toUpperCase(),
              controller: _nameController),
          const SizedBox(height: 24),
          _TerminalField(
              label: locale.translate('image_url').toUpperCase(),
              controller: _imageController),
          const SizedBox(height: 24),
          _TerminalField(
              label: locale.translate('position_label').toUpperCase(),
              controller: _positionController),
          const SizedBox(height: 24),
          _TerminalField(
              label: locale.translate('company_label').toUpperCase(),
              controller: _companyController),
          const SizedBox(height: 24),
          _TerminalField(
              label: 'SYSTEM MANIFEST (BIO)',
              controller: _bioController,
              isMultiline: true),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TerminalField(
                    label: locale.translate('city').toUpperCase(),
                    controller: _cityController),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TerminalField(
                    label: locale.translate('country').toUpperCase(),
                    controller: _countryController),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedBirthDate ??
                          DateTime.now()
                              .subtract(const Duration(days: 365 * 18)),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF00E5FF),
                              onPrimary: Colors.black,
                              surface: Color(0xFF161616),
                              onSurface: Colors.white,
                            ),
                            dialogBackgroundColor: const Color(0xFF0D0D0D),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => _selectedBirthDate = date);
                    }
                  },
                  child: AbsorbPointer(
                    child: _TerminalField(
                      label: locale.translate('birth_date').toUpperCase(),
                      controller: TextEditingController(
                        text: _selectedBirthDate == null
                            ? ''
                            : "${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}",
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.translate('gender').toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF00E5FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF161616),
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 14),
                          items: ['Male', 'Female'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedGender = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SectionTitle(icon: Icons.link_rounded, title: 'SOCIAL NODES'),
          const SizedBox(height: 8),
          _TerminalField(
              label: 'GITHUB',
              controller: _githubController,
              hint: 'github.com/username'),
          const SizedBox(height: 16),
          _TerminalField(
              label: 'LINKEDIN',
              controller: _linkedinController,
              hint: 'linkedin.com/in/username'),
          const SizedBox(height: 16),
          _TerminalField(
              label: 'PORTFOLIO',
              controller: _portfolioController,
              hint: 'https://yourwebsite.com'),
          const SizedBox(height: 48),
          _SyncButton(onPressed: _updateProfile, isLoading: _isLoading),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final controller = TextEditingController();
    final locale = AppLocalization.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: Text(locale.translate('change_password'),
            style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: locale.translate('new_password'),
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.translate('cancel'),
                style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().length < 6) {
                AppWidgets.showSnackBar(context, 'Password too short',
                    type: SnackBarType.error);
                return;
              }
              try {
                await Provider.of<AuthController>(context, listen: false)
                    .updatePassword(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  AppWidgets.showSnackBar(
                      context, 'Password updated successfully',
                      type: SnackBarType.success);
                }
              } catch (e) {
                if (mounted)
                  AppWidgets.showSnackBar(context, e.toString(),
                      type: SnackBarType.error);
              }
            },
            child: Text(locale.translate('update_button'),
                style: const TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirm() {
    final locale = AppLocalization.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: Text(locale.translate('delete_account'),
            style: GoogleFonts.spaceGrotesk(color: Colors.redAccent)),
        content: Text(locale.translate('delete_account_confirm'),
            style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.translate('cancel'),
                style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Provider.of<AuthController>(context, listen: false)
                    .deleteAccount();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted)
                  AppWidgets.showSnackBar(context, e.toString(),
                      type: SnackBarType.error);
              }
            },
            child: Text(locale.translate('delete').toUpperCase(),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(AppLocalization locale) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _SecurityItem(
            title: locale.translate('blocked_users'),
            subtitle: locale.translate('blocked_users_sub'),
            trailing: _OutlineButton(
              label: locale.translate('VIEW_LIST').toUpperCase(),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NetworkPage(
                            initialTab: NetworkTab.blocked,
                            isSingleMode: true,
                          ))),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.03), height: 1),
          _SecurityItem(
            title: locale.translate('change_password'),
            subtitle: locale.translate('change_password_sub'),
            trailing: _OutlineButton(
              label: locale.translate('edit').toUpperCase(),
              onPressed: _showChangePasswordDialog,
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.03), height: 1),
          _SecurityItem(
            title: locale.translate('delete_account'),
            subtitle: locale.translate('delete_account_sub'),
            trailing: _OutlineButton(
              label: locale.translate('delete').toUpperCase(),
              onPressed: _showDeleteAccountConfirm,
              isDanger: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(AppLocalization locale) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildLanguageSwitcher(locale),
        ],
      ),
    );
  }

  Widget _buildLegalCard(AppLocalization locale) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _SecurityItem(
            title: locale.translate('privacy_policy'),
            subtitle: 'Read our data protection protocols',
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white24, size: 14),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PolicyPage(
                          title: locale.translate('privacy_policy'),
                          contentKey: 'PRIVACY_PROTOCOL'))),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.03), height: 1),
          _SecurityItem(
            title: locale.translate('terms_conditions'),
            subtitle: 'Review the rules of the zone',
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white24, size: 14),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PolicyPage(
                          title: locale.translate('terms_conditions'),
                          contentKey: 'TERMS_PROTOCOL'))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher(AppLocalization locale) {
    final appProvider = Provider.of<AppProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.language_rounded,
                    color: Colors.white.withOpacity(0.3), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(locale.translate('language'),
                      style:
                          GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _LangChip(
                  label: 'EN',
                  isActive: appProvider.locale.languageCode == 'en',
                  onTap: () => appProvider.setLocale(const Locale('en')),
                ),
                _LangChip(
                  label: 'AR',
                  isActive: appProvider.locale.languageCode == 'ar',
                  onTap: () => appProvider.setLocale(const Locale('ar')),
                ),
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
          if (mounted)
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SplashScreen()));
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
  final String? hint;
  const _TerminalField(
      {required this.label,
      required this.controller,
      this.isMultiline = false,
      this.hint});

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
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(
                color: Colors.white.withOpacity(0.1), fontSize: 12),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide:
                    const BorderSide(color: Color(0xFF00E5FF), width: 0.5)),
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Color(0xFF006064), strokeWidth: 2))
                : Text(
                    'SYNC PROFILE DATA',
                    style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF006064),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1),
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
  const _SecurityItem(
      {required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDanger;
  const _OutlineButton(
      {required this.label, required this.onPressed, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDanger ? Colors.redAccent : Colors.white,
        side: BorderSide(
            color: isDanger
                ? Colors.redAccent.withOpacity(0.5)
                : Colors.white.withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _LangChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00E5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: isActive
                ? const Color(0xFF0D0D0D)
                : Colors.white.withOpacity(0.3),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
