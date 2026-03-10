import 'dart:io';

/// No emulador Android, localhost não funciona - usa 10.0.2.2 (host da máquina).
String getApiBaseUrl(String defaultUrl) {
  if (Platform.isAndroid && defaultUrl.contains('localhost')) {
    return defaultUrl.replaceFirst('localhost', '10.0.2.2');
  }
  if (Platform.isAndroid && defaultUrl.contains('127.0.0.1')) {
    return defaultUrl.replaceFirst('127.0.0.1', '10.0.2.2');
  }
  return defaultUrl;
}
