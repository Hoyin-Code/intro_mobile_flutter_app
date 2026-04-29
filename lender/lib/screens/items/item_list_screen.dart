import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../models/item_model.dart';
import '../../providers/distance_filter_provider.dart';
import '../../providers/items_provider.dart';
import '../../widgets/distance_filter_sheet.dart';
import '../../widgets/item_card.dart';

enum _SortOrder { alphabetical, newest, priceLow, priceHigh }

class ItemListScreen extends ConsumerStatefulWidget {
  const ItemListScreen({super.key});

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  String? _selectedCategory;
  _SortOrder _sortOrder = _SortOrder.newest;

  static const _distance = Distance();

  List<ItemModel> _applyFilters(
      List<ItemModel> items, DistanceFilter? distanceFilter) {
    var result = _selectedCategory == null
        ? List<ItemModel>.from(items)
        : items.where((i) => i.category == _selectedCategory).toList();

    if (distanceFilter != null) {
      result = result.where((item) {
        final km = _distance.as(
          LengthUnit.Kilometer,
          distanceFilter.center,
          item.address.latLng,
        );
        return km <= distanceFilter.radiusKm;
      }).toList();
    }

    switch (_sortOrder) {
      case _SortOrder.alphabetical:
        result.sort((a, b) => a.title.compareTo(b.title));
      case _SortOrder.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortOrder.priceLow:
        result.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
      case _SortOrder.priceHigh:
        result.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
    }
    return result;
  }

  String get _sortLabel => switch (_sortOrder) {
        _SortOrder.alphabetical => 'Alphabetical',
        _SortOrder.newest => 'Newest first',
        _SortOrder.priceLow => 'Price: low to high',
        _SortOrder.priceHigh => 'Price: high to low',
      };

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _SortOrder.values
              .map(
                (order) => RadioListTile<_SortOrder>(
                  value: order,
                  groupValue: _sortOrder,
                  title: Text(_labelFor(order)),
                  onChanged: (val) {
                    setState(() => _sortOrder = val!);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showDistanceFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const DistanceFilterSheet(),
    );
  }

  String _labelFor(_SortOrder order) => switch (order) {
        _SortOrder.alphabetical => 'Alphabetical',
        _SortOrder.newest => 'Newest first',
        _SortOrder.priceLow => 'Price: low to high',
        _SortOrder.priceHigh => 'Price: high to low',
      };

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);
    final distanceFilter = ref.watch(distanceFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final categories = (items.map((i) => i.category).toSet().toList()
            ..sort());
          final filtered = _applyFilters(items, distanceFilter);
          final distances = distanceFilter == null
              ? null
              : {
                  for (final item in filtered)
                    item.id: _distance.as(
                      LengthUnit.Kilometer,
                      distanceFilter.center,
                      item.address.latLng,
                    ),
                };

          return Column(
            children: [
              _CategoryBar(
                categories: categories,
                selected: _selectedCategory,
                onSelect: (cat) => setState(() => _selectedCategory = cat),
              ),
              _SortLocationRow(
                sortLabel: _sortLabel,
                onSortTap: _showSortSheet,
                onLocationTap: _showDistanceFilterSheet,
                distanceFilter: distanceFilter,
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No items found.'))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => ItemCard(
                          item: filtered[index],
                          distanceKm: distances?[filtered[index].id],
                          onTap: () =>
                              context.push('/items/${filtered[index].id}'),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _CategoryChip(
            label: 'All',
            isSelected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final cat in categories)
            _CategoryChip(
              label: cat,
              isSelected: selected == cat,
              onTap: () => onSelect(cat),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? color : Colors.grey[700],
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortLocationRow extends StatelessWidget {
  const _SortLocationRow({
    required this.sortLabel,
    required this.onSortTap,
    required this.onLocationTap,
    this.distanceFilter,
  });

  final String sortLabel;
  final VoidCallback onSortTap;
  final VoidCallback onLocationTap;
  final DistanceFilter? distanceFilter;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final isActive = distanceFilter != null;
    final locationLabel = isActive
        ? 'Within ${distanceFilter!.radiusKm.round()} km'
        : 'Location';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onSortTap,
            child: Row(
              children: [
                Icon(Icons.swap_vert, size: 18, color: color),
                const SizedBox(width: 4),
                Text(
                  sortLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onLocationTap,
            child: Container(
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
                  : EdgeInsets.zero,
              decoration: isActive
                  ? BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    )
                  : null,
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.location_on : Icons.location_on_outlined,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locationLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
