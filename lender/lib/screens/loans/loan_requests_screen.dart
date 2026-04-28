import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/loan_request_provider.dart';
import '../../widgets/loan_status_badge.dart';

class LoanRequestsScreen extends ConsumerStatefulWidget {
  const LoanRequestsScreen({super.key});

  @override
  ConsumerState<LoanRequestsScreen> createState() =>
      _LoanRequestsScreenState();
}

class _LoanRequestsScreenState extends ConsumerState<LoanRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incomingAsync = ref.watch(lenderRequestsProvider);
    final outgoingAsync = ref.watch(borrowerRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          incomingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (requests) {
              if (requests.isEmpty) {
                return const Center(
                    child: Text('No incoming requests yet.'));
              }
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, i) {
                  final r = requests[i];
                  return ListTile(
                    title: Text('Item: ${r.itemId}'),
                    subtitle: Text(
                        '${r.startDate.toDate().toLocal()} → ${r.endDate.toDate().toLocal()}'),
                    trailing: LoanStatusBadge(status: r.status),
                    onTap: () => context.push('/loans/${r.id}'),
                  );
                },
              );
            },
          ),
          outgoingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (requests) {
              if (requests.isEmpty) {
                return const Center(child: Text('No outgoing requests yet.'));
              }
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, i) {
                  final r = requests[i];
                  return ListTile(
                    title: Text('Item: ${r.itemId}'),
                    subtitle: Text(
                        '${r.startDate.toDate().toLocal()} → ${r.endDate.toDate().toLocal()}'),
                    trailing: LoanStatusBadge(status: r.status),
                    onTap: () => context.push('/loans/${r.id}'),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
