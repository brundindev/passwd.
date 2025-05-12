import 'package:flutter/material.dart';
import '../services/folder_service.dart';

// Componente de selección de carpetas con estilos mejorados
class FolderSelectorScreen extends StatelessWidget {
  final String? selectedFolderId;
  final Function(String?) onChange;

  const FolderSelectorScreen({
    Key? key,
    required this.selectedFolderId,
    required this.onChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final folderService = FolderService();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera con título
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                color: isDarkMode ? Colors.white : Colors.black87,
                size: 28,
              ),
              SizedBox(width: 16),
              Text(
                'Seleccionar carpeta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        
        Divider(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          height: 1,
        ),
        
        // Lista de carpetas
        Expanded(
          child: StreamBuilder<List<dynamic>>(
            stream: folderService.getFolders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode ? Colors.white70 : Colors.blue,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar carpetas',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.red.shade700,
                    ),
                  ),
                );
              }

              final folders = snapshot.data as List<dynamic>;
              
              return ListView(
                children: [
                  // Opción para todas las contraseñas
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.home_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      'Todas las contraseñas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: selectedFolderId == null ? FontWeight.bold : FontWeight.normal,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: selectedFolderId == null,
                    trailing: selectedFolderId == null
                      ? Icon(Icons.check_circle_rounded, color: Colors.green)
                      : null,
                    onTap: () => onChange(null),
                  ),
                  
                  // Mostrar opciones de carpetas
                  if (folders.isEmpty)
                    _buildEmptyFolderMessage(context, isDarkMode)
                  else
                    ...folders.map((folder) => _buildFolderItem(
                      context, 
                      folder, 
                      selectedFolderId == folder.id,
                      () => onChange(folder.id),
                      isDarkMode,
                    )).toList(),
                  
                  Divider(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    height: 1,
                  ),
                  
                  // Opción para crear nueva carpeta
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      'Crear nueva carpeta',
                      style: TextStyle(
                        fontSize: 17,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/folders');
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyFolderMessage(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 64,
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No tienes carpetas creadas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Crea carpetas para organizar tus contraseñas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/folders');
            },
            icon: Icon(Icons.add),
            label: Text('Crear carpeta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFolderItem(
    BuildContext context,
    dynamic folder,
    bool isSelected,
    VoidCallback onTap,
    bool isDarkMode,
  ) {
    // Convertir color hexadecimal a Color
    Color folderColor;
    try {
      final buffer = StringBuffer();
      buffer.write('ff'); // Opacidad completa
      buffer.write(folder.color.replaceFirst('#', ''));
      folderColor = Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      folderColor = Colors.blue;
    }
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: folderColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.folder_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        folder.name,
        style: TextStyle(
          fontSize: 17,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: folder.description != null && folder.description.isNotEmpty
        ? Text(
            folder.description,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          )
        : Text(
            "${folder.passwordCount ?? '0'} contraseñas",
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
      selected: isSelected,
      trailing: isSelected
        ? Icon(Icons.check_circle_rounded, color: Colors.green)
        : null,
      onTap: onTap,
    );
  }
} 