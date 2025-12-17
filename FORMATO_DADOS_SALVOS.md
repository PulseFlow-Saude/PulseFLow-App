# 📋 Formato dos Dados Salvos - PulseFlow App

Este documento descreve onde e como os dados de **Hormônios**, **Diabetes** e **Pressão Arterial** são salvos no MongoDB.

---

## 🔬 1. HORMÔNIOS

### Coleção
- **Nome**: `hormonais`

### Formato do Documento
```json
{
  "_id": ObjectId("..."),
  "paciente": "string",  // ID do paciente (pode ser ObjectId como string)
  "hormonio": "string",  // Nome do hormônio (ex: "TSH", "T3", "Cortisol", etc.)
  "valor": double,       // Valor numérico do hormônio
  "data": "ISO8601",     // Data no formato ISO8601 (string)
  "createdAt": "ISO8601", // Data de criação (string)
  "updatedAt": "ISO8601"  // Data de atualização (string)
}
```

### Exemplo
```json
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),
  "paciente": "507f191e810c19729de860ea",
  "hormonio": "TSH",
  "valor": 2.5,
  "data": "2024-01-15T10:30:00.000Z",
  "createdAt": "2024-01-15T10:30:05.123Z",
  "updatedAt": "2024-01-15T10:30:05.123Z"
}
```

### Campos Principais
- `paciente`: ID do paciente (não usa `pacienteId`, usa `paciente`)
- `hormonio`: Nome do hormônio como string
- `valor`: Valor numérico (double)
- `data`: Data da medição (ISO8601 string)

### Localização no Código
- **Salvamento**: `lib/screens/hormonal/hormonal_controller.dart` (linha 79)
- **Modelo**: `lib/models/hormonal.dart`

---

## 🩺 2. DIABETES

### Coleção
- **Nome**: `diabetes`

### Formato do Documento
```json
{
  "_id": ObjectId("..."),
  "pacienteId": ObjectId("...") | "string",  // ID do paciente (ObjectId ou string)
  "data": "ISO8601",     // Data no formato ISO8601 (string)
  "glicemia": double,    // Valor da glicemia
  "unidade": "string"    // Unidade: "mg/dL" ou "mmol/L"
}
```

### Exemplo
```json
{
  "_id": ObjectId("507f1f77bcf86cd799439012"),
  "pacienteId": ObjectId("507f191e810c19729de860ea"),
  "data": "2024-01-15T08:00:00.000Z",
  "glicemia": 95.5,
  "unidade": "mg/dL"
}
```

### Campos Principais
- `pacienteId`: ID do paciente (pode ser ObjectId ou string)
- `data`: Data da medição (ISO8601 string)
- `glicemia`: Valor da glicemia (double)
- `unidade`: Unidade de medida ("mg/dL" ou "mmol/L")

### Localização no Código
- **Salvamento**: `lib/services/database_service.dart` (linha 224)
- **Modelo**: `lib/models/diabetes.dart`
- **Config**: `lib/config/database_config.dart` → `diabetesCollection = 'diabetes'`

---

## 💓 3. PRESSÃO ARTERIAL

### Coleção
- **Nome**: `pressoes`

### Formato do Documento
```json
{
  "_id": ObjectId("..."),
  "pacienteId": ObjectId("...") | "string",  // ID do paciente (ObjectId ou string)
  "data": "ISO8601",     // Data no formato ISO8601 (string)
  "sistolica": double,   // Pressão sistólica (mmHg)
  "diastolica": double   // Pressão diastólica (mmHg)
}
```

### Exemplo
```json
{
  "_id": ObjectId("507f1f77bcf86cd799439013"),
  "pacienteId": ObjectId("507f191e810c19729de860ea"),
  "data": "2024-01-15T14:30:00.000Z",
  "sistolica": 120.0,
  "diastolica": 80.0
}
```

### Campos Principais
- `pacienteId`: ID do paciente (pode ser ObjectId ou string)
- `data`: Data da medição (ISO8601 string)
- `sistolica`: Pressão sistólica em mmHg (double)
- `diastolica`: Pressão diastólica em mmHg (double)

### Localização no Código
- **Salvamento**: `lib/services/database_service.dart` (linha 577)
- **Modelo**: `lib/models/pressao_arterial.dart`

---

## 📊 RESUMO

| Tipo | Coleção | Campo ID do Paciente | Campos Específicos |
|------|---------|---------------------|-------------------|
| **Hormônios** | `hormonais` | `paciente` (string) | `hormonio`, `valor`, `data`, `createdAt`, `updatedAt` |
| **Diabetes** | `diabetes` | `pacienteId` (ObjectId/string) | `glicemia`, `unidade`, `data` |
| **Pressão Arterial** | `pressoes` | `pacienteId` (ObjectId/string) | `sistolica`, `diastolica`, `data` |

---

## ⚠️ OBSERVAÇÕES IMPORTANTES

1. **Inconsistência no campo do paciente**:
   - Hormônios usa `paciente` (string)
   - Diabetes e Pressão usam `pacienteId` (ObjectId ou string)

2. **Formato de Data**:
   - Todos salvam datas como **ISO8601 strings** (`data.toIso8601String()`)

3. **Formato do ID do Paciente**:
   - O código tenta converter para ObjectId primeiro, se falhar usa como string
   - Isso permite compatibilidade com dados existentes

4. **Campos Adicionais**:
   - Hormônios inclui `createdAt` e `updatedAt`
   - Diabetes e Pressão não incluem esses campos automaticamente

---

## 🔍 CONSULTAS ÚTEIS

### Buscar todos os hormônios de um paciente
```javascript
db.hormonais.find({ paciente: "ID_DO_PACIENTE" })
```

### Buscar todos os registros de diabetes de um paciente
```javascript
db.diabetes.find({ pacienteId: ObjectId("ID_DO_PACIENTE") })
// ou
db.diabetes.find({ pacienteId: "ID_DO_PACIENTE" })
```

### Buscar todos os registros de pressão de um paciente
```javascript
db.pressoes.find({ pacienteId: ObjectId("ID_DO_PACIENTE") })
// ou
db.pressoes.find({ pacienteId: "ID_DO_PACIENTE" })
```

---

**Última atualização**: Dezembro 2024








