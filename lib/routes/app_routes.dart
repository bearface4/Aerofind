import 'package:flutter/material.dart';
import '../screens/shared/splash_screen.dart';
import '../screens/shared/login_screen.dart';
import '../screens/shared/role_selection.dart';

class AppRoutes {
  // Route name constants
  static const String splash = '/';
  static const String login = '/login';
  static const String roleselection = '/roleselection';

  // Route map
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    roleselection: (context) => const RoleSelectionScreen(),
  };
}
