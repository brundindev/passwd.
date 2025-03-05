import 'dart:math';

class PasswordGenerator {
  static const String upperCaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String lowerCaseLetters = 'abcdefghijklmnopqrstuvwxyz';
  static const String numbers = '0123456789';
  static const String specialCharacters = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  
  static final List<String> dicewareWords = [
    // Aquí irían las palabras del diccionario Diceware
    // Por brevedad, solo incluyo algunas palabras de ejemplo
    'abajo', 'banco', 'casa', 'dato', 'edad',
    'fase', 'gato', 'hora', 'isla', 'jugo',
    // ... más palabras
  ];

  static String generateRandomPassword({
    int length = 16,
    bool useUpperCase = true,
    bool useLowerCase = true,
    bool useNumbers = true,
    bool useSpecialChars = true,
  }) {
    final random = Random.secure();
    final charSet = StringBuffer();
    final password = StringBuffer();

    if (useUpperCase) charSet.write(upperCaseLetters);
    if (useLowerCase) charSet.write(lowerCaseLetters);
    if (useNumbers) charSet.write(numbers);
    if (useSpecialChars) charSet.write(specialCharacters);

    if (charSet.isEmpty) {
      throw ArgumentError('Debe seleccionar al menos un conjunto de caracteres');
    }

    final chars = charSet.toString();
    for (var i = 0; i < length; i++) {
      password.write(chars[random.nextInt(chars.length)]);
    }

    return password.toString();
  }

  static String generateDicewarePassword({int wordCount = 4}) {
    final random = Random.secure();
    final words = <String>[];

    for (var i = 0; i < wordCount; i++) {
      words.add(dicewareWords[random.nextInt(dicewareWords.length)]);
    }

    return words.join('-');
  }

  static bool evaluatePasswordStrength(String password) {
    if (password.length < 8) return false;
    
    bool hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowerCase = password.contains(RegExp(r'[a-z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    
    return (hasUpperCase && hasLowerCase && hasNumbers && hasSpecialChars);
  }
}
