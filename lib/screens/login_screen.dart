import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/snackbar_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'dart:ui';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _isDarkMode = true; // Valor predeterminado es modo oscuro

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Theme(
      data: _isDarkMode
          ? ThemeData.dark().copyWith(
              textTheme: ThemeData.dark().textTheme.apply(
                    fontFamily: 'SF Pro',
                  ),
              colorScheme: ColorScheme.dark(
                primary: Colors.blue,
                secondary: Colors.blueAccent,
                surface: Colors.grey[900]!,
              ),
            )
          : ThemeData.light().copyWith(
              textTheme: ThemeData.light().textTheme.apply(
                    fontFamily: 'SF Pro',
                  ),
              colorScheme: ColorScheme.light(
                primary: Colors.blue,
                secondary: Colors.blueAccent,
                surface: Colors.grey[100]!,
              ),
            ),
      child: Scaffold(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        body: Stack(
          children: [
            // Fondo con GIF y transparencia
            Positioned.fill(
              child: Opacity(
                opacity: _isDarkMode ? 0.7 : 0.3,
                child: Image.asset(
                  'assets/background.gif',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Filtro de fondo con blur
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: (_isDarkMode ? Colors.black : Colors.white).withOpacity(0.3),
              ),
            ),
            
            // Patrón de puntos
            CustomPaint(
              painter: DotPatternPainter(
                color: _isDarkMode ? Colors.white : Colors.black,
                opacity: _isDarkMode ? 0.15 : 0.07,
              ),
              child: Container(),
            ),
            
            // Contenido
            SafeArea(
              child: Builder(
                builder: (context) {
                  return SingleChildScrollView(
                    child: Center(
                      child: SizedBox(
                        width: size.width > 600 ? 600 : size.width * 0.9,
                        height: size.height * 0.9,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Botón para volver
                                IconButton(
                                  icon: Icon(
                                    Icons.arrow_back_ios_rounded,
                                    color: _isDarkMode ? Colors.white : Colors.black,
                                    size: 20,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                
                                // Toggle para tema claro/oscuro
                                Row(
                                  children: [
                                    Icon(
                                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                      color: _isDarkMode ? Colors.white : Colors.black,
                                      size: 16,
                                    ),
                                    SizedBox(width: 5),
                                    Switch(
                                      value: _isDarkMode,
                                      onChanged: (value) {
                                        setState(() {
                                          _isDarkMode = value;
                                        });
                                      },
                                      activeColor: Colors.blueAccent,
                                      inactiveThumbColor: Colors.amber,
                                      activeTrackColor: Colors.blue.withOpacity(0.5),
                                      inactiveTrackColor: Colors.orange.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 20),
                            
                            // Título
                            Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            
                            SizedBox(height: 40),
                            
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Campo de correo electrónico
                                  _buildTextField(
                                    controller: _emailController,
                                    labelText: 'Correo electrónico',
                                    prefixIcon: Icons.email_outlined,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Por favor, ingresa tu correo electrónico';
                                      } else if (!_isValidEmail(val)) {
                                        return 'Ingresa un correo electrónico válido';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // Campo de contraseña
                                  _buildTextField(
                                    controller: _passwordController,
                                    labelText: 'Contraseña',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Por favor, ingresa tu contraseña';
                                      } else if (val.length < 6) {
                                        return 'La contraseña debe tener al menos 6 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  SizedBox(height: 20),
                                  
                                  // Enlace de olvidó contraseña
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        // Mostrar diálogo en lugar de navegar
                                        _showForgotPasswordDialog();
                                      },
                                      child: Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: 30),
                                  
                                  // Botón de iniciar sesión
                                  ElevatedButton(
                                    onPressed: () => _signIn(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      minimumSize: Size(double.infinity, 50),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: 30),
                            
                            // Divisor "O"
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: _isDarkMode 
                                        ? Colors.white.withOpacity(0.2) 
                                        : Colors.black.withOpacity(0.1),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'O',
                                    style: TextStyle(
                                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: _isDarkMode 
                                        ? Colors.white.withOpacity(0.2) 
                                        : Colors.black.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 30),
                            
                            // Botón de Google
                            OutlinedButton.icon(
                              onPressed: () => _signInWithGoogle(),
                              icon: Image.asset(
                                'assets/google_logo.png',
                                height: 24,
                              ),
                              label: Text(
                                'Continuar con Google',
                                style: TextStyle(
                                  fontSize: 16, 
                                  color: _isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _isDarkMode 
                                      ? Colors.white.withOpacity(0.3) 
                                      : Colors.black.withOpacity(0.2),
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                minimumSize: Size(double.infinity, 50),
                              ),
                            ),
                            
                            SizedBox(height: 30),
                            
                            // Enlace para registrarse
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '¿No tienes una cuenta? ',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/register');
                                  },
                                  child: Text(
                                    'Regístrate',
                                    style: TextStyle(
                                      color: Colors.blue,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      validator: validator,
      style: TextStyle(
        color: _isDarkMode ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: _isDarkMode ? Colors.white70 : Colors.black54,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: _isDarkMode ? Colors.white70 : Colors.black54,
          size: 20,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: _isDarkMode 
            ? Colors.white.withOpacity(0.1) 
            : Colors.black.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isDarkMode 
                ? Colors.white.withOpacity(0.2) 
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.withOpacity(0.8),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
  
  // Validación simple de email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _signIn(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Cerrar el diálogo de carga
        Navigator.of(context).pop();

        if (userCredential.user != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        // Cerrar el diálogo de carga
        Navigator.of(context).pop();
        
        String errorMessage = 'Error de autenticación';
        
        if (e.code == 'user-not-found') {
          errorMessage = 'No existe ningún usuario con este correo electrónico';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Contraseña incorrecta';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'El formato del correo electrónico no es válido';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'Este usuario ha sido deshabilitado';
        }
        
        showSnackBar(context, errorMessage);
    } catch (e) {
        // Cerrar el diálogo de carga
        Navigator.of(context).pop();
        showSnackBar(context, 'Error: ${e.toString()}');
      }
    }
  }

  // Método para mostrar el diálogo de recuperación de contraseña
  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            'Restablecer contraseña',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
          child: Form(
            key: formKey,
            child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                  Text(
                    'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      labelStyle: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: _isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _isDarkMode ? Colors.white24 : Colors.black26,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      filled: true,
                      fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    ),
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Ingresa un correo electrónico válido';
                    }
                    return null;
                  },
                ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
                          ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _resetPassword(emailController.text);
                }
              },
                            style: ElevatedButton.styleFrom(
                backgroundColor: _isDarkMode ? Colors.blueAccent : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Enviar'),
            ),
          ],
        );
      },
    );
  }
  
  // Método para enviar el correo de restablecimiento de contraseña
  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showSnackBar(
        context,
        'Hemos enviado un enlace a tu correo para restablecer tu contraseña.'
      );
    } catch (e) {
      showSnackBar(
        context,
        'Error al enviar el correo: ${e.toString()}'
      );
    }
  }

  // Método para iniciar sesión con Google
  Future<void> _signInWithGoogle() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                SizedBox(height: 20),
                Text(
                  'Conectando con Google...',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Iniciar el flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Si el usuario cancela el inicio de sesión
      if (googleUser == null) {
        Navigator.of(context).pop(); // Cerrar diálogo de carga
        return;
      }

      // Obtener detalles de autenticación de la solicitud
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crear una nueva credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión con Firebase usando la credencial
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Cerrar el diálogo de carga
      Navigator.of(context).pop();
      
      // Navegar a la pantalla principal
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // Cerrar el diálogo de carga
      Navigator.of(context).pop();
      
      String errorMessage = 'Error al iniciar sesión con Google';
      
      if (e is FirebaseAuthException) {
        if (e.code == 'account-exists-with-different-credential') {
          errorMessage = 'Ya existe una cuenta con este correo electrónico pero con diferente método de inicio de sesión';
        } else if (e.code == 'invalid-credential') {
          errorMessage = 'Error en las credenciales de acceso';
        } else if (e.code == 'operation-not-allowed') {
          errorMessage = 'El inicio de sesión con Google no está habilitado';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'Esta cuenta ha sido deshabilitada';
        } else if (e.code == 'user-not-found') {
          errorMessage = 'No se encontró ninguna cuenta con este correo electrónico';
        } else if (e.code == 'network-request-failed') {
          errorMessage = 'Error de conexión a internet. Verifica tu conexión e intenta de nuevo';
        }
      } else if (e is PlatformException) {
        if (e.code == 'network_error') {
          errorMessage = 'Error de conexión a internet. Verifica tu conexión e intenta de nuevo';
        }
      }
      
      showSnackBar(context, errorMessage);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class DotPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;
  
  DotPatternPainter({
    this.color = Colors.white,
    this.opacity = 0.15,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
      
    final spacing = 25.0; // Espacio entre puntos
    final dotSize = 1.0; // Tamaño de los puntos
    
    // Pequeña variación para que los puntos no estén perfectamente alineados
    final random = Random(42); // Semilla fija para consistencia
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Añadir una ligera variación a la posición
        final offsetX = random.nextDouble() * 5 - 2.5;
        final offsetY = random.nextDouble() * 5 - 2.5;
        
        // Variación en la opacidad para crear un efecto más interesante
        final variableOpacity = opacity * (0.5 + random.nextDouble() * 0.5);
        paint.color = color.withOpacity(variableOpacity);
        
        canvas.drawCircle(
          Offset(x + offsetX, y + offsetY), 
          dotSize * (0.8 + random.nextDouble() * 0.4), // Pequeña variación en el tamaño
          paint
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(DotPatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}