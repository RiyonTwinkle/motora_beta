import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/account_screen.dart';
import 'screens/fasttag_screen.dart';
import 'screens/fuel_odo_screen.dart';
import 'screens/garage_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_verify_screen.dart';
import 'screens/payment_gateway_screen.dart';
import 'screens/qr_contact_screen.dart';
import 'screens/service_screen.dart';
import 'screens/telemetry_screen.dart';

void main() {
  runApp(const MotoroApp());
}

class MotoroApp extends StatelessWidget {
  const MotoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOTORO - Connected Vehicle Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/otp_verify': (context) => const OtpVerifyScreen(phoneNumber: '+91 9876543210'),
        '/home': (context) => const HomeScreen(),
        '/garage': (context) => const GarageScreen(),
        '/telemetry': (context) => const TelemetryScreen(),
        '/fuel_odo': (context) => const FuelOdoScreen(),
        '/service': (context) => const ServiceScreen(),
        '/fasttag': (context) => const FastTagScreen(),
        '/account': (context) => const AccountScreen(),
        '/payment_gateway': (context) => const PaymentGatewayScreen(),
        '/qr_contact': (context) => const QrContactScreen(),
      },
    );
  }
}
