import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
// import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  BiometricService._();

  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get canCheckBiometrics async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Returns true if authentication succeeded.
  Future<bool> authenticate({
    String reason = 'Unlock Vault',
  }) async {
    try {
      final supported = await canCheckBiometrics;
      if (!supported) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // allow device PIN/pattern as fallback
        // options: const AuthenticationOptions(
        //   biometricOnly: false,
        //   stickyAuth: true,
        //   useErrorDialogs: true,
        // ),
      );
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.noBiometricsEnrolled ||
          e.code == LocalAuthExceptionCode.noBiometricHardware ||
          e.code == LocalAuthExceptionCode.noCredentialsSet) {
        return false;
      }
      return false;
    }
  }
}
