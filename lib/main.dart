import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() => runApp(const PharmacyApp());

class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Эмийн сан',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // Backspace/Delete товчнуудыг Navigator-ийн "go back" shortcut-аас
        // чөлөөлж, TextField дотор зөв ажиллуулна.
        shortcuts: <ShortcutActivator, Intent>{
          ...WidgetsApp.defaultShortcuts,
          const SingleActivator(LogicalKeyboardKey.backspace):
              const DoNothingAndStopPropagationTextIntent(),
          const SingleActivator(LogicalKeyboardKey.delete):
              const DoNothingAndStopPropagationTextIntent(),
        },
        home: const LoginScreen(),
      ),
    );
  }
}
