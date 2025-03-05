import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'dart:typed_data';

class EncryptionService {
  late SecretKey _masterKey;
  final _algorithm = Xchacha20.poly1305Aead();
  static const _saltLength = 32;
  static const _nonceLength = 24;
  static const _iterations = 100000;

  Future<void> initializeWithPassword(String password) async {
    final salt = List<int>.filled(_saltLength, 0); // En producción, usar salt único
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: _iterations,
      bits: 256,
    );
    
    _masterKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  Future<List<int>> encrypt(List<int> data) async {
    final nonce = _algorithm.newNonce();
    final box = await _algorithm.encrypt(
      data,
      secretKey: _masterKey,
      nonce: nonce,
    );
    
    return Uint8List.fromList([
      ...nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  Future<List<int>> decrypt(List<int> encryptedData) async {
    if (encryptedData.length < _nonceLength) {
      throw EncryptionException('Datos cifrados inválidos');
    }

    final nonce = encryptedData.sublist(0, _nonceLength);
    final macLength = 16; // Longitud fija para Poly1305
    final cipherText = encryptedData.sublist(
      _nonceLength,
      encryptedData.length - macLength,
    );
    final mac = Mac(encryptedData.sublist(
      encryptedData.length - macLength,
    ));

    try {
      return await _algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: _masterKey,
      );
    } catch (e) {
      throw EncryptionException('Error al descifrar los datos');
    }
  }
}

class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);
  
  @override
  String toString() => message;
} 