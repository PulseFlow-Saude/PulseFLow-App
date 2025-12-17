import 'package:get/get.dart';
import '../../models/patient.dart';
import '../../models/medical_note.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class MedicalRecordsController extends GetxController {
  final AuthService _auth = AuthService.instance;
  final DatabaseService _db = Get.find<DatabaseService>();

  final Rxn<Patient> patient = Rxn<Patient>();
  final RxBool isLoading = true.obs;
  final RxList<MedicalNote> notes = <MedicalNote>[].obs;
  final RxBool isSidebarOpen = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      final current = _auth.currentUser;
      if (current != null) {
        patient.value = current;
        await _loadNotes(current.id!);
      } else {
        // Tenta revalidar sessão e obter paciente
        await _auth.init();
        patient.value = _auth.currentUser;
        if (patient.value?.id != null) {
          await _loadNotes(patient.value!.id!);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadNotes(String patientId) async {
    final fetched = await _db.getMedicalNotesByPatientId(patientId);
    notes.assignAll(fetched);
  }

  Future<void> loadNotes() async {
    if (patient.value?.id != null) {
      isLoading.value = true;
      try {
        await _loadNotes(patient.value!.id!);
      } finally {
        isLoading.value = false;
      }
    }
  }

  void toggleSidebar() {
    isSidebarOpen.toggle();
  }
}


