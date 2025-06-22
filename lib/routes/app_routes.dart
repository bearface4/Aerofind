import 'package:flutter/material.dart';
import '../screens/shared/splash_screen.dart';
import '../screens/shared/login_screen.dart';
import '../screens/shared/role_selection.dart';
import '../screens/seller/seller_registration_screen.dart';
import '../screens/seller/seller_registration_pending.dart';

class AppRoutes {
  // Route name constants
  static const String splash = '/';
  static const String login = '/login';
  static const String roleselection = '/roleselection';
  static const String sellerregistration = '/sellerregistration';
  static const String sellerregistrationpending = '/sellerregistrationpending';

  // Route map
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    roleselection: (context) => const RoleSelectionScreen(),
    sellerregistration: (context) => const SellerRegistrationScreen(),
    sellerregistrationpending: (context) => const SellerPendingScreen(),
  };
}
