import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../services/imgbb_service.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _positionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthController>(context, listen: false).currentUser!;
    _nameController.text = user.name;
    _bioController.text = user.bio;
    _positionController.text = user.position;
    _cityController.text = user.city;
    _countryController.text = user.country;
    _githubController.text = user.socialLinks?['github'] ?? '';
    _linkedinController.text = user.socialLinks?['linkedin'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _positionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  void _saveProfile() async {
    setState(() => _isSaving = true);
    final authController = Provider.of<AuthController>(context, listen: false);
    final firestoreService = FirestoreService();
    final user = authController.currentUser!;

    String? imageUrl = user.profileImage;
    if (_imageFile != null) {
      imageUrl = await ImgBBService.uploadImage(_imageFile!) ?? user.profileImage;
    }

    final updatedUser = user.copyWith(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      position: _positionController.text.trim(),
      city: _cityController.text.trim(),
      country: _countryController.text.trim(),
      profileImage: imageUrl,
      socialLinks: {
        'github': _githubController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
      },
    );

    await firestoreService.updateUser(updatedUser);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final user = Provider.of<AuthController>(context).currentUser!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppWidgets.appBar(
        locale.translate('edit_profile'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _saveProfile,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.cardLight,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) as ImageProvider : null),
                        child: (user.profileImage.isEmpty && _imageFile == null)
                            ? const Icon(Icons.person, size: 50, color: AppColors.textSecondary)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap to change photo', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 28),

            // Basic Info Section
            AppWidgets.sectionTitle('Basic Info'),
            _inputField(controller: _nameController, label: locale.translate('name'), icon: Icons.person_outline),
            _inputField(controller: _positionController, label: locale.translate('position'), icon: Icons.work_outline),
            _inputField(controller: _bioController, label: locale.translate('bio'), icon: Icons.notes, maxLines: 4),

            // Location Section
            AppWidgets.sectionTitle('Location'),
            _inputField(controller: _cityController, label: locale.translate('city'), icon: Icons.location_city_outlined),
            _inputField(controller: _countryController, label: locale.translate('country'), icon: Icons.flag_outlined),

            // Social Links Section
            AppWidgets.sectionTitle('Social Links'),
            _inputField(controller: _githubController, label: 'GitHub URL', icon: Icons.link),
            _inputField(controller: _linkedinController, label: 'LinkedIn URL', icon: Icons.work),

            const SizedBox(height: 16),
            AppWidgets.gradientButton(
              label: 'Save Changes',
              onPressed: _isSaving ? null : _saveProfile,
              isLoading: _isSaving,
              icon: Icons.check,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: AppWidgets.fieldDecoration(label, prefixIcon: icon),
      ),
    );
  }
}
