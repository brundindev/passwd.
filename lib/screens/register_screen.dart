import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Cerrar el teclado
    FocusScope.of(context).unfocus();
    
    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      print("Validación del formulario falló");
      return;
    }
    
    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Obtener valores de los controladores
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    print("Iniciando registro para email: $email");
    
    // Configurar un timeout global para todo el proceso
    bool timeoutOccurred = false;
    Future.delayed(Duration(seconds: 10)).then((_) {
      if (_isLoading && mounted) {
        print("⚠️ TIMEOUT GLOBAL EN REGISTRO - Forzando finalización");
        timeoutOccurred = true;
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El registro tardó demasiado tiempo, pero tu cuenta ha sido creada. Intenta iniciar sesión.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 6),
          ),
        );
        
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
    
    try {
      // Paso 1: Registrar usuario
      final authService = Provider.of<AuthService>(context, listen: false);
      UserCredential userCredential = await authService.registerWithEmailAndPassword(email, password);
      print("✅ Usuario registrado con UID: ${userCredential.user!.uid}");
      
      // Paso 2: Intentar enviar verificación (saltamos al paso 3 si hay error)
      bool emailVerificationSent = false;
      try {
        print("📧 Intentando enviar correo de verificación...");
        await userCredential.user!.sendEmailVerification();
        emailVerificationSent = true;
        print("✅ Correo de verificación enviado con éxito");
      } catch (e) {
        print("⚠️ Error al enviar correo: $e");
        // Continuamos aunque falle el envío del correo
      }
      
      // Paso 3: Cerrar sesión
      try {
        await authService.signOut();
        print("✅ Usuario desconectado después del registro");
      } catch (e) {
        print("⚠️ Error al cerrar sesión: $e");
        // Continuamos aunque falle el cierre de sesión
      }
      
      // Paso 4: Actualizar UI y mostrar el popup (solo si no ha ocurrido timeout)
      if (!timeoutOccurred && mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Mostrar el popup de verificación de email
        _showEmailVerificationDialog(email, emailVerificationSent);
      }
    } catch (e) {
      print("❌ ERROR EN REGISTRO: $e");
      
      // Manejar el error solo si no ha ocurrido timeout
      if (!timeoutOccurred && mounted) {
        String errorMsg = 'Error al registrar: $e';
        
        if (e.toString().contains('email-already-in-use')) {
          errorMsg = 'Este correo ya está registrado. Intenta iniciar sesión.';
        } else if (e.toString().contains('weak-password')) {
          errorMsg = 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
        } else if (e.toString().contains('invalid-email')) {
          errorMsg = 'El formato del correo electrónico no es válido.';
        } else if (e.toString().contains('network')) {
          errorMsg = 'Error de conexión a Internet. Comprueba tu conexión y vuelve a intentarlo.';
        } else if (e.toString().contains('timeout')) {
          errorMsg = 'El registro ha tardado demasiado tiempo. Por favor, inténtalo de nuevo.';
        } else if (e.toString().contains('Error durante el inicio de sesión con Google')) {
          errorMsg = 'Error durante el registro con Google. Por favor, inténtalo de nuevo.';
        } else {
          // Intentar usar el servicio de manejo de errores para obtener un mensaje más específico
          try {
            final authService = Provider.of<AuthService>(context, listen: false);
            errorMsg = authService.handleAuthError(e);
          } catch (_) {
            // Si falla, seguir usando el mensaje por defecto
          }
        }
        
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Variable para rastrear si el diálogo está mostrado
    bool isDialogShowing = false;
    
    try {
      // Mostrar diálogo de carga
      if (mounted) {
        isDialogShowing = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 16,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 50, 
                      width: 50, 
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        strokeWidth: 5,
                      )
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Registrando con Google...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Conectando con Google',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
      
      // Aumentamos el timeout a 30 segundos para dar más tiempo al primer intento
      Future<void> timeoutFuture = Future.delayed(Duration(seconds: 30)).then((_) {
        if (mounted && isDialogShowing && Navigator.of(context, rootNavigator: true).canPop()) {
          print("Timeout de seguridad activado para cerrar el diálogo de carga en Google Sign-In");
          try {
            Navigator.of(context, rootNavigator: true).pop();
            isDialogShowing = false;
            setState(() {
              _isLoading = false;
              _errorMessage = "La conexión con Google está tardando demasiado. Por favor, inténtalo de nuevo.";
            });
          } catch (e) {
            print("Error al cerrar el diálogo por timeout: $e");
          }
        }
      });
      
      print("Iniciando proceso de registro con Google...");
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Intentamos directamente la autenticación con Google sin usar Future.any
      // para evitar posibles interrupciones tempranas
      try {
        final result = await authService.signInWithGoogle();
        
        // Si llegamos aquí, cancelamos el timeout
        timeoutFuture.ignore();
        
        print("Registro con Google exitoso. UID: ${result.user?.uid}");
      
        // Verificar que el usuario esté autenticado
        final currentUser = FirebaseAuth.instance.currentUser;
        print("Verificando estado de autenticación después del registro con Google: ${currentUser?.uid ?? 'No autenticado'}");
        
        if (currentUser == null) {
          throw Exception("El usuario no fue autenticado correctamente después del registro con Google");
        }
        
        // Esperar un poco para hacer visible la carga
        await Future.delayed(Duration(milliseconds: 800));
        
        if (mounted) {
          // Cerrar el diálogo de carga si está abierto
          if (isDialogShowing && Navigator.of(context, rootNavigator: true).canPop()) {
            try {
              Navigator.of(context, rootNavigator: true).pop();
              isDialogShowing = false;
            } catch (navError) {
              print("Error al cerrar diálogo: $navError");
            }
          }
          
          // Detener completamente la carga
          setState(() {
            _isLoading = false;
          });
          
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cuenta de Google vinculada correctamente. ¡Bienvenido a PASSWD!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          
          print("Navegando a la pantalla principal (HomeScreen)...");
          
          // Navegar directamente a HomeScreen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        }
      } catch (e) {
        print("Error específico en la autenticación con Google: $e");
        
        // Cancelamos el timeout ya que ya tenemos un error
        timeoutFuture.ignore();
        
        if (mounted) {
          // Cerrar el diálogo de carga si está abierto
          if (isDialogShowing && Navigator.of(context, rootNavigator: true).canPop()) {
            try {
              Navigator.of(context, rootNavigator: true).pop();
              isDialogShowing = false;
            } catch (navError) {
              print("Error al cerrar diálogo: $navError");
            }
          }
          
          setState(() {
            _isLoading = false;
            
            // Mensaje de error más específico según el tipo de error
            if (e.toString().contains('canceled')) {
              _errorMessage = "Se canceló el inicio de sesión con Google. Por favor, inténtalo de nuevo.";
            } else if (e.toString().contains('network')) {
              _errorMessage = "Error de conexión. Verifica tu conexión a internet e inténtalo de nuevo.";
            } else if (e.toString().contains('credential')) {
              _errorMessage = "Error de credenciales. Por favor, inténtalo de nuevo con otra cuenta de Google.";
            } else {
              _errorMessage = "No se pudo completar el registro con Google. Por favor, inténtalo de nuevo.";
            }
          });
        }
      }
      
    } catch (e) {
      print("Error general durante el registro con Google: $e");
      
      // Cerrar el diálogo de carga si está abierto
      if (mounted && isDialogShowing && Navigator.of(context, rootNavigator: true).canPop()) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          isDialogShowing = false;
        } catch (navError) {
          print("Error al cerrar diálogo: $navError");
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          try {
            // Intentar usar el servicio de manejo de errores para obtener un mensaje más específico
            final authService = Provider.of<AuthService>(context, listen: false);
            _errorMessage = authService.handleAuthError(e);
          } catch (_) {
            _errorMessage = "Ocurrió un error inesperado durante el registro con Google. Por favor, inténtalo de nuevo más tarde.";
          }
        });
      }
    }
  }

  // Método para mostrar el diálogo de verificación de email
  void _showEmailVerificationDialog(String email, bool emailSent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verificación de Email',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (emailSent)
                Text(
                  'Hemos enviado un correo de verificación a:',
                  style: TextStyle(fontSize: 14),
                )
              else
                Text(
                  'Se ha creado tu cuenta pero hubo un problema al enviar el correo de verificación a:',
                  style: TextStyle(fontSize: 14),
                ),
              SizedBox(height: 8),
              Text(
                email,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: emailSent ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: emailSent ? Colors.green.shade300 : Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          emailSent ? Icons.info_outline : Icons.warning_amber_outlined, 
                          color: emailSent ? Colors.green : Colors.orange, 
                          size: 20
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            emailSent
                                ? 'Por favor, verifica tu correo electrónico antes de iniciar sesión.'
                                : 'No pudimos enviar el correo de verificación. Podrás solicitar uno nuevo desde la pantalla de inicio de sesión.',
                            style: TextStyle(
                              color: emailSent ? Colors.green.shade800 : Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (emailSent) ...[
                      SizedBox(height: 10),
                      Text(
                        'Revisa tu bandeja de entrada y haz clic en el enlace de verificación que hemos enviado.',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (emailSent)
              TextButton(
                onPressed: () async {
                  try {
                    // Intentar reenviar el correo de verificación
                    final authService = Provider.of<AuthService>(context, listen: false);
                    
                    // Iniciar sesión temporalmente
                    try {
                      final result = await authService.signInWithEmailAndPassword(
                        email,
                        _passwordController.text.trim(),
                      );
                      await result.user?.sendEmailVerification();
                      await authService.signOut();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Correo de verificación reenviado'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      print("Error al reenviar verificación: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No se pudo reenviar el correo de verificación'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    print("Error general al reenviar correo: $e");
                  }
                },
                child: Text('Reenviar correo'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Ir a iniciar sesión'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con GIF animado
          SizedBox.expand(
            child: Image.asset(
              'assets/background.gif',
              fit: BoxFit.cover,
            ),
          ),
          
          // Capa de oscurecimiento para mejorar legibilidad
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          
          // Patrón de puntos decorativos
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
            painter: DotPatternPainter(),
          ),
          
          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Botón de volver atrás
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                
                // Contenido del formulario
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person_add,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                'Crear cuenta',
                                style: Theme.of(context).textTheme.displaySmall,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Protege tus contraseñas con PASSWD',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 40),
                              if (_errorMessage != null) 
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_errorMessage != null) 
                                SizedBox(height: 20),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email, color: Colors.grey[800]),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: TextStyle(color: Colors.black87),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Por favor ingresa un email válido';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: Icon(Icons.lock, color: Colors.grey[800]),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword ? Icons.visibility : Icons.visibility_off,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: TextStyle(color: Colors.black87),
                                obscureText: !_showPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Confirmar contraseña',
                                  prefixIcon: Icon(Icons.lock, color: Colors.grey[800]),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showConfirmPassword = !_showConfirmPassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: TextStyle(color: Colors.black87),
                                obscureText: !_showConfirmPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor confirma tu contraseña';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: _isLoading
                                      ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black))
                                      : Text('Crear cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white30)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('O registrarse con', style: TextStyle(color: Colors.white70)),
                                  ),
                                  Expanded(child: Divider(color: Colors.white30)),
                                ],
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading 
                                    ? null 
                                    : () => _signInWithGoogle(),
                                  icon: Image.asset(
                                    'assets/google_logo.png',
                                    height: 24,
                                  ),
                                  label: Text('Google', style: TextStyle(fontSize: 16, color: Colors.white)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '¿Ya tienes una cuenta?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, '/login');
                                    },
                                  child: Text(
                                    'Inicia sesión',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pintor personalizado para crear un patrón de puntos
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    
    const spacing = 30.0; // Espacio entre puntos
    final dotSize = 2.0; // Tamaño de los puntos
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Añadir algo de variación en la opacidad para crear un efecto más interesante
        paint.color = Colors.white.withOpacity(0.1 + (x * y) % 0.3);
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}