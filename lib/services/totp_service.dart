import 'dart:typed_data';
import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';

class TOTPService {
  static const int defaultPeriod = 30;
  static const int defaultDigits = 6;

  static String generateTOTP(String secret, {
    int period = defaultPeriod,
    int digits = defaultDigits,
  }) {
    // Decodificar la clave secreta base32
    final secretBytes = base32.decode(secret.toUpperCase());
    
    // Obtener el tiempo actual en segundos y dividir por el período
    final timeCounter = (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ period;
    
    // Convertir el contador a bytes
    final timeBytes = _int64ToBytes(timeCounter);
    
    // Calcular HMAC-SHA1
    final hmac = Hmac(sha1, secretBytes);
    final hash = hmac.convert(timeBytes).bytes;
    
    // Obtener el offset
    final offset = hash[hash.length - 1] & 0xf;
    
    // Generar el código OTP
    final binary = ((hash[offset] & 0x7f) << 24) |
                  ((hash[offset + 1] & 0xff) << 16) |
                  ((hash[offset + 2] & 0xff) << 8) |
                  (hash[offset + 3] & 0xff);
    
    final otp = binary % pow(10, digits);
    return otp.toString().padLeft(digits, '0');
  }

  static Uint8List _int64ToBytes(int value) {
    final buffer = Uint8List(8);
    for (var i = 7; i >= 0; i--) {
      buffer[i] = value & 0xff;
      value >>= 8;
    }
    return buffer;
  }

  static String generateSecretKey() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(20, (i) => random.nextInt(256))
    );
    return base32.encode(bytes);
  }
}
