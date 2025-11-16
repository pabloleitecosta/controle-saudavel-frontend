import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('settings_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text(t.t('language')),
              trailing: DropdownButton<Locale>(
                value: settings.locale,
                onChanged: (locale) {
                  if (locale != null) {
                    settings.setLocale(locale);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: Locale('pt', 'BR'),
                    child: Text('Português (Brasil)'),
                  ),
                  DropdownMenuItem(
                    value: Locale('en', 'US'),
                    child: Text('English (US)'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
