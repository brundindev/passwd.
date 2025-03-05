import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Variable para controlar el estado de reinicio
  bool _needsGoogleSignInReset = false;

  // Obtener el estado de autenticación como un stream
  Stream<User?> get authStateChanges {
    print("Configurando stream de authStateChanges. Web: $kIsWeb");
    return _auth.authStateChanges();
  }

  // Manejo personalizado de errores
  String handleAuthError(dynamic error) {
    print("Error de autenticación: $error");
    print("Error tipo: ${error.runtimeType}");
    
    if (error is FirebaseAuthException) {
      print("FirebaseAuthException código: ${error.code}");
      // Errores específicos de FirebaseAuth
      switch (error.code) {
        case 'keychain-error':
          return "Error de acceso al llavero. Por favor verifica los permisos de la aplicación en macOS.";
        case 'user-not-found':
          return "No existe un usuario con este correo electrónico.";
        case 'wrong-password':
          return "Contraseña incorrecta.";
        case 'email-already-in-use':
          return "Este correo electrónico ya está en uso.";
        case 'weak-password':
          return "La contraseña es demasiado débil.";
        case 'invalid-email':
          return "El formato del correo electrónico no es válido.";
        case 'network-request-failed':
          return "Error de conexión. Verifica tu conexión a internet.";
        case 'internal-error':
          return "Error interno de Firebase. Por favor intenta de nuevo.";
        case 'operation-not-allowed':
          return "Esta operación no está permitida. Contacta al administrador.";
        default:
          return "Error de autenticación: ${error.message}";
      }
    } else if (error is PlatformException) {
      // Errores específicos de la plataforma
      return "Error de plataforma: ${error.message}";
    } else {
      // Otros errores
      return "Error inesperado: $error";
    }
  }

  // Iniciar sesión con correo y contraseña
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print("Intentando iniciar sesión con email: $email en plataforma: ${kIsWeb ? 'web' : 'nativa'}");
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Inicio de sesión exitoso: ${result.user?.uid}");
      return result;
    } catch (e) {
      print("Error al iniciar sesión con correo: $e");
      rethrow;
    }
  }

  // Registrarse con correo y contraseña
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      print("Intentando registrar usuario con email: $email");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("Usuario registrado exitosamente: ${result.user?.uid}");
      
      // Guardar usuario en la base de datos
      try {
        await _database.child('usuarios').child(result.user!.uid).set({
          'nombre': email.split('@')[0], // Usamos el nombre de usuario del correo
          'pass': '', // Campo vacío por seguridad
        });
        print("Información del usuario guardada en la base de datos");
      } catch (dbError) {
        print("Error al guardar información del usuario en la base de datos: $dbError");
        // Continuar aunque haya error en la base de datos
      }
      
      return result;
    } catch (e) {
      print("Error al registrarse con correo: $e");
      rethrow;
    }
  }

  // Iniciar sesión con Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Comprobar si estamos en la web
      if (kIsWeb) {
        print("Ejecutando inicio de sesión con Google en plataforma web");
        
        try {
          // Configuración del proveedor de Google para web
          GoogleAuthProvider authProvider = GoogleAuthProvider();
          // Añadir ámbitos (scopes) opcionales
          authProvider.addScope('email');
          authProvider.addScope('profile');
          
          print("Configurado proveedor Google, intentando signInWithPopup");
          
          // Opción 1: Iniciar sesión con ventana emergente
          return await _auth.signInWithPopup(authProvider).catchError((error) {
            print("Error con signInWithPopup: $error");
            
            print("Intentando con signInWithRedirect como alternativa");
            // Opción 2 (alternativa): Usar redirección si popup falla
            return _auth.signInWithRedirect(authProvider).then((_) {
              // Esta promesa no se resolverá en el caso de redirección
              // ya que la página se recargará
              return _auth.getRedirectResult();
            });
          });
        } catch (webError) {
          print("Error específico en autenticación web: $webError");
          rethrow;
        }
      } else {
        print("Ejecutando inicio de sesión con Google en plataforma nativa");
        
        // Verificar si necesitamos reiniciar la instancia de GoogleSignIn
        if (_needsGoogleSignInReset) {
          print("Reinicializando instancia de GoogleSignIn después de logout");
          await _resetGoogleSignIn();
          _needsGoogleSignInReset = false;
        } else {
          // Intentar cerrar cualquier sesión previa para forzar la selección de cuenta
          try {
            await _googleSignIn.signOut();
            // Pequeña pausa para asegurar que la instancia de GoogleSignIn se reinicie
            await Future.delayed(Duration(milliseconds: 300));
          } catch (e) {
            print("Error al reiniciar sesión anterior de Google: $e");
            // Continuar a pesar del error de limpieza
          }
        }
        
        // Iniciar el proceso de autenticación con Google para plataformas nativas
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          throw Exception('Inicio de sesión con Google cancelado por el usuario');
        }

        // Obtener los detalles de autenticación de la solicitud
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Crear una nueva credencial
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Iniciar sesión en Firebase con la credencial de Google
        UserCredential result = await _auth.signInWithCredential(credential);
        
        // Verificar si es un nuevo usuario
        if (result.additionalUserInfo?.isNewUser ?? false) {
          // Guardar nuevo usuario en la base de datos
          await _database.child('usuarios').child(result.user!.uid).set({
            'nombre': googleUser.displayName ?? googleUser.email.split('@')[0] ?? 'Usuario',
            'pass': '', // Campo vacío por seguridad
          });
        }
        
        return result;
      }
    } catch (e) {
      print("Error al iniciar sesión con Google: $e");
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      // Marcar que necesitamos reiniciar GoogleSignIn
      _needsGoogleSignInReset = true;
      
      // Primero cerrar la sesión de Firebase
      await _auth.signOut();
      
      // Luego limpiar GoogleSignIn si no estamos en la web
      if (!kIsWeb) {
        print("Limpiando sesión de Google");
        await _resetGoogleSignIn();
      } else {
        // En web solo cerramos la sesión normal
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print("Error al cerrar sesión: $e");
      rethrow;
    }
  }

  // Obtener usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Función para reiniciar GoogleSignIn
  Future<void> _resetGoogleSignIn() async {
    try {
      // Cerrar sesión primero
      await _googleSignIn.signOut();
      // Desconectar completamente
      await _googleSignIn.disconnect();
      // Esperar para asegurar que la desconexión sea completa
      await Future.delayed(Duration(milliseconds: 500));
      print("GoogleSignIn reseteado correctamente");
    } catch (e) {
      print("Error al resetear GoogleSignIn: $e");
      // Continuar a pesar del error
    }
  }
} 