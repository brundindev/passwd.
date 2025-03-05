import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/password.dart';
import '../services/password_service.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import '../widgets/password_list_item.dart';
import 'settings_screen.dart';

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

  // Función para generar contraseñas aleatorias seguras
  String generateRandomPassword({int length = 12}) {
    final Random random = Random.secure();
    const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
    const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String numberChars = '0123456789';
    const String specialChars = '!@#%&*_?';
    
    final String allChars = lowercaseChars + uppercaseChars + numberChars + specialChars;
    
    // Asegurar que hay al menos uno de cada tipo de caracter
    String password = '';
    password += lowercaseChars[random.nextInt(lowercaseChars.length)];
    password += uppercaseChars[random.nextInt(uppercaseChars.length)];
    password += numberChars[random.nextInt(numberChars.length)];
    password += specialChars[random.nextInt(specialChars.length)];
    
    // Rellenar con caracteres aleatorios
    for (int i = 4; i < length; i++) {
      password += allChars[random.nextInt(allChars.length)];
    }
    
    // Mezclar todos los caracteres
    final List<String> passwordChars = password.split('');
    passwordChars.shuffle(random);
    
    return passwordChars.join('');
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
          children: [
            Container(
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
            SizedBox(height: 24),
            Text(
              '¿Estás seguro de que quieres eliminar esta contraseña permanentemente?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
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
    // Variables para almacenar los datos del formulario
    String sitio = '';
    String usuario = '';
    String password = '';
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
                  controller: TextEditingController(text: password),
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
                              password = newPassword;
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
                    password = value ?? '';
                  },
                  onChanged: (value) {
                    password = value;
                  },
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
                        Text("Guardando contraseña...", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            );
            
            try {
              final passwordService = Provider.of<PasswordService>(context, listen: false);
              
              // Crear nueva Password
              final newPassword = Password(
                sitio: sitio,
                usuario: usuario,
                password: password,
              );
              
              // Guardar la contraseña
              await passwordService.addPassword(newPassword);
              
              // Cerrar el diálogo de carga y el formulario
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              
              // Mostrar mensaje de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Contraseña guardada correctamente'),
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
                  content: Text('Error al guardar la contraseña: $e'),
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
      title: 'Nueva contraseña',
      actions: actions,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Color de texto blanco para el título
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
}
