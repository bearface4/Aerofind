import 'package:flutter/material.dart';
import '../screens/shared/splash_screen.dart';
import '../screens/shared/login_screen.dart';
import '../screens/shared/role_selection.dart';
import '../screens/seller/seller_registration_screen.dart';
import '../screens/seller/seller_registration_pending.dart';
import '../screens/consumer/consumer_registration_screen.dart';
import '../screens/consumer/email_verification_screen.dart';
import '../screens/shared/login_otp_screen.dart';
import '../screens/consumer/consumer_home_page.dart';
import '../screens/seller/seller_home_page.dart';
import '../screens/consumer/consumer_favorite_page.dart';
import '../screens/consumer/consumer_track_orders.dart';
import '../screens/consumer/consumer_profile_page.dart';
import '../screens/consumer/consumer_main_page.dart';
import '../screens/seller/seller_order_page.dart';
import '../screens/seller/seller_inventory.dart';
import '../screens/seller/seller_profile.dart';
import '../screens/seller/seller_main_page.dart';

class AppRoutes {
  // Route name constants
  static const String splash = '/';
  static const String login = '/login';
  static const String roleselection = '/roleselection';
  static const String sellerregistration = '/sellerregistration';
  static const String sellerregistrationpending = '/sellerregistrationpending';
  static const String consumerregistration = '/consumerregistration';
  static const String emailverification = '/emailverification';
  static const String loginotp = '/loginotp';
  static const String consumerhome = '/consumerhome';
  static const String consumerfavorites = '/consumerfavorites';
  static const String consumertrack = '/consumertrack';
  static const String consumerprofile = '/consumerprofile';
  static const String consumermain = '/consumermain';
  static const String sellerhome = '/sellerhome';
  static const String sellerorders = '/sellerorders';
  static const String sellerinventory = '/sellerinventory';
  static const String sellerprofile = '/sellerprofile';
  static const String sellermain = '/sellermain';

  // Route map
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    roleselection: (context) => const RoleSelectionScreen(),
    sellerregistration: (context) => const SellerRegistrationScreen(),
    sellerregistrationpending: (context) => const SellerPendingScreen(),
    consumerregistration: (context) => const ConsumerRegistrationScreen(),
    emailverification: (context) => const EmailVerificationScreen(),
    loginotp: (context) => const LoginOtpScreen(),
    consumerhome: (context) => const ConsumerHomePage(),
    consumerfavorites: (context) => const ConsumerFavoritePage(),
    consumertrack: (context) => const ConsumerTrackOrdersPage(),
    consumerprofile: (context) => const ConsumerProfilePage(),
    consumermain: (context) => const ConsumerMainPage(),
    sellerhome: (context) => const SellerHomePage(),
    sellerorders: (context) => const SellerOrdersPage(),
    sellerinventory: (context) => SellerInventoryPage(),
    sellerprofile: (context) => const SellerProfilePage(),
    sellermain: (context) => const SellerMainPage(),
  };
}
