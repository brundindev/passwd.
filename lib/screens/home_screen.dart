import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/password.dart';
import '../services/password_service.dart';
import '../services/auth_service.dart';
import '../services/password_generator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import '../widgets/password_list_item.dart';
import 'settings_screen.dart';
import 'folders_screen.dart';
import '../services/folder_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingAuth = true;
  final bool _isLoadingPasswords = true;
  String? _errorMessage;
  final String _currentSection = 'all'; // 'all', 'favorites', 'trash'
  String _searchQuery = '';
  int _currentIndex = 0;
  String? _selectedFolderId;
  final FolderService _folderService = FolderService();

  // Utilizar el servicio PasswordGenerator en lugar de la implementación local
  String generateRandomPassword({int length = 12}) {
    return PasswordGenerator.generateRandomPassword(
      length: length,
      useUpperCase: true,
      useLowerCase: true,
      useNumbers: true,
      useSpecialChars: true,
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Esperar un momento para dar tiempo al sistema de autenticación
    await Future.delayed(Duration(milliseconds: 500));
    
    if (mounted) {
      final currentUser = FirebaseAuth.instance.currentUser;
      print("HomeScreen initState - Usuario actual: ${currentUser?.uid ?? 'No autenticado'}");
      
      setState(() {
        _isLoadingAuth = false;
      });

      // Si no hay usuario autenticado, navegar a la pantalla de bienvenida
      if (currentUser == null && mounted) {
        print("Usuario no autenticado en HomeScreen - redirigiendo a WelcomeScreen");
        Future.microtask(() {
          Navigator.of(context).pushReplacementNamed('/welcome');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    String title = "Todas las contraseñas";
    
    if (_currentIndex == 1) {
      title = "Favoritos";
    } else if (_currentIndex == 2) {
      title = "Papelera";
    }
    
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text("No has iniciado sesión"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: PopupMenuButton(
              offset: Offset(0, 56),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: currentUser.photoURL != null 
                        ? Colors.transparent 
                        : Colors.blue.shade200,
                    backgroundImage: currentUser.photoURL != null 
                        ? NetworkImage(currentUser.photoURL!) 
                        : null,
                    child: currentUser.photoURL == null
                        ? Text(
                            currentUser.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 8),
                  Text(
                    currentUser.email ?? 'Usuario',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('Mi perfil'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'folders',
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined),
                      SizedBox(width: 8),
                      Text('Mis Carpetas'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'profile') {
                  Navigator.pushNamed(context, '/profile');
                } else if (value == 'folders') {
                  Navigator.pushNamed(context, '/folders');
                } else if (value == 'logout') {
                  await _showLogoutDialog();
                }
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(""),
              accountEmail: Text(currentUser.email ?? ""),
              currentAccountPicture: CircleAvatar(
                backgroundColor: currentUser.photoURL != null 
                    ? Colors.transparent 
                    : Colors.blue.shade200,
                backgroundImage: currentUser.photoURL != null 
                    ? NetworkImage(currentUser.photoURL!) 
                    : null,
                child: currentUser.photoURL == null
                    ? Text(
                        currentUser.email?.substring(0, 1).toUpperCase() ?? "",
                        style: TextStyle(
                          fontSize: 40.0,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            ListTile(
              leading: Icon(Icons.password),
              title: Text('Todas las contraseñas'),
              selected: _currentIndex == 0,
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.star),
              title: Text('Favoritos'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Papelera'),
              selected: _currentIndex == 2,
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.folder_outlined),
              title: Text('Mis Carpetas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/folders');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar contraseñas',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ),
          
          // Selector de carpetas
          if (_currentIndex == 0) // Solo mostrar en la vista de todas las contraseñas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: FutureBuilder(
                future: _getFolders(),
        builder: (context, snapshot) {
                  String folderText = 'Seleccionar carpeta';
                  
                  if (_selectedFolderId != null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                      folderText = 'Cargando carpeta...';
                    } else if (snapshot.hasData) {
                      final folders = snapshot.data as List;
                      for (var folder in folders) {
                        if (folder.id == _selectedFolderId) {
                          folderText = 'Carpeta: ${folder.name}';
                          break;
                        }
                      }
                    } else {
                      folderText = 'Carpeta seleccionada';
                    }
                  }
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          _showFolderSelectionMenu(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                color: Theme.of(context).primaryColor,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  folderText,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Contenido principal
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 2 ? null : FloatingActionButton(
        onPressed: () {
          _showAddPasswordDialog(context);
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.password),
            label: 'Contraseñas',
          ),
          NavigationDestination(
            icon: Icon(Icons.star),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.delete),
            label: 'Papelera',
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    // Si todavía estamos verificando la autenticación, mostrar una pantalla de carga
    if (_isLoadingAuth) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Cargando datos del usuario..."),
          ],
        ),
      );
    }

    // Obtener el usuario actual directamente
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 20),
            Text("No se ha podido verificar tu sesión"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/welcome');
              },
              child: Text("Volver al inicio"),
            ),
          ],
        ),
      );
    }

    // Si ya hemos confirmado que hay un usuario autenticado, cargar la pantalla normal
    print("Construyendo HomeScreen para usuario: ${currentUser.uid}");
    final passwordService = Provider.of<PasswordService>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<List<Password>>(
      stream: _getPasswordStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
          }
          
          if (snapshot.hasError) {
            return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  "Error al cargar las contraseñas",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          );
        }
        
        List<Password> passwords = snapshot.data ?? [];
        
        // Aplicar filtro de búsqueda
        passwords = _filterPasswords(passwords);
          
          if (passwords.isEmpty) {
          IconData iconData;
          String message;
          
          if (_currentIndex == 1) {
            iconData = Icons.star_border;
            message = "No tienes contraseñas favoritas";
          } else if (_currentIndex == 2) {
            iconData = Icons.delete_outline;
            message = "No hay elementos en la papelera";
          } else if (_searchQuery.isNotEmpty) {
            iconData = Icons.search_off;
            message = "No se encontraron resultados para '$_searchQuery'";
          } else {
            iconData = Icons.vpn_key_outlined;
            message = "No tienes contraseñas guardadas";
          }
          
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Icon(iconData, size: 72, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                  message,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),

                ),
                if (_currentIndex == 0 && _searchQuery.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAddPasswordDialog(context);
                      },
                      icon: Icon(Icons.add),
                      label: Text("Añadir contraseña"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
          padding: EdgeInsets.only(top: 8),
            itemCount: passwords.length,
            itemBuilder: (context, index) {
              final password = passwords[index];
            return _buildPasswordListItem(password);
            },
          );
        },
    );
  }
  
  Stream<List<Password>> _getPasswordStream() {
    final passwordService = Provider.of<PasswordService>(context, listen: false);
    
    if (_currentIndex == 1) {
      // Favoritos
      return passwordService.getFavoritePasswords();
    } else if (_currentIndex == 2) {
      // Papelera
      return passwordService.getTrashPasswords();
    } else if (_selectedFolderId != null) {
      // Contraseñas de la carpeta seleccionada
      return _folderService.getPasswordsInFolder(_selectedFolderId!);
    } else {
      // Todas las contraseñas (no eliminadas)
      return passwordService.getPasswords();
    }
  }
  
  List<Password> _filterPasswords(List<Password> passwords) {
    if (_searchQuery.isEmpty) return passwords;
    
    return passwords.where((password) {
      return password.sitio.toLowerCase().contains(_searchQuery) ||
             password.usuario.toLowerCase().contains(_searchQuery);
    }).toList();
  }
  
  Widget _buildPasswordListItem(Password password) {
    return PasswordListItem(
      password: password,
      onToggleFavorite: () => _toggleFavorite(password),
      onDelete: () => _deletePassword(password),
      onView: () => _showPasswordDetails(password),
      onEdit: () => _editPassword(password),
      onAddToFolder: () => _showAddToFolderDialog(password),
      isInTrash: _currentIndex == 2,
      onRestore: _currentIndex == 2 ? () => _restorePassword(password) : null,
    );
  }

  Future<void> _toggleFavorite(Password password) async {
    final passwordService = Provider.of<PasswordService>(context, listen: false);
    try {
      final updatedPassword = Password(
        id: password.id,
        sitio: password.sitio,
        usuario: password.usuario,
        password: password.password,
        fechaCreacion: password.fechaCreacion,
        ultimaModificacion: password.ultimaModificacion,
        isFavorite: !(password.isFavorite ?? false),
      );
      
      await passwordService.updatePassword(updatedPassword);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedPassword.isFavorite 
            ? 'Añadido a favoritos' 
            : 'Eliminado de favoritos'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar favorito: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _deletePassword(Password password) async {
    final passwordService = Provider.of<PasswordService>(context, listen: false);
    
    try {
      if (_currentIndex == 2) {
        // Eliminación permanente
        Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: Text(
                '¿Estás seguro de que quieres eliminar esta contraseña permanentemente?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Esta acción no se puede deshacer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );

        List<Widget> actions = [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await passwordService.deletePasswordPermanently(password.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Contraseña eliminada permanentemente'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Eliminar', style: TextStyle(fontSize: 16)),
          ),
        ];

        _showModernModal(
            context,
          content,
          title: 'Eliminar permanentemente',
          actions: actions,
        );
      } else {
        // Mover a la papelera
        await passwordService.movePasswordToTrash(password.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contraseña movida a la papelera'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'DESHACER',
              onPressed: () async {
                await passwordService.restorePasswordFromTrash(password.id);
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la contraseña: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  Future<void> _restorePassword(Password password) async {
    final passwordService = Provider.of<PasswordService>(context, listen: false);
    
    try {
      await passwordService.restorePasswordFromTrash(password.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contraseña restaurada'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al restaurar la contraseña: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 60, 
          width: 60, 
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            strokeWidth: 5,
          )
        ),
        SizedBox(height: 24),
        Text(
          'Cerrando sesión...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Por favor, espera un momento',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    // Usar showDialog directamente para el diálogo de cierre de sesión, con ancho personalizado
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            ),
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 320), // Ancho más estrecho
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    
    await Future.delayed(Duration(seconds: 2));
    
    await AuthService().signOut();
    
    Navigator.of(context).pop();
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => WelcomeScreen()),
      (route) => false,
    );
  }

  bool _isPasswordFavorite(Password password) {
    return password.isFavorite ?? false;
  }

  void _editPassword(Password password) {
    // Variables para almacenar los datos del formulario
    String sitio = password.sitio;
    String usuario = password.usuario;
    String passwordText = password.password;
    bool isFavorite = password.isFavorite;
    List<String> selectedFolderIds = List.from(password.folderIds);
    String selectedFolderName = '';
    
    if (selectedFolderIds.isNotEmpty) {
      // Obtener nombre de la primera carpeta (para simplicidad)
      _folderService.getFolders().first.then((folders) {
        for (var folder in folders) {
          if (folder.id == selectedFolderIds.first) {
            selectedFolderName = folder.name;
            break;
          }
        }
      });
    }
    
    final formKey = GlobalKey<FormState>();
    bool showPassword = false;
    
    Widget content = StatefulBuilder(
      builder: (context, setDialogState) {
        return Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: sitio,
                  style: TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Sitio web',
                    prefixIcon: Icon(Icons.web),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el nombre del sitio';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    sitio = value ?? '';
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  initialValue: usuario,
                  style: TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    // El usuario es opcional
                    return null;
                  },
                  onSaved: (value) {
                    usuario = value ?? '';
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: TextEditingController(text: passwordText),
                  style: TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
                          tooltip: 'Generar contraseña segura',
                          onPressed: () {
                            final newPassword = generateRandomPassword();
                            setDialogState(() {
                              passwordText = newPassword;
                              showPassword = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  obscureText: !showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la contraseña';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    passwordText = value ?? '';
                  },
                  onChanged: (value) {
                    passwordText = value;
                  },
                ),
                SizedBox(height: 20),
                
                // Selector de carpeta
                InkWell(
                  onTap: () {
                    // Cerrar temporalmente este diálogo
                    Navigator.of(context).pop();
                    
                    // Abrir el selector de carpetas personalizado
                    _showFolderSelectorDialog(
                      context, 
                      selectedFolderIds, 
                      (newSelectedIds, newSelectedName) {
                        // Actualizar los IDs y nombre seleccionados
                        setState(() {
                          selectedFolderIds = newSelectedIds;
                          selectedFolderName = newSelectedName;
                        });
                        
                        // Volver a abrir el diálogo de editar contraseña
                        _editPassword(password);
                      }
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.folder_outlined, color: Theme.of(context).primaryColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedFolderIds.isEmpty 
                              ? 'Sin carpeta asignada' 
                              : 'Carpeta: $selectedFolderName',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: isFavorite,
                      onChanged: (value) {
                        setDialogState(() {
                          isFavorite = value ?? false;
                        });
                      },
                      activeColor: Colors.amber,
                      checkColor: Colors.white,
                    ),
                    Text(
                      'Marcar como favorito', 
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );

    List<Widget> actions = [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text('Cancelar', style: TextStyle(fontSize: 16)),
      ),
      SizedBox(width: 8),
      ElevatedButton(
        onPressed: () async {
          if (formKey.currentState!.validate()) {
            formKey.currentState!.save();
            
            // Mostrar indicador de carga
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
              child: Row(
                      mainAxisSize: MainAxisSize.min,
                children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 24),
                        Text("Actualizando contraseña...", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            );
            
            try {
              final passwordService = Provider.of<PasswordService>(context, listen: false);
              
              // Crear la contraseña actualizada
              final updatedPassword = password.copyWith(
                sitio: sitio,
                usuario: usuario,
                password: passwordText,
                isFavorite: isFavorite,
                folderIds: selectedFolderIds,
                ultimaModificacion: DateTime.now(),
              );
              
              // Actualizar la contraseña
              await passwordService.updatePassword(updatedPassword);
              
              // Cerrar el diálogo de carga y el formulario
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              
              // Mostrar mensaje de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Contraseña actualizada correctamente'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } catch (e) {
              // Cerrar el diálogo de carga
              Navigator.of(context).pop();
              
              // Mostrar error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al actualizar la contraseña: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('Guardar', style: TextStyle(fontSize: 16)),
      ),
    ];

    _showModernModal(
      context, 
      content, 
      title: 'Editar contraseña',
      actions: actions,
    );
  }

  void _showPasswordDetails(Password password) {
    bool showPassword = false;
    String domain = password.sitio.toLowerCase();
    
    // Extraer dominio para el icono
    if (domain.startsWith('http://')) {
      domain = domain.substring(7);
    } else if (domain.startsWith('https://')) {
      domain = domain.substring(8);
    }
    if (domain.startsWith('www.')) {
      domain = domain.substring(4);
    }
    int slashIndex = domain.indexOf('/');
    if (slashIndex != -1) {
      domain = domain.substring(0, slashIndex);
    }
    
    Widget content = StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      domain.isNotEmpty ? domain[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              _buildDetailItem(Icons.web, 'Sitio web', password.sitio),
              SizedBox(height: 12),
              _buildDetailItem(Icons.person, 'Usuario', password.usuario),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF2C2C2C), // Gris oscuro para el fondo
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                        Icon(Icons.lock, color: Colors.grey.shade300, size: 20),
                        SizedBox(width: 8),
                Text(
                          'Contraseña',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            showPassword ? password.password : '••••••••••••',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: showPassword ? null : 'monospace',
                              color: Colors.white, // Texto blanco para la contraseña
                            ),
                          ),
                ),
                IconButton(
                  icon: Icon(
                            showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                              showPassword = !showPassword;
                    });
                  },
                ),
                        IconButton(
                          icon: Icon(Icons.copy, color: Theme.of(context).primaryColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: password.password));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Contraseña copiada al portapapeles'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                        ),
                        // Botón para añadir a carpeta
                        IconButton(
                          icon: Icon(Icons.folder_open, color: Theme.of(context).primaryColor),
                          tooltip: 'Añadir a carpeta',
                          onPressed: () {
                            Navigator.pop(context); // Cerrar el diálogo de detalles
                            _showAddToFolderDialog(password);
                  },
                ),
              ],
            ),
          ],
        ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(Icons.calendar_today, 'Creada', _formatDate(password.fechaCreacion)),
                  ),
                  Expanded(
                    child: _buildDetailItem(Icons.update, 'Modificada', _formatDate(password.ultimaModificacion)),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    password.isFavorite ? Icons.star : Icons.star_border,
                    color: password.isFavorite ? Colors.amber : Colors.grey.shade400,
                  ),
                  SizedBox(width: 8),
                  Text(
                    password.isFavorite ? 'Marcada como favorita' : 'No es favorita',
                    style: TextStyle(
                      color: password.isFavorite ? Colors.amber.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );

    List<Widget> actions = [
                    TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text('Cerrar', style: TextStyle(fontSize: 16)),
      ),
      SizedBox(width: 8),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          _editPassword(password);
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('Editar', style: TextStyle(fontSize: 16)),
      ),
    ];

    _showModernModal(
                context,
      content,
      title: 'Detalles de la contraseña',
      actions: actions,
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2C), // Gris más oscuro para los contenedores de detalle
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade300, size: 20), // Icono más claro
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300, // Texto más claro para la etiqueta
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white, // Texto blanco para el valor
            ),
          ),
        ],
                ),
              );
            }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddPasswordDialog(BuildContext context) {
    List<String> selectedFolderIds = _selectedFolderId != null ? [_selectedFolderId!] : [];
    String selectedFolderName = '';
    
    if (_selectedFolderId != null) {
      _folderService.getFolders().first.then((folders) {
        for (var folder in folders) {
          if (folder.id == _selectedFolderId) {
            selectedFolderName = folder.name;
            break;
          }
        }
      });
    }
    
    showDialog(
                context: context,
      builder: (dialogContext) {
        final TextEditingController siteController = TextEditingController();
        final TextEditingController usernameController = TextEditingController();
        final TextEditingController passwordController = TextEditingController();
        bool showPassword = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Añadir contraseña'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: siteController,
                      style: TextStyle(color: Colors.grey[700]),
                      decoration: InputDecoration(
                        labelText: 'Sitio web o aplicación',
                        prefixIcon: Icon(Icons.web),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: usernameController,
                      style: TextStyle(color: Colors.grey[700]),
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario o email',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      style: TextStyle(color: Colors.grey[700]),
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                showPassword ? Icons.visibility_off : Icons.visibility,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh),
                              onPressed: () {
                                passwordController.text = generateRandomPassword();
                                // Mostrar la contraseña nueva automáticamente
                                setState(() {
                                  showPassword = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Selector de carpeta
                    InkWell(
                      onTap: () {
                        // En lugar de cerrar y volver a abrir el diálogo, muestra el selector de carpetas
                        // como otro diálogo modal que se abrirá encima del actual
                        _showFolderSelectorDialog(
                          context, 
                          selectedFolderIds, 
                          (newSelectedIds, newSelectedName) {
                            // Actualizar los IDs y nombre seleccionados
                            setState(() {
                              selectedFolderIds = newSelectedIds;
                              selectedFolderName = newSelectedName;
                            });
                          }
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.folder_outlined, color: Theme.of(context).primaryColor),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedFolderIds.isEmpty 
                                  ? 'Seleccionar carpeta (opcional)' 
                                  : 'Carpeta: $selectedFolderName',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                  actions: [
                    TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                      child: Text('Cancelar'),
                    ),
                ElevatedButton(
                  onPressed: () {
                    // Validar campos
                    if (siteController.text.isEmpty || 
                        usernameController.text.isEmpty || 
                        passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Por favor, completa todos los campos')),
                      );
                      return;
                    }
                    
                    // Crear nueva contraseña
                    final newPassword = Password(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      sitio: siteController.text,
                      usuario: usernameController.text,
                      password: passwordController.text,
                      fechaCreacion: DateTime.now(),
                      ultimaModificacion: DateTime.now(),
                      isFavorite: false,
                      isInTrash: false,
                      folderIds: selectedFolderIds,
                    );
                    
                    // Guardar contraseña
                    Provider.of<PasswordService>(context, listen: false).addPassword(newPassword);
                    
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Contraseña añadida correctamente')),
                    );
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  // Método para mostrar el selector de carpetas como un diálogo superpuesto
  void _showFolderSelectorDialog(
    BuildContext context,
    List<String> currentSelectedIds,
    Function(List<String>, String) onSelect
  ) {
    List<String> selectedFolderIds = List.from(currentSelectedIds);
    String selectedFolderName = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Seleccionar carpeta'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: FutureBuilder(
              future: _getFolders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
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
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
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
                    return ListView(
                      children: [
                        // Opción "Sin carpeta"
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.folder_off,
                              color: Colors.grey[600],
                            ),
                          ),
                          title: Text(
                            'Sin carpeta',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          selected: selectedFolderIds.isEmpty,
                          trailing: selectedFolderIds.isEmpty
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : null,
                          onTap: () {
                            setState(() {
                              selectedFolderIds = [];
                              selectedFolderName = '';
                            });
                          },
                        ),
                        Divider(),
                        
                        // Lista de carpetas
                        ...folders.map((folder) {
                          // Convertir color hexadecimal a Color de Flutter
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
                          
                          final isSelected = selectedFolderIds.contains(folder.id);
                          
                          return ListTile(
                            leading: Container(
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
                            ),
                            title: Text(
                              folder.name,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.green)
                              : null,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedFolderIds.remove(folder.id);
                                  selectedFolderName = '';
                                } else {
                                  selectedFolderIds = [folder.id];
                                  selectedFolderName = folder.name;
                                }
                              });
                            },
                          );
                        }).toList(),
                      ],
                    );
                  }
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onSelect(selectedFolderIds, selectedFolderName);
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _showModernModal(BuildContext context, Widget content, {String title = '', List<Widget>? actions}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            ),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              backgroundColor: Color(0xFF212121), // Gris oscuro para el modal
              insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: title.isNotEmpty ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    if (title.isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: title == 'Eliminar permanentemente' 
                          ? Center(
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: content,
                    ),
                    if (actions != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Mostrar el menú de selección de carpetas
  void _showFolderSelectionMenu(BuildContext context) {
    // Obtener la lista de contraseñas para el conteo
    final passwordService = Provider.of<PasswordService>(context, listen: false);
    passwordService.getPasswords().first.then((passwords) {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
                children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Seleccionar carpeta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
              Divider(height: 0),
              FutureBuilder(
                future: _getFolders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Error al cargar las carpetas',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    );
                  }
                  
                  final folders = snapshot.data ?? [];
                  
                  if (folders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.folder_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No tienes carpetas creadas',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
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
                  
                  return Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        // Opción para mostrar todas las contraseñas
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.home,
                              color: Colors.black87,
                            ),
                          ),
                          title: Text(
                            'Todas las contraseñas',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          selected: _selectedFolderId == null,
                          onTap: () {
                            setState(() {
                              _selectedFolderId = null;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        Divider(),
                        // Lista de carpetas
                        ...folders.map((folder) {
                          // Convertir color hexadecimal a Color de Flutter
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
                          
                          // Contar las contraseñas que pertenecen a esta carpeta
                          final passwordCount = passwords.where((p) => p.folderIds.contains(folder.id)).length;
                          
                          return ListTile(
                            leading: Container(
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
                            ),
                            title: Text(
                              folder.name,
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                            subtitle: Text(
                              '$passwordCount contraseña${passwordCount != 1 ? 's' : ''}',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedFolderId = folder.id;
                              });
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                        Divider(),
                        // Opción para crear nueva carpeta
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            'Crear nueva carpeta',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/folders');
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    });
  }
  
  // Obtener lista de carpetas
  Future<List<dynamic>> _getFolders() async {
    try {
      // Simular carga de datos para dar tiempo a la UI
      await Future.delayed(Duration(milliseconds: 300));
      
      // Intentar obtener las carpetas de forma síncrona
      final folders = await _folderService.getFolders().first;
      return folders;
    } catch (e) {
      print('Error al cargar carpetas: $e');
      return [];
    }
  }
  
  // Mostrar diálogo para añadir contraseña a una carpeta
  void _showAddToFolderDialog(Password password) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Añadir a carpeta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 0),
            FutureBuilder(
              future: _getFolders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error al cargar las carpetas',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  );
                }
                
                final folders = snapshot.data ?? [];
                
                if (folders.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.folder_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No tienes carpetas creadas',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
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
                
                return Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Opción para quitar la contraseña de todas las carpetas
                      if (password.folderIds.isNotEmpty)
                        Column(
                          children: [
                            ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.folder_off,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                'Quitar de todas las carpetas',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'La contraseña aparecerá solo en "Todas las contraseñas"',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              onTap: () async {
                                try {
                                  final passwordService = Provider.of<PasswordService>(context, listen: false);
                                  
                                  // Crear una copia de la contraseña con folderIds vacío
                                  final updatedPassword = password.copyWith(folderIds: []);
                                  await passwordService.updatePassword(updatedPassword);
                                  
                                  Navigator.pop(context);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Contraseña quitada de todas las carpetas'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                            Divider(),
                          ],
                        ),
                        
                      // Lista de carpetas
                      ...folders.map((folder) {
                        // Convertir color hexadecimal a Color de Flutter
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
                        
                        // Verificar si la contraseña ya está en esta carpeta
                        bool isInFolder = password.folderIds.contains(folder.id);
                        
                        return ListTile(
                          leading: Container(
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
                          ),
                          title: Text(
                            folder.name,
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                          trailing: isInFolder 
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : null,
                          onTap: () async {
                            try {
                              final passwordService = Provider.of<PasswordService>(context, listen: false);
                              
                              // Si ya está en la carpeta, removerla
                              if (isInFolder) {
                                final updatedPassword = password.removeFromFolder(folder.id);
                                await passwordService.updatePassword(updatedPassword);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Contraseña eliminada de ${folder.name}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } 
                              // Si no está en la carpeta, añadirla
                              else {
                                final updatedPassword = password.addToFolder(folder.id);
                                await passwordService.updatePassword(updatedPassword);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Contraseña añadida a ${folder.name}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              
                              Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
