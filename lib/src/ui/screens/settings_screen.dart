import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../providers/notification_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final notifications = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('settings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.t('language'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<Locale>(
                    value: settings.locale,
                    onChanged: (locale) {
                      if (locale != null) {
                        settings.setLocale(locale);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: Locale('pt', 'BR'),
                        child: Text('Portugues (Brasil)'),
                      ),
                      DropdownMenuItem(
                        value: Locale('en', 'US'),
                        child: Text('English (US)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.t('theme_mode'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: settings.themeMode,
                    onChanged: (mode) {
                      if (mode != null) settings.setThemeMode(mode);
                    },
                    title: Text(t.t('theme_system')),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: settings.themeMode,
                    onChanged: (mode) {
                      if (mode != null) settings.setThemeMode(mode);
                    },
                    title: Text(t.t('theme_light')),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: settings.themeMode,
                    onChanged: (mode) {
                      if (mode != null) settings.setThemeMode(mode);
                    },
                    title: Text(t.t('theme_dark')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(t.t('notifications')),
                  subtitle: Text(t.t('notifications_desc')),
                  value: notifications.hydrationEnabled,
                  onChanged: (value) =>
                      notifications.toggleHydration(value),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Lembretes de refeições'),
                  subtitle: const Text('Cafe, almoço e jantar'),
                  value: notifications.mealReminderEnabled,
                  onChanged: (value) =>
                      notifications.toggleMealReminder(value),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: Text(t.t('privacy_mode')),
                  subtitle: Text(t.t('privacy_mode_desc')),
                  value: settings.privacyMode,
                  onChanged: settings.togglePrivacyMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
