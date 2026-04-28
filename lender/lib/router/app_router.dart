import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/items/add_item_screen.dart';
import '../screens/items/item_detail_screen.dart';
import '../screens/items/item_list_screen.dart';
import '../screens/loans/loan_detail_screen.dart';
import '../screens/loans/loan_requests_screen.dart';
import '../screens/profile/profile_screen.dart';

// Converts the auth stream into a ChangeNotifier so go_router can react to
// sign-in / sign-out events and re-evaluate the redirect guard.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final notifier =
      _AuthNotifier(ref.watch(authServiceProvider).authStateChanges);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/items',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/signup';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/items';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),

      // Shell wraps all main tabs — bottom nav bar stays visible everywhere
      // including on nested detail screens (item detail, loan detail, etc.)
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => HomeScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/items',
                builder: (_, __) => const ItemListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, __) => const AddItemScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => ItemDetailScreen(
                        itemId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/loans',
                builder: (_, __) => const LoanRequestsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => LoanDetailScreen(
                        loanRequestId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
