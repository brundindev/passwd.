import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

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
          return "No existe ninguna cuenta asociada a este correo electrónico. Por favor, regístrate primero.";
        case 'wrong-password':
          return "La contraseña introducida es incorrecta. Por favor, inténtalo de nuevo.";
        case 'email-already-in-use':
          return "Este correo electrónico ya está registrado. Intenta iniciar sesión o utiliza otro correo.";
        case 'weak-password':
          return "La contraseña es demasiado débil. Utiliza al menos 6 caracteres combinando letras, números y símbolos.";
        case 'invalid-email':
          return "El formato del correo electrónico no es válido. Comprueba que has escrito correctamente tu dirección.";
        case 'network-request-failed':
          return "Error de conexión a Internet. Comprueba tu conexión y vuelve a intentarlo.";
        case 'internal-error':
          return "Error interno en el servidor. Por favor, inténtalo de nuevo más tarde.";
        case 'operation-not-allowed':
          return "Esta operación no está permitida. Contacta con el administrador del sistema.";
        case 'too-many-requests':
          return "Has realizado demasiados intentos fallidos. Por favor, espera unos minutos e inténtalo de nuevo.";
        case 'requires-recent-login':
          return "Esta operación requiere que hayas iniciado sesión recientemente. Por favor, cierra sesión y vuelve a iniciarla.";
        case 'expired-action-code':
          return "El código de acción ha caducado. Por favor, solicita un nuevo código.";
        case 'invalid-action-code':
          return "El código de acción no es válido. Es posible que ya haya sido utilizado o esté mal formateado.";
        case 'account-exists-with-different-credential':
          return "Ya existe una cuenta con este correo electrónico pero con otro método de inicio de sesión. Prueba con otro método.";
        case 'invalid-credential':
          return "Las credenciales proporcionadas no son válidas o han caducado. Por favor, inténtalo de nuevo.";
        case 'user-disabled':
          return "Esta cuenta ha sido desactivada. Contacta con el soporte para más información.";
        case 'invalid-verification-code':
          return "El código de verificación introducido no es válido. Por favor, comprueba e inténtalo de nuevo.";
        case 'invalid-verification-id':
          return "El ID de verificación no es válido. Reinicia el proceso de verificación.";
        case 'captcha-check-failed':
          return "La verificación de seguridad ha fallado. Por favor, inténtalo de nuevo.";
        case 'app-not-authorized':
          return "Esta aplicación no está autorizada para usar Firebase Authentication.";
        case 'missing-verification-code':
          return "Falta el código de verificación. Por favor, completa todos los campos.";
        case 'missing-verification-id':
          return "Falta el ID de verificación. Por favor, reinicia el proceso.";
        case 'quota-exceeded':
          return "Se ha excedido la cuota de operaciones. Por favor, inténtalo más tarde.";
        case 'email-change-needs-verification':
          return "El cambio de correo electrónico requiere verificación. Revisa tu bandeja de entrada.";
        default:
          return "Error de autenticación: ${error.message}. Por favor, inténtalo de nuevo.";
      }
    } else if (error is PlatformException) {
      // Errores específicos de la plataforma
      String errorCode = error.code;
      String errorMessage = error.message ?? "Error de plataforma desconocido";
      
      if (errorCode == 'sign_in_canceled' || errorCode == 'sign_in_failed') {
        return "Se ha cancelado o fallado el inicio de sesión. Por favor, inténtalo de nuevo.";
      } else if (errorCode.contains('network')) {
        return "Error de red. Comprueba tu conexión a Internet e inténtalo de nuevo.";
      } else if (errorCode.contains('google')) {
        return "Error al conectar con Google. Por favor, inténtalo de nuevo más tarde.";
      } else {
        return "Error de plataforma: $errorMessage";
      }
    } else if (error is TimeoutException) {
      return "La operación ha tardado demasiado tiempo. Comprueba tu conexión a Internet e inténtalo de nuevo.";
    } else {
      // Otros errores
      String errorMsg = error.toString();
      
      if (errorMsg.contains('timeout') || errorMsg.contains('tiempo')) {
        return "Tiempo de espera agotado. Comprueba tu conexión a Internet e inténtalo de nuevo.";
      } else if (errorMsg.contains('network') || errorMsg.contains('conexión') || errorMsg.contains('red')) {
        return "Error de conexión a Internet. Verifica tu red e inténtalo de nuevo.";
      } else if (errorMsg.contains('cancel') || errorMsg.contains('cancelad')) {
        return "Operación cancelada. Inténtalo de nuevo cuando estés listo.";
      } else if (errorMsg.contains('Google')) {
        return "Error al conectar con Google. Por favor, inténtalo de nuevo o usa otro método de inicio de sesión.";
      } else {
        return "Ha ocurrido un error inesperado. Por favor, inténtalo de nuevo más tarde.";
      }
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
      print("Iniciando registro rápido con email: $email");
      // Intentar el registro con tiempo máximo de 5 segundos
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(Duration(seconds: 5), onTimeout: () {
        throw TimeoutException("Tiempo de espera agotado durante el registro");
      });
      
      print("Usuario registrado correctamente con UID: ${result.user?.uid}");
      
      // Guardar usuario en la base de datos (opcional, con tiempo limitado)
      try {
        await _database.child('usuarios').child(result.user!.uid).set({
          'nombre': email.split('@')[0], // Nombre de usuario del correo
          'pass': '', // Campo vacío por seguridad
          'registroCompletado': true,
          'fechaRegistro': DateTime.now().toIso8601String(),
        }).timeout(Duration(seconds: 2), onTimeout: () {
          print("Timeout al guardar en base de datos, pero el usuario ya está registrado");
          return null;
        });
        print("Información del usuario guardada en la base de datos");
      } catch (dbError) {
        print("Advertencia: No se guardó información adicional en la base de datos: $dbError");
        // Continuamos aunque haya error en la base de datos
      }
      
      return result;
    } on TimeoutException catch (e) {
      print("Error de timeout durante el registro: $e");
      throw Exception("El registro tomó demasiado tiempo. Intenta de nuevo o verifica tu conexión a Internet.");
    } catch (e) {
      print("Error estándar durante el registro: $e");
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
          // Cerrar cualquier sesión previa para evitar problemas de cache
          await _auth.signOut();
          
          // Configuración del proveedor de Google para web
          GoogleAuthProvider authProvider = GoogleAuthProvider();
          // Añadir ámbitos (scopes) opcionales
          authProvider.addScope('email');
          authProvider.addScope('profile');
          
          print("Configurado proveedor Google, intentando signInWithPopup");
          
          try {
            // Opción 1: Iniciar sesión con ventana emergente
            return await _auth.signInWithPopup(authProvider);
          } catch (popupError) {
            print("Error con signInWithPopup: $popupError");
            
            print("Intentando con signInWithRedirect como alternativa");
            // Opción 2 (alternativa): Usar redirección
            await _auth.signInWithRedirect(authProvider);
            // Esta línea solo se ejecutará si la redirección falla o regresa
            return await _auth.getRedirectResult();
          }
        } catch (webError) {
          print("Error específico en autenticación web: $webError");
          rethrow;
        }
      } else {
        print("Ejecutando inicio de sesión con Google en plataforma nativa");
        
        // Establecer un timeout global para todo el proceso
        return await Future.delayed(const Duration(milliseconds: 200)).then((_) async {
          try {
            print("⚠️ IMPORTANTE: Realizando limpieza forzada de sesiones Google previas");
            // Resetear completamente Google Sign In siempre en el primer intento
            await _forceCompleteReset();
            
            // Iniciar el proceso de autenticación con Google para plataformas nativas
            print("📱 Solicitando signIn con GoogleSignIn");
            final GoogleSignInAccount? googleUser = await _googleSignIn.signIn()
                .timeout(
                  const Duration(seconds: 30),
                  onTimeout: () {
                    print("⏱️ TIMEOUT en GoogleSignIn.signIn()");
                    throw TimeoutException('Tiempo de espera agotado al obtener la cuenta de Google');
                  },
                );
            
            if (googleUser == null) {
              print("❌ Usuario canceló el inicio de sesión con Google");
              throw Exception('Inicio de sesión con Google cancelado por el usuario');
            }

            print("✅ Usuario Google seleccionado: ${googleUser.email}");
            
            // Obtener los detalles de autenticación de la solicitud
            print("🔑 Obteniendo tokens de autenticación...");
            final GoogleSignInAuthentication googleAuth = await googleUser.authentication
                .timeout(
                  const Duration(seconds: 20),
                  onTimeout: () {
                    print("⏱️ TIMEOUT en googleUser.authentication");
                    throw TimeoutException('Tiempo de espera agotado al obtener la autenticación de Google');
                  },
                );

            print("✅ Tokens obtenidos correctamente");
            
            // Crear una nueva credencial
            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );

            print("🔥 Credencial Google obtenida, iniciando sesión en Firebase");
            
            // Iniciar sesión en Firebase con la credencial de Google
            UserCredential result = await _auth.signInWithCredential(credential)
                .timeout(
                  const Duration(seconds: 20),
                  onTimeout: () {
                    print("⏱️ TIMEOUT en Firebase auth");
                    throw TimeoutException('Tiempo de espera agotado al iniciar sesión en Firebase');
                  },
                );
            
            print("✅ Inicio de sesión en Firebase exitoso: ${result.user?.uid}");
            
            // Verificar si es un nuevo usuario
            if (result.additionalUserInfo?.isNewUser ?? false) {
              print("👤 Nuevo usuario detectado, guardando en base de datos");
              
              // Guardar nuevo usuario en la base de datos con manejo de errores mejorado
              try {
                await _database.child('usuarios').child(result.user!.uid).set({
                  'nombre': googleUser.displayName ?? googleUser.email.split('@')[0] ?? 'Usuario',
                  'pass': '', // Campo vacío por seguridad
                  'registroCompletado': true,
                  'fechaRegistro': DateTime.now().toIso8601String(),
                  'metodoRegistro': 'google',
                }).timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    print("⚠️ TIMEOUT al guardar datos del usuario, pero la autenticación fue exitosa");
                    return null;
                  },
                );
                print("✅ Datos del usuario guardados correctamente en la base de datos");
              } catch (dbError) {
                // No interrumpir el flujo si falla el guardado en DB
                print("⚠️ Error al guardar datos del usuario: $dbError");
                print("📝 La autenticación fue exitosa, continuando sin datos adicionales");
              }
            } else {
              print("👤 Usuario existente detectado, no es necesario guardar datos");
            }
            
            _needsGoogleSignInReset = true; // Asegurar limpieza en próximo uso
            return result;
            
          } on TimeoutException catch (e) {
            print("⏱️ ERROR DE TIMEOUT: $e");
            throw Exception("La conexión con Google está tardando demasiado. Por favor, verifica tu conexión a Internet e inténtalo de nuevo.");
          } catch (e) {
            print("❌ ERROR específico durante el proceso de Google Sign In: $e");
            
            // Intentar diagnóstico y recuperación
            try {
              await _resetGoogleSignIn();
            } catch (resetError) {
              print("⚠️ No se pudo resetear Google Sign In tras error: $resetError");
            }
            
            // Determinar mensaje de error más específico
            if (e.toString().contains('network')) {
              throw Exception("Error de conexión de red. Verifica tu conexión a Internet.");
            } else if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
              throw Exception("Inicio de sesión cancelado. Por favor, completa el proceso de inicio de sesión con Google.");
            } else if (e.toString().contains('credential')) {
              throw Exception("Error con las credenciales de Google. Por favor, intenta con otra cuenta.");
            } else {
              throw Exception("Error durante el inicio de sesión con Google: $e");
            }
          }
        });
      }
    } catch (e) {
      print("❌ ERROR GENERAL en signInWithGoogle: $e");
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
      print("Iniciando reseteo completo de GoogleSignIn");
      
      // Cerrar sesión primero
      try {
        await _googleSignIn.signOut();
        print("GoogleSignIn.signOut() completado");
      } catch (signOutError) {
        print("Error en GoogleSignIn.signOut(): $signOutError");
        // Continuar a pesar del error
      }
      
      // Esperar un momento para evitar problemas de concurrencia
      await Future.delayed(Duration(milliseconds: 200));
      
      // Desconectar completamente
      try {
        await _googleSignIn.disconnect();
        print("GoogleSignIn.disconnect() completado");
      } catch (disconnectError) {
        print("Error en GoogleSignIn.disconnect(): $disconnectError");
        // Continuar a pesar del error
      }
      
      // Esperar para asegurar que la desconexión sea completa
      await Future.delayed(Duration(milliseconds: 500));
      print("GoogleSignIn reseteado correctamente");
    } catch (e) {
      print("Error general al resetear GoogleSignIn: $e");
      // Continuar a pesar del error
    }
  }

  // Enviar correo de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print("Enviando correo de restablecimiento a: $email");
      await _auth.sendPasswordResetEmail(email: email);
      print("Correo de restablecimiento enviado correctamente");
    } catch (e) {
      print("Error al enviar correo de restablecimiento: $e");
      rethrow;
    }
  }

  // Función para forzar un reseteo completo de GoogleSignIn
  Future<void> _forceCompleteReset() async {
    try {
      // Primero cerrar sesión en Firebase
      try {
        await _auth.signOut();
        print("✅ Firebase.signOut() completado");
      } catch (e) {
        print("⚠️ Error en Firebase.signOut(): $e");
      }
      
      // Esperar un momento antes de continuar
      await Future.delayed(Duration(milliseconds: 300));
      
      // Resetear GoogleSignIn
      try {
        await _googleSignIn.signOut();
        print("✅ GoogleSignIn.signOut() completado");
      } catch (e) {
        print("⚠️ Error en GoogleSignIn.signOut(): $e");
      }
      
      // Esperar otro momento
      await Future.delayed(Duration(milliseconds: 300));
      
      // Forzar desconexión completa
      try {
        await _googleSignIn.disconnect();
        print("✅ GoogleSignIn.disconnect() completado");
      } catch (e) {
        print("⚠️ Error en GoogleSignIn.disconnect(): $e");
      }
      
      // Esperar un poco más para asegurar que todo se ha reiniciado
      await Future.delayed(Duration(milliseconds: 500));
      print("✅ Reseteo completo finalizado");
    } catch (e) {
      print("⚠️ Error general en _forceCompleteReset: $e");
      // Continuar a pesar del error
    }
  }
} 