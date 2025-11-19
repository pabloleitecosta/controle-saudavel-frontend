import 'package:controle_saudavel/src/ui/screens/add_meal_manual_screen.dart';
import 'package:controle_saudavel/src/ui/screens/profile_goals_screen.dart';
import 'package:controle_saudavel/src/ui/screens/recipe_create_screen.dart';
import 'package:controle_saudavel/src/ui/screens/recipe_list_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'src/core/i18n.dart';
import 'src/core/theme.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/settings_provider.dart';
import 'src/services/auth_service.dart';
import 'src/ui/screens/add_meal_screen.dart';
import 'src/ui/screens/community_screen.dart';
import 'src/ui/screens/home_screen.dart';
import 'src/ui/screens/login_screen.dart';
import 'src/ui/screens/photo_recognition_screen.dart';
import 'src/ui/screens/profile_screen.dart';
import 'src/ui/screens/settings_screen.dart';
import 'src/ui/screens/signup_screen.dart';
import 'src/ui/screens/stats_screen.dart';
import 'src/ui/screens/create_post_screen.dart';
import 'src/ui/screens/recipe_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ControleSaudavelApp());
}

class ControleSaudavelApp extends StatelessWidget {
  const ControleSaudavelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Controle Saudável',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: const [
              Locale('pt', 'BR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: LoginScreen.route,
            routes: {
              LoginScreen.route: (_) => const LoginScreen(),
              SignupScreen.route: (_) => const SignupScreen(),
              HomeScreen.route: (_) => const HomeScreen(),
              AddMealScreen.route: (_) => const AddMealScreen(),
              AddMealManualScreen.route: (_) =>
                  const AddMealManualScreen(),
              PhotoRecognitionScreen.route: (_) =>
                  const PhotoRecognitionScreen(),
              StatsScreen.route: (_) => const StatsScreen(),
              ProfileScreen.route: (_) => const ProfileScreen(),
              SettingsScreen.route: (_) => const SettingsScreen(),
              CommunityScreen.route: (_) => const CommunityScreen(),
              CreatePostScreen.route: (_) => const CreatePostScreen(),
              ProfileGoalsScreen.route: (_) => const ProfileGoalsScreen(),
              RecipeListScreen.route: (_) => const RecipeListScreen(),
              RecipeCreateScreen.route: (_) => const RecipeCreateScreen(),
              RecipeDetailScreen.route: (context) {
                    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                    return RecipeDetailScreen(recipeId: args['id'] as String);
              },
            },
          );
        },
      ),
    );
  }
}
