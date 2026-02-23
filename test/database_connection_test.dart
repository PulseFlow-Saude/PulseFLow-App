import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulseflow_app/services/database_service.dart';

/// Testa a conexão com o MongoDB usando a URI do .env (ex.: Atlas) ou fallback local.
void main() {
  setUpAll(() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  });

  test('MongoDB: conexão com o banco', () async {
    final db = DatabaseService();
    await db.testConnection();
    expect(true, isTrue, reason: 'Conexão com MongoDB deve ser estabelecida');
  });
}
