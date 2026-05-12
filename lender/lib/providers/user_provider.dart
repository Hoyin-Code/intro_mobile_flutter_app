import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final userNameProvider = FutureProvider.family<String, String>((ref, userId) async {
  final user = await ref.watch(userServiceProvider).getUserOnce(userId);
  return user?.name ?? 'Unknown';
});

final userDataProvider = FutureProvider.family<UserModel?, String>((ref, userId) {
  return ref.watch(userServiceProvider).getUserOnce(userId);
});
