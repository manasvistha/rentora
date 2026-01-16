import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project Imports
import 'package:rentora/app/app.dart';
import 'package:rentora/core/services/hive/hive_service.dart';

// --- Provider Definitions ---
// These are defined globally. We use UnimplementedError because
// we will override them in the ProviderScope below.

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError();
});

// --- Main Entry Point ---

void main() async {
  // 1. Ensure Flutter framework is ready for async calls
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();

  // 3. Initialize Hive
  final hiveService = HiveService();
  await hiveService.init();

  runApp(
    // 4. Wrap the app in ProviderScope for Riverpod
    ProviderScope(
      overrides: [
        // Inject the instances we just initialized
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        hiveServiceProvider.overrideWithValue(hiveService),
      ],
      child: const App(),
    ),
  );
}
