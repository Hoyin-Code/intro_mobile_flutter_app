import '../../utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/loan_request_model.dart';
import '../../providers/loan_request_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_avatar.dart';
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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lenderAsync   = ref.watch(lenderRequestsProvider);
    final borrowerAsync = ref.watch(borrowerRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.inbox_outlined),        text: 'Inbox'),
            Tab(icon: Icon(Icons.check_circle_outline),  text: 'Ready'),
            Tab(icon: Icon(Icons.send_outlined),         text: 'Sent'),
            Tab(icon: Icon(Icons.swap_horiz),            text: 'Active'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Incoming: pending / rejected requests ────────────────────
          lenderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (all) {
              final requests = all
                  .where((r) => r.status == LoanStatus.pending ||
                      r.status == LoanStatus.rejected)
                  .toList()
                ..sort((a, b) {
                  if (a.status == b.status) return 0;
                  if (a.status == LoanStatus.rejected) return 1;
                  return -1;
                });
              if (requests.isEmpty) {
                return const Center(child: Text('No incoming requests.'));
              }
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (_, i) => _LoanRequestTile(
                  request: requests[i],
                  showBorrower: true,
                ),
              );
            },
          ),

          // ── Pick Up: accepted, waiting to be handed over ─────────────
          lenderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (all) {
              final pickup = all
                  .where((r) => r.status == LoanStatus.accepted)
                  .toList();
              if (pickup.isEmpty) {
                return const Center(child: Text('No items ready for pick up.'));
              }
              return ListView.builder(
                itemCount: pickup.length,
                itemBuilder: (_, i) => _LoanRequestTile(
                  request: pickup[i],
                  showBorrower: true,
                ),
              );
            },
          ),

          // ── My Requests: me requesting from others ───────────────────
          borrowerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (requests) {
              if (requests.isEmpty) {
                return const Center(child: Text('No outgoing requests.'));
              }
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (_, i) => _LoanRequestTile(
                  request: requests[i],
                  showBorrower: false,
                ),
              );
            },
          ),

          // ── Outgoing: my items currently being lent out ──────────────
          lenderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (all) {
              final active = all
                  .where((r) => r.status == LoanStatus.active ||
                      r.status == LoanStatus.returned)
                  .toList();
              if (active.isEmpty) {
                return const Center(
                    child: Text('No active lends at the moment.'));
              }
              return ListView.builder(
                itemCount: active.length,
                itemBuilder: (_, i) => _LoanRequestTile(
                  request: active[i],
                  showBorrower: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LoanRequestTile extends ConsumerWidget {
  const _LoanRequestTile({
    required this.request,
    required this.showBorrower,
  });

  final LoanRequestModel request;
  final bool showBorrower;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId    = showBorrower ? request.borrowerId : request.lenderId;
    final nameAsync = ref.watch(userNameProvider(userId));
    final label     = showBorrower ? 'Requested by' : 'Lending from';
    final color     = Theme.of(context).colorScheme.primary;

    final name = nameAsync.when(
      data: (n) => n,
      loading: () => '…',
      error: (_, __) => 'Unknown',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/loans/${request.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        UserAvatar(name: name, radius: 16),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    LoanStatusBadge(status: request.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.formatRange(request.startDate, request.endDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '€${request.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
