import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import '../services/imgbb_service.dart';
import '../providers/app_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  final List<File> _images = [];
  bool _isUploading = false;

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _images.add(File(pickedFile.path)));
    }
  }

  void _createPost() async {
    if (_textController.text.trim().isEmpty && _images.isEmpty) return;

    setState(() => _isUploading = true);
    final user = Provider.of<AuthController>(context, listen: false).currentUser!;
    final postController = Provider.of<PostController>(context, listen: false);

    List<String> imageUrls = [];
    for (var img in _images) {
      final url = await ImgBBService.uploadImage(img);
      if (url != null) imageUrls.add(url);
    }

    final post = PostModel(
      id: '', // Will be generated
      authorId: user.uid,
      authorName: user.name,
      authorProfileImage: user.profileImage,
      authorPosition: user.position,
      text: _textController.text.trim(),
      images: imageUrls,
      createdAt: DateTime.now(),
    );

    await postController.createPost(post);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate('create_post')),
        actions: [
          if (_isUploading)
            const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
          else
            IconButton(icon: const Icon(Icons.send), onPressed: _createPost),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: null,
              decoration: InputDecoration(hintText: 'What is on your mind as a developer?', hintStyle: const TextStyle(color: Colors.grey)),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [
                ..._images.map((img) => Stack(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(img, width: 100, height: 100, fit: BoxFit.cover)),
                    Positioned(right: 0, top: 0, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => setState(() => _images.remove(img)))),
                  ],
                )),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add_a_photo, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
