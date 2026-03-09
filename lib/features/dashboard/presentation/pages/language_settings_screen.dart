import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/app/localization/locale_provider.dart';
import 'package:rentora/app/theme/ambient_light_provider.dart';
import 'package:rentora/app/theme/theme_mode_provider.dart';
import 'package:rentora/core/localization/app_localizations.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocale = ref.watch(localeProvider);
    final selectedThemeMode = ref.watch(themeModeProvider);
    final autoThemeByLight = ref.watch(autoThemeByLightProvider);
    final ambientLightState = ref.watch(ambientLightProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F5),
      appBar: AppBar(
        title: Text(context.tr('settings')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F3D3D),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Auto theme by light sensor',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Switch to dark in low light and light in bright light',
                ),
                value: autoThemeByLight,
                onChanged: (value) {
                  ref.read(autoThemeByLightProvider.notifier).setEnabled(value);
                },
              ),
              if (autoThemeByLight) ...[
                const SizedBox(height: 8),
                _AmbientLightStatusCard(state: ambientLightState),
                const SizedBox(height: 20),
              ],
              Text(
                context.tr('theme'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('selectThemeMode'),
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              _ThemeModeCard(
                title: context.tr('lightMode'),
                value: ThemeMode.light,
                groupValue: selectedThemeMode,
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  }
                },
              ),
              const SizedBox(height: 12),
              _ThemeModeCard(
                title: context.tr('darkMode'),
                value: ThemeMode.dark,
                groupValue: selectedThemeMode,
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  }
                },
              ),
              const SizedBox(height: 12),
              _ThemeModeCard(
                title: context.tr('systemDefault'),
                value: ThemeMode.system,
                groupValue: selectedThemeMode,
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('language'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('selectLanguage'),
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              _LanguageCard(
                title: context.tr('english'),
                value: 'en',
                groupValue: selectedLocale.languageCode,
                onChanged: (code) {
                  if (code != null) {
                    ref.read(localeProvider.notifier).setLanguageCode(code);
                  }
                },
              ),
              const SizedBox(height: 12),
              _LanguageCard(
                title: context.tr('nepali'),
                value: 'ne',
                groupValue: selectedLocale.languageCode,
                onChanged: (code) {
                  if (code != null) {
                    ref.read(localeProvider.notifier).setLanguageCode(code);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientLightStatusCard extends StatelessWidget {
  const _AmbientLightStatusCard({required this.state});

  final AmbientLightState state;

  String _modeLabel(ThemeMode? mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
      case null:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ambient Light Monitor',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('Current lux: ${state.lux?.toStringAsFixed(1) ?? '-'}'),
          const SizedBox(height: 4),
          Text('Suggested mode: ${_modeLabel(state.suggestedMode)}'),
          const SizedBox(height: 4),
          Text('Status: ${state.status}'),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: const Color(0xFF2F9E9A),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: RadioListTile<ThemeMode>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: const Color(0xFF2F9E9A),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }
}
