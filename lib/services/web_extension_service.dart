import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/password.dart';
import 'password_service.dart';

class WebExtensionService {
  static final WebExtensionService _instance = WebExtensionService._internal();
  factory WebExtensionService() => _instance;
  WebExtensionService._internal();

  final PasswordService _passwordService = PasswordService();
  HttpServer? _server;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  // Iniciar el servidor local
  Future<bool> startServer({int port = 8080}) async {
    try {
      if (_isRunning) {
        debugPrint('[WebExtension] El servidor ya está en ejecución');
        return true;
      }

      // Crear servidor HTTP
      debugPrint('[WebExtension] Intentando iniciar servidor en puerto $port...');
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;

      debugPrint('[WebExtension] ✅ Servidor iniciado en 0.0.0.0:$port');
      _printRoutesInfo(); // Imprimir información de rutas disponibles

      // Manejar solicitudes
      _server!.listen((HttpRequest request) async {
        // Limpiar y procesar la ruta para hacerla más uniforme
        final String rawPath = request.uri.path;
        final String normalizedPath = _normalizePath(rawPath);
        
        debugPrint('[WebExtension] 📥 Solicitud recibida: ${request.method} $rawPath (normalizada: $normalizedPath) desde ${request.connectionInfo?.remoteAddress.address}');
        
        try {
          // Configurar CORS para permitir solicitudes de la extensión - esto es crítico
          _configurarCORS(request);
  
          // Manejar solicitudes OPTIONS (preflight)
          if (request.method == 'OPTIONS') {
            _manejarSolicitudOPTIONS(request);
            return;
          }
  
          // === ENDPOINTS PRINCIPALES ===
          
          // Endpoint para verificar estado del servidor
          if (normalizedPath == '/status') {
            _manejarSolicitudStatus(request);
            return;
          }
          
          // Manejar solicitud de credenciales
          if (normalizedPath == '/get-credentials' && request.method == 'GET') {
            await _handleGetCredentials(request);
            return;
          } 
          
          // Endpoint para guardar credenciales - usar el mismo formato que otros endpoints
          if ((normalizedPath == '/guardar-credencial' || normalizedPath == '/guardar_credencial') && request.method == 'POST') {
            debugPrint('[WebExtension] 📝 Solicitud para guardar credenciales recibida');
            await _handleSaveCredentials(request);
            return;
          }
          
          // Si no coincide con ninguna ruta, imprimir detalle de lo recibido para debug
          debugPrint('[WebExtension] ❌ Endpoint no encontrado: "$rawPath" (normalizada: "$normalizedPath") (${request.method})');
          debugPrint('[WebExtension] URI completa: ${request.uri.toString()}');
          
          request.response.statusCode = HttpStatus.notFound;
          request.response.headers.contentType = ContentType.json;
          request.response.write(json.encode({
            'error': 'Endpoint no encontrado',
            'path': rawPath,
            'normalized_path': normalizedPath,
            'method': request.method
          }));
          await request.response.close();
        } catch (e) {
          debugPrint('[WebExtension] ❌ Error al procesar solicitud: $e');
          // Intentar enviar una respuesta de error 
          try {
            request.response.statusCode = HttpStatus.internalServerError;
            request.response.headers.contentType = ContentType.json;
            request.response.write(json.encode({
              'error': 'Error interno del servidor',
              'message': e.toString()
            }));
            await request.response.close();
          } catch (closeError) {
            // La respuesta probablemente ya fue cerrada o enviada
            debugPrint('[WebExtension] No se pudo enviar respuesta de error: $closeError');
          }
        }
      }, onError: (e) {
        debugPrint('[WebExtension] ❌ Error en el servidor: $e');
      });

      return true;
    } catch (e) {
      debugPrint('[WebExtension] ❌ Error al iniciar el servidor: $e');
      _isRunning = false;
      return false;
    }
  }

  // Detener el servidor
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      _isRunning = false;
      debugPrint('[WebExtension] Servidor detenido');
    }
  }

  // Configurar cabeceras CORS
  void _configurarCORS(HttpRequest request) {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization, X-Requested-With');
    request.response.headers.add('Access-Control-Max-Age', '86400'); // 24 horas
  }

  // Manejar solicitud OPTIONS
  void _manejarSolicitudOPTIONS(HttpRequest request) {
    debugPrint('[WebExtension] ✅ Respondiendo a solicitud OPTIONS (preflight)');
    request.response.statusCode = HttpStatus.ok;
    request.response.close();
  }

  // Manejar solicitud de estado
  void _manejarSolicitudStatus(HttpRequest request) {
    debugPrint('[WebExtension] ✅ Solicitud de estado');
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(json.encode({
      'status': 'ok',
      'message': 'Servidor del gestor de contraseñas en funcionamiento',
      'timestamp': DateTime.now().toIso8601String()
    }));
    request.response.close();
  }

  // Manejar solicitud de credenciales basado en la URL del sitio
  Future<void> _handleGetCredentials(HttpRequest request) async {
    try {
      // Obtener el parámetro 'sitio' de la URL
      final sitio = request.uri.queryParameters['sitio'];
      debugPrint('[WebExtension] 🔍 Buscando credenciales para sitio: $sitio');
      
      if (sitio == null || sitio.isEmpty) {
        debugPrint('[WebExtension] ❌ Parámetro sitio no proporcionado');
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'error': 'Parámetro sitio no proporcionado'
        }));
        await request.response.close();
        return;
      }

      if (sitio == 'test') {
        debugPrint('[WebExtension] ✅ Solicitud de prueba detectada, respondiendo con 404');
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'error': 'Esto es una solicitud de prueba',
          'credenciales': []
        }));
        await request.response.close();
        return;
      }

      // Obtener todas las contraseñas del usuario
      try {
        final passwords = await _passwordService.getPasswordsForSite(sitio);
        debugPrint('[WebExtension] 🔍 Encontradas ${passwords.length} credenciales para $sitio');
        
        // Si no se encuentran contraseñas para el sitio
        if (passwords.isEmpty) {
          debugPrint('[WebExtension] ❌ No se encontraron credenciales para $sitio');
          request.response.statusCode = HttpStatus.notFound;
          request.response.headers.contentType = ContentType.json;
          request.response.write(json.encode({
            'error': 'No se encontraron credenciales para $sitio',
            'credenciales': []
          }));
          await request.response.close();
          return;
        }

        // Devolver todas las credenciales en formato JSON
        final List<Map<String, dynamic>> credenciales = passwords.map((password) => {
          'id': password.id,
          'usuario': password.usuario,
          'password': password.password,
          'sitio': password.sitio,
          'fechaCreacion': password.fechaCreacion.toIso8601String(),
          'ultimaModificacion': password.ultimaModificacion.toIso8601String(),
        }).toList();
        
        debugPrint('[WebExtension] ✅ Enviando ${credenciales.length} credenciales para $sitio');
        
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'credenciales': credenciales,
          'total': credenciales.length
        }));
        
        await request.response.close();
      } catch (authError) {
        debugPrint('[WebExtension] ❌ Error de autenticación: $authError');
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'error': 'Usuario no autenticado. Inicie sesión en la aplicación PASSWD.'
        }));
        await request.response.close();
      }
    } catch (e) {
      debugPrint('[WebExtension] ❌ Error al manejar solicitud de credenciales: $e');
      // Intentar enviar una respuesta de error
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'error': 'Error interno del servidor: $e'
        }));
        await request.response.close();
      } catch (closeError) {
        // La respuesta probablemente ya fue cerrada o enviada
        debugPrint('[WebExtension] No se pudo enviar respuesta de error: $closeError');
      }
    }
  }

  // Añadir método para manejar la solicitud de guardar credenciales
  Future<void> _handleSaveCredentials(HttpRequest request) async {
    try {
      debugPrint('[WebExtension] 📥 Procesando solicitud para guardar nuevas credenciales');
      
      // Leer el cuerpo de la solicitud
      final String content = await utf8.decoder.bind(request).join();
      debugPrint('[WebExtension] 📄 Datos recibidos: $content');
      
      final Map<String, dynamic> data = json.decode(content);
      
      // Verificar que los datos estén completos
      if (data['sitio'] == null || data['usuario'] == null || data['password'] == null) {
        debugPrint('[WebExtension] ❌ Datos incompletos para guardar credencial');
        debugPrint('[WebExtension] 🔍 Campos recibidos: ${data.keys.join(', ')}');
        
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'success': false,
          'error': 'Datos incompletos. Se requiere sitio, usuario y password.',
          'campos_recibidos': data.keys.toList()
        }));
        await request.response.close();
        return;
      }
      
      // Crear objeto Password con los datos recibidos
      final password = Password(
        id: '0', // El ID debe ser un String, no un int
        usuario: data['usuario'],
        password: data['password'],
        sitio: data['sitio'],
        fechaCreacion: DateTime.now(),
        ultimaModificacion: DateTime.now(),
      );
      
      debugPrint('[WebExtension] 🔐 Credencial a guardar: Sitio=${password.sitio}, Usuario=${password.usuario}, Contraseña=********');
      
      // Guardar la contraseña en la base de datos
      try {
        // El método addPassword no devuelve un ID, es void
        await _passwordService.addPassword(password);
        
        debugPrint('[WebExtension] ✅ Credencial guardada con éxito');
        
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'success': true,
          'message': 'Credencial guardada con éxito',
          'sitio': password.sitio,
          'usuario': password.usuario
        }));
        await request.response.close();
      } catch (saveError) {
        debugPrint('[WebExtension] ❌ Error al guardar la credencial: $saveError');
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'success': false,
          'error': 'Error al guardar la credencial: $saveError'
        }));
        await request.response.close();
      }
    } catch (e) {
      debugPrint('[WebExtension] ❌ Error al procesar solicitud para guardar credencial: $e');
      
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode({
          'success': false,
          'error': 'Error interno del servidor: $e'
        }));
        await request.response.close();
      } catch (closeError) {
        debugPrint('[WebExtension] No se pudo enviar respuesta de error: $closeError');
      }
    }
  }

  void _printRoutesInfo() {
    debugPrint('\n[WebExtension] 📌 RUTAS DISPONIBLES EN EL SERVIDOR:');
    debugPrint('-----------------------------------------------------');
    debugPrint('✅ GET    /status               - Verificar estado del servidor');
    debugPrint('✅ GET    /get-credentials      - Obtener credenciales para un sitio');
    debugPrint('✅ POST   /guardar-credencial   - Guardar nuevas credenciales');
    debugPrint('✅ POST   /guardar_credencial   - Alias alternativo');
    debugPrint('');
    debugPrint('🔄 Todas las rutas anteriores también funcionan con prefijo /api');
    debugPrint('   Ejemplos: /api/status, /api/guardar-credencial, etc.');
    debugPrint('');
    debugPrint('🔍 Función de normalización de rutas implementada:');
    debugPrint('   - Se elimina el prefijo /api si existe');
    debugPrint('   - Se eliminan barras duplicadas y barras al final');
    debugPrint('   - Se acepta tanto guion como guion bajo para separar palabras');
    debugPrint('-----------------------------------------------------');
    debugPrint('[WebExtension] 🌐 Servidor escuchando en http://localhost:${_server?.port}\n');
  }

  // Método para normalizar la ruta
  String _normalizePath(String path) {
    String normalized = path;
    
    // Eliminar /api si está presente al principio
    if (normalized.startsWith('/api')) {
      normalized = normalized.substring(4);
    }
    
    // Asegurarse de que comience con /
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    
    // Eliminar barras duplicadas
    while (normalized.contains('//')) {
      normalized = normalized.replaceAll('//', '/');
    }
    
    // Eliminar barra al final si existe
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    
    return normalized;
  }
} 