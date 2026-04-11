import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'shimmer_component.dart';

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final bool isCircle;
  final BoxBorder? border;
  final Widget? child;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.isCircle = false,
    this.border,
    this.child,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildError(context);
    }

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => ShimmerComponent(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        borderRadius: isCircle ? (width ?? 40) / 2 : borderRadius,
      ),
      errorWidget: (context, url, error) => errorWidget ?? _buildError(context),
    );

    if (isCircle) {
      image = ClipOval(child: image);
    } else if (borderRadius > 0) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }

    if (border != null || child != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: border,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (child != null) child!,
          ],
        ),
      );
    }

    return image;
  }

  Widget _buildError(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white.withValues(alpha: 0.1),
        size: (width != null && width! < 30) ? 14 : 20,
      ),
    );
  }
}
