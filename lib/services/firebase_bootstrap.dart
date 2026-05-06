import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../config/app_config.dart';
import '../firebase_options.dart';

/// Um único [Firebase.initializeApp] por isolate (evita condições de corrida no
/// Dart). O crash nativo `+[FIRApp addAppToAppDictionary]` costuma vir do iOS a
/// configurar o FIRApp por causa do GoogleService-Info.plist **e** do Dart a
/// chamar `Firebase.initializeApp` — isso é tratado no [Podfile] (patch).
class FirebaseBootstrap {
  FirebaseBootstrap._();

  /// Um future por isolate. O FIRApp é global no processo iOS/Android;
  /// isolados em paralelo podem disputar o primeiro `configure` (evite com opções válidas + tratamento no handler).
  static Future<void>? _inFlight;

  /// `true` só após [Firebase.initializeApp] concluir com sucesso (ou app duplicada OK).
  /// Se as credenciais forem placeholders ou faltar plist/json nativo, fica `false`
  /// e o resto do app pode continuar sem FCM.
  static bool isReady = false;

  static Future<void> ensureInitialized() async {
    if (!AppConfig.useFirebase) return;
    _inFlight ??= _runInit();
    await _inFlight;
  }

  /// Mesmo fluxo que [ensureInitialized]; isolados de background têm cópia própria de [_inFlight].
  static Future<void> ensureInitializedInBackgroundIsolate() async {
    await ensureInitialized();
  }

  static Future<void> _runInit() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isReady = true;
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        isReady = true;
      } else {
        isReady = false;
        debugPrint('[FirebaseBootstrap] FirebaseException: ${e.code} ${e.message}');
      }
    } catch (e, st) {
      isReady = false;
      debugPrint('[FirebaseBootstrap] Firebase não inicializado (app continua sem FCM): $e');
      debugPrint('$st');
    }
  }
}
