import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  
  // Inicializar Firebase ANTES de registrar o background handler
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Registrar o handler de mensagens em background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    // Continuar com notificações locais apenas
  }
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Usar configurações padrão se .env não estiver disponível
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
  Get.put(SettingsController());
  
         try {
           Get.put(NotificationService());
         } catch (e) {
           // Erro ao inicializar NotificationService
         }

  // Verifica se precisa migrar senhas antigas
  try {
    final migrationService = Get.find<MigrationService>();
    final status = await migrationService.checkMigrationStatus();
    
    if (status['needsMigration']) {
      // Executa migração automaticamente
      await migrationService.migrateAllPasswords();
    }
  } catch (e) {
    // Silenciosamente falha se não conseguir verificar migração
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
        ],
        locale: Locale(
          settings.language.value.split('_').first,
          settings.language.value.split('_').length > 1
              ? settings.language.value.split('_')[1]
              : '',
        ),
      );
    });
  }
}