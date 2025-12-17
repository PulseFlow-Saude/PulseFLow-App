import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/login/login_screen.dart';
import '../screens/registration/registration_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/login/verify_2fa_screen.dart';

import '../screens/forgot_password/forgot_password_screen.dart';
import '../screens/reset_password/reset_password_screen.dart';
import '../screens/medical_records/medical_records_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/enxaqueca/enxaqueca_screen.dart';
import '../screens/diabetes/diabetes_screen.dart';
import '../screens/pressaoArterial/pressao_screen.dart';
import '../screens/login/paciente_controller.dart'; // Ajuste o caminho
import '../screens/medical_records/medical_record_details_screen.dart';
import '../screens/evento_clinico/evento_clinico_form_screen.dart';
import '../screens/evento_clinico/evento_clinico_history_screen.dart';
import '../screens/crise_gastrite/crise_gastrite_form_screen.dart';
import '../screens/crise_gastrite/crise_gastrite_history_screen.dart';
import '../screens/menstruacao/menstruacao_form_screen.dart';
import '../screens/menstruacao/menstruacao_history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/profile_controller.dart';
import '../screens/pulse_key/pulse_key_screen.dart';
import '../screens/smartwatch/smartwatch_screen.dart';
import '../screens/health_history/health_history_screen.dart';
import '../screens/health_history/heart_rate_history_screen.dart';
import '../screens/health_history/steps_history_screen.dart';
import '../screens/health_history/sleep_history_screen.dart';
import '../screens/exame/exame_upload_screen.dart';
import '../screens/exame/exame_list_screen.dart';
import '../screens/hormonal/hormonal_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/history_selection/history_selection_screen.dart';
import '../screens/appointments/appointment_specialty_screen.dart';
import '../screens/appointments/appointment_doctor_list_screen.dart';
import '../screens/appointments/appointment_scheduler_screen.dart';
import '../screens/appointments/upcoming_appointments_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/access_history/access_history_screen.dart';
import '../screens/institutional/about_screen.dart';
import '../screens/institutional/faq_screen.dart';
import '../screens/institutional/security_screen.dart';
import '../screens/institutional/contact_screen.dart';
import '../screens/institutional/privacy_screen.dart';
import '../screens/institutional/app_version_screen.dart';
import '../screens/institutional/settings_screen.dart';
import '../services/auth_service.dart';

import  'app_routes.dart';

// Middleware para verificar autenticação
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      final authService = Get.find<AuthService>();
      if (!authService.isAuthenticated) {
        return RouteSettings(name: Routes.LOGIN);
      }
    } catch (e) {
      // Se não conseguir encontrar o AuthService, redireciona para login
      return RouteSettings(name: Routes.LOGIN);
    }
    return null;
  }
}

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    ),
    GetPage(
      name: Routes.REGISTRATION,
      page: () => ProfessionalRegistrationScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.RESET_PASSWORD,
      page: () => const ResetPasswordScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.MEDICAL_RECORDS,
      page: () => const MedicalRecordsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.VERIFY_2FA,
      page: () => const Verify2FAScreen(
        patientId: '',
        method: 'email',
      ),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    ),
    GetPage(
      name: Routes.MENU,
      page: () => const MenuScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.ENXAQUECA,
      page: () {
        final pacienteController = Get.find<PacienteController>();
        return EnxaquecaScreen(pacienteId: pacienteController.pacienteId.value);
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.DIABETES,
      page: () {
        final pacienteController = Get.find<PacienteController>();
        return DiabetesScreen(pacienteId: pacienteController.pacienteId.value);
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.PRESSAO,
      page: () {
        final pacienteController = Get.find<PacienteController>();
        return PressaoScreen(pacienteId: pacienteController.pacienteId.value);
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.MEDICAL_RECORD_DETAILS,
      page: () => const MedicalRecordDetailsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    ),
    GetPage(
      name: Routes.EVENTO_CLINICO_FORM,
      page: () => const EventoClinicoFormScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.EVENTO_CLINICO_HISTORY,
      page: () => const EventoClinicoHistoryScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.CRISE_GASTRITE_FORM,
      page: () => const CriseGastriteFormScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.CRISE_GASTRITE_HISTORY,
      page: () => const CriseGastriteHistoryScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.MENSTRUACAO_FORM,
      page: () => const MenstruacaoFormScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.MENSTRUACAO_HISTORY,
      page: () => const MenstruacaoHistoryScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProfileController>(() => ProfileController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.PULSE_KEY,
      page: () => const PulseKeyScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.SMARTWATCH,
      page: () => const SmartwatchScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.HEALTH_HISTORY,
      page: () => const HealthHistoryScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.HEART_RATE_HISTORY,
      page: () => const HeartRateHistoryScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.STEPS_HISTORY,
      page: () => const StepsHistoryScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.SLEEP_HISTORY,
      page: () => const SleepHistoryScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.EXAME_UPLOAD,
      page: () => const ExameUploadScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.EXAME_LIST,
      page: () => const ExameListScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.HORMONAL,
      page: () {
        final pacienteId = Get.find<PacienteController>().pacienteId.value;
        return HormonalScreen(pacienteId: pacienteId);
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    ),
    GetPage(
      name: Routes.HISTORY_SELECTION,
      page: () => const HistorySelectionScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    ),
    GetPage(
      name: Routes.APPOINTMENTS_SPECIALTY,
      page: () => const AppointmentSpecialtyScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.APPOINTMENTS_DOCTORS,
      page: () => const AppointmentDoctorListScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.APPOINTMENT_SCHEDULER,
      page: () => const AppointmentSchedulerScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.UPCOMING_APPOINTMENTS,
      page: () => const UpcomingAppointmentsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.NOTIFICATIONS,
      page: () => const NotificationsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.ACCESS_HISTORY,
      page: () => const AccessHistoryScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.ABOUT,
      page: () => const AboutScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.FAQ,
      page: () => const FaqScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.SECURITY,
      page: () => const SecurityScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.CONTACT,
      page: () => const ContactScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.PRIVACY,
      page: () => const PrivacyScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.APP_VERSION,
      page: () => const AppVersionScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => SettingsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      middlewares: [AuthMiddleware()],
    ),
  ];
} 