import 'package:flutter/material.dart';
import '../../core/i18n.dart';

class AddMealScreen extends StatelessWidget {
  static const route = '/meal/add';
  const AddMealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('add_meal')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/meal/add/manual');
              },
              icon: const Icon(Icons.edit),
              label: Text(t.t('add_meal_manual')),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/meal/photo');
              },
              icon: const Icon(Icons.camera_alt),
              label: Text(t.t('add_meal_photo')),
            ),
          ],
        ),
      ),
    );
  }
}
