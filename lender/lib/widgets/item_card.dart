import 'package:flutter/material.dart';

import '../models/item_model.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.distanceKm,
  });

  final ItemModel item;
  final VoidCallback onTap;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.photoUrls.isNotEmpty
                  ? Image.network(
                      item.photoUrls.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _Placeholder(),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : const _Placeholder(),
                    )
                  : const _Placeholder(),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            "Price: €${item.pricePerDay}/day",
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          Text(
            distanceKm != null
                ? _formatDistance(distanceKm!)
                : _relativeTime(item.createdAt.toDate()),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(1)} km away';
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Updated today';
    if (diff.inDays == 1) return 'Updated yesterday';
    return 'Updated ${diff.inDays} days ago';
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.grey, size: 32),
      ),
    );
  }
}
