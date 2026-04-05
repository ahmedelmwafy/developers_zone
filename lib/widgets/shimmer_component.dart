import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerComponent extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerComponent({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF161616),
        highlightColor: const Color(0xFF242424),
        period: const Duration(milliseconds: 1500),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }

  static Widget listShimmer({int count = 5}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerComponent(width: 40, height: 40, borderRadius: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerComponent(width: 120, height: 12),
                    const SizedBox(height: 6),
                    ShimmerComponent(width: 80, height: 8),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            ShimmerComponent(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            ShimmerComponent(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            ShimmerComponent(width: 200, height: 16),
            const SizedBox(height: 24),
            ShimmerComponent(width: double.infinity, height: 180, borderRadius: 16),
          ],
        ),
      ),
    );
  }

  static Widget circleShimmer({double size = 40}) {
    return ShimmerComponent(width: size, height: size, borderRadius: size / 2);
  }

  static Widget userTileShimmer({int count = 6}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            ShimmerComponent(width: 60, height: 60, borderRadius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerComponent(width: 120, height: 14),
                  const SizedBox(height: 8),
                  ShimmerComponent(width: 200, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

