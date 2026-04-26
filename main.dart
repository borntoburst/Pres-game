import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'utils/app_theme.dart';
import 'utils/score_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait for better kid UX
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ScoreProvider(),
      child: const PreschoolGamesApp(),
    ),
  );
}

class PreschoolGamesApp extends StatelessWidget {
  const PreschoolGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Games',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
