import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/add_location_sheet.dart';
import '../../widgets/item_card.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final myItemsAsync = ref.watch(myItemsProvider);
    final locationsAsync = ref.watch(userLocationsProvider);
    final firestoreUser = user != null
        ? ref.watch(userDataProvider(user.uid)).value
        : null;

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
            child: UserAvatar(
              name: firestoreUser?.name ?? user?.email ?? '',
              photoUrl: firestoreUser?.photoUrl,
              radius: 40,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(firestoreUser?.name ?? user?.email ?? '')),
          const Divider(height: 32),

          // ── My Locations ──────────────────────────────────────────────
          Row(
            children: [
              Text('My Locations',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => AddLocationSheet(onSaved: (_) {}),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          locationsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (locations) {
              if (locations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No saved locations yet.'),
                );
              }
              return Column(
                children: locations.map((loc) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => context.push(
                        '/profile/location',
                        extra: loc,
                      ),
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(loc.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${loc.street}, ${loc.postalCode} ${loc.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                          Icons.chevron_right, size: 18,
                          color: Colors.grey),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const Divider(height: 32),

          // ── My Listings ───────────────────────────────────────────────
          Text('My Listings',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          myItemsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (items) {
              if (items.isEmpty) {
                return const Text('You have no listings yet.');
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => ItemCard(
                  item: items[i],
                  onTap: () => context.push('/items/${items[i].id}'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
