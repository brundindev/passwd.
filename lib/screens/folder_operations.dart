import 'package:flutter/material.dart';
import '../models/password.dart';
import '../models/folder.dart';
import '../services/folder_service.dart';

// Esta función muestra un diálogo para añadir una contraseña a una carpeta
void showAddToFolderDialog(BuildContext context, Password password) {
  final FolderService folderService = FolderService();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Añadir a carpeta'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: FutureBuilder(
          future: _getFolders(folderService),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar carpetas'));
            }
            
            final folders = snapshot.data ?? [];
            
            if (folders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No tienes carpetas creadas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Crea carpetas para organizar tus contraseñas',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/folders');
                      },
                      child: Text('Crear carpeta'),
                    ),
                  ],
                ),
              );
            }
            
            return StatefulBuilder(
              builder: (context, setState) {
                return ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final isInFolder = password.folderIds.contains(folder.id);
                    
                    return ListTile(
                      leading: _buildFolderIcon(folder),
                      title: Text(folder.name),
                      subtitle: Text('${folder.passwordCount} contraseñas'),
                      trailing: Checkbox(
                        value: isInFolder,
                        onChanged: (value) async {
                          try {
                            if (value == true) {
                              // Añadir a la carpeta
                              await folderService.addPasswordToFolder(
                                password.id, folder.id);
                            } else {
                              // Quitar de la carpeta
                              await folderService.removePasswordFromFolder(
                                password.id, folder.id);
                            }
                            
                            // Actualizar UI
                            setState(() {});
                            
                            // Mostrar mensaje de éxito
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(value == true 
                                ? 'Añadido a ${folder.name}' 
                                : 'Quitado de ${folder.name}'),
                              duration: Duration(seconds: 2),
                            ));
                          } catch (e) {
                            // Mostrar error
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        },
                      ),
                      onTap: () async {
                        try {
                          final newValue = !isInFolder;
                          if (newValue) {
                            // Añadir a la carpeta
                            await folderService.addPasswordToFolder(
                              password.id, folder.id);
                          } else {
                            // Quitar de la carpeta
                            await folderService.removePasswordFromFolder(
                              password.id, folder.id);
                          }
                          
                          // Actualizar UI
                          setState(() {});
                          
                          // Mostrar mensaje de éxito
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(newValue 
                              ? 'Añadido a ${folder.name}' 
                              : 'Quitado de ${folder.name}'),
                            duration: Duration(seconds: 2),
                          ));
                        } catch (e) {
                          // Mostrar error
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ));
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cerrar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/folders');
          },
          child: Text('Gestionar carpetas'),
        ),
      ],
    ),
  );
}

// Obtener carpetas de forma asíncrona
Future<List<Folder>> _getFolders(FolderService folderService) async {
  try {
    final folders = await folderService.getFolders().first;
    return folders;
  } catch (e) {
    print('Error al cargar carpetas: $e');
    return [];
  }
}

// Construir icono de carpeta con su color
Widget _buildFolderIcon(Folder folder) {
  Color folderColor;
  try {
    final buffer = StringBuffer();
    buffer.write('ff'); // Opacidad completa
    buffer.write(folder.color.replaceFirst('#', ''));
    folderColor = Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    // Usar color predeterminado si hay error
    folderColor = Colors.blue;
  }
  
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: folderColor,
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.folder,
      color: Colors.white,
    ),
  );
} 