import 'dart:math';

class PasswordGenerator {
  // Caracteres para generar contraseñas
  static const String _lowercaseLetters = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _specialChars = '!@#\$%^&*()-_=+[]{}|;:,.<>?/';
  
  // Método para generar una contraseña aleatoria
  static String generateStrongPassword({int length = 12}) {
    final Random random = Random.secure();
    final StringBuffer password = StringBuffer();
    
    // Aseguramos que la contraseña tenga al menos un carácter de cada tipo
    password.write(_lowercaseLetters[random.nextInt(_lowercaseLetters.length)]);
    password.write(_uppercaseLetters[random.nextInt(_uppercaseLetters.length)]);
    password.write(_numbers[random.nextInt(_numbers.length)]);
    password.write(_specialChars[random.nextInt(_specialChars.length)]);
    
    // Todas las categorías de caracteres combinadas
    final String allChars = _lowercaseLetters + _uppercaseLetters + _numbers + _specialChars;
    
    // Agregar caracteres aleatorios hasta alcanzar la longitud deseada
    while (password.length < length) {
      password.write(allChars[random.nextInt(allChars.length)]);
    }
    
    // Convertir el buffer a string y mezclar los caracteres
    final List<String> passwordChars = password.toString().split('');
    passwordChars.shuffle(random);
    
    return passwordChars.join('');
  }
} 