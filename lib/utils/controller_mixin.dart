import 'package:flutter/material.dart';
import 'package:get/get.dart';

mixin SafeControllerMixin on GetxController {
  
  final List<TextEditingController> _controllers = [];
  
  void addController(TextEditingController controller) {
    _controllers.add(controller);
  }
  
  void addControllers(List<TextEditingController> controllers) {
    _controllers.addAll(controllers);
  }
  
  void clearControllers() {
    for (final controller in _controllers) {
      try {
        controller.clear();
      } catch (e) {
      }
    }
  }
  
  void disposeControllers() {
    for (final controller in _controllers) {
      try {
        controller.dispose();
      } catch (e) {
      }
    }
    _controllers.clear();
  }
  
  @override
  void onClose() {
    disposeControllers();
    super.onClose();
  }
} 