import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import '../utils/snackbar_utils.dart';
import 'package:email_validator/email_validator.dart';
import 'dart:ui';
import 'dart:math';

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _isDarkMode = true; // Valor predeterminado es modo oscuro

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
    
    // Mostrar diálogo de carga
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
                  'Creando cuenta...',
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
    
    // Obtener valores de los controladores
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    // Configurar un timeout global para todo el proceso
    bool timeoutOccurred = false;
    Future.delayed(Duration(seconds: 10)).then((_) {
      if (_isLoading && mounted) {
        print("⚠️ TIMEOUT GLOBAL EN REGISTRO - Forzando finalización");
        timeoutOccurred = true;
        setState(() {
          _isLoading = false;
        });
        
        // Cerrar diálogo de carga
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        
        showSnackBar(context, 'El registro tardó demasiado tiempo, pero tu cuenta ha sido creada. Intenta iniciar sesión.');
        
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
      
      // Cerrar el diálogo de carga
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
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
      
      // Cerrar el diálogo de carga
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
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
        
        showSnackBar(context, errorMsg);
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
        // Cerrar diálogo de carga
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _isLoading = false;
        });
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
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Cerrar el diálogo de carga
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Mostrar mensaje de éxito
      showSnackBar(
        context,
        'Cuenta de Google vinculada correctamente. ¡Bienvenido a PASSWD!',
      );
      
      // Navegar a la pantalla principal
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } catch (e) {
      // Cerrar el diálogo de carga
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      setState(() {
        _isLoading = false;
        
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
        }
        
        _errorMessage = errorMessage;
      });
      
      showSnackBar(context, _errorMessage!);
    }
  }

  // Método para mostrar el diálogo de verificación de email
  void _showEmailVerificationDialog(String email, bool emailSent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
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
                    color: _isDarkMode ? Colors.white : Colors.black,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                )
              else
                Text(
                  'Se ha creado tu cuenta pero hubo un problema al enviar el correo de verificación a:',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              SizedBox(height: 8),
              Text(
                email,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: emailSent 
                    ? (_isDarkMode ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.1))
                    : (_isDarkMode ? Colors.orange.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: emailSent 
                      ? (_isDarkMode ? Colors.green.shade700 : Colors.green.shade300)
                      : (_isDarkMode ? Colors.orange.shade700 : Colors.orange.shade300)
                  ),
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
                              color: emailSent 
                                ? (_isDarkMode ? Colors.green.shade300 : Colors.green.shade800)
                                : (_isDarkMode ? Colors.orange.shade300 : Colors.orange.shade800),
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
                          color: _isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
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
                    
                    // Mostrar diálogo de carga
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
                                  'Reenviando correo...',
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
                    
                    // Iniciar sesión temporalmente
                    try {
                      final result = await authService.signInWithEmailAndPassword(
                        email,
                        _passwordController.text.trim(),
                      );
                      await result.user?.sendEmailVerification();
                      await authService.signOut();
                      
                      // Cerrar diálogo de carga
                      Navigator.of(context, rootNavigator: true).pop();
                      
                      showSnackBar(
                        context,
                        'Correo de verificación reenviado',
                      );
                    } catch (e) {
                      // Cerrar diálogo de carga
                      Navigator.of(context, rootNavigator: true).pop();
                      
                      print("Error al reenviar verificación: $e");
                      showSnackBar(
                        context,
                        'No se pudo reenviar el correo de verificación',
                      );
                    }
                  } catch (e) {
                    print("Error general al reenviar correo: $e");
                  }
                },
                child: Text(
                  'Reenviar correo',
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                ),
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
                backgroundColor: Colors.blue,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : (isConfirmPassword ? _obscureConfirmPassword : false),
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
        suffixIcon: isPassword || isConfirmPassword
            ? IconButton(
                icon: Icon(
                  (isPassword ? _obscurePassword : _obscureConfirmPassword) 
                    ? Icons.visibility_off 
                    : Icons.visibility,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    if (isPassword) {
                      _obscurePassword = !_obscurePassword;
                    } else {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }
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
                background: Colors.black,
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
                background: Colors.white,
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
                      child: Container(
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
                              'Crear cuenta',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            
                            SizedBox(height: 10),
                            
                            Text(
                              'Protege tus contraseñas con PASSWD',
                              style: TextStyle(
                                fontSize: 16,
                                color: _isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: 40),
                            
                            if (_errorMessage != null) 
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            if (_errorMessage != null) SizedBox(height: 20),
                            
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
                                      } else if (!EmailValidator.validate(val)) {
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
                                  
                                  SizedBox(height: 16),
                                  
                                  // Campo de confirmar contraseña
                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    labelText: 'Confirmar contraseña',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    isConfirmPassword: true,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Por favor, confirma tu contraseña';
                                      } else if (val != _passwordController.text) {
                                        return 'Las contraseñas no coinciden';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  SizedBox(height: 30),
                                  
                                  // Botón de registro
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      minimumSize: Size(double.infinity, 50),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                        : Text(
                                            'Crear cuenta',
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
                              onPressed: _isLoading ? null : () => _signInWithGoogle(),
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
                            
                            // Enlace para iniciar sesión
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '¿Ya tienes una cuenta? ',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(context, '/login');
                                  },
                                  child: Text(
                                    'Inicia sesión',
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