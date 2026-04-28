import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../widgets/item_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final myItemsAsync = ref.watch(myItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(user?.email ?? '')),
          const Divider(height: 32),
          Text('My Listings',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          myItemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (items) {
              if (items.isEmpty) {
                return const Text('You have no listings yet.');
              }
              return Column(
                children: items
                    .map((item) => ItemCard(
                          item: item,
                          onTap: () => context.push('/items/${item.id}'),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
