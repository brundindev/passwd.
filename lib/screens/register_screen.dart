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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Mostrar diálogo de carga
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
                    'Creando tu cuenta...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Esto solo tomará un momento',
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
      
      // Configurar un timeout de seguridad para cerrar el diálogo después de 10 segundos
      // independientemente de lo que suceda
      Future.delayed(Duration(seconds: 10)).then((_) {
        if (mounted && Navigator.of(context).canPop()) {
          print("Timeout de seguridad activado para cerrar el diálogo de carga");
          try {
            Navigator.of(context).pop();
          } catch (e) {
            print("Error al cerrar el diálogo por timeout: $e");
          }
        }
      });
      
      try {
        print("Iniciando proceso de registro...");
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // Registrar al usuario
        final result = await authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        print("Registro exitoso. UID: ${result.user?.uid}");
        
        // Verificar que el usuario esté autenticado
        final currentUser = FirebaseAuth.instance.currentUser;
        print("Verificando estado de autenticación después del registro: ${currentUser?.uid ?? 'No autenticado'}");
        
        // Esperar un poco para hacer visible la carga
        await Future.delayed(Duration(milliseconds: 800));
        
        if (mounted) {
          // Cerrar el diálogo de carga
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          
          // Cerrar sesión después del registro exitoso
          try {
            await authService.signOut();
            print("Sesión cerrada después del registro exitoso");
          } catch (signOutError) {
            print("Error al cerrar sesión: $signOutError");
            // Continuamos con el flujo aunque haya error al cerrar sesión
          }
          
          // Detener completamente la carga
          setState(() {
            _isLoading = false;
          });
          
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cuenta creada correctamente. Por favor inicia sesión.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          
          print("Navegando a la pantalla de login...");
          
          // Usar una navegación más simple y directa posible
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          }
        }
      } catch (e) {
        print("Error durante el registro: $e");
        
        // Cerrar el diálogo de carga
        if (mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          
          setState(() {
            try {
              final authService = Provider.of<AuthService>(context, listen: false);
              _errorMessage = authService.handleAuthError(e);
            } catch (handlerError) {
              print("Error al manejar el error: $handlerError");
              _errorMessage = "Ocurrió un error durante el registro: $e";
            }
            _isLoading = false;
          });
        }
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
      
      // Configurar un timeout de seguridad para cerrar el diálogo después de 30 segundos
      Future<void> timeoutFuture = Future.delayed(Duration(seconds: 30)).then((_) {
        if (mounted && isDialogShowing && Navigator.of(context).canPop()) {
          print("Timeout de seguridad activado para cerrar el diálogo de carga en Google Sign-In");
          try {
            Navigator.of(context).pop();
            isDialogShowing = false;
            setState(() {
              _isLoading = false;
              _errorMessage ??= "No se pudo completar el registro con Google. Por favor, inténtalo de nuevo.";
            });
          } catch (e) {
            print("Error al cerrar el diálogo por timeout: $e");
          }
        }
      });
      
      print("Iniciando proceso de registro con Google...");
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Usar Future.any para manejar tanto el timeout como la autenticación
      await Future.any([
        timeoutFuture,
        _attemptGoogleSignIn(authService),
      ]);
      
    } catch (e) {
      print("Error durante el registro con Google: $e");
      
      // Cerrar el diálogo de carga si está abierto
      if (mounted && isDialogShowing && Navigator.of(context).canPop()) {
        try {
          Navigator.of(context).pop();
          isDialogShowing = false;
        } catch (navError) {
          print("Error al cerrar diálogo: $navError");
        }
      }
      
      if (mounted) {
        setState(() {
          try {
            final authService = Provider.of<AuthService>(context, listen: false);
            _errorMessage = authService.handleAuthError(e);
            print("Mensaje de error manejado: $_errorMessage");
          } catch (handlerError) {
            print("Error al manejar el error: $handlerError");
            _errorMessage = "Ocurrió un error durante el registro con Google: $e";
          }
          _isLoading = false;
        });
      }
    }
  }
  
  // Método separado para el intento de inicio de sesión con Google
  Future<void> _attemptGoogleSignIn(AuthService authService) async {
    try {
      // Intentar la autenticación con Google
      final result = await authService.signInWithGoogle();
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
        if (Navigator.of(context).canPop()) {
          try {
            Navigator.of(context).pop();
          } catch (navError) {
            print("Error al cerrar diálogo: $navError");
          }
        }
        
        // Cerrar sesión después del registro exitoso
        try {
          await authService.signOut();
          print("Sesión con Google cerrada después del registro exitoso");
        } catch (signOutError) {
          print("Error al cerrar sesión de Google: $signOutError");
          // Continuamos con el flujo aunque haya error al cerrar sesión
        }
        
        // Detener completamente la carga
        setState(() {
          _isLoading = false;
        });
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta de Google vinculada correctamente. Por favor inicia sesión.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        print("Navegando a la pantalla de login...");
        
        // Usar una navegación más simple y directa posible
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      }
    } catch (e) {
      print("Error en _attemptGoogleSignIn: $e");
      rethrow; // Re-lanzar para que sea manejado por el catch principal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black,
                ],
              ),
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