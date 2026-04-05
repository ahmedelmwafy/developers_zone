import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../services/imgbb_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
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
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthController>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
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

  Future<void> _pickAndUploadImage() async {
    final locale = AppLocalization.of(context)!;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1000,
    );

    if (image != null) {
      setState(() => _isUploadingImage = true);
      final url = await ImgBBService.uploadImage(File(image.path));
      if (url != null) {
        setState(() {
          _imageController.text = url;
          _isUploadingImage = false;
        });
        AppWidgets.showSnackBar(context, locale.translate('profile_image_uploaded'), type: SnackBarType.success);
      } else {
        setState(() => _isUploadingImage = false);
        AppWidgets.showSnackBar(context, locale.translate('profile_image_failed'), type: SnackBarType.error);
      }
    }
  }

  Future<void> _updateProfile() async {
    final locale = AppLocalization.of(context)!;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthController>(context, listen: false);
    final user = auth.currentUser!;

    if (_nameController.text.trim().isEmpty) {
      AppWidgets.showSnackBar(context, locale.translate('name_required'), type: SnackBarType.error);
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
        AppWidgets.showSnackBar(context, locale.translate('profile_sync_success'), type: SnackBarType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppWidgets.showSnackBar(context, e.toString(), type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final user = Provider.of<AuthController>(context).currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: Text(
          locale.translate('edit_profile').toUpperCase(),
          style: AppLocalization.digitalFont(
            context,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00E5FF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.only(right: 20), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 2))))
            : TextButton(
                onPressed: _updateProfile,
                child: Text(locale.translate('update_button').toUpperCase(),
                    style: AppLocalization.digitalFont(context,
                        color: const Color(0xFF00E5FF),
                        fontWeight: FontWeight.w800)),
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildAvatarSection(user),
            const SizedBox(height: 48),
            _TerminalField(label: locale.translate('name'), controller: _nameController),
            const SizedBox(height: 24),
            _TerminalField(label: locale.translate('position'), controller: _positionController),
            const SizedBox(height: 24),
            _TerminalField(label: locale.translate('company_label'), controller: _companyController),
            const SizedBox(height: 24),
            _TerminalField(label: locale.translate('bio'), controller: _bioController, isMultiline: true),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _TerminalField(label: locale.translate('city'), controller: _cityController)),
                const SizedBox(width: 16),
                Expanded(child: _TerminalField(label: locale.translate('country'), controller: _countryController)),
              ],
            ),
            const SizedBox(height: 24),
            _buildDateAndGender(locale),
            const SizedBox(height: 48),
            _SectionTitle(icon: Icons.link_rounded, title: locale.translate('links')),
            const SizedBox(height: 16),
            _TerminalField(label: 'GITHUB', controller: _githubController, hint: 'github.com/username'),
            const SizedBox(height: 16),
            _TerminalField(label: locale.translate('LINKEDIN').toUpperCase(), controller: _linkedinController, hint: 'linkedin.com/in/username'),
            const SizedBox(height: 16),
            _TerminalField(label: locale.translate('PORTFOLIO').toUpperCase(), controller: _portfolioController, hint: 'https://website.com'),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(UserModel user) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 2),
              image: _imageController.text.isNotEmpty
                  ? DecorationImage(image: NetworkImage(_imageController.text), fit: BoxFit.cover)
                  : user.profileImage.isNotEmpty
                      ? DecorationImage(image: NetworkImage(user.profileImage), fit: BoxFit.cover)
                      : null,
              color: Colors.white10,
            ),
            child: _isUploadingImage 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
              : (_imageController.text.isEmpty && user.profileImage.isEmpty)
                ? Icon(Icons.person_rounded, color: Colors.white.withOpacity(0.1), size: 64)
                : null,
          ),
          GestureDetector(
            onTap: _isUploadingImage ? null : _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0D0D0D), width: 4),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0D0D0D), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndGender(AppLocalization locale) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5FF), onPrimary: Colors.black, surface: Color(0xFF161616)),
                  ),
                  child: child!,
                ),
              );
              if (date != null) setState(() => _selectedBirthDate = date);
            },
            child: AbsorbPointer(
              child: _TerminalField(
                label: locale.translate('BIRTH_DATE').toUpperCase(),
                controller: TextEditingController(
                  text: _selectedBirthDate == null ? '' : "${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}",
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
              Text(locale.translate('gender'),
                  style: AppLocalization.digitalFont(context,
                      color: const Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF161616),
                    style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 14),
                    items: [
                      DropdownMenuItem(
                          value: 'Male', child: Text(locale.translate('male'))),
                      DropdownMenuItem(
                          value: 'Female',
                          child: Text(locale.translate('female'))),
                    ],
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TerminalField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isMultiline;
  final String? hint;

  const _TerminalField({
    required this.label,
    required this.controller,
    this.isMultiline = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppLocalization.digitalFont(
            context,
            color: const Color(0xFF00E5FF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: isMultiline ? 4 : 1,
          style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF00E5FF))),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00E5FF), size: 16),
        const SizedBox(width: 12),
        Text(title.toUpperCase(),
            style: AppLocalization.digitalFont(context,
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
      ],
    );
  }
}
