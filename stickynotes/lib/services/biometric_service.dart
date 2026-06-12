// lib/services/biometric_service.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final _auth = LocalAuthentication();

  /// Returns true if the device supports biometrics AND has enrolled fingers.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user for biometric authentication.
  /// Returns true on success, false on failure / cancellation.
  Future<bool> authenticate({String reason = 'Unlock your note'}) async {
    if (kIsWeb) return false;
    try {
      // local_auth 3.x removed AuthenticationOptions; just pass localizedReason.
      return await _auth.authenticate(localizedReason: reason);
    } catch (_) {
      return false;
    }
  }
}
