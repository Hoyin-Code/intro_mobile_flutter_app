import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/items_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loan_request_sheet.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return itemsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (items) {
        final item = items.where((i) => i.id == itemId).firstOrNull;
        if (item == null) {
          return const Scaffold(body: Center(child: Text('Item not found.')));
        }

        final isOwner = currentUser?.uid == item.ownerId;

        return Scaffold(
          appBar: AppBar(title: Text(item.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (item.photoUrls.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    itemCount: item.photoUrls.length,
                    itemBuilder: (context, i) => Image.network(
                      item.photoUrls[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(item.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('€${item.pricePerDay.toStringAsFixed(2)} / day',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                      '${item.averageRating.toStringAsFixed(1)} (${item.totalReviews} reviews)'),
                ],
              ),
              const SizedBox(height: 16),
              Text(item.description),
              const SizedBox(height: 8),
              Text('Condition: ${item.condition.name}',
                  style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 32),
              _SellerRow(ownerId: item.ownerId),
            ],
          ),
          bottomNavigationBar: isOwner
              ? null
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: item.isAvailable
                        ? () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              builder: (_) => LoanRequestSheet(
                                item: item,
                                borrowerId: currentUser!.uid,
                              ),
                            )
                        : null,
                    child: Text(
                        item.isAvailable ? 'Request to Borrow' : 'Unavailable'),
                  ),
                ),
        );
      },
    );
  }
}

class _SellerRow extends ConsumerWidget {
  const _SellerRow({required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider(ownerId));
    final color = Theme.of(context).colorScheme.primary;

    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(initial,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700))
                : null,
          ),
          title: Text(user.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 3),
              Text(
                '${user.averageRating.toStringAsFixed(1)} · ${user.totalReviews} reviews',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: TextButton(
            onPressed: () => context.push('/profile/user/$ownerId'),
            child: const Text('View profile'),
          ),
        );
      },
    );
  }
}
