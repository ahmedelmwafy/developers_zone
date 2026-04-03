import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../services/imgbb_service.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';

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

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate('edit_profile')),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(10.0), child: CircularProgressIndicator()))
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _saveProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : NetworkImage(Provider.of<AuthController>(context).currentUser!.profileImage) as ImageProvider,
                child: const Align(alignment: Alignment.bottomRight, child: CircleAvatar(radius: 15, backgroundColor: Color(0xFF673AB7), child: Icon(Icons.camera_alt, size: 15))),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: locale.translate('name'), labelStyle: const TextStyle(color: Colors.grey))),
            TextField(controller: _positionController, decoration: InputDecoration(labelText: locale.translate('position'), labelStyle: const TextStyle(color: Colors.grey))),
            TextField(controller: _bioController, decoration: InputDecoration(labelText: locale.translate('bio'), labelStyle: const TextStyle(color: Colors.grey)), maxLines: null),
            TextField(controller: _cityController, decoration: InputDecoration(labelText: locale.translate('city'), labelStyle: const TextStyle(color: Colors.grey))),
            TextField(controller: _countryController, decoration: InputDecoration(labelText: locale.translate('country'), labelStyle: const TextStyle(color: Colors.grey))),
            const SizedBox(height: 10),
            TextField(controller: _githubController, decoration: const InputDecoration(labelText: 'GitHub URL', labelStyle: TextStyle(color: Colors.grey))),
            TextField(controller: _linkedinController, decoration: const InputDecoration(labelText: 'LinkedIn URL', labelStyle: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
