import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/migration_service.dart';
import 'screens/login/paciente_controller.dart';
import 'screens/login/login_controller.dart';
import 'services/enxaqueca_service.dart';
import 'services/diabetes_service.dart';
import 'services/notification_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/notifications/firebase_handlers.dart';
import 'screens/institutional/settings_controller.dart';
import 'services/app_translations.dart';
Future<void> _safeAwait(
  Future<void> Function() action, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    await action().timeout(timeout);
  } catch (_) {
    // Evita travar o boot por serviços opcionais ou rede lenta.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[Oryon][FlutterError] ${details.exceptionAsString()}');
    debugPrint(details.stack?.toString() ?? '');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[Oryon][zone] $error\n$stack');
    return false;
  };

  SystemChrome.setSystemUIOverlayStyle(AppTheme.lightStatusBarOverlay);

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  /// Firebase antes de [runApp] bloqueava o primeiro frame (até vários segundos no dispositivo).
  unawaited(_configureFirebaseMessagingWhenReady());

  final dbService = Get.put(DatabaseService());
  Get.put(MigrationService());
  final authService = Get.put(AuthService());
  Get.put(PacienteController());
  Get.put(LoginController());
  Get.put(EnxaquecaService());
  Get.put(DiabetesService());
  final settingsController = Get.put(SettingsController());

  Get.clearTranslations();
  Get.addTranslations(AppTranslations().keys);
  Get.fallbackLocale = const Locale('pt', 'BR');
  Get.locale = settingsController.effectiveLocale;

  runApp(const MyApp());

  debugPrint('[Oryon] runApp concluído');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    debugPrint('[Oryon] primeiro frame agendado (pós-runApp)');
    if (!Get.isRegistered<NotificationService>()) {
      try {
        Get.put(NotificationService());
      } catch (e, st) {
        debugPrint('[Oryon] NotificationService falhou: $e\n$st');
      }
    }
    // Segunda frame — auth/Mongo/partilhad não competem com o decode do PNG e theme no splash.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapServices(
        dbService: dbService,
        authService: authService,
        settingsController: settingsController,
      ));
    });
  });
}

Future<void> _configureFirebaseMessagingWhenReady() async {
  if (!AppConfig.useFirebase) return;
  await _safeAwait(
    () => FirebaseBootstrap.ensureInitialized(),
    timeout: const Duration(seconds: 5),
  );
  if (!FirebaseBootstrap.isReady) return;
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<void> _bootstrapServices({
  required DatabaseService dbService,
  required AuthService authService,
  required SettingsController settingsController,
}) async {
  // Antes de gravar prefs (definições): reinstalação sem logout deixa Keychain com token/biometria;
  // prefs vazios permitem detetar e limpar. [AuthService.init] volta a sincronizar depois.
  try {
    await authService
        .syncKeychainAuthWithInstall()
        .timeout(const Duration(seconds: 3));
  } catch (_) {}

  // Preferências e locale primeiro — leves; UI já pode atualizar quando MyApp faz rebuild.
  await _safeAwait(
    settingsController.ensurePreferencesLoaded,
    timeout: const Duration(seconds: 2),
  );
  Get.locale = settingsController.effectiveLocale;
  debugPrint(
    '[Oryon] bootstrap: locale=${settingsController.effectiveLocale.languageCode}',
  );

  // Auth antes do Mongo para sessão rápida; timeout curto evita UI “gelada”.
  try {
    await authService.init().timeout(const Duration(seconds: 4));
  } catch (_) {
    await _safeAwait(authService.logout, timeout: const Duration(seconds: 2));
  }

  // Mongo em background — não segurar isolate principal até abrir/consultas.
  unawaited(
    _safeAwait(
      () => dbService.testConnection(),
      timeout: const Duration(seconds: 8),
    ),
  );
}

/// Evita embrulhar [GetMaterialApp] em [Obx] (reinstancia o navegador e no iOS costuma falhar ao compor).
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Workers? _themeLocaleWorkers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = Get.find<SettingsController>();
      _themeLocaleWorkers = Workers([
        ever(settings.darkTheme, (_) {
          if (mounted) setState(() {});
        }),
        ever(settings.language, (_) {
          if (mounted) setState(() {});
        }),
      ]);
    });
  }

  @override
  void dispose() {
    _themeLocaleWorkers?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeData(
      useMaterial3: true,
      primaryColor: AppTheme.primaryBlue,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primaryBlue,
        primary: AppTheme.primaryBlue,
        secondary: AppTheme.secondaryBlue,
      ),
      textTheme: TextTheme(
        displayLarge: AppTheme.titleLarge,
        displayMedium: AppTheme.titleMedium,
        displaySmall: AppTheme.titleSmall,
        bodyLarge: AppTheme.bodyLarge,
        bodyMedium: AppTheme.bodyMedium,
        bodySmall: AppTheme.bodySmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppTheme.primaryButtonStyle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: AppTheme.secondaryButtonStyle,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppTheme.secondaryBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppTheme.secondaryBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppTheme.error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        systemOverlayStyle: AppTheme.lightStatusBarOverlay,
      ),
    );

    final settings = Get.find<SettingsController>();

    final darkThemeData = themeData.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: themeData.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: Colors.white,
      ),
      appBarTheme: themeData.appBarTheme.copyWith(
        systemOverlayStyle: AppTheme.lightStatusBarOverlay,
      ),
    );

    return GetMaterialApp(
      title: 'Oryon Health',
      // Fundo atrás do navigator (entre rotas / animações presas).
      color: AppTheme.primaryBlue,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 500),
      opaqueRoute: true,
      scrollBehavior: MaterialScrollBehavior().copyWith(
        physics: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
            ? const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              )
            : null,
      ),
      theme: themeData,
      darkTheme: darkThemeData,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.lightStatusBarOverlay,
          sized: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
      themeMode:
          settings.darkTheme.value ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.SPLASH,
      getPages: AppPages.routes,
      translations: AppTranslations(),
      fallbackLocale: const Locale('pt', 'BR'),
      locale: settings.effectiveLocale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('de', 'DE'),
        Locale('zh', 'CN'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('pt', 'BR');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('pt', 'BR');
      },
    );
  }
}
