import FirebaseCore
import Flutter
import UIKit

/// Configuração nativa antes dos plugins — evita IOS-COR000003 (“No app configured yet”) quando
/// o FCM/Installations tocam Firebase antes do `main()` Dart correr `Firebase.initializeApp`.
/// No Dart, [FirebaseBootstrap] trata `duplicate-app` se o `Firebase.initializeApp` repetir setup.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
