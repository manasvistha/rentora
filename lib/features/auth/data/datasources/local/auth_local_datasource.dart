import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/services/hive/hive_service.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';
import 'package:rentora/features/auth/data/datasources/auth_datasource.dart';
import 'package:rentora/features/auth/data/models/auth_hive_model.dart';

// Provider returns the Interface to avoid type-cast errors in Repository
final authLocalDataSourceProvider = Provider<IAuthLocalDataSource>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  final userSessionService = ref.read(userSessionServiceProvider);
  return AuthLocalDataSource(
    hiveService: hiveService,
    userSessionService: userSessionService,
  );
});

class AuthLocalDataSource implements IAuthLocalDataSource {
  final HiveService _hiveService;
  final UserSessionService _userSessionService;

  AuthLocalDataSource({
    required HiveService hiveService,
    required UserSessionService userSessionService,
  }) : _hiveService = hiveService,
       _userSessionService = userSessionService;

  @override
  Future<AuthHiveModel> register(AuthHiveModel user) async {
    await _hiveService.register(user);
    return user;
  }

  @override
  Future<AuthHiveModel?> login(String email, String password) async {
    // 1. Verify credentials via Hive
    final user = await _hiveService.login(email, password);

    if (user != null) {
      // 2. Persist the session using your UserSessionService
      await _userSessionService.saveUserSession(
        userId: user.id, // Matches 'userId' in your service
        email: user.email,
        name: user.name,
        token: 'OFFLINE_LOCAL_TOKEN', // Temporary token for offline state
      );
    }
    return user;
  }

  @override
  Future<AuthHiveModel?> getCurrentUser() async {
    // Get the ID from the session service first
    final session = await _userSessionService.getUserSession();
    final userId = session['id'];

    if (userId == null) return null;

    // Fetch full object from Hive
    return await _hiveService.getUserById(userId);
  }

  @override
  Future<bool> logOut() async {
    try {
      await _userSessionService
          .deleteSession(); // Using your service's delete method
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AuthHiveModel?> getUserById(String id) async {
    return await _hiveService.getUserById(id);
  }

  @override
  Future<AuthHiveModel?> getUserByEmail(String email) async {
    return await _hiveService.getUserByEmail(email);
  }

  @override
  Future<bool> updateUser(AuthHiveModel user) async {
    try {
      await _hiveService.updateUser(user);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteUser(String id) async {
    try {
      await _hiveService.deleteUser(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
