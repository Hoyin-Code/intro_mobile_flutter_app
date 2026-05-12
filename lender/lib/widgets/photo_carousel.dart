import 'package:flutter/material.dart';

class PhotoCarousel extends StatelessWidget {
  const PhotoCarousel({
    super.key,
    required this.photoUrls,
    this.height = 220,
  });

  final List<String> photoUrls;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: photoUrls.length,
        itemBuilder: (_, i) => Image.network(
          photoUrls[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Icon(
              Icons.image_outlined,
              color: Colors.grey,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
