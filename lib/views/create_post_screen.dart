import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import '../services/imgbb_service.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? postToEdit;
  const CreatePostScreen({this.postToEdit, super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  final List<dynamic> _images = []; // Can be File or String (URL)
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.postToEdit != null) {
      _textController.text = widget.postToEdit!.text;
      _images.addAll(widget.postToEdit!.images);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _images.add(File(pickedFile.path)));
  }

  void _submitPost() async {
    if (_textController.text.trim().isEmpty && _images.isEmpty) return;

    setState(() => _isUploading = true);
    final user = Provider.of<AuthController>(context, listen: false).currentUser!;
    final postController = Provider.of<PostController>(context, listen: false);

    List<String> imageUrls = [];
    for (var img in _images) {
      if (img is String) {
        imageUrls.add(img);
      } else if (img is File) {
        final url = await ImgBBService.uploadImage(img);
        if (url != null) imageUrls.add(url);
      }
    }

    if (widget.postToEdit != null) {
      final updatedPost = widget.postToEdit!.copyWith(
        text: _textController.text.trim(),
        images: imageUrls,
      );
      await postController.updatePost(updatedPost);
    } else {
      final post = PostModel(
        id: '',
        authorId: user.uid,
        authorName: user.name,
        authorProfileImage: user.profileImage,
        authorPosition: user.position,
        text: _textController.text.trim(),
        images: imageUrls,
        createdAt: DateTime.now(),
      );
      await postController.createPost(post);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final user = Provider.of<AuthController>(context).currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.postToEdit != null ? locale.translate('edit_post') : locale.translate('create_post')),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _submitPost,
                icon: Icon(widget.postToEdit != null ? Icons.check : Icons.send, size: 16, color: AppColors.primary),
                label: Text(
                    widget.postToEdit != null ? locale.translate('update_button') : locale.translate('post_button'),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withValues(alpha: 0.06), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Author header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.cardLight,
                    backgroundImage: user?.profileImage.isNotEmpty == true ? NetworkImage(user!.profileImage) : null,
                    child: user?.profileImage.isEmpty != false ? const Icon(Icons.person, color: AppColors.textSecondary) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(user?.position ?? '', style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Text Input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _textController,
                maxLines: null,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.6),
                decoration: InputDecoration(
                  hintText: locale.translate('post_hint'),
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                ),
              ),
            ),
          ),
          // Image previews
          if (_images.isNotEmpty)
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _images.length + 1,
                itemBuilder: (context, i) {
                  if (i == _images.length) {
                    return GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 110,
                        height: 110,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                            const SizedBox(height: 4),
                            Text(locale.translate('add_more'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }
                  final img = _images[i];
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: img is String
                              ? Image.network(img, width: 110, height: 110, fit: BoxFit.cover)
                              : Image.file(img as File, width: 110, height: 110, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          // Toolbar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
            ),
            padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
            child: Row(
              children: [
                _ToolbarButton(
                  icon: Icons.image_outlined,
                  label: locale.translate('photo'),
                  onTap: _pickImage,
                ),
                const Spacer(),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (_, val, __) => Text(
                    locale.translate('chars_count').replaceFirst('{}', val.text.length.toString()),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolbarButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
