import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo animado con gradiente en estilo Apple
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      // Tonos más refinados inspirados en macOS/iOS
                      Color(0xFF2C2C2E),       // Gris oscuro
                      Color(0xFF1C1C1E),       // Casi negro
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Efecto de luz dinámica al estilo Apple
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              // Calcular posición de la "luz" que se mueve suavemente
              final lightPosX = 0.5 + 0.5 * sin(_animationController.value * pi * 0.7);
              final lightPosY = 0.4 + 0.4 * cos(_animationController.value * pi * 0.5);
              
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      -1.0 + lightPosX * 2.0, 
                      -1.0 + lightPosY * 2.0
                    ),
                    radius: 1.8,
                    colors: [
                      Color(0xFF0A84FF).withOpacity(0.4),  // Azul iOS
                      Color(0xFF5E5CE6).withOpacity(0.1),  // Violeta iOS
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              );
            },
          ),
          
          // Efecto de desenfoque suave
          BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 5.0,
              sigmaY: 5.0,
            ),
            child: Container(
              color: Colors.transparent,
            ),
          ),
          
          // Elementos gráficos minimalistas
          CustomPaint(
            painter: AppleBackgroundPainter(animation: _animationController),
            size: Size.infinite,
          ),
          
          // Contenido principal
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    
                    // Logo con efecto de profundidad
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/logo_passwd.JPEG',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Título con efecto de gradiente
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: const Text(
                        "PASSWD.",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Subtítulo con estilo
                    Text(
                      "Tu gestor de contraseñas seguro",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.3,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Botón de inicio de sesión estilo iOS/macOS
                    _buildAppleButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      label: "Iniciar Sesión",
                      isPrimary: true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Botón de registro estilo iOS/macOS
                    _buildAppleButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      label: "Registrarse",
                      isPrimary: false,
                    ),
                    
                    const Spacer(),
                    
                    // Versión de la aplicación con estilo
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "v1.0.2-a",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget para botones estilo Apple
  Widget _buildAppleButton({
    required VoidCallback onPressed,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: Color(0xFF0A84FF).withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Color(0xFF0A84FF) : Colors.transparent,
          foregroundColor: Colors.white,
          elevation: isPrimary ? 0 : 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: isPrimary ? Colors.transparent : Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
          ),
        ),
        child: Container(
          width: double.infinity,
          height: 60,
          alignment: Alignment.center,
          decoration: isPrimary
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.white : Colors.white.withOpacity(0.9),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// Pintor personalizado para crear efectos visuales elegantes estilo Apple
class AppleBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  
  AppleBackgroundPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar líneas suaves y elegantes
    _drawElegantLines(canvas, size);
    
    // Dibujar puntos sutiles
    _drawSubtleParticles(canvas, size);
  }
  
  void _drawElegantLines(Canvas canvas, Size size) {
    final lineCount = 5;
    
    for (int i = 0; i < lineCount; i++) {
      // Cada línea tiene una posición y fase diferente
      final verticalOffset = size.height * (0.1 + 0.8 * i / (lineCount - 1));
      final horizontalPhase = 0.2 * i;
      
      final path = Path();
      
      // Crear curvas elegantes
      path.moveTo(0, verticalOffset);
      
      final controlPoints = 8;
      final width = size.width;
      
      // Mantener el último punto procesado
      double lastY = verticalOffset;
      
      for (int j = 0; j <= controlPoints; j++) {
        final x = width * j / controlPoints;
        
        // Calcular altura con animación
        final waveHeight = size.height * 0.03 * (1 + i % 3);
        final normalizedAnimValue = 
            (animation.value + horizontalPhase) % 1.0;
            
        final y = verticalOffset + 
            sin((j / controlPoints + normalizedAnimValue) * pi * 2) * waveHeight;
        
        if (j == 0) {
          path.moveTo(x, y);
          lastY = y;
        } else {
          // Usar curva cuadrática para suavizar
          final prevX = width * (j - 1) / controlPoints;
          final controlX = (prevX + x) / 2;
          
          path.quadraticBezierTo(controlX, lastY, x, y);
          lastY = y;
        }
      }
      
      // Configurar el estilo de la línea
      final opacity = 0.15 - (0.03 * i);
      final lineWidth = 1.0 + (i * 0.5);
      
      final paint = Paint()
        ..color = Color(0xFF0A84FF).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 2.0);
      
      canvas.drawPath(path, paint);
    }
  }
  
  void _drawSubtleParticles(Canvas canvas, Size size) {
    final random = Random(42);
    final particleCount = 50;
    
    for (int i = 0; i < particleCount; i++) {
      // Posición base de cada partícula
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      
      // Pequeña variación en posición basada en la animación
      final offsetX = sin(animation.value * pi * 2 + i) * 3.0;
      final offsetY = cos(animation.value * pi * 2 + i * 1.3) * 3.0;
      
      final x = baseX + offsetX;
      final y = baseY + offsetY;
      
      // Calcular tamaño y opacidad
      final radius = 1.0 + random.nextDouble() * 1.5;
      final opacity = 0.05 + random.nextDouble() * 0.05;
      
      // Calcular color basado en posición (más azul en parte superior, más violeta en inferior)
      final normalizedY = y / size.height;
      final colorBlend = normalizedY.clamp(0.0, 1.0);
      
      final color = Color.lerp(
        Color(0xFF0A84FF), // Azul iOS en la parte superior
        Color(0xFF5E5CE6), // Violeta iOS en la parte inferior
        colorBlend,
      )!.withOpacity(opacity);
      
      // Dibujar la partícula
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}