import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/migration_service.dart';
import 'screens/login/paciente_controller.dart';
import 'screens/login/login_controller.dart';
import 'services/enxaqueca_service.dart';
import 'services/diabetes_service.dart';
import 'services/notification_service.dart';
import 'services/notifications/firebase_handlers.dart';
import 'screens/institutional/settings_controller.dart';
import 'services/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar com ícones brancos (hora, bateria) para fundos escuros
  SystemChrome.setSystemUIOverlayStyle(AppTheme.blueSystemOverlayStyle);

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Usar configurações padrão se .env não estiver disponível
  }
  
  if (AppConfig.useFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      // Continuar com notificações locais apenas
    }
  }
  
  final dbService = Get.put(DatabaseService());
  try {
    await dbService.testConnection();
  } catch (e) {
    // Erro ao conectar com banco de dados
  }

  Get.put(MigrationService());

  final authService = Get.put(AuthService());
  await authService.init();
  
  Get.put(PacienteController());
  Get.put(LoginController());
  Get.put(EnxaquecaService());
  Get.put(DiabetesService());
<<<<<<< Updated upstream
  Get.put(SettingsController());
  await SettingsController.ensureLoaded();

  try {
           Get.put(NotificationService());
         } catch (e) {
           // Erro ao inicializar NotificationService
         }
=======
  final settingsController = Get.put(SettingsController());
  await settingsController.ensurePreferencesLoaded();

  // Carrega traduções e locale ANTES de runApp e de NotificationService
  final translations = AppTranslations();
  Get.clearTranslations();
  Get.addTranslations(translations.keys);
  Get.fallbackLocale = const Locale('pt', 'BR');
  Get.locale = settingsController.effectiveLocale;
>>>>>>> Stashed changes

  try {
    Get.put(NotificationService());
  } catch (e) {
    // Erro ao inicializar NotificationService
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final settings = Get.find<SettingsController>();
      final themeData = ThemeData(
        primaryColor: AppTheme.primaryBlue,
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppTheme.secondaryBlue),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppTheme.secondaryBlue),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppTheme.error),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppTheme.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      );

      return GetMaterialApp(
        title: 'PulseFlow',
        theme: themeData,
        darkTheme: themeData.copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: themeData.colorScheme.copyWith(
            brightness: Brightness.dark,
            primary: Colors.white,
          ),
        ),
        themeMode: settings.darkTheme.value ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        translations: AppTranslations(),
        fallbackLocale: const Locale('pt', 'BR'),
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
        locale: settings.effectiveLocale,
        localeResolutionCallback: (locale, supportedLocales) {
          if (locale == null) return const Locale('pt', 'BR');
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) return supported;
          }
          return const Locale('pt', 'BR');
        },
      );
    });
  }
}