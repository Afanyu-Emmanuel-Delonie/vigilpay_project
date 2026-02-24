import 'package:flutter/material.dart';

import '../../../../core/constants/route_constants.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final args = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
        <String, dynamic>{};
    final flow = (args['flow'] ?? '').toString();

    if (flow == 'forgot-password') {
      Navigator.pushReplacementNamed(context, RouteConstants.changePassword);
      return;
    }

    Navigator.pushReplacementNamed(context, RouteConstants.login);
  }

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
        <String, dynamic>{};
    final email = (args['email'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter the 6-digit code sent to $email'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'OTP code'),
                validator: (value) {
                  final otp = value?.trim() ?? '';
                  if (otp.length != 6) {
                    return 'OTP must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _verify,
                  child: const Text('Verify OTP'),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
