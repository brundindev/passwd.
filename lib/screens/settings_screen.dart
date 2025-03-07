import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/password_service.dart';
import '../services/export_import_service.dart';
import '../services/app_settings_service.dart';
import '../services/inactivity_detector.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with InactivityDetectorMixin {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    // Usar el servicio de configuración para obtener los valores
    final settings = Provider.of<AppSettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Usar autenticación biométrica'),
            subtitle: const Text('Usar huella o Face ID para desbloquear'),
            trailing: Switch(
              value: settings.useBiometrics,
              onChanged: (value) {
                settings.setUseBiometrics(value);
              },
            ),
          ),
          ListTile(
            title: const Text('Bloqueo automático'),
            subtitle: const Text('Cerrar sesión automáticamente por inactividad'),
            trailing: Switch(
              value: settings.autoLock,
              onChanged: (value) {
                // Usamos el método seguro que evita completamente el cierre de sesión
                safeToggleAutoLock(value);
                
                // Forzamos la actualización del UI manualmente
                setState(() {});
                
                // En 200ms, actualizamos el UI de nuevo para reflejar el cambio
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    setState(() {});
                  }
                });
              },
            ),
          ),
          if (settings.autoLock)
            ListTile(
              title: const Text('Retraso de bloqueo'),
              subtitle: Text('${settings.autoLockDelay} minutos'),
              trailing: DropdownButton<int>(
                value: settings.autoLockDelay,
                items: [1, 2, 5, 10].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value min'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    // Usamos el método seguro para cambiar el retraso
                    safeSetAutoLockDelay(newValue);
                    
                    // Forzamos la actualización del UI
                    setState(() {});
                  }
                },
              ),
            ),
          ListTile(
            title: const Text('Mostrar códigos TOTP'),
            subtitle: const Text('Mostrar códigos de autenticación en la lista'),
            trailing: Switch(
              value: settings.showTOTPCodes,
              onChanged: (value) {
                settings.setShowTOTPCodes(value);
              },
            ),
          ),
          const Divider(),
          /*ListTile(
            title: const Text('Cambiar contraseña maestra'),
            leading: const Icon(Icons.lock),
            onTap: () {
              // Implementar cambio de contraseña maestra
              resetUserActivity(); // Registrar actividad del usuario
            },
          ),*/
          ListTile(
            title: const Text('Exportar contraseñas a CSV'),
            subtitle: const Text('Exportar a un formato compatible con navegadores'),
            leading: const Icon(Icons.download),
            trailing: _isExporting 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  ) 
                : null,
            onTap: _isExporting ? null : () {
              _exportPasswordsToCSV();
              resetUserActivity(); // Registrar actividad del usuario
            },
          ),
          ListTile(
            title: const Text('Importar contraseñas desde CSV'),
            subtitle: const Text('Importar desde archivos de otros gestores'),
            leading: const Icon(Icons.upload),
            trailing: _isImporting 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  ) 
                : null,
            onTap: _isImporting ? null : () {
              _importPasswordsFromCSV();
              resetUserActivity(); // Registrar actividad del usuario
            },
          ),
        ],
      ),
    );
  }
  
  /// Exporta las contraseñas a un archivo CSV
  Future<void> _exportPasswordsToCSV() async {
    setState(() {
      _isExporting = true;
    });
    
    try {
      final passwordService = Provider.of<PasswordService>(context, listen: false);
      final exportService = ExportImportService(passwordService);
      
      // Generar el contenido CSV
      final csvContent = await exportService.generatePasswordsCSV();
      
      // Permitir al usuario seleccionar la ubicación para guardar el archivo
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar contraseñas como CSV',
        fileName: 'passwd_export_${DateTime.now().millisecondsSinceEpoch}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      
      if (outputFile == null) {
        // Usuario canceló la operación
        if (mounted) {
          _showResultDialog('Exportación cancelada', 'No se seleccionó ninguna ubicación para guardar el archivo.');
        }
        return;
      }
      
      // Asegurarse de que la extensión sea .csv
      if (!outputFile.toLowerCase().endsWith('.csv')) {
        outputFile += '.csv';
      }
      
      // Guardar el archivo en la ubicación seleccionada
      final result = await exportService.savePasswordsToFile(csvContent, outputFile);
      
      if (mounted) {
        _showResultDialog('Exportación completada', result);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog('Error de exportación', 'No se pudieron exportar las contraseñas: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
  
  /// Importa contraseñas desde un archivo CSV
  Future<void> _importPasswordsFromCSV() async {
    try {
      // Mostrar selector de archivos
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return; // Usuario canceló
      }
      
      if (mounted) {
        setState(() {
          _isImporting = true;
        });
      }
      
      // Procesar el archivo seleccionado
      final file = File(result.files.single.path!);
      
      // Verificar que es un archivo CSV válido
      if (!file.path.toLowerCase().endsWith('.csv')) {
        _showResultDialog('Error de importación', 'El archivo seleccionado no es un archivo CSV válido.');
        setState(() {
          _isImporting = false;
        });
        return;
      }
      
      // Realizar la importación
      final passwordService = Provider.of<PasswordService>(context, listen: false);
      final importService = ExportImportService(passwordService);
      
      final importResult = await importService.importPasswordsFromCSV(file);
      
      // Mostrar resultado
      if (mounted) {
        _showResultDialog('Importación de contraseñas', importResult);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog('Error de importación', 'No se pudieron importar las contraseñas: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
  
  /// Muestra un diálogo con el resultado de la operación
  void _showResultDialog(String title, String message) {
    resetUserActivity(); // Registrar actividad del usuario al mostrar un diálogo
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetUserActivity(); // Registrar actividad al cerrar el diálogo
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
