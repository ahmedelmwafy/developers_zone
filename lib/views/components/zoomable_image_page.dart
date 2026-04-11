import 'package:flutter/material.dart';
import '../../widgets/app_cached_image.dart';

class ZoomableImagePage extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const ZoomableImagePage({required this.imageUrl, this.heroTag, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: heroTag != null
                  ? Hero(
                      tag: heroTag!,
                      child: AppCachedImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                      ),
                    )
                  : AppCachedImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
