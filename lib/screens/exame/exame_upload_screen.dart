import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/exame.dart';
import '../../services/exame_service.dart';
import '../../services/api_service.dart';
import '../login/paciente_controller.dart';
import 'exame_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pulse_bottom_navigation.dart';
import '../../widgets/pulse_side_menu.dart';
import '../../widgets/pulse_drawer_button.dart';

class ExameUploadScreen extends StatefulWidget {
  const ExameUploadScreen({super.key});

  @override
  State<ExameUploadScreen> createState() => _ExameUploadScreenState();
}

class _ExameUploadScreenState extends State<ExameUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _categoriaController = TextEditingController();
  DateTime? _data = DateTime.now();
  PlatformFile? _selectedFile;
  bool _isSaving = false;

  final ExameService _exameService = Get.put(ExameService());
  final PacienteController _pacienteController = Get.find<PacienteController>();
  final ExameController _exameController = Get.put(ExameController());
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'heic'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao selecionar arquivo: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String> _persistFileLocally(PlatformFile file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final examesDir = Directory('${appDir.path}/exames');
    if (!await examesDir.exists()) {
      await examesDir.create(recursive: true);
    }
    final targetPath = '${examesDir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final sourcePath = file.path!;
    final savedFile = await File(sourcePath).copy(targetPath);
    return savedFile.path;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    
    if (_data == null) {
      Get.snackbar(
        'Atenção',
        'Selecione uma data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      HapticFeedback.mediumImpact();
      return;
    }

    if (_selectedFile == null) {
      Get.snackbar(
        'Atenção',
        'Selecione um arquivo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      HapticFeedback.mediumImpact();
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      final arquivoFile = File(_selectedFile!.path!);
      if (!await arquivoFile.exists()) {
        throw Exception('Arquivo não encontrado');
      }

      final nome = _nomeController.text.trim();
      final categoria = _categoriaController.text.trim();
      final data = _data!;

      final uploadResult = await _apiService.uploadExame(
        nome: nome,
        categoria: categoria,
        data: data,
        arquivo: arquivoFile,
      );

      final exameData = uploadResult['exame'];
      String? exameId;
      if (exameData != null) {
        if (exameData['_id'] is Map && exameData['_id']['\$oid'] != null) {
          exameId = exameData['_id']['\$oid'].toString();
        } else if (exameData['_id'] != null) {
          exameId = exameData['_id'].toString();
        }
      }
      
      final serverFilePath = exameData?['filePath']?.toString() ?? '';
      
      final localPath = await _persistFileLocally(_selectedFile!);

      final exame = Exame(
        id: exameId,
        nome: nome,
        categoria: categoria,
        data: data,
        filePath: serverFilePath.isNotEmpty ? serverFilePath : localPath,
        paciente: _pacienteController.pacienteId.value,
      );

      await _exameController.adicionarExame(exame);
      
      if (mounted) {
        _nomeController.clear();
        _categoriaController.clear();
        setState(() {
          _data = DateTime.now();
          _selectedFile = null;
        });
        
        HapticFeedback.mediumImpact();
        Get.snackbar(
          'Sucesso',
          uploadResult['message'] ?? 'Exame salvo com sucesso',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        
        await _exameController.carregarExames(_pacienteController.pacienteId.value);
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Get.back(result: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Erro',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00324A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _data = picked;
      });
      HapticFeedback.lightImpact();
    }
  }

  IconData _getFileIcon() {
    if (_selectedFile == null) return Icons.insert_drive_file_outlined;
    final ext = _selectedFile!.extension?.toLowerCase() ?? '';
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['png', 'jpg', 'jpeg', 'heic'].contains(ext)) return Icons.image;
    return Icons.insert_drive_file;
  }

  Color _getFileColor() {
    if (_selectedFile == null) return Colors.grey;
    final ext = _selectedFile!.extension?.toLowerCase() ?? '';
    if (ext == 'pdf') return Colors.red;
    if (['png', 'jpg', 'jpeg', 'heic'].contains(ext)) return Colors.blue;
    return Colors.grey;
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isPhone = screenSize.width < 420;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.blueSystemOverlayStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFF00324A),
        drawer: const PulseSideMenu(activeItem: PulseNavItem.menu),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(isSmallScreen),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth;
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.only(
                                left: isPhone ? 16 : 20,
                                right: isPhone ? 16 : 20,
                                top: isSmallScreen ? 16 : 20,
                                bottom: 120,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 20 : 24),
                                  
                                  _buildModernTextField(
                                    controller: _nomeController,
                                    label: 'Nome do Exame',
                                    hint: 'Ex: Hemograma completo',
                                    icon: Icons.description_outlined,
                                    isRequired: true,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  
                                  _buildModernTextField(
                                    controller: _categoriaController,
                                    label: 'Categoria',
                                    hint: 'Ex: Exames de sangue',
                                    icon: Icons.category_outlined,
                                    isRequired: true,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  
                                  _buildDateField(isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  
                                  _buildFileSelectorCard(isSmallScreen, isPhone),
                                  SizedBox(height: isSmallScreen ? 20 : 24),
                                  
                                  _buildActionButtons(isSmallScreen),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const PulseBottomNavigation(activeItem: PulseNavItem.menu),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isSmallScreen ? 16 : 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF00324A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const PulseDrawerButton(iconSize: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anexar Exame',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: isSmallScreen ? 20 : 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adicione um novo exame ao seu prontuário',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.toNamed(Routes.EXAME_LIST);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.visibility_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFF00324A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informações do Exame',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00324A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Preencha os dados do exame',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: const Color(0xFF00324A).withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool isSmallScreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF00324A)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF212121),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(fontSize: isSmallScreen ? 15 : 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: isSmallScreen ? 14 : 15,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00324A), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 14 : 16,
              vertical: isSmallScreen ? 14 : 16,
            ),
          ),
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildDateField(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: const Color(0xFF00324A)),
            const SizedBox(width: 6),
            Text(
              'Data do Exame',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF212121),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 14 : 16,
              vertical: isSmallScreen ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _data != null
                        ? DateFormat('dd/MM/yyyy').format(_data!)
                        : 'Selecione a data',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      color: _data != null ? const Color(0xFF212121) : Colors.grey[400],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileSelectorCard(bool isSmallScreen, bool isPhone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file_outlined, size: 18, color: const Color(0xFF00324A)),
            const SizedBox(width: 6),
            Text(
              'Arquivo do Exame',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF212121),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              gradient: _selectedFile != null
                  ? LinearGradient(
                      colors: [
                        _getFileColor().withOpacity(0.1),
                        _getFileColor().withOpacity(0.05),
                      ],
                    )
                  : null,
              color: _selectedFile == null ? const Color(0xFFF8F9FA) : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedFile != null
                    ? _getFileColor().withOpacity(0.3)
                    : Colors.grey[300]!,
                width: _selectedFile != null ? 2 : 1,
              ),
            ),
            child: _selectedFile == null
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00324A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFF00324A),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Toque para selecionar arquivo',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00324A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF, PNG, JPG ou HEIC',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: _getFileColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getFileColor().withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getFileColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getFileIcon(),
                                color: _getFileColor(),
                                size: isSmallScreen ? 28 : 32,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Arquivo selecionado',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedFile!.name,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF212121),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_selectedFile!.size != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.description_outlined,
                                          size: isSmallScreen ? 12 : 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatFileSize(_selectedFile!.size),
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                });
                                HapticFeedback.lightImpact();
                              },
                              icon: const Icon(Icons.close_rounded, size: 22),
                              color: Colors.grey[600],
                              tooltip: 'Remover arquivo',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.refresh_outlined, size: 18),
                          label: const Text('Trocar arquivo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00324A),
                            side: const BorderSide(color: Color(0xFF00324A), width: 1.5),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.cloud_upload, size: 22),
            label: Text(
              _isSaving ? 'Salvando...' : 'Salvar Exame',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00324A),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 14 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.toNamed(Routes.EXAME_LIST);
            },
            icon: const Icon(Icons.visibility_outlined, size: 20),
            label: Text(
              'Visualizar Exames',
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00324A),
              side: const BorderSide(color: Color(0xFF00324A), width: 1.5),
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 14 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
