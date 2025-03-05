import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'app_settings_service.dart';
import '../services/auth_service.dart';

// Un mixin para detectar la inactividad del usuario
mixin InactivityDetectorMixin<T extends StatefulWidget> on State<T> {
  Timer? _inactivityTimer;
  bool _isLocked = false;
  bool _isChangingSettings = false; // Bandera para prevenir cierre durante cambios

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // Método para reiniciar el temporizador de inactividad
  void _resetInactivityTimer() {
    // Cancelar el temporizador existente si hay uno
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    
    final settings = Provider.of<AppSettingsService>(context, listen: false);
    
    // Si el bloqueo automático está desactivado, no hacemos nada más
    if (!settings.autoLock) return;
    
    // Registramos el tiempo de actividad
    settings.resetLastActiveTime();

    // Iniciar un nuevo temporizador que verifica la inactividad periódicamente
    _inactivityTimer = Timer.periodic(
      const Duration(seconds: 15), // Verificar cada 15 segundos
      (_) => _checkInactivity(),
    );
  }

  // Verifica si debemos bloquear la aplicación
  void _checkInactivity() {
    if (_isLocked) return; // Evitar duplicados
    if (_isChangingSettings) return; // No verificar durante cambios de configuración
    
    // Verificar si estamos en la pantalla de configuración
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != null && currentRoute.contains('settings')) {
      // Si estamos en la pantalla de configuración, solo actualizamos el tiempo
      resetUserActivity();
      return;
    }
    
    final settings = Provider.of<AppSettingsService>(context, listen: false);
    
    // Solo bloquear si el bloqueo automático está activado Y ha pasado el tiempo suficiente
    if (settings.autoLock && settings.shouldLockApp()) {
      _lockApp();
    }
  }

  // Método para bloquear la aplicación
  void _lockApp() {
    // Si estamos en la pantalla de configuración, no cerramos sesión
    // La ruta actual debe contener "settings" para la pantalla de configuración
    if (ModalRoute.of(context)?.settings.name?.contains('settings') ?? false) {
      resetUserActivity();
      return;
    }
    
    _isLocked = true;
    _inactivityTimer?.cancel();
    
    // Cerrar sesión
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut().then((_) {
      // Redirigir al usuario a la pantalla de inicio de sesión
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    });
  }

  // Método para detectar interacción del usuario
  void resetUserActivity() {
    if (_isLocked) return;
    
    final settings = Provider.of<AppSettingsService>(context, listen: false);
    
    // Solo actualizamos el tiempo de actividad, sin más acciones
    settings.resetLastActiveTime();
  }
  
  // Método específico para actualizar la configuración de bloqueo automático sin cerrar sesión
  void updateAutoLockSettings() {
    // Marcar que estamos cambiando configuraciones para prevenir verificaciones
    _isChangingSettings = true;
    
    // Asegurarnos de reiniciar correctamente el temporizador según la nueva configuración
    _resetInactivityTimer();
    
    // Desactivar la bandera después de un breve tiempo
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _isChangingSettings = false;
      }
    });
  }

  // Este método es EXCLUSIVAMENTE para cambiar la configuración de bloqueo automático
  // sin ninguna posibilidad de cierre de sesión
  void safeToggleAutoLock(bool newValue) {
    // Establecer la bandera de cambio de configuración para evitar verificaciones
    _isChangingSettings = true;
    
    // Obtener el servicio de configuración
    final settings = Provider.of<AppSettingsService>(context, listen: false);
    
    // Cambiar la configuración de forma segura
    settings.setValueWithoutNotifying('auto_lock', newValue);
    
    // Liberar todos los temporizadores actuales
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    
    // Actualizar el tiempo de actividad
    settings.resetLastActiveTime();
    
    // Reiniciar el temporizador si es necesario
    if (newValue) {
      // Esperar un momento antes de iniciar un nuevo temporizador
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _inactivityTimer = Timer.periodic(
            const Duration(seconds: 15),
            (_) => _checkInactivity(),
          );
        }
      });
    }
    
    // Programar para desactivar la bandera después
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _isChangingSettings = false;
      }
    });
  }

  // Este método es EXCLUSIVAMENTE para cambiar el retraso de bloqueo automático
  // sin ninguna posibilidad de cierre de sesión
  void safeSetAutoLockDelay(int newValue) {
    // Establecer la bandera de cambio de configuración para evitar verificaciones
    _isChangingSettings = true;
    
    // Obtener el servicio de configuración
    final settings = Provider.of<AppSettingsService>(context, listen: false);
    
    // Cambiar la configuración de forma segura
    settings.setValueWithoutNotifying('auto_lock_delay', newValue);
    
    // Actualizar el tiempo de actividad
    settings.resetLastActiveTime();
    
    // Cancelar el temporizador anterior
    _inactivityTimer?.cancel();
    
    // Iniciar un nuevo temporizador si el bloqueo automático está activado
    if (settings.autoLock) {
      _inactivityTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _checkInactivity(),
      );
    }
    
    // Programar para desactivar la bandera después
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _isChangingSettings = false;
      }
    });
  }
}

// Widget que envuelve a la aplicación para detectar la actividad del usuario
class ActivityDetector extends StatefulWidget {
  final Widget child;
  
  const ActivityDetector({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  _ActivityDetectorState createState() => _ActivityDetectorState();
}

class _ActivityDetectorState extends State<ActivityDetector> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettingsService>(context);
    
    // Si el bloqueo automático está desactivado, mostrar el hijo normalmente
    if (!settings.autoLock) {
      return widget.child;
    }
    
    // Detectar gestos del usuario
    return Listener(
      onPointerDown: (_) => _updateLastActivityTime(context),
      onPointerMove: (_) => _updateLastActivityTime(context),
      onPointerUp: (_) => _updateLastActivityTime(context),
      child: widget.child,
    );
  }
  
  void _updateLastActivityTime(BuildContext context) {
    // Actualizar el tiempo de actividad cuando se detecte actividad del usuario
    Provider.of<AppSettingsService>(context, listen: false).resetLastActiveTime();
  }
} 