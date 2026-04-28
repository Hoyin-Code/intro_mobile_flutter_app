import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_request_model.dart';
import '../services/loan_request_service.dart';
import 'auth_provider.dart';

final loanRequestServiceProvider =
    Provider<LoanRequestService>((ref) => LoanRequestService());

// Requests where the current user is the lender (incoming requests)
final lenderRequestsProvider = StreamProvider<List<LoanRequestModel>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return const Stream.empty();
  return ref.watch(loanRequestServiceProvider).getRequestsForLender(userId);
});

// Requests where the current user is the borrower (outgoing requests)
final borrowerRequestsProvider = StreamProvider<List<LoanRequestModel>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return const Stream.empty();
  return ref.watch(loanRequestServiceProvider).getRequestsForBorrower(userId);
});
