import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import '../services/imgbb_service.dart';
import '../providers/app_provider.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? postToEdit;
  const CreatePostScreen({this.postToEdit, super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _codeController = TextEditingController();
  final List<dynamic> _images = [];
  bool _isUploading = false;
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    
    // Check post permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthController>(context, listen: false).currentUser;
      if (user != null && !user.canPost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.of(context)!.translate('posting_restricted'))),
        );
        Navigator.pop(context);
      }
    });

    if (widget.postToEdit != null) {
      final text = widget.postToEdit!.text;
      _images.addAll(widget.postToEdit!.images);
      _tags.addAll(widget.postToEdit!.tags);

      String body = text;

      // Parse Title
      if (text.startsWith('# ')) {
        final lines = text.split('\n');
        _titleController.text = lines.first.replaceFirst('# ', '').trim();
        body = lines.skip(1).join('\n').trim();
      }

      // Parse Code
      final codeMatch = RegExp(r'```(?:\w+)?\n([\s\S]*?)```').firstMatch(body);
      if (codeMatch != null) {
        _codeController.text = codeMatch.group(1)?.trim() ?? '';
        body = body.replaceFirst(codeMatch.group(0)!, '').trim();
      }

      _textController.text = body;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _images.add(File(pickedFile.path)));
  }

  void _submitPost() async {
    if (_textController.text.trim().isEmpty && _images.isEmpty) return;

    setState(() => _isUploading = true);
    final user =
        Provider.of<AuthController>(context, listen: false).currentUser!;
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

    String finalContent = _textController.text.trim();
    if (_titleController.text.isNotEmpty) {
      finalContent = "# ${_titleController.text}\n\n$finalContent";
    }
    if (_codeController.text.isNotEmpty) {
      finalContent = "$finalContent\n\n```python\n${_codeController.text}\n```";
    }

    if (widget.postToEdit != null) {
      final updatedPost = widget.postToEdit!.copyWith(
        text: finalContent,
        images: imageUrls,
        tags: _tags,
      );
      await postController.updatePost(updatedPost);
    } else {
      final post = PostModel(
        id: '',
        authorId: user.uid,
        authorName: user.name,
        authorProfileImage: user.profileImage,
        authorPosition: user.position,
        isAuthorVerified: user.isVerified,
        text: finalContent,
        images: imageUrls,
        tags: _tags,
        createdAt: DateTime.now(),
      );
      await postController.createPost(post);
    }

    if (mounted) Navigator.pop(context);
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    final locale = AppLocalization.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: Text(locale.translate('TAGS_LABEL'),
            style: AppLocalization.digitalFont(context, color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: locale.translate('ADD_TAG_PROMPT'),
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
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _tags.add(controller.text.trim().toUpperCase()));
              }
              Navigator.pop(context);
            },
            child: Text(locale.translate('ADD_ACTION'),
                style: const TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  void _showLinkDialog() {
    final textController = TextEditingController();
    final urlController = TextEditingController();
    final locale = AppLocalization.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: Text(locale.translate('INSERT_LINK'),
            style: AppLocalization.digitalFont(context, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: locale.translate('LINK_TEXT'),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3))),
            ),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: locale.translate('LINK_URL'),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.translate('cancel'),
                style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              final linkText = textController.text.trim();
              final linkUrl = urlController.text.trim();
              if (linkUrl.isNotEmpty) {
                final markdown = '[$linkText]($linkUrl)';
                final selection = _textController.selection;
                final newText = _textController.text.replaceRange(
                  selection.start == -1
                      ? _textController.text.length
                      : selection.start,
                  selection.end == -1
                      ? _textController.text.length
                      : selection.end,
                  markdown,
                );
                _textController.text = newText;
              }
              Navigator.pop(context);
            },
            child: Text(locale.translate('ADD_ACTION'),
                style: const TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  void _wrapSelection(String prefix, [String? suffix]) {
    final selection = _textController.selection;
    final text = _textController.text;
    
    if (selection.start == -1 || selection.end == -1) {
      final newText = text + prefix + (suffix ?? prefix);
      _textController.text = newText;
      return;
    }

    final selectedText = selection.textInside(text);
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText${suffix ?? prefix}',
    );
    _textController.text = newText;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.postToEdit != null
              ? locale.translate('edit_post').toUpperCase()
              : locale.translate('create_post').toUpperCase(),
          style: AppLocalization.digitalFont(context, 
            color: Colors.white.withOpacity(0.3),
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: _PublishButton(
                isLoading: _isUploading,
                onPressed: _submitPost,
                label: locale.translate('post_button').toUpperCase(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _SectionLabel(text: locale.translate('CLASSIFICATION_NAME')),
            TextField(
              controller: _titleController,
              cursorColor: const Color(0xFF00E5FF),
              style: AppLocalization.digitalFont(context, 
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: locale.translate('ENTRY_TITLE'),
                hintStyle: AppLocalization.digitalFont(context, 
                  color: Colors.white.withOpacity(0.05),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._tags.map((tag) => GestureDetector(
                    onLongPress: () => setState(() => _tags.remove(tag)),
                    child: _TagChip(text: tag))),
                _AddTagButton(
                    onPressed: _showAddTagDialog,
                    label: locale.translate('ADD_ACTION')),
              ],
            ),
            const SizedBox(height: 48),
            _SectionLabel(text: locale.translate('TECHNICAL_MANIFEST')),
            const SizedBox(height: 16),
            _buildEditorToolbar(),
            TextField(
              controller: _textController,
              maxLines: null,
              cursorColor: const Color(0xFF00E5FF),
              style: AppLocalization.digitalFont(context, 
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.7,
              ),
              decoration: InputDecoration(
                hintText: locale.translate('post_hint'),
                hintStyle: AppLocalization.digitalFont(context, 
                  color: Colors.white.withOpacity(0.1),
                  fontSize: 16,
                ),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 48),
            _SectionLabel(
                text: locale.translate('VISUAL_DOCUMENTATION')),
            const SizedBox(height: 20),
            _buildGraphicSection(locale),
            const SizedBox(height: 48),
            _SectionLabel(
                text: locale.translate('CODE_REPOSITORY')),
            const SizedBox(height: 20),
            _buildCodeEditor(locale),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorToolbar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ToolbarIcon(
              icon: Icons.format_bold_rounded,
              onPressed: () => _wrapSelection('**')),
          _ToolbarIcon(
              icon: Icons.format_italic_rounded,
              onPressed: () => _wrapSelection('*')),
          _ToolbarIcon(icon: Icons.link_rounded, onPressed: _showLinkDialog),
          _ToolbarIcon(
              icon: Icons.format_list_bulleted_rounded,
              onPressed: () => _wrapSelection('\n- ')),
          _ToolbarIcon(
              icon: Icons.code_rounded,
              isActive: true,
              onPressed: () => _wrapSelection('`')),
          Icon(Icons.help_outline_rounded,
              color: Colors.white.withOpacity(0.1), size: 18),
        ],
      ),
    );
  }

  Widget _buildGraphicSection(AppLocalization locale) {
    return Row(
      children: [
        if (_images.isEmpty)
          Expanded(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.04),
                      style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white.withOpacity(0.05), size: 36),
                    const SizedBox(height: 12),
                    Text(locale.translate('photo').toUpperCase(),
                        style: AppLocalization.digitalFont(context, 
                            color: Colors.white.withOpacity(0.15),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length + 1,
                itemBuilder: (context, index) {
                  if (index == _images.length) {
                    return GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Icon(Icons.add_rounded,
                            color: Colors.white.withOpacity(0.2)),
                      ),
                    );
                  }
                  final img = _images[index];
                  return Stack(
                    children: [
                      Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: img is String
                                ? NetworkImage(img)
                                : FileImage(img) as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCodeEditor(AppLocalization locale) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.03))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFF27C93F), shape: BoxShape.circle)),
                  ],
                ),
                Text(locale.translate('KERNEL_FILENAME'),
                    style: AppLocalization.digitalFont(context, 
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _codeController,
              maxLines: 8,
              cursorColor: const Color(0xFF00E5FF),
              style: GoogleFonts.sourceCodePro(
                  color: const Color(0xFF00E5FF).withOpacity(0.8),
                  fontSize: 13,
                  height: 1.6),
              decoration: InputDecoration(
                hintText: locale.translate('INSERT_CODE_HINT'),
                hintStyle: GoogleFonts.sourceCodePro(
                    color: Colors.white.withOpacity(0.05)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: AppLocalization.digitalFont(context, 
          color: const Color(0xFF00E5FF).withOpacity(0.4),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String label;
  const _PublishButton(
      {required this.isLoading, required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(label,
                  style: AppLocalization.digitalFont(context, 
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.12)),
      ),
      child: Text('#$text',
          style: AppLocalization.digitalFont(context, 
              color: const Color(0xFF00E5FF).withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w800)),
    );
  }
}

class _AddTagButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? label;
  const _AddTagButton({required this.onPressed, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white30, size: 12),
            const SizedBox(width: 6),
            Text(label ?? 'ADD',
                style: AppLocalization.digitalFont(context, 
                    color: Colors.white30,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  const _ToolbarIcon(
      {required this.icon, required this.onPressed, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon,
          color: isActive
              ? const Color(0xFF00E5FF)
              : Colors.white.withOpacity(0.2),
          size: 20),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
