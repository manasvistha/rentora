import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light/light.dart';
import 'package:rentora/app/theme/theme_mode_provider.dart';
import 'package:rentora/core/services/storage/shared_prefs_service.dart';

class AmbientLightState {
  final bool isMonitoring;
  final bool sensorAvailable;
  final double? lux;
  final ThemeMode? suggestedMode;
  final String status;

  const AmbientLightState({
    required this.isMonitoring,
    required this.sensorAvailable,
    required this.lux,
    required this.suggestedMode,
    required this.status,
  });

  factory AmbientLightState.initial({required bool monitoring}) {
    return AmbientLightState(
      isMonitoring: monitoring,
      sensorAvailable: true,
      lux: null,
      suggestedMode: null,
      status: monitoring ? 'Waiting for sensor...' : 'Auto mode off',
    );
  }

  AmbientLightState copyWith({
    bool? isMonitoring,
    bool? sensorAvailable,
    double? lux,
    ThemeMode? suggestedMode,
    String? status,
  }) {
    return AmbientLightState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      sensorAvailable: sensorAvailable ?? this.sensorAvailable,
      lux: lux ?? this.lux,
      suggestedMode: suggestedMode ?? this.suggestedMode,
      status: status ?? this.status,
    );
  }
}

class AutoThemeByLightNotifier extends Notifier<bool> {
  static const _prefsKey = 'auto_theme_by_light_sensor';

  @override
  bool build() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      return prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(_prefsKey, enabled);
    } catch (_) {
      // Keep in-memory value even if persistence fails.
    }
  }
}

final autoThemeByLightProvider =
    NotifierProvider<AutoThemeByLightNotifier, bool>(
      AutoThemeByLightNotifier.new,
    );

class AmbientLightNotifier extends Notifier<AmbientLightState> {
  static const _darkThresholdLux = 35.0;
  static const _brightThresholdLux = 85.0;
  static const _applyDebounce = Duration(milliseconds: 1600);

  final Light _light = Light();
  StreamSubscription<int>? _subscription;
  Timer? _debounceTimer;
  ThemeMode? _pendingMode;

  @override
  AmbientLightState build() {
    final enabled = ref.watch(autoThemeByLightProvider);

    ref.onDispose(() {
      _subscription?.cancel();
      _debounceTimer?.cancel();
    });

    if (enabled) {
      _startListening();
      return AmbientLightState.initial(monitoring: true);
    }

    _stopListening();
    return AmbientLightState.initial(monitoring: false);
  }

  void _startListening() {
    if (_subscription != null) return;

    try {
      _subscription = _light.lightSensorStream.listen(
        (luxValue) {
          final lux = luxValue.toDouble();
          final suggested = _modeFromLux(lux);

          state = state.copyWith(
            isMonitoring: true,
            sensorAvailable: true,
            lux: lux,
            suggestedMode: suggested,
            status: 'Lux: ${lux.toStringAsFixed(1)}',
          );

          _scheduleThemeApply(suggested);
        },
        onError: (Object _) {
          state = state.copyWith(
            sensorAvailable: false,
            status: 'Ambient light sensor unavailable',
          );
        },
      );
    } catch (_) {
      state = state.copyWith(
        sensorAvailable: false,
        status: 'Ambient light sensor unavailable',
      );
    }
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingMode = null;
  }

  ThemeMode _modeFromLux(double lux) {
    final current = ref.read(themeModeProvider);

    // Hysteresis prevents noisy lux changes from flickering theme.
    if (current == ThemeMode.dark && lux < _brightThresholdLux) {
      return ThemeMode.dark;
    }
    if (current == ThemeMode.light && lux > _darkThresholdLux) {
      return ThemeMode.light;
    }

    return lux <= _darkThresholdLux ? ThemeMode.dark : ThemeMode.light;
  }

  void _scheduleThemeApply(ThemeMode mode) {
    if (_pendingMode == mode) return;

    _pendingMode = mode;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_applyDebounce, () {
      final autoEnabled = ref.read(autoThemeByLightProvider);
      if (!autoEnabled || _pendingMode == null) return;

      ref
          .read(themeModeProvider.notifier)
          .setThemeModeFromSensor(_pendingMode!);
    });
  }
}

final ambientLightProvider =
    NotifierProvider<AmbientLightNotifier, AmbientLightState>(
      AmbientLightNotifier.new,
    );
