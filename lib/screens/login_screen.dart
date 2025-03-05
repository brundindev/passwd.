import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  final bool _obscurePassword = true;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
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
                    'Iniciando sesión...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Verificando credenciales',
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

      try {
        print("Iniciando proceso de login con email...");
        final authService = Provider.of<AuthService>(context, listen: false);
        
        final result = await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        print("Login exitoso. UID: ${result.user?.uid}");
        
        // Esperar un poco para hacer visible la carga
        await Future.delayed(Duration(milliseconds: 800));
        
        if (mounted) {
          // Cerrar el diálogo de carga
          Navigator.of(context).pop();
          
          setState(() {
            _isLoading = false;
          });
          
          print("Navegando directamente a HomeScreen después del login...");
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        print("Error durante el login: $e");
        
        // Cerrar el diálogo de carga
        if (mounted) {
          Navigator.of(context).pop();
          
          setState(() {
            final authService = Provider.of<AuthService>(context, listen: false);
            _errorMessage = authService.handleAuthError(e);
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
                  'Iniciando sesión con Google...',
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
    
    try {
      print("Iniciando proceso de login con Google...");
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.signInWithGoogle().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'La autenticación con Google está tomando demasiado tiempo. '
            'Por favor, intenta iniciar sesión usando email y contraseña.'
          );
        },
      );
      
      print("Login con Google exitoso. UID: ${result.user?.uid}");
      
      // Esperar un poco para hacer visible la carga
      await Future.delayed(Duration(milliseconds: 800));
      
      if (mounted) {
        // Cerrar el diálogo de carga
        Navigator.of(context).pop();
        
        setState(() {
          _isLoading = false;
        });
        
        print("Navegando directamente a HomeScreen después del login con Google...");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print("Error durante el login con Google: $e");
      
      // Cerrar el diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        setState(() {
          _isLoading = false;
          
          if (e.toString().contains("popup has been closed by the user")) {
            _errorMessage = "Inicio de sesión con Google cancelado";
          } else if (e.toString().contains("popup") || 
                     e.toString().contains("browser") ||
                     e.toString().contains("ventana")) {
            _errorMessage = "No se pudo abrir la ventana de inicio de sesión de Google. " "Por favor, verifica si tienes un bloqueador de ventanas emergentes activo.";
          } else {
            final authService = Provider.of<AuthService>(context, listen: false);
            _errorMessage = authService.handleAuthError(e);
          }
        });
      }
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icono de la aplicación
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
                                child: const Icon(
                                  Icons.lock,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 24),
                              
                              // Título y subtítulo
                              Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Accede a tus contraseñas seguras',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 32),

                              // Mensaje de error
                              if (_errorMessage != null)
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_errorMessage != null) SizedBox(height: 16),

                              // Formulario de inicio de sesión
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icon(Icons.email, color: Colors.grey[800]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                style: TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: Icon(Icons.lock, color: Colors.grey[800]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword ? Icons.visibility_off : Icons.visibility,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu contraseña';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _signInWithEmailAndPassword(),
                              ),
                              SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Implementar recuperación de contraseña
                                  },
                                  child: Text(
                                    'Olvidé mi contraseña',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signInWithEmailAndPassword,
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
                                      : Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white30)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('O continuar con', style: TextStyle(color: Colors.white70)),
                                  ),
                                  Expanded(child: Divider(color: Colors.white30)),
                                ],
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  icon: Image.asset('assets/google_logo.png', height: 24),
                                  label: Text('Google', style: TextStyle(fontSize: 16, color: Colors.white)),
                                  onPressed: _isLoading 
                                    ? null 
                                    : () => _signInWithGoogle(),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '¿No tienes cuenta?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, '/register');
                                    },
                                    child: Text(
                                      'Regístrate',
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