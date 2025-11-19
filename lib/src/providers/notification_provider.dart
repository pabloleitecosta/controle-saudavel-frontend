import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  bool _hydrationEnabled = false;
  bool _mealReminderEnabled = false;

  bool get hydrationEnabled => _hydrationEnabled;
  bool get mealReminderEnabled => _mealReminderEnabled;

  Future<void> initialize() async {
    await NotificationService.instance.init();
  }

  Future<void> toggleHydration(bool value) async {
    _hydrationEnabled = value;
    notifyListeners();
    if (value) {
      await NotificationService.instance.scheduleDailyReminder(
        id: 100,
        time: const TimeOfDay(hour: 10, minute: 0),
        title: 'Hora de se hidratar',
        body: 'Beba um copo de água para manter o corpo saudável.',
      );
      await NotificationService.instance.scheduleDailyReminder(
        id: 101,
        time: const TimeOfDay(hour: 15, minute: 0),
        title: 'Hidratação da tarde',
        body: 'Lembrete amigável para beber água.',
      );
    } else {
      await NotificationService.instance.cancelReminder(100);
      await NotificationService.instance.cancelReminder(101);
    }
  }

  Future<void> toggleMealReminder(bool value) async {
    _mealReminderEnabled = value;
    notifyListeners();
    if (value) {
      await NotificationService.instance.scheduleDailyReminder(
        id: 200,
        time: const TimeOfDay(hour: 8, minute: 0),
        title: 'Café da manhã',
        body: 'Registre seu café da manhã e mantenha o foco!',
      );
      await NotificationService.instance.scheduleDailyReminder(
        id: 201,
        time: const TimeOfDay(hour: 12, minute: 30),
        title: 'Almoço',
        body: 'Como foi sua refeição? Registre agora mesmo.',
      );
      await NotificationService.instance.scheduleDailyReminder(
        id: 202,
        time: const TimeOfDay(hour: 19, minute: 0),
        title: 'Jantar',
        body: 'Registrar seu jantar ajuda a manter o controle.',
      );
    } else {
      await NotificationService.instance.cancelReminder(200);
      await NotificationService.instance.cancelReminder(201);
      await NotificationService.instance.cancelReminder(202);
    }
  }
}
