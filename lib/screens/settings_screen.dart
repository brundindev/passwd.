import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/password_service.dart';
import '../services/export_import_service.dart';
import '../services/app_settings_service.dart';
import '../services/inactivity_detector.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Color(0xFFF2F2F7), // Color de fondo estilo iOS
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 20),
        children: [
          // Sección de seguridad
          _buildSectionHeader('SEGURIDAD'),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                title: 'Bloqueo automático',
                subtitle: 'Cerrar sesión por inactividad',
                leading: _buildIconContainer(
                  icon: Icons.lock_clock,
                  color: Colors.green,
                ),
                trailing: Switch.adaptive(
                  value: settings.autoLock,
                  activeColor: Colors.blue,
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
                divider: settings.autoLock,
              ),
              if (settings.autoLock)
                _buildSettingsTile(
                  title: 'Retraso de bloqueo',
                  subtitle: '${settings.autoLockDelay} minutos',
                  leading: _buildIconContainer(
                    icon: Icons.timer_outlined,
                    color: Colors.orange,
                  ),
              trailing: DropdownButton<int>(
                    value: settings.autoLockDelay,
                    underline: SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
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
                  divider: false,
                ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Sección de preferencias
          _buildSectionHeader('PREFERENCIAS'),
          _buildSettingsCard(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: AbsorbPointer(
                  child: Opacity(
                    opacity: 0.5,
                    child: _buildSettingsTile(
                      title: 'Autenticación biométrica',
                      subtitle: 'Habilitar desbloqueo con huella o FaceID',
                      leading: Stack(
                        children: [
                          _buildIconContainer(
                            icon: Icons.fingerprint,
                            color: Colors.grey,
                          ),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Switch.adaptive(
                        value: false,
                        activeColor: Colors.grey,
                        onChanged: null,
                      ),
                      divider: true,
                    ),
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: AbsorbPointer(
                  child: Opacity(
                    opacity: 0.5,
                    child: _buildSettingsTile(
                      title: 'Mostrar códigos TOTP',
                      subtitle: 'Funcionalidad temporalmente deshabilitada',
                      leading: Stack(
                        children: [
                          _buildIconContainer(
                            icon: Icons.qr_code,
                            color: Colors.grey,
                          ),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Switch.adaptive(
                        value: false,
                        activeColor: Colors.grey,
                        onChanged: null,
                      ),
                      divider: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Sección de datos
          _buildSectionHeader('DATOS'),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                title: 'Exportar contraseñas',
                subtitle: 'Exportar a formato CSV',
                leading: _buildIconContainer(
                  icon: Icons.download_rounded,
                  color: Colors.blue,
                ),
                trailing: _isExporting
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
                onTap: _isExporting ? null : () {
                  _exportPasswordsToCSV();
                  resetUserActivity();
                },
                divider: true,
              ),
              _buildSettingsTile(
                title: 'Importar contraseñas',
                subtitle: 'Importar desde archivos CSV',
                leading: _buildIconContainer(
                  icon: Icons.upload_rounded,
                  color: Colors.green,
                ),
                trailing: _isImporting
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
                onTap: _isImporting ? null : () {
                  _importPasswordsFromCSV();
                  resetUserActivity();
                },
                divider: false,
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Sección de información
          _buildSectionHeader('INFORMACIÓN'),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                title: 'Versión',
                subtitle: 'PASSWD v1.0',
                leading: _buildIconContainer(
                  icon: Icons.info_outline,
                  color: Colors.grey,
                ),
                divider: false,
              ),
            ],
          ),
          
          SizedBox(height: 30),
          
          // Texto de copyright
          Center(
            child: Text(
              'PASSWD. © 2025 brundindev.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
  
  // Construye un encabezado de sección
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
  
  // Construye una tarjeta para agrupar elementos de configuración
  Widget _buildSettingsCard({required List<Widget> children}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
  
  // Construye un elemento de configuración dentro de una tarjeta
  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required Widget leading,
    Widget? trailing,
    bool divider = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                leading,
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          if (divider)
            Divider(
              height: 1,
              indent: 56,
              endIndent: 16,
            ),
        ],
      ),
    );
  }
  
  // Construye un contenedor para iconos con fondo y color personalizado
  Widget _buildIconContainer({required IconData icon, required Color color}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
