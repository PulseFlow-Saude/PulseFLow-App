import 'package:local_auth/local_auth.dart';

/// Autenticação local (Face ID, Touch ID, impressão digital ou PIN do dispositivo).
class BiometricLoginService {
  BiometricLoginService._();
  static final BiometricLoginService instance = BiometricLoginService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> get isDeviceSupported async {
    try {
      final canBio = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return canBio || supported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
