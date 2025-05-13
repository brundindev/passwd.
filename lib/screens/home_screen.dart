import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';
import '../models/password.dart';
import '../services/password_service.dart';
import '../services/auth_service.dart';
import '../services/password_generator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import '../widgets/password_list_item.dart';
import 'settings_screen.dart';
import '../services/folder_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'folder_selector_screen.dart';

class AppDesign {
  // Colores principales
  static const Color primaryBlue = Color(0xFF3A7BF2);
  static const Color secondaryBlue = Color(0xFF2E5ED9);
  static const Color accentPurple = Color(0xFF8C61FF);
  static const Color accentGreen = Color(0xFF1ED696);
  static const Color accentOrange = Color(0xFFFF9950);
  
  // Colores para modo oscuro y claro
  static const Color darkBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1E1E22);
  static const Color darkCard = Color(0xFF2A2A30);
  
  static const Color lightBackground = Color(0xFFF8F9FD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF2F4F9);
  
  // Estilos de texto
  static TextStyle headingStyle(bool isDark) => TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 24,
    color: isDark ? Colors.white : Colors.black87,
    letterSpacing: -0.5,
  );
  
  static TextStyle subtitleStyle(bool isDark) => TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: isDark ? Colors.white70 : Colors.black54,
  );
  
  // Decoraciones
  static BoxDecoration cardDecoration(bool isDark) => BoxDecoration(
    color: isDark ? darkCard : lightCard,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: isDark ? Colors.black26 : Colors.black.withOpacity(0.06),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
    border: Border.all(
      color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.1),
      width: 1,
    ),
  );
  
  // Duración estándar de animaciones
  static const Duration animDuration = Duration(milliseconds: 300);
  static const Duration animDurationSlow = Duration(milliseconds: 500);
}

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
  bool _isDarkMode = true; // Por defecto iniciamos en modo oscuro, como está actualmente

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

    // Usar el valor de _isDarkMode para definir el tema
    final isDarkMode = _isDarkMode;

    return Theme(
      // Wrap con Theme para aplicar el tema basado en _isDarkMode
      data: isDarkMode 
        ? ThemeData.dark().copyWith(
            primaryColor: AppDesign.primaryBlue,
            scaffoldBackgroundColor: AppDesign.darkBackground,
            appBarTheme: AppBarTheme(
              backgroundColor: AppDesign.darkBackground,
              elevation: 0,
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: AppDesign.primaryBlue,
            scaffoldBackgroundColor: AppDesign.lightBackground,
            appBarTheme: AppBarTheme(
              backgroundColor: AppDesign.lightBackground,
              elevation: 0,
            ),
          ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: isDarkMode 
                    ? Colors.black.withOpacity(0.6) 
                    : Colors.white.withOpacity(0.7),
                toolbarHeight: 70,
                elevation: 0,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                leading: Builder(
                  builder: (context) => MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? Colors.grey.shade900.withOpacity(0.5) 
                              : Colors.grey.shade200.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            CupertinoIcons.sidebar_left,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            size: 22,
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          tooltip: 'Menú',
                        ),
                      ),
                    ),
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: isDarkMode ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                actions: [
                  // Botón de recarga de contraseñas
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppDesign.primaryBlue.withOpacity(isDarkMode ? 0.2 : 0.1),
                            AppDesign.accentPurple.withOpacity(isDarkMode ? 0.15 : 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          CupertinoIcons.arrow_clockwise,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          size: 20,
                        ),
                        tooltip: 'Recargar contraseñas',
                        onPressed: () {
                          _refreshPasswords();
                        },
                      ),
                    ),
                  ),
                  
                  // Selector de tema (claro/oscuro)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      height: 40,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [Color(0xFF2C2C36), Color(0xFF1E1E28)]
                              : [Color(0xFFF0F0F5), Color(0xFFE8E8F0)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Icono de modo oscuro
                          AnimatedOpacity(
                            opacity: isDarkMode ? 1.0 : 0.4,
                            duration: AppDesign.animDuration,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                    ? Color(0xFF35354D).withOpacity(0.7)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                CupertinoIcons.moon_stars_fill,
                                color: isDarkMode ? Colors.white : Colors.black54,
                                size: 20,
                              ),
                            ),
                          ),
                          
                          // Switch personalizado
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isDarkMode = !_isDarkMode;
                                });
                              },
                              child: AnimatedContainer(
                                duration: AppDesign.animDuration,
                                width: 40,
                                height: 22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: isDarkMode 
                                      ? Colors.grey.shade800 
                                      : Colors.grey.shade300,
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedPositioned(
                                      duration: AppDesign.animDuration,
                                      curve: Curves.easeOutBack,
                                      left: isDarkMode ? 20 : 2,
                                      top: 2,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isDarkMode
                                                ? [Colors.white, Colors.grey.shade300]
                                                : [AppDesign.accentOrange, Colors.yellow],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                              spreadRadius: -2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Icono de modo claro
                          AnimatedOpacity(
                            opacity: !isDarkMode ? 1.0 : 0.4,
                            duration: AppDesign.animDuration,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: !isDarkMode 
                                    ? Colors.amber.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                CupertinoIcons.sun_max_fill,
                                color: !isDarkMode ? Colors.amber : Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Perfil de usuario
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 12),
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => _buildAppleStyleMenu(),
                        );
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? [AppDesign.secondaryBlue.withOpacity(0.3), AppDesign.accentPurple.withOpacity(0.2)]
                                : [AppDesign.secondaryBlue.withOpacity(0.1), AppDesign.accentPurple.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppDesign.primaryBlue,
                                    AppDesign.secondaryBlue,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppDesign.primaryBlue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                    spreadRadius: -2,
                                  ),
                                ],
                                border: Border.all(
                                  color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: currentUser.photoURL != null
                                    ? Image.network(
                                        currentUser.photoURL!,
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Text(
                                          currentUser.email?.substring(0, 1).toUpperCase() ?? 'U',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                currentUser.displayName?.split(" ")[0] ??
                                    (currentUser.email?.split("@")[0] ?? 'Usuario'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      Color(0xFF0A1128), // Azul oscuro con tono neón
                      Color(0xFF1A1B4B), // Azul-morado medio
                      Color(0xFF1C1259), // Morado oscuro
                    ]
                  : [
                      Colors.white, // Blanco puro
                      Color(0xFFF8F9FD), // Blanco ligeramente azulado
                      Color(0xFFF0F4FF), // Blanco con tono azul muy suave
                    ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Efectos de fondo neón
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                painter: NeonBackgroundPainter(isDarkMode: isDarkMode),
              ),
              
              // Contenido principal
              Stack(
                children: [
                  _buildMainContent(currentUser),
                ],
              ),
            ],
          ),
        ),
        drawer: SizedBox(
          width: MediaQuery.of(context).size.width * 0.28, // Reducir ancho a aproximadamente 1/4 de la pantalla
          child: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode 
                  ? Color(0xFF121212)
                  : Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: Offset(5, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Cabecera con foto y datos del usuario
                  Container(
                    padding: EdgeInsets.only(top: 35, bottom: 15, left: 10, right: 10),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                        ? Color(0xFF161616) // Contraste mejorado
                        : Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: currentUser.photoURL != null 
                              ? Colors.transparent 
                              : AppDesign.primaryBlue,
                          backgroundImage: currentUser.photoURL != null 
                              ? NetworkImage(currentUser.photoURL!) 
                              : null,
                          child: currentUser.photoURL == null
                              ? Text(
                                  currentUser.email?.substring(0, 1).toUpperCase() ?? 'U',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(height: 10),
                        Text(
                          currentUser.displayName ?? 'Usuario',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          currentUser.email ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDarkMode ? Colors.grey : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Espacio para los elementos de menú
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      children: [
                        // Título de sección
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                          child: Text(
                            'MENÚ PRINCIPAL',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey : Colors.grey.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        
                        // Elemento: Todas las contraseñas
                        _buildDrawerItem(
                          icon: Icons.password_rounded,
                          label: 'Todas las contraseñas',
                          isSelected: _currentIndex == 0,
                          iconColor: Colors.blue,
                          selectedColor: Colors.blue.shade100,
                          onTap: () {
                            setState(() {
                              _currentIndex = 0;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        
                        // Elemento: Favoritos
                        _buildDrawerItem(
                          icon: Icons.star_rounded,
                          label: 'Favoritos',
                          isSelected: _currentIndex == 1,
                          iconColor: Colors.amber,
                          selectedColor: Colors.amber.shade100,
                          onTap: () {
                            setState(() {
                              _currentIndex = 1;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        
                        // Elemento: Papelera
                        _buildDrawerItem(
                          icon: Icons.delete_rounded,
                          label: 'Papelera',
                          isSelected: _currentIndex == 2,
                          iconColor: Colors.red,
                          selectedColor: Colors.red.shade100,
                          onTap: () {
                            setState(() {
                              _currentIndex = 2;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        
                        // Elemento: Mis Carpetas
                        _buildDrawerItem(
                          icon: Icons.folder_rounded,
                          label: 'Mis Carpetas',
                          iconColor: Colors.orange,
                          selectedColor: Colors.orange.shade100,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/folders');
                          },
                        ),
                        
                        Divider(thickness: 0.5, height: 32),
                        
                        // Título de sección
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                          child: Text(
                            'AJUSTES',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey : Colors.grey.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        
                        // Elemento: Configuración
                        _buildDrawerItem(
                          icon: Icons.settings_rounded,
                          label: 'Configuración',
                          iconColor: Colors.purple,
                          selectedColor: Colors.purple.shade100,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SettingsScreen()),
                            );
                          },
                        ),
                        
                        // Elemento: Cerrar Sesión
                        _buildDrawerItem(
                          icon: Icons.logout_rounded,
                          label: 'Cerrar sesión',
                          iconColor: Colors.grey,
                          selectedColor: Colors.grey.shade200,
                          onTap: () {
                            Navigator.pop(context);
                            _showLogoutDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Pie con versión de la app
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PASSWD v1.0.2-a',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey : Colors.grey.shade700,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _currentIndex != 2
          ? Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppDesign.primaryBlue,
                    AppDesign.secondaryBlue,
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppDesign.primaryBlue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    _showAddPasswordDialog(context);
                  },
                  child: Center(
                    child: Icon(
                      CupertinoIcons.add,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          : null,
        bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 75, // Aumentado de 70 a 75
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode 
                      ? [
                          Colors.black.withOpacity(0.85),
                          Colors.black.withOpacity(0.95),
                        ]
                      : [
                          Colors.white.withOpacity(0.85),
                          Colors.white.withOpacity(0.95),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                    spreadRadius: -5,
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildNavItem(
                          icon: Icons.lock_outlined, 
                          activeIcon: Icons.lock, 
                          label: 'Contraseñas',
                          isSelected: _currentIndex == 0,
                          color: Colors.blue,
                          onTap: () {
                            setState(() {
                              _currentIndex = 0;
                              _selectedFolderId = null;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildNavItem(
                          icon: Icons.star_border_rounded, 
                          activeIcon: Icons.star_rounded, 
                          label: 'Favoritos',
                          isSelected: _currentIndex == 1,
                          color: Colors.amber,
                          onTap: () {
                            setState(() {
                              _currentIndex = 1;
                              _selectedFolderId = null;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildNavItem(
                          icon: Icons.delete_outline_rounded, 
                          activeIcon: Icons.delete_rounded, 
                          label: 'Papelera',
                          isSelected: _currentIndex == 2,
                          color: Colors.red,
                          onTap: () {
                            setState(() {
                              _currentIndex = 2;
                              _selectedFolderId = null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Widget para construir un ítem del menú lateral
  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    Color? iconColor,
    Color? selectedColor,
    required VoidCallback onTap,
  }) {
    final isDarkMode = _isDarkMode;
    final color = isSelected ? (iconColor ?? Colors.blue) : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade800);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected 
                ? (selectedColor ?? Colors.blue.withOpacity(0.1))
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? (iconColor ?? Colors.blue).withOpacity(0.1)
                      : isDarkMode 
                          ? Colors.grey.shade800.withOpacity(0.5)
                          : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? (iconColor ?? Colors.blue) : color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? (iconColor ?? Colors.blue) : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor ?? Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Método para construir un ítem del menú de navegación estilo Apple
  Widget _buildNavigationItem({
    required IconData icon, 
    required String label, 
    required bool isSelected, 
    required VoidCallback onTap,
    Color activeColor = Colors.blue,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected 
              ? isDarkMode 
                  ? activeColor.withOpacity(0.2) 
                  : activeColor.withOpacity(0.15)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected 
                  ? activeColor 
                  : isDarkMode 
                      ? Colors.grey.shade400 
                      : Colors.grey.shade500,
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: isSelected ? 8 : 0,
              ),
              AnimatedSize(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: isSelected ? null : 0,
                  child: isSelected
                    ? Text(
                        label,
                        style: TextStyle(
                          color: activeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      )
                    : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Nuevo método para construir el menú de perfil estilo Apple
  Widget _buildAppleStyleMenu() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Perfil del usuario
          Container(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: user?.photoURL != null 
                        ? Colors.transparent 
                        : Colors.blue.shade400,
                    backgroundImage: user?.photoURL != null 
                        ? NetworkImage(user!.photoURL!) 
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                            user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Usuario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Opciones
          _buildMenuOption(
            icon: Icons.person_outline_rounded,
            iconColor: Colors.blue,
            label: 'Mi perfil',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          
          _buildMenuOption(
            icon: Icons.settings_outlined,
            iconColor: Colors.grey.shade600,
            label: 'Configuración',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          
          _buildMenuOption(
            icon: Icons.folder_outlined,
            iconColor: Colors.orange,
            label: 'Mis carpetas',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/folders');
            },
          ),
          
          // Separador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(),
          ),
          
          // Cerrar sesión
          _buildMenuOption(
            icon: Icons.logout_rounded,
            iconColor: Colors.red,
            label: 'Cerrar sesión',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
          
          // Área para cancelar
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Método para construir una opción de menú
  Widget _buildMenuOption({
    required IconData icon, 
    required Color iconColor, 
    required String label, 
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDestructive 
        ? Colors.red 
        : (isDarkMode ? Colors.white : Colors.black87);
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    final isDarkMode = _isDarkMode;
    
    // Si todavía estamos verificando la autenticación, mostrar una pantalla de carga
    if (_isLoadingAuth) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDarkMode ? AppDesign.darkCard : AppDesign.lightCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppDesign.primaryBlue),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              "Cargando datos del usuario...",
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Espera un momento, por favor",
              style: TextStyle(
                color: isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black54,
                fontSize: 16,
              ),
            ),
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.withOpacity(0.7),
                    Colors.red.withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.exclamationmark_shield_fill,
                size: 50,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32),
            Text(
              "No se ha podido verificar tu sesión",
              style: AppDesign.headingStyle(isDarkMode),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Es necesario iniciar sesión para acceder a tus contraseñas seguras",
                textAlign: TextAlign.center,
                style: AppDesign.subtitleStyle(isDarkMode),
              ),
            ),
            SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppDesign.primaryBlue,
                    AppDesign.secondaryBlue,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppDesign.primaryBlue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/welcome');
                },
                icon: Icon(CupertinoIcons.arrow_right),
                label: Text("Volver al inicio"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Si ya hemos confirmado que hay un usuario autenticado, cargar la pantalla normal
    print("Construyendo HomeScreen para usuario: ${currentUser.uid}");
    
    return StreamBuilder<List<Password>>(
      stream: _getPasswordStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppDesign.darkCard : AppDesign.lightCard,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppDesign.primaryBlue),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  "Cargando contraseñas...",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Tus datos están protegidos con cifrado de alta seguridad",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
          
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withOpacity(0.8),
                        Colors.red.withOpacity(0.5),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  "Error al cargar las contraseñas",
                  style: AppDesign.headingStyle(isDarkMode),
                ),
                SizedBox(height: 16),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 32),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade900.withOpacity(0.7) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppDesign.primaryBlue,
                        AppDesign.secondaryBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppDesign.primaryBlue.withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _refreshPasswords,
                    icon: Icon(CupertinoIcons.refresh),
                    label: Text("Intentar de nuevo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
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
          String description;
          
          if (_currentIndex == 1) {
            iconData = CupertinoIcons.star;
            message = "No tienes contraseñas favoritas";
            description = "Marca como favorito los accesos que uses con frecuencia para acceder rápidamente";
          } else if (_currentIndex == 2) {
            iconData = CupertinoIcons.trash;
            message = "No hay elementos en la papelera";
            description = "Aquí aparecerán las contraseñas que has eliminado temporalmente";
          } else if (_searchQuery.isNotEmpty) {
            iconData = CupertinoIcons.search;
            message = "No se encontraron resultados";
            description = "No hay coincidencias para \"$_searchQuery\"";
          } else if (_selectedFolderId != null) {
            iconData = CupertinoIcons.folder;
            message = "Esta carpeta está vacía";
            description = "Añade contraseñas para organizarlas mejor";
          } else {
            iconData = CupertinoIcons.lock;
            message = "No tienes contraseñas guardadas";
            description = "Empieza añadiendo tu primera contraseña";
          }
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [Colors.grey.shade800, Colors.grey.shade900]
                            : [Colors.grey.shade200, Colors.grey.shade300],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Icon(
                      iconData, 
                      size: 50, 
                      color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    message,
                    style: AppDesign.headingStyle(isDarkMode),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    description,
                    style: AppDesign.subtitleStyle(isDarkMode),
                    textAlign: TextAlign.center,
                  ),
                  if (_currentIndex == 0 && _searchQuery.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppDesign.primaryBlue,
                              AppDesign.secondaryBlue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppDesign.primaryBlue.withOpacity(0.4),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showAddPasswordDialog(context);
                          },
                          icon: Icon(CupertinoIcons.plus),
                          label: Text("Añadir contraseña"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
          
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                physics: BouncingScrollPhysics(),
                scrollbars: false,
              ),
              child: ListView.separated(
                padding: EdgeInsets.only(top: 8, bottom: 24, left: 16, right: 16),
                itemCount: passwords.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final password = passwords[index];
                  
                  // Aplicar efecto de animación escalonada a cada elemento
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.95, end: 1.0),
                    curve: Curves.easeOutCubic,
                    duration: AppDesign.animDuration,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: _buildPasswordItem(password),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPasswordItem(Password password) {
    final isDarkMode = _isDarkMode;
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
    
    // Determinar color para el dominio
    Color domainColor = _generateColorFromName(domain);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  AppDesign.secondaryBlue.withOpacity(0.25), 
                  AppDesign.accentPurple.withOpacity(0.2)
                ]
              : [
                  AppDesign.secondaryBlue.withOpacity(0.15), 
                  AppDesign.accentPurple.withOpacity(0.08)
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: PasswordListItem(
            password: password,
            onToggleFavorite: () => _toggleFavorite(password),
            onDelete: () => _deletePassword(password),
            onView: () => _showPasswordDetails(password),
            onEdit: () => _editPassword(password),
            onAddToFolder: () => _showAddToFolderDialog(password),
            isInTrash: _currentIndex == 2,
            onRestore: _currentIndex == 2 ? () => _restorePassword(password) : null,
          ),
        ),
      ),
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

  // Método para actualizar una contraseña existente
  void _updatePassword(String passwordId, String sitio, String usuario, String password, bool isFavorite, String notes) {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Actualizar en Firebase
      FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUser.uid)
        .collection('pass')
        .doc(passwordId)
        .update({
          'sitio': sitio,
          'usuario': usuario,
          'password': password,
          'ultimaModificacion': DateTime.now(),
          'isFavorite': isFavorite,
          'notes': notes,
        });
      
      // Refrescar contraseñas
      _refreshPasswords();
      
      // Mostrar mensaje de éxito
      _showNotification('Contraseña actualizada correctamente');
    } catch (e) {
      print('Error al actualizar contraseña: $e');
      _showNotification('Error al actualizar la contraseña', isError: true);
    }
  }
  
  // Método para guardar una nueva contraseña
  void _savePassword(String sitio, String usuario, String password) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      // Generar un ID único
      final String passwordId = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .collection('pass')
          .doc()
          .id;
      
      // Crear el documento de contraseña
      final now = DateTime.now();
      final passwordData = {
        'id': passwordId,
        'sitio': sitio,
        'usuario': usuario,
        'password': password,
        'fechaCreacion': now,
        'ultimaModificacion': now,
        'isFavorite': false,
        'isInTrash': false,
        'folderIds': <String>[],
      };
      
      // Guardar en Firebase
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .collection('pass')
          .doc(passwordId)
          .set(passwordData);
      
      // Mostrar mensaje de éxito
      _showNotification('Contraseña guardada correctamente');
      
      // Refrescar passwords
      _refreshPasswords();
    } catch (e) {
      print('Error al guardar contraseña: $e');
      _showNotification('Error al guardar la contraseña', isError: true);
    }
  }
  
  void _editPassword(Password password) {
    final TextEditingController sitioController = TextEditingController(text: password.sitio);
    final TextEditingController usuarioController = TextEditingController(text: password.usuario);
    final TextEditingController passwordController = TextEditingController(text: password.password);
    final TextEditingController notesController = TextEditingController(text: password.notes);
    
    final formKey = GlobalKey<FormState>();
    bool showPassword = false;
    String? errorMessage;
    
    final isDarkMode = _isDarkMode;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        // Indicador de arrastre
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // Título y descripción
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                                    'Editar contraseña',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Actualiza los detalles de tu contraseña',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        
                        // Campo de Sitio
                        Text(
                          'Sitio web',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: sitioController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.web_rounded,
                          hintText: 'Ingresa el sitio web',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un sitio web';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Campo de Usuario
                        Text(
                          'Usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: usuarioController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.person_rounded,
                          hintText: 'Ingresa el nombre de usuario',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un nombre de usuario';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Campo de Contraseña
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            // Botón para generar contraseña
                            GestureDetector(
                              onTap: () {
                                String generatedPassword = _generateRandomPassword();
                                setState(() {
                                  passwordController.text = generatedPassword;
                                  showPassword = true;
                                });
                                
                                // Mostrar un pequeño mensaje de confirmación
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Se ha generado una contraseña segura'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      onPressed: () {},
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_fix_high_rounded,
                                      color: Colors.blue,
                    size: 16,
                  ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Generar',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: passwordController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.lock_rounded,
                          hintText: 'Ingresa la contraseña',
                          obscureText: !showPassword,
                          suffix: GestureDetector(
                            onTap: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                            child: Icon(
                              showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                              size: 22,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa una contraseña';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        
                        // Campo de Notas
                        Text(
                          'Notas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: notesController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.note_rounded,
                          hintText: 'Ingresa notas adicionales (opcional)',
                          maxLines: 3,
                          obscureText: false,
                        ),
                        SizedBox(height: 24),
                        
                        // Botones de acción
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton(
                  onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  _updatePassword(
                                    password.id,
                                    sitioController.text,
                                    usuarioController.text,
                                    passwordController.text,
                                    password.isFavorite,
                                    notesController.text,
                                  );
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Guardar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Método para crear campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required bool isDarkMode,
    required IconData prefixIcon,
    required String hintText,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    // Si el campo es obscureText, maxLines debe ser 1
    final effectiveMaxLines = obscureText ? 1 : maxLines;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          // Forzar el color negro para el texto en cualquier modo
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: Colors.blue,
        cursorWidth: 1.2,
        obscureText: obscureText,
        maxLines: effectiveMaxLines,
        decoration: InputDecoration(
          // Asegurar fondo blanco para contraste con texto negro
          fillColor: Colors.white,
          filled: true,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              prefixIcon,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              size: 22,
            ),
          ),
          suffixIcon: suffix != null ? Padding(
            padding: const EdgeInsets.only(right: 12),
            child: suffix,
          ) : null,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorStyle: TextStyle(
            color: Colors.red.shade400,
            fontSize: 12,
          ),
        ),
        validator: validator,
      ),
    );
  }

  void _showPasswordDetails(Password password) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
    
    // Determinar color para el dominio
    Color domainColor = _generateColorFromName(domain);
    
    Widget content = StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar del sitio
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        domainColor,
                        domainColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: domainColor.withOpacity(0.3),
                        blurRadius: 10,
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
                        fontSize: 36,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Acciones rápidas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón de favorito
                  _buildQuickActionButton(
                    icon: password.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    label: password.isFavorite ? 'Quitar favorito' : 'Añadir favorito',
                    color: Colors.amber,
                    onTap: () {
                      _toggleFavoritePassword(password);
                    setState(() {
                        // No podemos modificar directamente password.isFavorite porque es final
                        // Solo actualizamos la UI, la base de datos ya se actualizó en _toggleFavoritePassword
                      });
                      // Cerramos el diálogo para mostrar los cambios al reabrir
                      Navigator.of(context).pop();
                      // Volvemos a mostrar los detalles con la contraseña actualizada
                      _getPasswordById(password.id).then((updatedPassword) {
                        if (updatedPassword != null) {
                          _showPasswordDetails(updatedPassword);
                        }
                    });
                  },
                ),
                  SizedBox(width: 16),
                  // Botón de carpeta
                  _buildQuickActionButton(
                    icon: Icons.folder_rounded,
                    label: 'Gestionar carpetas',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).pop();
                      _showManageFolders(password);
                  },
                ),
              ],
              ),
              
              SizedBox(height: 24),
              
              // Detalles del sitio y usuario
              _buildDetailCard(
                icon: Icons.web_rounded,
                iconColor: Colors.blue,
                title: "Sitio web",
                value: password.sitio,
                showCopy: true,
                copyValue: password.sitio,
                isDarkMode: isDarkMode,
              ),
              
              SizedBox(height: 16),
              
              _buildDetailCard(
                icon: Icons.person_rounded,
                iconColor: Colors.green,
                title: "Usuario",
                value: password.usuario,
                showCopy: true,
                copyValue: password.usuario,
                isDarkMode: isDarkMode,
              ),
              
              SizedBox(height: 16),
              
              // Tarjeta especial para la contraseña
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade900.withOpacity(0.4) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lock_rounded, 
                            color: Colors.indigo,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Contraseña',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
            ),
          ],
        ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              showPassword ? password.password : '••••••••••••',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: showPassword ? null : 'monospace',
                                fontWeight: showPassword ? FontWeight.normal : FontWeight.bold,
                                letterSpacing: showPassword ? 0 : 2,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Botón para mostrar/ocultar
                        _buildActionButton(
                          icon: showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          label: showPassword ? 'Ocultar' : 'Mostrar',
                          color: Colors.blue,
                          onTap: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                        SizedBox(width: 12),
                        // Botón para copiar
                        _buildActionButton(
                          icon: Icons.copy_rounded,
                          label: 'Copiar',
                          color: Colors.green,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: password.password));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Contraseña copiada al portapapeles'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.black87,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Sección de notas
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade900.withOpacity(0.4) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.note_rounded, 
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Notas',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: password.notes.isEmpty 
                        ? Text(
                            'No hay notas adicionales',
                            style: TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          )
                        : Text(
                            password.notes,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                    ),
                    if (password.notes.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(
                            icon: Icons.copy_rounded,
                            label: 'Copiar',
                            color: Colors.amber,
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: password.notes));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Notas copiadas al portapapeles'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.black87,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Sección de metadatos
              Text(
                'METADATOS',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              
              SizedBox(height: 12),
              
              // Fechas en tarjetas lado a lado
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      label: 'Creado',
                      value: _formatDateDetailed(password.fechaCreacion),
                      icon: Icons.calendar_today_rounded,
                      color: Colors.blue,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip(
                      label: 'Modificado',
                      value: _formatDateDetailed(password.ultimaModificacion),
                      icon: Icons.update_rounded,
                      color: Colors.purple,
                      isDarkMode: isDarkMode,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Cerrar',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          _editPassword(password);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Editar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];

    _showModernModal(
      context,
      content,
      title: 'Detalles de contraseña',
      actions: actions,
    );
  }
  
  // Construir chip de información para los metadatos
  Widget _buildInfoChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Método para crear tarjetas de detalles
  Widget _buildDetailCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool showCopy = false,
    String? copyValue,
    required bool isDarkMode,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900.withOpacity(0.4) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: iconColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (showCopy && copyValue != null) 
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.copy_rounded,
                    label: 'Copiar',
                    color: Colors.green,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: copyValue));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$title copiado al portapapeles'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.black87,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // Método para botones de acción
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método auxiliar para formatear fechas con detalle
  String _formatDateDetailed(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);
    
    final formatter = date.year == now.year
        ? '${date.day} de ${_getMonthName(date.month)}'
        : '${date.day} de ${_getMonthName(date.month)} de ${date.year}';
    
    if (dateToCompare == today) {
      return 'Hoy, $formatter';
    } else if (dateToCompare == yesterday) {
      return 'Ayer, $formatter';
    }
    
    return formatter;
  }
  
  String _getMonthName(int month) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return months[month - 1];
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
    
    showModalBottomSheet(
                context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final TextEditingController siteController = TextEditingController();
        final TextEditingController usernameController = TextEditingController();
        final TextEditingController passwordController = TextEditingController();
        final TextEditingController notesController = TextEditingController();
        bool showPassword = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            final isDarkMode = _isDarkMode;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        // Indicador de arrastre
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // Título
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Añadir contraseña',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Guarda los detalles de tu contraseña',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        
                        // Campo de Sitio
                        Text(
                          'Sitio web',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: siteController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.web_rounded,
                          hintText: 'Ingresa el sitio web',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un sitio web';
                            }
                            return null;
                          },
                    ),
                    SizedBox(height: 16),
                        
                        // Campo de Usuario
                        Text(
                          'Usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: usernameController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.person_rounded,
                          hintText: 'Ingresa el nombre de usuario',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un nombre de usuario';
                            }
                            return null;
                          },
                    ),
                    SizedBox(height: 16),
                        
                        // Campo de Contraseña
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                  ),
                            // Botón para generar contraseña
                            GestureDetector(
                              onTap: () {
                                String generatedPassword = generateRandomPassword();
                    setState(() {
                                  passwordController.text = generatedPassword;
                                  showPassword = true;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_fix_high_rounded,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Generar',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: passwordController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.lock_rounded,
                          hintText: 'Ingresa la contraseña',
                          obscureText: !showPassword,
                          suffix: GestureDetector(
                            onTap: () {
                                setState(() {
                                showPassword = !showPassword;
                    });
                  },
                            child: Icon(
                              showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                              size: 22,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa una contraseña';
                            }
                            return null;
                          },
                      ),
                        SizedBox(height: 16),
                        
                        // Campo de Notas
                        Text(
                          'Notas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: notesController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.note_rounded,
                          hintText: 'Ingresa notas adicionales (opcional)',
                          maxLines: 3,
                          obscureText: false,
                    ),
                    SizedBox(height: 24),
                    
                    // Selector de carpeta
                        Text(
                          'Carpeta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        _showFolderSelectorDialog(
                          context, 
                          selectedFolderIds, 
                          (newSelectedIds, newSelectedName) {
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
                              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                                width: 1,
                              ),
                        ),
                        child: Row(
                          children: [
                                Icon(
                                  Icons.folder_outlined, 
                                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700
                                ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedFolderIds.isEmpty 
                                      ? 'Sin carpeta (opcional)'
                                  : 'Carpeta: $selectedFolderName',
                                style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                                Icon(
                                  Icons.arrow_forward_ios, 
                                  size: 16, 
                                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700
                    ),
                  ],
                ),
              ),
                        ),
                        SizedBox(height: 30),
                        
                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                    ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                  onPressed: () {
                    // Validar campos
                    if (siteController.text.isEmpty || 
                        usernameController.text.isEmpty || 
                        passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Por favor, completa los campos obligatorios')),
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
                                    notes: notesController.text,
                    );
                    
                    // Guardar contraseña
                    Provider.of<PasswordService>(context, listen: false).addPassword(newPassword);
                    
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Contraseña añadida correctamente')),
                    );
                  },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Guardar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                ),
              ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
    
    // Obtener el modo actual (claro/oscuro)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
                context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
          title: Text(
            'Seleccionar carpeta',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: FutureBuilder(
              future: _getFolders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(
                    color: isDarkMode ? Colors.white70 : Colors.blue,
                  ));
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text(
                    'Error al cargar carpetas',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ));
                }
                
                final folders = snapshot.data ?? [];
                
                if (folders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_outlined, 
                          size: 48, 
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes carpetas creadas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/folders');
                          },
                          child: Text('Crear carpeta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
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
                              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.folder_off,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          title: Text(
                            'Sin carpeta',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontWeight: selectedFolderIds.isEmpty ? FontWeight.bold : FontWeight.normal,
                            ),
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
                        Divider(
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
                                color: isDarkMode ? Colors.white : Colors.black87,
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
                        }),
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
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onSelect(selectedFolderIds, selectedFolderName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // Método para refrescar las contraseñas
  Future<void> _refreshPasswords() async {
    try {
      final passwordService = Provider.of<PasswordService>(context, listen: false);
      
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Sincronizando contraseñas...",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );
      
      // Forzar una recarga desde la base de datos
      await passwordService.refreshPasswords();
      
      // Cerrar diálogo de carga
      Navigator.of(context).pop();
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contraseñas actualizadas correctamente'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      // Forzar reconstrucción de la UI
      setState(() {});
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      Navigator.of(context, rootNavigator: true).pop();
      
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar las contraseñas: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Método para mostrar los diálogos de manera moderna estilo Apple
  void _showModernModal(BuildContext context, Widget content, {String title = '', List<Widget>? actions}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
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
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
              insetPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 700, // Aumentado para que sea más ancho
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: title.isNotEmpty ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    if (title.isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: content,
                      ),
                    ),
                    if (actions != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 12,
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
  
  // Mostrar el menú de selección de carpetas
  void _showFolderSelectionMenu(BuildContext context) {
    final isDarkMode = _isDarkMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            child: FolderSelectorScreen(
              selectedFolderId: _selectedFolderId,
              onChange: (folderId) {
                setState(() {
                  _selectedFolderId = folderId;
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }
  
  // Mostrar diálogo para añadir contraseña a una carpeta
  void _showAddToFolderDialog(Password password) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastre
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Text(
                    'Añadir a carpeta',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDarkMode ? Colors.white : Colors.grey.shade700,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1),
            
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
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }
                
                final folders = snapshot.data as List<dynamic>;
                
                if (folders.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode 
                              ? Colors.grey.shade800.withOpacity(0.5)
                              : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.folder_outlined,
                            size: 40,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes carpetas creadas',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Crea carpetas para organizar tus contraseñas',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/folders');
                          },
                          icon: Icon(Icons.add_rounded),
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
                        SizedBox(height: 20),
                      ],
                    ),
                  );
                }
                
                // Lista de opciones
                List<Widget> options = [];
                
                // Opción para quitar de carpetas
                if (password.folderIds.isNotEmpty) {
                  options.add(
                    _buildFolderOption(
                      icon: Icons.folder_off_rounded,
                      iconColor: Colors.red,
                      title: 'Quitar de todas las carpetas',
                      subtitle: 'La contraseña aparecerá solo en "Todas las contraseñas"',
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                  
                  options.add(Divider(height: 1));
                }
                
                // Añadir carpetas
                for (var folder in folders) {
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
                  
                  options.add(
                    _buildFolderOption(
                      icon: Icons.folder_rounded,
                      iconColor: folderColor,
                      title: folder.name,
                      isSelected: isInFolder,
                      onTap: () async {
                        try {
                          final passwordService = Provider.of<PasswordService>(context, listen: false);
                          
                          // Si ya está en la carpeta, borrarla
                          if (isInFolder) {
                            final updatedPassword = password.removeFromFolder(folder.id);
                            await passwordService.updatePassword(updatedPassword);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Contraseña eliminada de ${folder.name}'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }
                
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: options,
                  ),
                );
              },
            ),
            
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Obtener el stream de contraseñas según la sección actual
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
  
  // Filtrar contraseñas según la búsqueda
  List<Password> _filterPasswords(List<Password> passwords) {
    if (_searchQuery.isEmpty) return passwords;
    
    return passwords.where((password) {
      return password.sitio.toLowerCase().contains(_searchQuery) ||
             password.usuario.toLowerCase().contains(_searchQuery);
    }).toList();
  }
  
  // Generar color basado en el nombre del dominio
  Color _generateColorFromName(String name) {
    if (name.isEmpty) return Colors.blue;
    
    // Calcular un valor hash basado en el nombre
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Lista de colores predefinidos agradables para iOS
    List<Color> iosColors = [
      Color(0xFF007AFF), // Azul
      Color(0xFF34C759), // Verde
      Color(0xFFFF9500), // Naranja
      Color(0xFFFF2D55), // Rosa
      Color(0xFF5856D6), // Púrpura
      Color(0xFFAF52DE), // Violeta
      Color(0xFF5AC8FA), // Azul claro
      Color(0xFFFF3B30), // Rojo
      Color(0xFFFFCC00), // Amarillo
    ];
    
    // Usar el hash para seleccionar un color de la lista
    return iosColors[hash.abs() % iosColors.length];
  }
  
  // Mostrar menú de opciones para una contraseña
  void _showPasswordOptionsMenu(Password password) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Avatar del sitio
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _generateColorFromName(password.sitio),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        password.sitio.isNotEmpty ? password.sitio[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          password.sitio,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          password.usuario,
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            
            // Opciones
            _buildPasswordOption(
              icon: Icons.visibility_rounded,
              iconColor: Colors.blue,
              label: 'Ver detalles',
              onTap: () {
                Navigator.pop(context);
                _showPasswordDetails(password);
              },
            ),
            _buildPasswordOption(
              icon: Icons.edit_rounded,
              iconColor: Colors.green,
              label: 'Editar contraseña',
              onTap: () {
                Navigator.pop(context);
                _editPassword(password);
              },
            ),
            _buildPasswordOption(
              icon: Icons.copy_rounded,
              iconColor: Colors.orange,
              label: 'Copiar contraseña',
              onTap: () {
                Navigator.pop(context);
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
            _buildPasswordOption(
              icon: password.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              iconColor: Colors.amber,
              label: password.isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
              onTap: () {
                Navigator.pop(context);
                _toggleFavoritePassword(password);
              },
            ),
            _buildPasswordOption(
              icon: Icons.folder_rounded,
              iconColor: Colors.indigo,
              label: 'Añadir a carpeta',
              onTap: () {
                Navigator.pop(context);
                _showAddToFolderDialog(password);
              },
            ),
            Divider(height: 1),
            _buildPasswordOption(
              icon: Icons.delete_rounded,
              iconColor: Colors.red,
              label: 'Eliminar contraseña',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _deletePassword(password);
              },
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
  
  // Construir opciones para el menú de contraseña
  Widget _buildPasswordOption({
    required IconData icon, 
    required Color iconColor, 
    required String label, 
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : iconColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive 
                    ? Colors.red 
                    : (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir el contenido principal
  Widget _buildMainContent(User currentUser) {
    final isDarkMode = _isDarkMode;
    
    return SafeArea(
      child: Column(
        children: [
          // Barra de búsqueda con efecto de profundidad
          AnimatedOpacity(
            opacity: 1.0,
            duration: AppDesign.animDuration,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [Color(0xFF1A1A24), Color(0xFF252532)]
                        : [Color(0xFFF0F0F8), Color(0xFFE8E8F0)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                      spreadRadius: -5,
                    ),
                  ],
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.07)
                        : Colors.grey.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar contraseñas',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 16,
                        ),
                        prefixIcon: Container(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            CupertinoIcons.search,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                icon: Icon(
                                  CupertinoIcons.clear_circled_solid,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                  size: 20,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Selector de carpetas con gradiente
          if (_currentIndex == 0) // Solo mostrar en la vista de todas las contraseñas
            AnimatedOpacity(
              opacity: 1.0,
              duration: AppDesign.animDuration,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [AppDesign.primaryBlue.withOpacity(0.2), AppDesign.accentPurple.withOpacity(0.15)]
                              : [AppDesign.primaryBlue.withOpacity(0.1), AppDesign.accentPurple.withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (!isDarkMode)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                              spreadRadius: -5,
                            ),
                        ],
                        border: Border.all(
                          color: isDarkMode 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _showFolderSelectionMenu(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                      ? AppDesign.primaryBlue.withOpacity(0.2) 
                                      : AppDesign.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppDesign.primaryBlue.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    CupertinoIcons.folder,
                                    color: AppDesign.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    folderText,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.grey[800],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_down,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                  size: 18,
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
            ),
          
          // Contenido principal
          Expanded(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: AppDesign.animDurationSlow,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir botones de acción rápida
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
                  SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
                ],
              ),
            ),
    );
  }
  
  // Método para gestionar en qué carpetas está la contraseña
  void _showManageFolders(Password password) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Gestionar carpetas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Selecciona las carpetas donde quieres guardar esta contraseña.',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Lista de carpetas con checkboxes
                      StreamBuilder(
                        stream: _folderService.getFolders(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          
                          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.folder_off_rounded,
                                      size: 48,
                                      color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No tienes carpetas creadas.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(context, '/folders');
                                      },
                                      icon: Icon(Icons.add_rounded),
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
      ),
    );
  }
                          
                          List<dynamic> folders = snapshot.data as List;
                          // Crear una copia local de los folderIds
                          List<String> currentFolderIds = List<String>.from(password.folderIds);
                          
                          return Column(
                            children: [
                              // Lista de carpetas
                              Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: folders.length,
                                  itemBuilder: (context, index) {
                                    var folder = folders[index];
                                    bool isSelected = currentFolderIds.contains(folder.id);
                                    
                                    // Convertir color hexadecimal a Color
                                    Color folderColor;
                                    try {
                                      final buffer = StringBuffer();
                                      buffer.write('ff');
                                      buffer.write(folder.color.replaceFirst('#', ''));
                                      folderColor = Color(int.parse(buffer.toString(), radix: 16));
                                    } catch (e) {
                                      folderColor = Colors.blue;
                                    }
                                    
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              currentFolderIds.remove(folder.id);
                                            } else {
                                              currentFolderIds.add(folder.id);
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                                              Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: folderColor.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.folder_rounded,
                                                  color: folderColor,
                                                  size: 22,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  folder.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDarkMode ? Colors.white : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Checkbox(
                                                value: isSelected,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    if (value == true) {
                                                      currentFolderIds.add(folder.id);
                                                    } else {
                                                      currentFolderIds.remove(folder.id);
                                                    }
                                                  });
                                                },
                                                activeColor: Colors.blue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              SizedBox(height: 24),
                              
                              // Botones de acción
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Guardar cambios
                                      _updatePasswordFolders(password, currentFolderIds);
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Guardar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }
  
  // Método para actualizar las carpetas de una contraseña
  void _updatePasswordFolders(Password password, List<String> newFolderIds) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      // Actualizar en Firebase
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .collection('pass')
          .doc(password.id)
          .update({
        'folderIds': newFolderIds,
        'ultimaModificacion': DateTime.now(),
      });
      
      // Mostrar mensaje de éxito
      _showNotification('Carpetas actualizadas correctamente');
      
      // Refrescar passwords
      _refreshPasswords();
    } catch (e) {
      print('Error al actualizar carpetas: $e');
      _showNotification('Error al actualizar carpetas', isError: true);
    }
  }
  
  // Método para marcar/desmarcar como favorita
  void _toggleFavoritePassword(Password password) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      // Actualizar en Firebase
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .collection('pass')
          .doc(password.id)
          .update({
        'isFavorite': !password.isFavorite,
        'ultimaModificacion': DateTime.now(),
      });
      
      // Mostrar mensaje de éxito
      _showNotification(password.isFavorite 
          ? 'Eliminado de favoritos'
          : 'Añadido a favoritos');
      
      // Refrescar passwords
      _refreshPasswords();
    } catch (e) {
      print('Error al actualizar favorito: $e');
      _showNotification('Error al actualizar favorito', isError: true);
    }
  }

  void _addPassword() {
    final TextEditingController sitioController = TextEditingController();
    final TextEditingController usuarioController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    
    final formKey = GlobalKey<FormState>();
    bool showPassword = false;
    bool isFavorite = false;
    String? errorMessage;
    final isDarkMode = _isDarkMode;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Indicador de arrastre
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // Título y descripción
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.lock_outlined,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nueva contraseña',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Guarda los detalles de acceso de forma segura',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        
                        // Campo de Sitio
                        Text(
                          'Sitio web',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: sitioController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.web_rounded,
                          hintText: 'Ingresa el sitio web',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un sitio web';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Campo de Usuario
                        Text(
                          'Usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: usuarioController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.person_rounded,
                          hintText: 'Ingresa el nombre de usuario',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un nombre de usuario';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Campo de Contraseña
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            // Botón para generar contraseña
                            GestureDetector(
                              onTap: () {
                                String generatedPassword = _generateRandomPassword();
                                setState(() {
                                  passwordController.text = generatedPassword;
                                  showPassword = true;
                                });
                                
                                // Mostrar un pequeño mensaje de confirmación
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Se ha generado una contraseña segura'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      onPressed: () {},
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_fix_high_rounded,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Generar',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: passwordController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.lock_rounded,
                          hintText: 'Ingresa la contraseña',
                          obscureText: !showPassword,
                          suffix: GestureDetector(
                            onTap: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                            child: Icon(
                              showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                              size: 22,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa una contraseña';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Opción para marcar como favorito
                        InkWell(
                          onTap: () {
                            setState(() {
                              isFavorite = !isFavorite;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: isFavorite ? Colors.amber.withOpacity(0.1) : isDarkMode ? Colors.transparent : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isFavorite ? Colors.amber : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Icon(
                                      isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: isFavorite ? Colors.amber : isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Marcar como favorito',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Spacer(),
                                Switch.adaptive(
                                  value: isFavorite,
                                  onChanged: (value) {
                                    setState(() {
                                      isFavorite = value;
                                    });
                                  },
                                  activeColor: Colors.amber,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // Campo de Notas
                        Text(
                          'Notas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextField(
                          controller: notesController,
                          isDarkMode: isDarkMode,
                          prefixIcon: Icons.note_rounded,
                          hintText: 'Ingresa notas adicionales (opcional)',
                          maxLines: 3,
                          obscureText: false,
                        ),
                        SizedBox(height: 24),
                        
                        // Botones de acción
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  _savePasswordWithFavorite(
                                    sitioController.text,
                                    usuarioController.text,
                                    passwordController.text,
                                    isFavorite,
                                    notes: notesController.text,
                                  );
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Guardar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Método para guardar una nueva contraseña con opción de favorito
  void _savePasswordWithFavorite(String sitio, String usuario, String password, bool isFavorite, {String notes = ''}) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    
    try {
      // Generar un ID único
      final String passwordId = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .collection('pass')
          .doc()
          .id;
      
      // Crear el documento de contraseña
      final now = DateTime.now();
      final passwordData = {
        'id': passwordId,
        'sitio': sitio,
        'usuario': usuario,
        'password': password,
        'fechaCreacion': now,
        'ultimaModificacion': now,
        'isFavorite': isFavorite,
        'isInTrash': false,
        'folderIds': <String>[],
        'notes': notes,
      };
      
      // Guardar en Firebase
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .collection('pass')
          .doc(passwordId)
          .set(passwordData);
      
      // Mostrar mensaje de éxito
      _showNotification('Contraseña guardada correctamente');
      
      // Refrescar passwords
      _refreshPasswords();
    } catch (e) {
      print('Error al guardar contraseña: $e');
      _showNotification('Error al guardar la contraseña', isError: true);
    }
  }
  
  // Método para generar una contraseña aleatoria segura
  String _generateRandomPassword() {
    const length = 16;
    const letterLowercase = 'abcdefghijklmnopqrstuvwxyz';
    const letterUppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const special = '@#%^&*()-_=+[]{}|;:,.<>/?';
    
    String chars = '';
    chars += letterLowercase;
    chars += letterUppercase;
    chars += numbers;
    chars += special;
    
    return List.generate(length, (index) {
      final indexRandom = Random.secure().nextInt(chars.length);
      return chars[indexRandom];
    }).join('');
  }

  // Método auxiliar para obtener una contraseña por ID
  Future<Password?> _getPasswordById(String passwordId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .collection('pass')
          .doc(passwordId)
          .get();
          
      if (doc.exists && doc.data() != null) {
        return Password.fromMap(doc.id, doc.data()!);
      }
    } catch (e) {
      print('Error al obtener contraseña por ID: $e');
    }
    return null;
  }

  // Método para construir los elementos de la barra de navegación estilo Apple
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = _isDarkMode;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDesign.animDuration,
          curve: Curves.easeOutCubic,
          width: double.infinity,  // Cambiado de 75 a ancho dinámico
          height: 40, // Reducido de 42 a 40
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Reducido vertical de 3 a 2
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDarkMode ? color.withOpacity(0.25) : color.withOpacity(0.15))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(isDarkMode ? 0.4 : 0.3),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected 
                    ? color 
                    : isDarkMode 
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                size: isSelected ? 20 : 18, // Reducido de 22/20 a 20/18
              ),
              SizedBox(height: 1), // Reducido de 2 a 1
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 9, // Reducido de 10 a 9
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.visible,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método auxiliar para mostrar notificaciones estilo iOS
  void _showNotification(String message, {bool isError = false}) {
    // Asegurar que no hay notificaciones previas
    ScaffoldMessenger.of(context).clearSnackBars();
    
    final isDarkMode = _isDarkMode;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isError
                    ? Colors.red.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode 
            ? Color(0xFF2C2C2E) 
            : Colors.white,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDarkMode 
                ? Colors.grey.withOpacity(0.2) 
                : Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: isError 
              ? Colors.red 
              : (isDarkMode ? Colors.blue : Colors.blue.shade700),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Construir opción de carpeta para el diálogo de añadir a carpeta
  Widget _buildFolderOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    final isDarkMode = _isDarkMode;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
// Clase para dibujar el patrón de fondo estilo Apple
class BackgroundPatternPainter extends CustomPainter {
  final Color color;
  final double patternSize;
  final double strokeWidth;

  BackgroundPatternPainter({
    required this.color,
    required this.patternSize,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double halfWidth = size.width / 2;
    final double halfHeight = size.height / 2;
    
    // Pintar gradiente de fondo
    final Paint gradientPaint = Paint();
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    gradientPaint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.1),
        color.withOpacity(0.05),
        color.withOpacity(0.02),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(rect);
    
    canvas.drawRect(rect, gradientPaint);
    
    // Pintar patrón de puntos principal con efecto de profundidad
    final dotPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill;

    // Dibujar grid de puntos con tallas variables para efecto de profundidad
    for (double x = 0; x < size.width; x += patternSize) {
      for (double y = 0; y < size.height; y += patternSize) {
        // Calcular distancia al centro para efecto de profundidad
        final double distanceToCenter = _distanceToPoint(
          x, y, halfWidth, halfHeight
        );
        final double maxDistance = _distanceToPoint(
          0, 0, halfWidth, halfHeight
        );
        
        // Reducir el tamaño de los puntos conforme se alejan del centro
        final double sizeFactor = 1.0 - (distanceToCenter / maxDistance) * 0.7;
        final double pointSize = ((x / patternSize).floor() % 3 == (y / patternSize).floor() % 3)
            ? 1.5 * sizeFactor 
            : 0.8 * sizeFactor;
        
        // Solo dibujar puntos con tamaño significativo
        if (pointSize > 0.3) {
          dotPaint.color = color.withOpacity(0.2 * sizeFactor);
          canvas.drawCircle(Offset(x, y), pointSize, dotPaint);
        }
      }
    }

    // Dibujar formas geométricas de fondo para añadir interés visual
    _drawBackgroundShapes(canvas, size, color);
    
    // Dibujar líneas de cuadrícula muy sutiles
    final gridPaint = Paint()
      ..color = color.withOpacity(0.07)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Líneas horizontales espaciadas
    for (double y = patternSize * 4; y < size.height; y += patternSize * 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Líneas verticales espaciadas
    for (double x = patternSize * 4; x < size.width; x += patternSize * 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }
  
  // Método auxiliar para calcular la distancia entre dos puntos
  double _distanceToPoint(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }
  
  // Método para dibujar formas geométricas decorativas
  void _drawBackgroundShapes(Canvas canvas, Size size, Color baseColor) {
    final Paint shapePaint = Paint()
      ..style = PaintingStyle.fill;
    
    // Random para posiciones aleatorias pero determinísticas
    final Random random = Random(42);
    
    // Dibujar círculos grandes difuminados
    for (int i = 0; i < 4; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = (50 + random.nextDouble() * 150);
      
      // Gradiente radial para los círculos
      shapePaint.shader = RadialGradient(
        colors: [
          baseColor.withOpacity(0.06),
          baseColor.withOpacity(0.01),
        ],
        stops: [0.0, 1.0],
        radius: 1.0,
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      
      canvas.drawCircle(Offset(x, y), radius, shapePaint);
    }
    
    // Dibujar algunos patrones hexagonales sutiles en ubicaciones estratégicas
    _drawHexagonPattern(
      canvas, 
      Offset(size.width * 0.2, size.height * 0.3),
      baseColor.withOpacity(0.08),
      30,
      3
    );
    
    _drawHexagonPattern(
      canvas, 
      Offset(size.width * 0.8, size.height * 0.7),
      baseColor.withOpacity(0.08),
      30,
      3
    );
  }
  
  // Método para dibujar un patrón de hexágonos
  void _drawHexagonPattern(Canvas canvas, Offset center, Color color, double size, int rings) {
    final Paint hexPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
      
    for (int ring = 0; ring < rings; ring++) {
      final double ringSize = size * (1 + ring * 0.5);
      
      Path hexPath = Path();
      for (int i = 0; i < 6; i++) {
        final double angle = (i * 60) * (pi / 180);
        final double x = center.dx + ringSize * cos(angle);
        final double y = center.dy + ringSize * sin(angle);
        
        if (i == 0) {
          hexPath.moveTo(x, y);
        } else {
          hexPath.lineTo(x, y);
        }
      }
      hexPath.close();
      
      canvas.drawPath(hexPath, hexPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Clase para dibujar un fondo con efecto neón
class NeonBackgroundPainter extends CustomPainter {
  final bool isDarkMode;
  
  NeonBackgroundPainter({required this.isDarkMode});
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Dibujamos círculos y óvalos con efecto neón en el fondo
    _drawNeonCircles(canvas, size);
    
    // Añadimos un efecto de grid sutil
    _drawNeonGrid(canvas, size);
  }
  
  void _drawNeonCircles(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final random = Random(42); // Semilla fija para consistencia
    
    // Crear varios círculos de diferentes tamaños y posiciones
    for (int i = 0; i < 8; i++) {
      double x = random.nextDouble() * width;
      double y = random.nextDouble() * height;
      double radius = 50 + random.nextDouble() * 200;
      
      // Colores neón adaptados según modo claro/oscuro
      Color neonColor;
      if (i % 3 == 0) {
        // Azul neón
        neonColor = isDarkMode ? Color(0xFF4D6CFA) : Color(0xFF3A7BF2);
      } else if (i % 3 == 1) {
        // Morado neón
        neonColor = isDarkMode ? Color(0xFF9D4EDD) : Color(0xFF8C61FF);
      } else {
        // Cyan neón
        neonColor = isDarkMode ? Color(0xFF02C3C7) : Color(0xFF00B4C6);
      }
      
      // Ajustar opacidad según el modo
      double baseOpacity = isDarkMode ? 0.2 : 0.15;
      
      // Crear un gradiente radial para el efecto de brillo
      final Paint circlePaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            neonColor.withOpacity(baseOpacity),
            neonColor.withOpacity(baseOpacity * 0.1),
            neonColor.withOpacity(0.0),
          ],
          stops: [0.0, 0.5, 1.0],
          radius: 1.0,
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        circlePaint,
      );
      
      // Añadir un pequeño brillo central más intenso
      final Paint centerPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            neonColor.withOpacity(isDarkMode ? 0.4 : 0.2),
            neonColor.withOpacity(0.0),
          ],
          stops: [0.0, 1.0],
          radius: 0.5,
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius * 0.3));
      
      canvas.drawCircle(
        Offset(x, y),
        radius * 0.3,
        centerPaint,
      );
    }
  }
  
  void _drawNeonGrid(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Ajustar opacidad según el modo
    double gridOpacity = isDarkMode ? 0.08 : 0.04;
    
    // Líneas horizontales
    final Paint horizontalLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFF02C3C7).withOpacity(gridOpacity),
          Colors.transparent,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, 1));
    
    for (double y = 50; y < height; y += 100) {
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        horizontalLinePaint,
      );
    }
    
    // Líneas verticales
    final Paint verticalLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color(0xFF9D4EDD).withOpacity(gridOpacity),
          Colors.transparent,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, 1, height));
    
    for (double x = 50; x < width; x += 100) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        verticalLinePaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

