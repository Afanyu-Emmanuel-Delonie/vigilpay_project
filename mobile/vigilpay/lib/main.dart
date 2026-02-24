import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/route_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/auth_gate_page.dart';
import 'features/auth/presentation/pages/change_password_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/otp_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/products/presentation/pages/products_page.dart';
import 'features/support/presentation/pages/support_feedback_page.dart';
import 'injection_container.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VigilPayApp());
}

class VigilPayApp extends StatelessWidget {
  const VigilPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: InjectionContainer.providers,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: RouteConstants.splash,
        routes: {
          RouteConstants.splash: (_) => const SplashPage(),
          RouteConstants.authGate: (_) => const AuthGatePage(),
          RouteConstants.login: (_) => const LoginPage(),
          RouteConstants.register: (_) => const RegisterPage(),
          RouteConstants.otp: (_) => const OtpPage(),
          RouteConstants.forgotPassword: (_) => const ForgotPasswordPage(),
          RouteConstants.changePassword: (_) => const ChangePasswordPage(),
          RouteConstants.home: (_) => const HomePage(),
          RouteConstants.products: (_) => const ProductsPage(),
          RouteConstants.supportFeedback: (_) => const SupportFeedbackPage(),
          RouteConstants.profile: (_) => const ProfilePage(),
        },
      ),
    );
  }
}

