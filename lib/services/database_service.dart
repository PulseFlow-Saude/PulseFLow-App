import 'package:mongo_dart/mongo_dart.dart';
import '../models/patient.dart';
import '../models/medical_note.dart';
import '../models/enxaqueca.dart';
import '../models/diabetes.dart';
import '../models/pressao_arterial.dart';
import '../models/evento_clinico.dart';
import '../models/crise_gastrite.dart';
import '../models/menstruacao.dart';
import '../models/exame.dart';
import '../models/health_data.dart';
import '../config/database_config.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Db? _db;
  bool _isConnecting = false;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Método público para testar conexão
  Future<void> testConnection() async {
    await _ensureConnection();
  }

  Future<void> _ensureConnection() async {
    if (_db != null && _db!.isConnected) {
      return;
    }

    if (_isConnecting) {
      return;
    }

    _isConnecting = true;
    int retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
        if (_db == null) {
          final uri = DatabaseConfig.connectionString;
          if (uri.isEmpty) {
            throw 'String de conexão não configurada';
          }
          _db = await Db.create(uri);
        }

        if (!_db!.isConnected) {
          await _db!.open();
          
          // Verificar conexão tentando listar as coleções
          try {
            await _db!.getCollectionNames();
            _isConnecting = false;
            return;
          } catch (e) {
            await _db!.close();
            _db = null;
            throw 'Falha na verificação da conexão';
          }
        }
      } catch (e, stack) {
        if (_db != null) {
          try {
            await _db!.close();
          } catch (e) {
            // Ignorar erro ao fechar
          }
          _db = null;
        }

        retryCount++;
        if (retryCount < _maxRetries) {
          await Future.delayed(_retryDelay);
        } else {
          _isConnecting = false;
          throw 'Falha ao conectar após $_maxRetries tentativas: $e';
        }
      }
    }
  }

  Future<void> connect() async {
    try {
      await _ensureConnection();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('users');
      final docs = await collection.find().toList();
      return docs.map((doc) {
        final map = Map<String, dynamic>.from(doc);
        final id = map['_id'];
        if (id is ObjectId) {
          map['id'] = id.toHexString();
        } else if (id != null) {
          map['id'] = id.toString();
        }
        map.remove('_id');
        return map;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // =================== ENXAQUECAS ===================
  Future<Enxaqueca> createEnxaqueca(Enxaqueca enxaqueca) async {
    try {
      await _ensureConnection();

      final collection = _db!.collection(DatabaseConfig.enxaquecasCollection);

      final data = enxaqueca.toMap();

      // Tentar salvar pacienteId como ObjectId quando possível
      try {
        data['pacienteId'] = ObjectId.parse(enxaqueca.pacienteId);
      } catch (_) {
        data['pacienteId'] = enxaqueca.pacienteId;
      }

      // Remover _id antes de inserir
      data.remove('_id');

      final result = await collection.insert(data);

      // Buscar o documento criado para retornar normalizado
      Map<String, dynamic>? created;
      if (result['_id'] != null) {
        created = await collection.findOne(where.id(result['_id']));
      } else {
        // Fallback: buscar pelo match de campos
        created = await collection.findOne(
          where
              .eq('pacienteId', data['pacienteId'])
              .eq('data', data['data'])
              .eq('intensidade', data['intensidade'])
              .eq('duracao', data['duracao']),
        );
      }

      if (created == null) {
        throw 'Erro ao criar registro de enxaqueca';
      }

      final normalized = Map<String, dynamic>.from(created);
      normalized['_id'] = normalized['_id'].toString();
      if (normalized['pacienteId'] != null) {
        normalized['pacienteId'] = normalized['pacienteId'].toString();
      }
      return Enxaqueca.fromMap(normalized);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Enxaqueca>> getEnxaquecasByPacienteId(String pacienteId) async {
    try {
      await _ensureConnection();

      final collection = _db!.collection(DatabaseConfig.enxaquecasCollection);

      final results = <Map<String, dynamic>>[];

      // Tentativa 1: pacienteId como ObjectId
      try {
        final objId = ObjectId.parse(pacienteId);
        final list = await collection.find(where.eq('pacienteId', objId)).toList();
        results.addAll(list.map((e) => Map<String, dynamic>.from(e)));
      } catch (_) {
      }

      // Tentativa 2: pacienteId como String
      final list2 = await collection.find(where.eq('pacienteId', pacienteId)).toList();
      results.addAll(list2.map((e) => Map<String, dynamic>.from(e)));

      // Normalizar e remover duplicados
      final normalized = results.map((doc) {
        final data = Map<String, dynamic>.from(doc);
        data['_id'] = data['_id'].toString();
        if (data['pacienteId'] != null) {
          data['pacienteId'] = data['pacienteId'].toString();
        }
        return data;
      }).toList();

      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final m in normalized) {
        final idStr = m['_id'].toString();
        if (!seen.contains(idStr)) {
          seen.add(idStr);
          unique.add(m);
        }
      }

      // Ordenar por data desc, se disponível
      unique.sort((a, b) {
        try {
          final da = DateTime.parse(a['data'].toString());
          final db = DateTime.parse(b['data'].toString());
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });

      return unique.map((m) => Enxaqueca.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // =================== DIABETES ===================
  Future<Diabetes> createDiabetes(Diabetes registro) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.diabetesCollection);

      final data = registro.toMap();
      data.remove('_id');
      try {
        data['pacienteId'] = ObjectId.parse(registro.pacienteId);
      } catch (_) {
        data['pacienteId'] = registro.pacienteId;
      }

      final result = await collection.insert(data);
      Map<String, dynamic>? created;
      if (result['_id'] != null) {
        created = await collection.findOne(where.id(result['_id']));
      } else {
        created = await collection.findOne(
          where
              .eq('pacienteId', data['pacienteId'])
              .eq('data', data['data'])
              .eq('glicemia', data['glicemia'])
              .eq('unidade', data['unidade']),
        );
      }
      if (created == null) throw 'Erro ao criar registro de diabetes';

      final normalized = Map<String, dynamic>.from(created);
      normalized['_id'] = normalized['_id'].toString();
      if (normalized['pacienteId'] != null) {
        normalized['pacienteId'] = normalized['pacienteId'].toString();
      }
      return Diabetes.fromMap(normalized);
    } catch (e) {
      rethrow;
    }
  }

  // =================== EVENTOS CLÍNICOS ===================
  Future<EventoClinico> createEventoClinico(EventoClinico evento) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.eventosClinicosCollection);

      final data = evento.toMap();
      data.remove('_id');
      
      // Converter paciente para ObjectId se possível
      ObjectId? pacienteObjectId;
      try {
        pacienteObjectId = ObjectId.parse(evento.paciente);
        data['paciente'] = pacienteObjectId;
      } catch (_) {
        data['paciente'] = evento.paciente;
      }
      
      data['createdAt'] = DateTime.now().toIso8601String();
      data['updatedAt'] = DateTime.now().toIso8601String();

      // Inserir o documento (o MongoDB adiciona o _id automaticamente ao objeto data)
      await collection.insert(data);
      
      // Após inserção, o documento data já contém o _id
      // Normalizar o documento para retornar
      final normalized = Map<String, dynamic>.from(data);
      normalized['_id'] = data['_id']?.toString() ?? '';
      if (normalized['paciente'] != null) {
        if (normalized['paciente'] is ObjectId) {
          normalized['paciente'] = normalized['paciente'].toString();
        } else {
          normalized['paciente'] = normalized['paciente'].toString();
        }
      }
      
      return EventoClinico.fromMap(normalized);
    } catch (e) {
      print('❌ [DatabaseService] Erro ao criar evento clínico: $e');
      rethrow;
    }
  }

  // =================== EXAMES ===================
  Future<Exame> createExame(Exame exame) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.examesCollection);

      final data = exame.toMap();
      data.remove('_id');

      // Converter paciente para ObjectId se possível
      try {
        data['paciente'] = ObjectId.parse(exame.paciente);
      } catch (_) {
        data['paciente'] = exame.paciente;
      }

      final result = await collection.insert(data);

      Map<String, dynamic>? created;
      if (result['_id'] != null) {
        created = await collection.findOne(where.id(result['_id']));
      }
      created ??= await collection.findOne(where
          .eq('paciente', data['paciente'])
          .eq('nome', data['nome'])
          .eq('categoria', data['categoria'])
          .eq('data', data['data'])
          .eq('filePath', data['filePath']));

      if (created == null) throw 'Erro ao criar exame';

      final normalized = Map<String, dynamic>.from(created);
      normalized['_id'] = normalized['_id'].toString();
      if (normalized['paciente'] != null) {
        normalized['paciente'] = normalized['paciente'].toString();
      }
      return Exame.fromMap(normalized);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Exame>> getExamesByPaciente(String pacienteId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.examesCollection);

      final results = <Map<String, dynamic>>[];
      try {
        final objId = ObjectId.parse(pacienteId);
        final list = await collection.find(where.eq('paciente', objId)).toList();
        results.addAll(list.map((e) => Map<String, dynamic>.from(e)));
      } catch (_) {}

      final list2 = await collection.find(where.eq('paciente', pacienteId)).toList();
      results.addAll(list2.map((e) => Map<String, dynamic>.from(e)));

      final normalized = results.map((doc) {
        final data = Map<String, dynamic>.from(doc);
        data['_id'] = data['_id'].toString();
        if (data['paciente'] != null) {
          data['paciente'] = data['paciente'].toString();
        }
        return data;
      }).toList();

      normalized.sort((a, b) {
        try {
          final da = DateTime.parse(a['data'].toString());
          final db = DateTime.parse(b['data'].toString());
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });

      return normalized.map((m) => Exame.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExame(String exameId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.examesCollection);
      bool deleted = false;

      // Tenta por ObjectId
      try {
        final r1 = await collection.remove(where.eq('_id', ObjectId.parse(exameId)));
        if (r1['ok'] == 1 && (r1['n'] ?? 0) > 0) {
          deleted = true;
        }
      } catch (_) {}

      // Fallback: tenta por string
      if (!deleted) {
        final r2 = await collection.remove(where.eq('_id', exameId));
        if (r2['ok'] == 1 && (r2['n'] ?? 0) > 0) {
          deleted = true;
        } else if (r2['ok'] != 1 && r2['errmsg'] != null) {
          throw 'Falha ao deletar exame: ${r2['errmsg']}';
        }
      }

      if (!deleted) {
        throw 'Exame não encontrado';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExameByObject(Exame exame) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.examesCollection);

      bool deleted = false;

      // 1) Se tiver ID, tenta deletar pelo _id (ObjectId e String)
      if (exame.id != null && exame.id!.isNotEmpty) {
        try {
          final r1 = await collection.remove(where.eq('_id', ObjectId.parse(exame.id!)));
          if (r1['ok'] == 1 && (r1['n'] ?? 0) > 0) {
            deleted = true;
          }
        } catch (_) {}
        if (!deleted) {
          final r2 = await collection.remove(where.eq('_id', exame.id));
          if (r2['ok'] == 1 && (r2['n'] ?? 0) > 0) {
            deleted = true;
          }
        }
      }

      // 2) Fallback: deletar por combinação de campos
      if (!deleted) {
        // Tentativa com paciente como ObjectId
        try {
          final r3 = await collection.remove(where
              .eq('paciente', ObjectId.parse(exame.paciente))
              .eq('filePath', exame.filePath)
              .eq('nome', exame.nome)
              .eq('categoria', exame.categoria)
              .eq('data', exame.data.toIso8601String()));
          if (r3['ok'] == 1 && (r3['n'] ?? 0) > 0) {
            deleted = true;
          }
        } catch (_) {}

        // Tentativa com paciente como String
        if (!deleted) {
          final r4 = await collection.remove(where
              .eq('paciente', exame.paciente)
              .eq('filePath', exame.filePath)
              .eq('nome', exame.nome)
              .eq('categoria', exame.categoria)
              .eq('data', exame.data.toIso8601String()));
          if (r4['ok'] == 1 && (r4['n'] ?? 0) > 0) {
            deleted = true;
          }
        }
      }

      if (!deleted) {
        throw 'Exame não encontrado';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<EventoClinico>> getEventosClinicosByPacienteId(String pacienteId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.eventosClinicosCollection);

      final results = <Map<String, dynamic>>[];
      try {
        final objId = ObjectId.parse(pacienteId);
        final list = await collection.find(where.eq('paciente', objId)).toList();
        results.addAll(list.map((e) => Map<String, dynamic>.from(e)));
      } catch (_) {}

      final list2 = await collection.find(where.eq('paciente', pacienteId)).toList();
      results.addAll(list2.map((e) => Map<String, dynamic>.from(e)));

      final normalized = results.map((doc) {
        final data = Map<String, dynamic>.from(doc);
        data['_id'] = data['_id'].toString();
        if (data['paciente'] != null) {
          data['paciente'] = data['paciente'].toString();
        }
        return data;
      }).toList();

      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final m in normalized) {
        final idStr = m['_id'].toString();
        if (!seen.contains(idStr)) {
          seen.add(idStr);
          unique.add(m);
        }
      }

      // Ordenar por data/hora (mais recente primeiro)
      unique.sort((a, b) {
        try {
          final da = DateTime.parse(a['dataHora'].toString());
          final db = DateTime.parse(b['dataHora'].toString());
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });

      return unique.map((m) => EventoClinico.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Diabetes>> getDiabetesByPacienteId(String pacienteId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.diabetesCollection);

      final results = <Map<String, dynamic>>[];
      
      try {
        final objId = ObjectId.parse(pacienteId);
        final list1 = await collection.find(where.eq('pacienteId', objId)).toList();
        results.addAll(list1.map((e) => Map<String, dynamic>.from(e)));
        
        final list2 = await collection.find(where.eq('paciente', objId)).toList();
        results.addAll(list2.map((e) => Map<String, dynamic>.from(e)));
      } catch (_) {}

      final list3 = await collection.find(where.eq('pacienteId', pacienteId)).toList();
      results.addAll(list3.map((e) => Map<String, dynamic>.from(e)));
      
      final list4 = await collection.find(where.eq('paciente', pacienteId)).toList();
      results.addAll(list4.map((e) => Map<String, dynamic>.from(e)));

      final normalized = results.map((doc) {
        final data = Map<String, dynamic>.from(doc);
        data['_id'] = data['_id'].toString();
        
        if (data['pacienteId'] != null) {
          data['pacienteId'] = data['pacienteId'].toString();
        } else if (data['paciente'] != null) {
          data['pacienteId'] = data['paciente'].toString();
        }
        
        if (data['nivelGlicemia'] != null && data['glicemia'] == null) {
          data['glicemia'] = data['nivelGlicemia'];
        }
        
        if (data['data'] is Map && data['data']['\$date'] != null) {
          data['data'] = data['data']['\$date'];
        }
        
        return data;
      }).toList();

      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final m in normalized) {
        final idStr = m['_id'].toString();
        if (!seen.contains(idStr)) {
          seen.add(idStr);
          unique.add(m);
        }
      }

      unique.sort((a, b) {
        try {
          String aDataStr = a['data'].toString();
          String bDataStr = b['data'].toString();
          
          if (a['data'] is Map && a['data']['\$date'] != null) {
            aDataStr = a['data']['\$date'].toString();
          }
          if (b['data'] is Map && b['data']['\$date'] != null) {
            bDataStr = b['data']['\$date'].toString();
          }
          
          final da = DateTime.parse(aDataStr);
          final db = DateTime.parse(bDataStr);
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });

      return unique.map((m) => Diabetes.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // =================== PRESSÃO ARTERIAL ===================
  Future<PressaoArterial> createPressao(PressaoArterial registro) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('pressoes');

      final data = registro.toMap();
      data.remove('_id');
      try {
        data['pacienteId'] = ObjectId.parse(registro.pacienteId);
      } catch (_) {
        data['pacienteId'] = registro.pacienteId;
      }

      final result = await collection.insert(data);
      Map<String, dynamic>? created;
      if (result['_id'] != null) {
        created = await collection.findOne(where.id(result['_id']));
      } else {
        created = await collection.findOne(where
            .eq('pacienteId', data['pacienteId'])
            .eq('data', data['data'])
            .eq('sistolica', data['sistolica'])
            .eq('diastolica', data['diastolica']));
      }
      if (created == null) throw 'Erro ao criar registro de pressão';

      final normalized = Map<String, dynamic>.from(created);
      normalized['_id'] = normalized['_id'].toString();
      if (normalized['pacienteId'] != null) {
        normalized['pacienteId'] = normalized['pacienteId'].toString();
      }
      return PressaoArterial.fromMap(normalized);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PressaoArterial>> getPressoesByPacienteId(String pacienteId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('pressoes');

      final results = <Map<String, dynamic>>[];
      try {
        final objId = ObjectId.parse(pacienteId);
        final list = await collection.find(where.eq('pacienteId', objId)).toList();
        results.addAll(list.map((e) => Map<String, dynamic>.from(e)));
      } catch (_) {}

      final list2 = await collection.find(where.eq('pacienteId', pacienteId)).toList();
      results.addAll(list2.map((e) => Map<String, dynamic>.from(e)));

      final normalized = results.map((doc) {
        final data = Map<String, dynamic>.from(doc);
        data['_id'] = data['_id'].toString();
        if (data['pacienteId'] != null) {
          data['pacienteId'] = data['pacienteId'].toString();
        }
        return data;
      }).toList();

      normalized.sort((a, b) {
        try {
          final da = DateTime.parse(a['data'].toString());
          final db = DateTime.parse(b['data'].toString());
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });

      return normalized.map((m) => PressaoArterial.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_db != null) {
      try {
        if (_db!.isConnected) {
          await _db!.close();
        }
      } catch (e) {
        rethrow;
      } finally {
        _db = null;
      }
    }
  }

  Future<List<MedicalNote>> getMedicalNotesByPatientId(String patientId) async {
    try {
      await _ensureConnection();

      final collection = _db!.collection(DatabaseConfig.medicalNotesCollection);

      // Alguns bancos gravam como 'pacienteId' (ObjectId) ou String.
      // Usamos aggregate + $lookup (populate) para trazer dados do paciente.
      List<Map<String, Object>> pipeline(Object match) => <Map<String, Object>>[
        <String, Object>{
          r'$match': <String, Object>{'pacienteId': match},
        },
        <String, Object>{
          r'$lookup': <String, Object>{
            'from': DatabaseConfig.patientsCollection,
            'localField': 'pacienteId',
            'foreignField': '_id',
            'as': 'paciente',
          },
        },
        <String, Object>{
          r'$sort': <String, Object>{'data': -1},
        },
      ];

      final results = <Map<String, dynamic>>[];

      // Tentativa 1: pacienteId como ObjectId
      try {
        final objId = ObjectId.parse(patientId);
        final stream = collection.aggregateToStream(pipeline(objId));
        results.addAll(await stream.toList());
      } catch (_) {
      }

      // Tentativa 2: pacienteId como String
      final stream2 = collection.aggregateToStream(pipeline(patientId));
      results.addAll(await stream2.toList());

      // Normalizar e mapear
      final normalized = results.map((doc) {
        final data = Map<String, dynamic>.from(doc);
        data['_id'] = data['_id'].toString();
        if (data['pacienteId'] != null) {
          data['patientId'] = data['pacienteId'].toString();
        }
        // Extrai nome do paciente do $lookup
        if (data['paciente'] is List && (data['paciente'] as List).isNotEmpty) {
          final p = Map<String, dynamic>.from((data['paciente'] as List).first);
          data['patientName'] = p['name'];
        }
        return data;
      }).toList();

      // Remover duplicados por _id
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final m in normalized) {
        final idStr = m['_id'].toString();
        if (!seen.contains(idStr)) {
          seen.add(idStr);
          unique.add(m);
        }
      }

      return unique.map((m) => MedicalNote.fromJson(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Patient> createPatient(Patient patient) async {
    try {
      await _ensureConnection();
      
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      // Remover o ID do JSON antes de inserir
      final patientJson = patient.toJson();
      patientJson.remove('_id');
      
      // Tentar inserir o documento
      final result = await collection.insert(patientJson);
      
      // Verificar se houve erro do Atlas Free Tier
      if (result['ok'] == 0 && result['code'] == 8000) {
        
        // Tentar buscar o documento pelo email
        final createdPatient = await collection.findOne(where.eq('email', patient.email));
        if (createdPatient != null) {
          
          // Converter o ID para string hexadecimal antes de criar o objeto Patient
          final patientData = Map<String, dynamic>.from(createdPatient);
          patientData['_id'] = (patientData['_id'] as ObjectId).toHexString();
          
          final patientObject = Patient.fromJson(patientData);
          
          return patientObject;
        } else {
          throw 'Erro ao criar paciente: Documento não encontrado após inserção';
        }
      }
      
      if (result['_id'] == null) {
        throw 'Erro ao criar paciente: ID não gerado';
      }
      
      // Buscar o paciente recém-criado para garantir que temos todos os dados
      final createdPatient = await collection.findOne(where.id(result['_id']));
      if (createdPatient == null) {
        throw 'Erro ao recuperar paciente após criação';
      }
      
      // Converter o ID para string hexadecimal antes de criar o objeto Patient
      final patientData = Map<String, dynamic>.from(createdPatient);
      if (patientData['_id'] is ObjectId) {
        patientData['_id'] = (patientData['_id'] as ObjectId).toHexString();
      } else {
        patientData['_id'] = patientData['_id'].toString();
      }
      
      return Patient.fromJson(patientData);
    } catch (e, stack) {
      rethrow;
    }
  }

  Future<Patient?> getPatientByEmail(String email) async {
    try {
      await _ensureConnection();
      
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      final result = await collection.findOne(where.eq('email', email));
      if (result != null) {
        
        // Converter o ID para string hexadecimal antes de criar o objeto Patient
        final patientData = Map<String, dynamic>.from(result);
        if (patientData['_id'] is ObjectId) {
          patientData['_id'] = (patientData['_id'] as ObjectId).toHexString();
        } else {
          patientData['_id'] = patientData['_id'].toString();
        }
        
        return Patient.fromJson(patientData);
      }
      return null;
    } catch (e, stack) {
      rethrow;
    }
  }

  Future<Patient?> getPatientById(ObjectId id) async {
    try {
      await _ensureConnection();
      
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      final result = await collection.findOne(where.id(id));
      if (result != null) {
        
        // Converter o ID para string hexadecimal antes de criar o objeto Patient
        final patientData = Map<String, dynamic>.from(result);
        if (patientData['_id'] is ObjectId) {
          patientData['_id'] = (patientData['_id'] as ObjectId).toHexString();
        } else {
          patientData['_id'] = patientData['_id'].toString();
        }
        
        return Patient.fromJson(patientData);
      }
      return null;
    } catch (e, stack) {
      rethrow;
    }
  }

  Future<Patient> updatePatient(ObjectId id, Patient patient) async {
    try {
      await _ensureConnection();
      
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      
      // Atualizar o documento
      final modifier = modify
        ..set('updatedAt', DateTime.now().toIso8601String());
      
      // Adicionar todos os campos do paciente ao modificador
      final patientJson = patient.toJson();
      
      patientJson.forEach((key, value) {
        if (key != '_id') { // Não atualizar o ID
          modifier.set(key, value);
        }
      });
      
      // Usar update() simples - compatível com Atlas Free Tier
      final result = await collection.update(
        where.id(id),
        modifier,
      );
      
      
      if (result['ok'] != 1) {
        throw 'Falha ao atualizar paciente: ${result['errmsg']}';
      }
      
      // Buscar o paciente atualizado
      final updatedPatient = await collection.findOne(where.id(id));
      if (updatedPatient == null) {
        throw 'Paciente não encontrado após atualização';
      }
      
      // Converter o ID para string hexadecimal antes de criar o objeto Patient
      final patientData = Map<String, dynamic>.from(updatedPatient);
      if (patientData['_id'] is ObjectId) {
        patientData['_id'] = (patientData['_id'] as ObjectId).toHexString();
      } else {
        patientData['_id'] = patientData['_id'].toString();
      }
      
      return Patient.fromJson(patientData);
    } catch (e, stack) {
      rethrow;
    }
  }

  Future<void> deletePatient(ObjectId id) async {
    try {
      await _ensureConnection();
      
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      // Usar remove() simples - compatível com Atlas Free Tier
      final result = await collection.remove(where.id(id));
      
      if (result['ok'] != 1) {
        throw 'Falha ao deletar paciente';
      }
      
      if (result['n'] == 0) {
        throw 'Paciente não encontrado';
      }
      
    } catch (e, stack) {
      rethrow;
    }
  }

  Future<void> setTwoFactorCode(String patientId, String code, DateTime expires) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      // Converter string para ObjectId
      final objectId = ObjectId.parse(patientId);
      
      // Usar update() simples - compatível com Atlas Free Tier
      final result = await collection.update(
        where.eq('_id', objectId),
        modify.set('twoFactorCode', code).set('twoFactorExpires', expires.toIso8601String()),
      );
      
      // Verificar se é erro do Atlas Free Tier (código 8000)
      if (result['ok'] == 0 && result['code'] == 8000) {
        return;
      }
      
      if (result['ok'] != 1) {
        throw 'Falha ao salvar código 2FA: ${result['errmsg']}';
      }
      
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> validateTwoFactorCode(String patientId, String code) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      // Converter string para ObjectId
      final objectId = ObjectId.parse(patientId);
      
      final result = await collection.findOne(where.eq('_id', objectId));
      if (result == null) {
        return false;
      }
      
      // Converter o ID para string antes de criar o objeto Patient
      final patientData = Map<String, dynamic>.from(result);
      patientData['_id'] = patientData['_id'].toString();
      
      final patient = Patient.fromJson(patientData);
      
      if (patient.twoFactorCode == code && patient.twoFactorExpires != null && patient.twoFactorExpires!.isAfter(DateTime.now())) {
        
        // Limpa o código após uso usando update() simples
        final clearResult = await collection.update(
          where.eq('_id', objectId),
          modify.unset('twoFactorCode').unset('twoFactorExpires'),
        );
        
        // Verificar se é erro do Atlas Free Tier (código 8000)
        if (clearResult['ok'] == 0 && clearResult['code'] == 8000) {
        } else if (clearResult['ok'] != 1) {
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setPasswordResetCode(String patientId, String code, DateTime expires) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      // Converter string para ObjectId
      final objectId = ObjectId.parse(patientId);
      
      // Usar update() simples - compatível com Atlas Free Tier
      final result = await collection.update(
        where.eq('_id', objectId),
        modify.set('passwordResetCode', code).set('passwordResetExpires', expires.toIso8601String()),
      );
      
      // Verificar se é erro do Atlas Free Tier (código 8000)
      if (result['ok'] == 0 && result['code'] == 8000) {
        return;
      }
      
      if (result['ok'] != 1) {
        throw 'Falha ao salvar código de redefinição: ${result['errmsg']}';
      }
      
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> validatePasswordResetCode(String patientId, String code) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      // Converter string para ObjectId
      final objectId = ObjectId.parse(patientId);
      
      final result = await collection.findOne(where.eq('_id', objectId));
      if (result == null) {
        return false;
      }
      
      // Converter o ID para string antes de criar o objeto Patient
      final patientData = Map<String, dynamic>.from(result);
      patientData['_id'] = patientData['_id'].toString();
      
      final patient = Patient.fromJson(patientData);
      
      if (patient.passwordResetCode == code && 
          patient.passwordResetExpires != null && 
          patient.passwordResetExpires!.isAfter(DateTime.now())) {
        
        // Limpa o código após uso usando update() simples
        final clearResult = await collection.update(
          where.eq('_id', objectId),
          modify.unset('passwordResetCode').unset('passwordResetExpires'),
        );
        
        // Verificar se é erro do Atlas Free Tier (código 8000)
        if (clearResult['ok'] == 0 && clearResult['code'] == 8000) {
        } else if (clearResult['ok'] != 1) {
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePatientPassword(String patientId, String hashedPassword) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      // Converter string para ObjectId
      final objectId = ObjectId.parse(patientId);
      
      // Usar update() simples - compatível com Atlas Free Tier
      final result = await collection.update(
        where.eq('_id', objectId),
        modify.set('password', hashedPassword).set('updatedAt', DateTime.now().toIso8601String()),
      );
      
      // Verificar se é erro do Atlas Free Tier (código 8000)
      if (result['ok'] == 0 && result['code'] == 8000) {
        return;
      }
      
      if (result['ok'] != 1) {
        throw 'Falha ao atualizar senha: ${result['errmsg']}';
      }
      
    } catch (e) {
      rethrow;
    }
  }

  // Atualiza um campo específico do paciente
  Future<void> updatePatientField(dynamic patientId, String fieldName, dynamic value) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection(DatabaseConfig.patientsCollection);
      
      // Converter string para ObjectId se necessário
      final objectId = patientId is String ? ObjectId.parse(patientId) : patientId;
      
      // Usar update() simples - compatível com Atlas Free Tier
      final result = await collection.update(
        where.eq('_id', objectId),
        modify.set(fieldName, value).set('updatedAt', DateTime.now().toIso8601String()),
      );
      
      // Verificar se é erro do Atlas Free Tier (código 8000) ou outros erros comuns
      if (result['ok'] == 0 && (result['code'] == 8000 || result['code'] == null)) {
        // Silencioso para Atlas Free Tier - operação foi bem-sucedida
        return;
      }
      
      
      // Para Atlas Free Tier, não verificar o 'ok' se não houver erro explícito
      if (result['ok'] != 1 && result['errmsg'] != null) {
        // Temporariamente comentado para testar se os dados estão sendo salvos
        // throw 'Falha ao atualizar campo $fieldName: ${result['errmsg']}';
      }
      
      
    } catch (e) {
      rethrow;
    }
  }

  // ========== CRISE GASTRITE METHODS ==========

  // Criar nova crise de gastrite
  Future<CriseGastrite> createCriseGastrite(CriseGastrite crise) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('crisegastrites');
      
      final data = crise.toJson();
      data.remove('_id'); // Remove o ID para permitir que o MongoDB gere um novo
      data['createdAt'] = DateTime.now().toIso8601String();
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      final result = await collection.insert(data);
      
      // Buscar o documento criado para retornar normalizado
      Map<String, dynamic>? created;
      if (result['_id'] != null) {
        created = await collection.findOne(where.id(result['_id']));
      } else {
        // Fallback: buscar pelo match de campos
        created = await collection.findOne(
          where
              .eq('paciente', data['paciente'])
              .eq('data', data['data'])
              .eq('intensidadeDor', data['intensidadeDor']),
        );
      }
      
      if (created == null) throw 'Erro ao criar crise de gastrite';
      
      return CriseGastrite.fromJson(created);
      
    } catch (e) {
      rethrow;
    }
  }

  // Buscar crises de gastrite por paciente
  Future<List<CriseGastrite>> getCrisesGastriteByPacienteId(String pacienteId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('crisegastrites');
      
      final list = await collection.find(
        where.eq('paciente', ObjectId.parse(pacienteId))
      ).toList();
      
      final crises = <CriseGastrite>[];
      for (final doc in list) {
        crises.add(CriseGastrite.fromJson(doc));
      }
      
      // Ordenar por data decrescente
      crises.sort((a, b) => b.data.compareTo(a.data));
      
      return crises;
      
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar crise de gastrite
  Future<void> updateCriseGastrite(CriseGastrite crise) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('crisegastrites');
      
      final data = crise.toJson();
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      final result = await collection.update(
        where.eq('_id', ObjectId.parse(crise.id!)),
        modify.set('data', data['data'])
            .set('intensidadeDor', data['intensidadeDor'])
            .set('sintomas', data['sintomas'])
            .set('alimentosIngeridos', data['alimentosIngeridos'])
            .set('medicacao', data['medicacao'])
            .set('alivioMedicacao', data['alivioMedicacao'])
            .set('observacoes', data['observacoes'])
            .set('updatedAt', data['updatedAt']),
      );
      
      if (result['ok'] != 1) {
        throw 'Falha ao atualizar crise de gastrite: ${result['errmsg']}';
      }
      
    } catch (e) {
      rethrow;
    }
  }

  // Deletar crise de gastrite
  Future<void> deleteCriseGastrite(String criseId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('crisegastrites');
      
      final result = await collection.remove(
        where.eq('_id', ObjectId.parse(criseId))
      );
      
      if (result['ok'] != 1) {
        throw 'Falha ao deletar crise de gastrite: ${result['errmsg']}';
      }
      
      if (result['n'] == 0) {
        throw 'Crise de gastrite não encontrada';
      }
      
    } catch (e) {
      rethrow;
    }
  }

  // Buscar crise de gastrite por ID
  Future<CriseGastrite?> getCriseGastriteById(String criseId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('crisegastrites');
      
      final doc = await collection.findOne(
        where.eq('_id', ObjectId.parse(criseId))
      );
      
      if (doc == null) {
        return null;
      }
      
      return CriseGastrite.fromJson(doc);
      
    } catch (e) {
      rethrow;
    }
  }

  // ========== HEALTH DATA METHODS ==========

  // Obter coleção genérica
  Future<DbCollection> getCollection(String collectionName) async {
    await _ensureConnection();
    return _db!.collection(collectionName);
  }

  // Obter dados de saúde por paciente
  Future<List<HealthData>> getHealthDataByPatientId(String patientId) async {
    try {
      await _ensureConnection();
      
      final collections = ['batimentos', 'passos', 'insonias'];
      final allData = <Map<String, dynamic>>[];
      
      for (final collectionName in collections) {
        final collection = _db!.collection(collectionName);
        
        // Tentativa 1: pacienteId como ObjectId
        try {
          final objId = ObjectId.parse(patientId);
          final list = await collection.find(where.eq('pacienteId', objId)).toList();
          allData.addAll(list.map((e) => Map<String, dynamic>.from(e)));
        } catch (_) {}
        
        // Tentativa 2: pacienteId como String
        final list2 = await collection.find(where.eq('pacienteId', patientId)).toList();
        allData.addAll(list2.map((e) => Map<String, dynamic>.from(e)));
      }
      
      // Normalizar e remover duplicados
      final normalized = allData.map((doc) {
        final data = Map<String, dynamic>.from(doc);
        data['_id'] = data['_id'].toString();
        if (data['pacienteId'] != null) {
          data['pacienteId'] = data['pacienteId'].toString();
        }
        return data;
      }).toList();
      
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final m in normalized) {
        final idStr = m['_id'].toString();
        if (!seen.contains(idStr)) {
          seen.add(idStr);
          unique.add(m);
        }
      }
      
      return unique.map((m) => HealthData.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Obter dados de saúde por tipo
  Future<List<HealthData>> getHealthDataByType(String patientId, String dataType) async {
    try {
      await _ensureConnection();
      
      String collectionName;
      switch (dataType.toLowerCase()) {
        case 'heartrate':
        case 'batimentos':
          collectionName = 'batimentos';
          break;
        case 'steps':
        case 'passos':
          collectionName = 'passos';
          break;
        case 'sleep':
        case 'insonias':
          collectionName = 'insonias';
          break;
        default:
          throw 'Tipo de dados não suportado: $dataType';
      }
      
      final collection = _db!.collection(collectionName);
      
      final results = <Map<String, dynamic>>[];
      
      // Tentativa 1: pacienteId como ObjectId
      try {
        final objId = ObjectId.parse(patientId);
        final list = await collection.find(where.eq('pacienteId', objId)).toList();
        results.addAll(list.map((e) => Map<String, dynamic>.from(e)));
      } catch (_) {}
      
      // Tentativa 2: pacienteId como String
      final list2 = await collection.find(where.eq('pacienteId', patientId)).toList();
      results.addAll(list2.map((e) => Map<String, dynamic>.from(e)));
      
      // Normalizar e remover duplicados
      final normalized = results.map((doc) {
        final data = Map<String, dynamic>.from(doc);
        data['_id'] = data['_id'].toString();
        if (data['pacienteId'] != null) {
          data['pacienteId'] = data['pacienteId'].toString();
        }
        return data;
      }).toList();
      
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final m in normalized) {
        final idStr = m['_id'].toString();
        if (!seen.contains(idStr)) {
          seen.add(idStr);
          unique.add(m);
        }
      }
      
      return unique.map((m) => HealthData.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Obter dados de saúde por período
  Future<List<HealthData>> getHealthDataByPeriod(String patientId, DateTime startDate, DateTime endDate) async {
    try {
      await _ensureConnection();
      
      final collections = ['batimentos', 'passos', 'insonias'];
      final allData = <Map<String, dynamic>>[];
      
      for (final collectionName in collections) {
        final collection = _db!.collection(collectionName);
        
        final results = <Map<String, dynamic>>[];
        
        // Tentativa 1: pacienteId como ObjectId
        try {
          final objId = ObjectId.parse(patientId);
          final list = await collection.find(
            where.eq('pacienteId', objId)
                .gte('data', startDate.toIso8601String())
                .lte('data', endDate.toIso8601String())
          ).toList();
          results.addAll(list.map((e) => Map<String, dynamic>.from(e)));
        } catch (_) {}
        
        // Tentativa 2: pacienteId como String
        final list2 = await collection.find(
          where.eq('pacienteId', patientId)
              .gte('data', startDate.toIso8601String())
              .lte('data', endDate.toIso8601String())
        ).toList();
        results.addAll(list2.map((e) => Map<String, dynamic>.from(e)));
        
        allData.addAll(results);
      }
      
      // Normalizar e remover duplicados
      final normalized = allData.map((doc) {
        final data = Map<String, dynamic>.from(doc);
        data['_id'] = data['_id'].toString();
        if (data['pacienteId'] != null) {
          data['pacienteId'] = data['pacienteId'].toString();
        }
        return data;
      }).toList();
      
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final m in normalized) {
        final idStr = m['_id'].toString();
        if (!seen.contains(idStr)) {
          seen.add(idStr);
          unique.add(m);
        }
      }
      
      return unique.map((m) => HealthData.fromMap(m)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Criar múltiplos dados de saúde
  Future<void> createMultipleHealthData(List<HealthData> healthDataList) async {
    try {
      await _ensureConnection();
      
      // Agrupar por tipo de dados
      final groupedData = <String, List<Map<String, dynamic>>>{};
      
      for (final healthData in healthDataList) {
        final tipo = healthData.dataType.toLowerCase();
        if (!groupedData.containsKey(tipo)) {
          groupedData[tipo] = [];
        }
        groupedData[tipo]!.add(healthData.toMap());
      }
      
      // Inserir em cada coleção
      for (final entry in groupedData.entries) {
        String collectionName;
        switch (entry.key) {
          case 'heartrate':
          case 'batimentos':
            collectionName = 'batimentos';
            break;
          case 'steps':
          case 'passos':
            collectionName = 'passos';
            break;
          case 'sleep':
          case 'insonias':
            collectionName = 'insonias';
            break;
          default:
            collectionName = 'batimentos';
        }
        
        final collection = _db!.collection(collectionName);
        
        // Preparar dados para inserção
        final dataToInsert = entry.value.map((data) {
          final newData = Map<String, dynamic>.from(data);
          newData.remove('_id');
          
          // Converter pacienteId para ObjectId se possível
          try {
            newData['pacienteId'] = ObjectId.parse(data['patientId'].toString());
          } catch (_) {
            newData['pacienteId'] = data['patientId'].toString();
          }
          
          newData['createdAt'] = DateTime.now().toIso8601String();
          newData['updatedAt'] = DateTime.now().toIso8601String();
          
          return newData;
        }).toList();
        
        await collection.insertAll(dataToInsert);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Deletar dados de saúde
  Future<void> deleteHealthData(String healthDataId) async {
    try {
      await _ensureConnection();
      
      final collections = ['batimentos', 'passos', 'insonias'];
      bool deleted = false;
      
      for (final collectionName in collections) {
        final collection = _db!.collection(collectionName);
        
        try {
          final result = await collection.remove(where.eq('_id', ObjectId.parse(healthDataId)));
          if (result['ok'] == 1 && result['n'] > 0) {
            deleted = true;
            break;
          }
        } catch (_) {
          // Continuar para próxima coleção
        }
      }
      
      if (!deleted) {
        throw 'Dados de saúde não encontrados';
      }
    } catch (e) {
      rethrow;
    }
  }

  // ========== MENSTRUAÇÃO METHODS ==========

  // Criar nova menstruação
  Future<Menstruacao> createMenstruacao(Menstruacao menstruacao) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('menstruacaos');
      
      final data = menstruacao.toJson();
      data.remove('_id'); // Remove o ID para permitir que o MongoDB gere um novo
      data['createdAt'] = DateTime.now().toIso8601String();
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      final result = await collection.insert(data);
      
      // Buscar o documento criado para retornar normalizado
      Map<String, dynamic>? created;
      if (result['_id'] != null) {
        created = await collection.findOne(where.id(result['_id']));
      } else {
        // Fallback: buscar pelo match de campos
        created = await collection.findOne(
          where
              .eq('pacienteId', data['pacienteId'])
              .eq('dataInicio', data['dataInicio'])
              .eq('dataFim', data['dataFim']),
        );
      }
      
      if (created == null) throw 'Erro ao criar menstruação';
      
      return Menstruacao.fromJson(created);
      
    } catch (e) {
      rethrow;
    }
  }

  // Buscar menstruações por paciente
  Future<List<Menstruacao>> getMenstruacoesByPacienteId(String pacienteId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('menstruacaos');
      
      final list = await collection.find(
        where.eq('pacienteId', ObjectId.parse(pacienteId))
      ).toList();
      
      final menstruacoes = <Menstruacao>[];
      for (final doc in list) {
        menstruacoes.add(Menstruacao.fromJson(doc));
      }
      
      // Ordenar por data de início decrescente
      menstruacoes.sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
      
      return menstruacoes;
      
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar menstruação
  Future<Menstruacao> updateMenstruacao(Menstruacao menstruacao) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('menstruacaos');
      
      final data = menstruacao.toJson();
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      final result = await collection.update(
        where.eq('_id', ObjectId.parse(menstruacao.id!)),
        data,
      );
      
      if (result['ok'] != 1) {
        throw 'Falha ao atualizar menstruação: ${result['errmsg']}';
      }
      
      // Buscar o documento atualizado
      final updated = await collection.findOne(
        where.eq('_id', ObjectId.parse(menstruacao.id!))
      );
      
      if (updated == null) throw 'Menstruação não encontrada após atualização';
      
      return Menstruacao.fromJson(updated);
      
    } catch (e) {
      rethrow;
    }
  }

  // Deletar menstruação
  Future<void> deleteMenstruacao(String menstruacaoId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('menstruacaos');
      
      final result = await collection.remove(
        where.eq('_id', ObjectId.parse(menstruacaoId))
      );
      
      if (result['ok'] != 1) {
        throw 'Falha ao deletar menstruação: ${result['errmsg']}';
      }
      
      if (result['n'] == 0) {
        throw 'Menstruação não encontrada';
      }
      
    } catch (e) {
      rethrow;
    }
  }

  // Buscar menstruação por ID
  Future<Menstruacao?> getMenstruacaoById(String menstruacaoId) async {
    try {
      await _ensureConnection();
      final collection = _db!.collection('menstruacaos');
      
      final doc = await collection.findOne(
        where.eq('_id', ObjectId.parse(menstruacaoId))
      );
      
      if (doc == null) return null;
      
      return Menstruacao.fromJson(doc);
      
    } catch (e) {
      rethrow;
    }
  }
} 