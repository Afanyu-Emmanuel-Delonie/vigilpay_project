import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/network/auth_session_manager.dart';
import '../../../../core/utils/request_state.dart';
import '../provider/auth_controller.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final sessionManager = context.read<AuthSessionManager>();
    final auth = context.read<AuthController>();

    final accessToken = await sessionManager.accessToken();

    if (!mounted) {
      return;
    }

    if (accessToken == null || accessToken.isEmpty) {
      Navigator.pushReplacementNamed(context, RouteConstants.login);
      return;
    }

    await auth.loadSession();

    if (!mounted) {
      return;
    }

    if (auth.sessionState == RequestState.success) {
      Navigator.pushReplacementNamed(context, RouteConstants.home);
      return;
    }

    await auth.logout();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, RouteConstants.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
