import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:rentora/app.dart';
import 'package:rentora/core/injection/injection.dart';
import 'package:rentora/core/services/hive/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  configureDependencies();

  // ✅ INIT HIVE ONCE BEFORE UI
  await GetIt.I<HiveService>().init();

  runApp(const App());
}
