import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

Future<bool> authenticateWithBiometrics(BuildContext context) async {
  final auth = LocalAuthentication();

  final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
  if (!canCheck) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This device does not support biometric verification")),
      );
    }
    return false;
  }

  try {
    final didAuthenticate = await auth.authenticate(
      localizedReason: 'Please verify to continue',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
    return didAuthenticate;
  } catch (e) {
    debugPrint('Auth error: $e');
    return false;
  }
}
