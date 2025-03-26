import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/password.dart';
import '../services/folder_service.dart';

class PasswordFolderMenu extends StatefulWidget {
  final Password password;
  
  const PasswordFolderMenu({
    super.key,
    required this.password,
  });

  @override
  _PasswordFolderMenuState createState() => _PasswordFolderMenuState();
}

class _PasswordFolderMenuState extends State<PasswordFolderMenu> {
  final FolderService _folderService = FolderService();
  bool _isLoading = false;
  
  // Convertir código hexadecimal a objeto Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
  
  Future<void> _toggleFolder(Folder folder) async {
    final isInFolder = widget.password.folderIds.contains(folder.id);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (isInFolder) {
        await _folderService.removePasswordFromFolder(widget.password.id, folder.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contraseña quitada de "${folder.name}"')),
        );
      } else {
        await _folderService.addPasswordToFolder(widget.password.id, folder.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contraseña añadida a "${folder.name}"')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Folder>>(
      stream: _folderService.getFolders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
        
        final folders = snapshot.data ?? [];
        
        if (folders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes carpetas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea una carpeta primero',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Cerrar el diálogo actual
                      Navigator.pop(context);
                      
                      // Navegar a la pantalla de carpetas
                      Navigator.pushNamed(context, '/folders');
                    },
                    child: const Text('Crear carpeta'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            final isInFolder = widget.password.folderIds.contains(folder.id);
            
            return ListTile(
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
                  : null,
              trailing: Checkbox(
                value: isInFolder,
                onChanged: (value) => _toggleFolder(folder),
              ),
              onTap: () => _toggleFolder(folder),
            );
          },
        );
      },
    );
  }
}

void showFolderMenu(BuildContext context, Password password) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Añadir a carpeta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: PasswordFolderMenu(password: password),
          ),
        ],
      );
    },
  );
} 