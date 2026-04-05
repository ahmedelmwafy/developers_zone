import 'package:flutter/material.dart';
import '../views/components/zoomable_image_page.dart';
import '../widgets/shimmer_component.dart';

class PostMediaWidget extends StatefulWidget {
  final List<String> images;
  final String postId;
  final double height;
  final double borderRadius;

  const PostMediaWidget({
    required this.images,
    required this.postId,
    this.height = 250,
    this.borderRadius = 16,
    super.key,
  });

  @override
  State<PostMediaWidget> createState() => _PostMediaWidgetState();
}

class _PostMediaWidgetState extends State<PostMediaWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: widget.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = widget.images[index];
                    final heroTag = 'media_${widget.postId}_${imageUrl.hashCode}_$index';
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ZoomableImagePage(
                              imageUrl: imageUrl,
                              heroTag: heroTag,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: heroTag,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return ShimmerComponent(
                              width: double.infinity,
                              height: widget.height,
                              borderRadius: widget.borderRadius,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.red.withValues(alpha: 0.1),
                              child: const Icon(Icons.error_outline, color: Colors.red),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      widget.images.length,
                      (index) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? const Color(0xFF00E5FF)
                              : Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.images.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
