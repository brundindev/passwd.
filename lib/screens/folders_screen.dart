import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../services/folder_service.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderService _folderService = FolderService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedColor = '#1E88E5'; // Color azul predeterminado
  bool _isLoading = false;
  
  final List<Map<String, dynamic>> _availableColors = [
    {'name': 'Azul', 'color': '#1E88E5'},
    {'name': 'Rojo', 'color': '#E53935'},
    {'name': 'Verde', 'color': '#43A047'},
    {'name': 'Amarillo', 'color': '#FDD835'},
    {'name': 'Morado', 'color': '#8E24AA'},
    {'name': 'Naranja', 'color': '#FB8C00'},
    {'name': 'Cian', 'color': '#00ACC1'},
    {'name': 'Gris', 'color': '#757575'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Convertir código hexadecimal a objeto Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _showAddFolderDialog() {
    _nameController.clear();
    _descriptionController.clear();
    _selectedColor = '#1E88E5';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nueva Carpeta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la carpeta',
                    hintText: 'Ingresa un nombre para la carpeta',
                  ),
                  style: TextStyle(color: Colors.grey[700]),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Describe el contenido de la carpeta',
                  ),
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableColors.map((colorMap) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = colorMap['color'];
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hexToColor(colorMap['color']),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == colorMap['color'] 
                              ? Colors.white 
                              : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingresa un nombre para la carpeta')),
                  );
                  return;
                }
                
                _addNewFolder();
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewFolder() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final newFolder = Folder(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
      );
      
      await _folderService.addFolder(newFolder);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Carpeta "${newFolder.name}" creada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la carpeta: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editFolder(Folder folder) async {
    _nameController.text = folder.name;
    _descriptionController.text = folder.description;
    _selectedColor = folder.color;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Carpeta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la carpeta',
                  ),
                  style: TextStyle(color: Colors.grey[700]),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableColors.map((colorMap) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = colorMap['color'];
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hexToColor(colorMap['color']),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == colorMap['color'] 
                              ? Colors.white 
                              : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingresa un nombre para la carpeta')),
                  );
                  return;
                }
                
                _updateFolder(folder);
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateFolder(Folder folder) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedFolder = folder.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
        lastModified: DateTime.now(),
      );
      
      await _folderService.updateFolder(updatedFolder);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Carpeta "${updatedFolder.name}" actualizada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la carpeta: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar carpeta'),
        content: Text('¿Estás seguro de que quieres eliminar la carpeta "${folder.name}"? '
                      'Las contraseñas no se eliminarán, solo se quitará la organización.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              
              try {
                await _folderService.deleteFolder(folder.id);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Carpeta "${folder.name}" eliminada correctamente')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar la carpeta: $e')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Carpetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFolderDialog,
            tooltip: 'Crear nueva carpeta',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Folder>>(
              stream: _folderService.getFolders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar las carpetas: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                final folders = snapshot.data ?? [];
                
                if (folders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No tienes carpetas creadas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crea carpetas para organizar tus contraseñas',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddFolderDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Crear Carpeta'),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _hexToColor(folder.color),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.folder,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(folder.name),
                        subtitle: folder.description.isNotEmpty
                            ? Text(folder.description)
                            : Text(
                                '${folder.passwordCount} contraseña${folder.passwordCount != 1 ? 's' : ''}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editFolder(folder),
                              tooltip: 'Editar carpeta',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteFolder(folder),
                              tooltip: 'Eliminar carpeta',
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FolderPasswordsScreen(folder: folder),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class FolderPasswordsScreen extends StatelessWidget {
  final Folder folder;
  
  const FolderPasswordsScreen({
    super.key,
    required this.folder,
  });
  
  @override
  Widget build(BuildContext context) {
    final folderService = FolderService();
    
    // Convertir código hexadecimal a objeto Color
    Color hexToColor(String hexString) {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
        backgroundColor: hexToColor(folder.color),
      ),
      body: StreamBuilder(
        stream: folderService.getPasswordsInFolder(folder.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar las contraseñas: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          
          final passwords = snapshot.data ?? [];
          
          if (passwords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.vpn_key, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay contraseñas en esta carpeta',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Añade contraseñas a esta carpeta desde el listado principal',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: passwords.length,
            itemBuilder: (context, index) {
              final password = passwords[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: Text(password.sitio),
                  subtitle: Text(password.usuario),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Quitar de la carpeta'),
                          content: Text('¿Quieres quitar "${password.sitio}" de esta carpeta?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                try {
                                  await folderService.removePasswordFromFolder(
                                    password.id, 
                                    folder.id
                                  );
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Contraseña quitada de "${folder.name}"')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                              child: const Text('Quitar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    // Navegar a la pantalla de detalle de la contraseña
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 