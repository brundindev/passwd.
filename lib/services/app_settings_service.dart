import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService extends ChangeNotifier {
  static const String _keyUseBiometrics = 'use_biometrics';
  static const String _keyAutoLock = 'auto_lock';
  static const String _keyAutoLockDelay = 'auto_lock_delay';
  static const String _keyShowTOTPCodes = 'show_totp_codes';
  
  late SharedPreferences _prefs;
  bool _initialized = false;
  
  // Valores por defecto
  bool _useBiometrics = true;
  bool _autoLock = true;
  int _autoLockDelay = 5;
  bool _showTOTPCodes = true;
  DateTime? _lastActiveTime;
  
  bool get isInitialized => _initialized;
  bool get useBiometrics => _useBiometrics;
  bool get autoLock => _autoLock;
  int get autoLockDelay => _autoLockDelay;
  bool get showTOTPCodes => _showTOTPCodes;
  DateTime? get lastActiveTime => _lastActiveTime;
  
  // Método para inicializar el servicio
  Future<void> initialize() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    
    // Cargar valores guardados
    _useBiometrics = _prefs.getBool(_keyUseBiometrics) ?? true;
    _autoLock = _prefs.getBool(_keyAutoLock) ?? true;
    _autoLockDelay = _prefs.getInt(_keyAutoLockDelay) ?? 5;
    _showTOTPCodes = _prefs.getBool(_keyShowTOTPCodes) ?? true;
    
    // Establecer tiempo de actividad inicial
    resetLastActiveTime();
    
    _initialized = true;
    notifyListeners();
  }
  
  // Actualizar tiempo de actividad
  void resetLastActiveTime() {
    _lastActiveTime = DateTime.now();
  }
  
  // Comprobar si debemos bloquear la aplicación
  bool shouldLockApp() {
    if (!_autoLock || _lastActiveTime == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(_lastActiveTime!);
    return difference.inMinutes >= _autoLockDelay;
  }
  
  // Setters que guardan los valores
  
  Future<void> setUseBiometrics(bool value) async {
    _useBiometrics = value;
    await _prefs.setBool(_keyUseBiometrics, value);
    notifyListeners();
  }
  
  Future<void> setAutoLock(bool value) async {
    // Actualizar el tiempo de actividad antes de cambiar la configuración
    resetLastActiveTime();
    
    // Si estamos desactivando, reseteamos primero para estar seguros
    if (!value) {
      _autoLock = value;
      await _prefs.setBool(_keyAutoLock, value);
      notifyListeners();
    } else {
      // Si estamos activando, actualizamos y luego notificamos
      _autoLock = value;
      await _prefs.setBool(_keyAutoLock, value);
      
      // Resetear de nuevo para estar seguros
      resetLastActiveTime();
      notifyListeners();
    }
  }
  
  Future<void> setAutoLockDelay(int value) async {
    _autoLockDelay = value;
    await _prefs.setInt(_keyAutoLockDelay, value);
    resetLastActiveTime();
    notifyListeners();
  }
  
  Future<void> setShowTOTPCodes(bool value) async {
    _showTOTPCodes = value;
    await _prefs.setBool(_keyShowTOTPCodes, value);
    notifyListeners();
  }
  
  // Método seguro para cambiar valores sin notificar a los listeners y evitar cierres de sesión
  Future<void> setValueWithoutNotifying(String key, dynamic value) async {
    // Según la clave, establecemos el valor correspondiente
    switch (key) {
      case 'auto_lock':
        _autoLock = value as bool;
        await _prefs.setBool(_keyAutoLock, value);
        break;
      case 'auto_lock_delay':
        _autoLockDelay = value as int;
        await _prefs.setInt(_keyAutoLockDelay, value);
        break;
      case 'use_biometrics':
        _useBiometrics = value as bool;
        await _prefs.setBool(_keyUseBiometrics, value);
        break;
      case 'show_totp_codes':
        _showTOTPCodes = value as bool;
        await _prefs.setBool(_keyShowTOTPCodes, value);
        break;
    }
    
    // Resetear el tiempo de actividad
    resetLastActiveTime();
    
    // No llamamos a notifyListeners() para evitar reconstrucciones que puedan
    // desencadenar el cierre de sesión
  }
} 