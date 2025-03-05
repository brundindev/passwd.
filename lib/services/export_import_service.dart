import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/password.dart';
import 'password_service.dart';

class ExportImportService {
  final PasswordService _passwordService;

  ExportImportService(this._passwordService);

  /// Genera el contenido CSV de todas las contraseñas sin guardarlo
  Future<String> generatePasswordsCSV() async {
    try {
      // Obtener todas las contraseñas (solo en memoria, no como stream)
      final passwords = await _getPasswordsList();
      
      if (passwords.isEmpty) {
        throw Exception('No hay contraseñas para exportar');
      }

      // Crear contenido CSV
      String csvContent = 'url,username,password,notes\n';
      
      for (var password in passwords) {
        // Formatear cada campo correctamente para CSV
        // Escapar comillas en los campos
        final sitio = _escapeCSVField(password.sitio);
        final usuario = _escapeCSVField(password.usuario);
        final pass = _escapeCSVField(password.password);
        final notas = ''; // No tenemos notas en nuestro modelo
        
        // Añadir fila
        csvContent += '$sitio,$usuario,$pass,$notas\n';
      }
      
      return csvContent;
    } catch (e) {
      debugPrint('Error al generar CSV de contraseñas: $e');
      rethrow;
    }
  }

  /// Exporta todas las contraseñas a un archivo CSV en la ubicación especificada
  Future<String> savePasswordsToFile(String content, String filePath) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return 'Contraseñas exportadas correctamente a: $filePath';
    } catch (e) {
      debugPrint('Error al guardar el archivo CSV: $e');
      return 'Error al guardar el archivo: $e';
    }
  }

  /// La función anterior para mantener compatibilidad
  /// Exporta todas las contraseñas a un archivo CSV
  Future<String> exportPasswordsToCSV() async {
    try {
      // Obtener todas las contraseñas (solo en memoria, no como stream)
      final passwords = await _getPasswordsList();
      
      if (passwords.isEmpty) {
        return 'No hay contraseñas para exportar';
      }

      // Crear contenido CSV
      String csvContent = 'url,username,password,notes\n';
      
      for (var password in passwords) {
        // Formatear cada campo correctamente para CSV
        // Escapar comillas en los campos
        final sitio = _escapeCSVField(password.sitio);
        final usuario = _escapeCSVField(password.usuario);
        final pass = _escapeCSVField(password.password);
        final notas = ''; // No tenemos notas en nuestro modelo
        
        // Añadir fila
        csvContent += '$sitio,$usuario,$pass,$notas\n';
      }
      
      // Guardar archivo
      final file = await _saveCSVFile(csvContent, 'passwd_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      
      return 'Contraseñas exportadas correctamente a: ${file.path}';
    } catch (e) {
      debugPrint('Error al exportar contraseñas: $e');
      return 'Error al exportar contraseñas: $e';
    }
  }

  /// Importa contraseñas desde un archivo CSV
  Future<String> importPasswordsFromCSV(File file) async {
    try {
      // Leer el archivo
      String fileContent = await file.readAsString();
      
      // Dividir en líneas
      List<String> lines = LineSplitter.split(fileContent).toList();
      
      // Verificar si hay contenido
      if (lines.isEmpty) {
        return 'El archivo está vacío';
      }
      
      // Obtener encabezados (primera línea)
      String headerLine = lines.first;
      List<String> headers = _parseCSVLine(headerLine);
      
      // Verificar formato compatible
      if (!_isValidCSVFormat(headers)) {
        return 'Formato CSV no compatible. Se requiere al menos URL, username y password';
      }
      
      // Procesar datos
      int importedCount = 0;
      int errorCount = 0;
      
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        
        try {
          List<String> fields = _parseCSVLine(lines[i]);
          
          // Crear contraseña a partir de los campos
          // Asumimos un formato básico: URL, usuario, contraseña, notas
          if (fields.length >= 3) {
            final newPassword = Password(
              id: '', // Se generará al guardar
              sitio: fields[0],
              usuario: fields[1],
              password: fields[2],
              fechaCreacion: DateTime.now(),
              ultimaModificacion: DateTime.now(),
              isFavorite: false,
              isInTrash: false,
              deletedAt: null,
            );
            
            // Guardar contraseña
            await _passwordService.addPassword(newPassword);
            importedCount++;
          } else {
            errorCount++;
          }
        } catch (e) {
          debugPrint('Error importando línea $i: $e');
          errorCount++;
        }
      }
      
      return 'Importación completada: $importedCount contraseñas importadas, $errorCount errores';
    } catch (e) {
      debugPrint('Error al importar contraseñas: $e');
      return 'Error al importar contraseñas: $e';
    }
  }

  // Métodos auxiliares
  
  /// Obtiene todas las contraseñas como lista (no como stream)
  Future<List<Password>> _getPasswordsList() async {
    // Esperar a que el stream emita al menos una vez
    final completer = Completer<List<Password>>();
    final subscription = _passwordService.getPasswords().listen(
      (passwords) {
        if (!completer.isCompleted) {
          completer.complete(passwords);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      }
    );
    
    try {
      final result = await completer.future;
      await subscription.cancel();
      return result;
    } catch (e) {
      await subscription.cancel();
      rethrow;
    }
  }

  /// Guarda el contenido CSV en un archivo
  Future<File> _saveCSVFile(String content, String filename) async {
    Directory? directory;
    if (!kIsWeb) {
      // En plataformas móviles, guardar en directorio de documentos
      directory = await getApplicationDocumentsDirectory();
    } else {
      // En web, no podemos guardar directamente, habría que usar una solución de descarga
      throw UnsupportedError('La exportación de CSV no está disponible en web');
    }
    
    final file = File('${directory.path}/$filename');
    return await file.writeAsString(content);
  }
  
  /// Escapa un campo para CSV (añade comillas si es necesario)
  String _escapeCSVField(String field) {
    // Si el campo contiene comas, comillas o saltos de línea, lo envolvemos entre comillas
    // y reemplazamos las comillas por comillas dobles
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
  
  /// Analiza una línea de CSV, respetando campos entre comillas
  List<String> _parseCSVLine(String line) {
    List<String> fields = [];
    bool inQuotes = false;
    StringBuffer currentField = StringBuffer();
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        // Si encontramos una comilla, puede ser inicio/fin de campo o una comilla escapada
        if (i + 1 < line.length && line[i + 1] == '"') {
          // Comilla escapada (""): añadir una comilla y saltar la siguiente
          currentField.write('"');
          i++; // Saltar la siguiente comilla
        } else {
          // Cambiar estado de estar dentro o fuera de comillas
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Final de campo (si no estamos dentro de comillas)
        fields.add(currentField.toString());
        currentField.clear();
      } else {
        // Caracter normal, añadir al campo actual
        currentField.write(char);
      }
    }
    
    // Añadir el último campo
    fields.add(currentField.toString());
    
    return fields;
  }
  
  /// Verifica si los encabezados del CSV tienen un formato compatible
  bool _isValidCSVFormat(List<String> headers) {
    // Verificar que al menos existan los campos básicos (pueden estar en cualquier orden)
    List<String> lowercaseHeaders = headers.map((h) => h.toLowerCase()).toList();
    
    // Verificación flexible: si tenemos al menos estos campos o similares
    bool hasUrl = lowercaseHeaders.any((h) => h.contains('url') || h.contains('sitio') || h.contains('site') || h.contains('web'));
    bool hasUsername = lowercaseHeaders.any((h) => h.contains('user') || h.contains('usuario') || h.contains('name') || h.contains('login'));
    bool hasPassword = lowercaseHeaders.any((h) => h.contains('pass') || h.contains('contraseña') || h.contains('password'));
    
    return hasUrl && hasUsername && hasPassword;
  }
}