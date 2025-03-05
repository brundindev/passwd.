import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/password_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/favorite_passwords_screen.dart';
import 'screens/trash_passwords_screen.dart';
import 'screens/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/password_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Definir colores de la aplicación
class AppColors {
  static const Color primaryColor = Color(0xFF000000); // Negro
  static const Color secondaryColor = Color(0xFFFFFFFF); // Blanco
  static const Color accentColor = Color(0xFF3A7BF2); // Azul para acentos
  static const Color errorColor = Color(0xFFE53935); // Rojo para errores
  static const Color successColor = Color(0xFF43A047); // Verde para éxito
  static const Color backgroundGradientLight = Color(0xFF121212); // Negro menos oscuro para gradientes
  static const Color backgroundGradientDark = Color(0xFF000000); // Negro puro para gradientes
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print("Iniciando Firebase... Plataforma web: $kIsWeb");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print("Firebase inicializado correctamente");
    print("Usuario actual: ${FirebaseAuth.instance.currentUser?.uid ?? 'No hay usuario autenticado'}");
    
    if (kIsWeb) {
      print("Configuración específica para web");
      // Comprobar si hay un resultado de redirección pendiente
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        try {
          final userCred = await FirebaseAuth.instance.getRedirectResult();
          user = userCred.user;
          if (user != null) {
            print("Usuario autenticado por redirección: ${user.uid}");
          }
        } catch (e) {
          print("No hay resultado de redirección pendiente o ocurrió un error: $e");
        }
      }
    }
  } catch (e) {
    print("Error al inicializar Firebase: $e");
    // Continuamos con la ejecución incluso si hay error
  }
  
  print("Configurando proveedores de la aplicación...");
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) {
            print("Creando instancia de AuthService");
            return AuthService();
          }
        ),
        Provider<PasswordService>(
          create: (_) {
            print("Creando instancia de PasswordService");
            return PasswordService();
          }
        ),
        ChangeNotifierProvider<PasswordProvider>(
          create: (_) {
            print("Creando instancia de PasswordProvider");
            return PasswordProvider();
          }
        ),
        StreamProvider(
          create: (context) {
            print("Configurando stream de authStateChanges");
            return Provider.of<AuthService>(context, listen: false).authStateChanges;
          },
          initialData: null,
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Colores base
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.primaryColor,
        canvasColor: AppColors.primaryColor,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accentColor,
          secondary: AppColors.secondaryColor,
          error: AppColors.errorColor,
          surface: AppColors.primaryColor,
        ),
        
        // Estilo de texto
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryColor,
            letterSpacing: 2,
          ),
          displayMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryColor,
          ),
          displaySmall: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryColor,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: AppColors.secondaryColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: AppColors.secondaryColor.withOpacity(0.9),
          ),
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryColor,
          ),
        ),
        
        // Estilos de AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(
            color: AppColors.secondaryColor,
          ),
        ),
        
        // Estilos de botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryColor,
            foregroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondaryColor,
            side: BorderSide(color: AppColors.secondaryColor, width: 2),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentColor,
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Estilos de Card y Dialog
        cardTheme: CardTheme(
          color: AppColors.primaryColor,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        
        // Estilo para campos de formulario
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.accentColor, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade800),
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIconColor: Colors.grey.shade800,
          suffixIconColor: Colors.grey.shade800,
        ),
        
        // Otros estilos
        dividerTheme: DividerThemeData(
          color: Colors.white24,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Color(0xFF323232),
          contentTextStyle: TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/settings': (context) => SettingsScreen(),
        '/favorites': (context) => FavoritePasswordsScreen(),
        '/trash': (context) => TrashPasswordsScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        print("AuthWrapper - Estado de conexión: ${snapshot.connectionState}");
        print("AuthWrapper - ¿Tiene datos?: ${snapshot.hasData}");
        print("AuthWrapper - ¿Tiene error?: ${snapshot.hasError}");
        if (snapshot.hasError) print("Error: ${snapshot.error}");
        
        // Mientras se conecta, muestra un indicador de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Verificando estado de autenticación...")
                ],
              ),
            ),
          );
        }
        
        // Si hay un error, mostrar mensaje de error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 20),
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/welcome');
                    },
                    child: Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Verificar usuario actual directamente como respaldo
        final currentUser = FirebaseAuth.instance.currentUser;
        print("Usuario actual en AuthWrapper: ${currentUser?.uid ?? 'No autenticado'}");
        
        // Si hay datos (usuario autenticado) o tenemos un usuario actual
        if (snapshot.hasData || currentUser != null) {
          print("Usuario autenticado, navegando a HomeScreen");
          return HomeScreen();
        }
        
        // Si no hay usuario autenticado
        print("Usuario no autenticado, navegando a LoginScreen");
        return LoginScreen();
      },
    );
  }
}
