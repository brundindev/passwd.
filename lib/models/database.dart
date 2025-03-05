import 'package:firebase_database/firebase_database.dart';
import '../services/encryption_service.dart';
import 'password_entry.dart';
import 'dart:convert';

class PasswordDatabase {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('passwords');
  final EncryptionService _encryptionService;

  PasswordDatabase(this._encryptionService);

  Future<void> addPassword(PasswordEntry password) async {
    final passwordMap = password.toMap();
    final jsonString = jsonEncode(passwordMap);
    final bytes = utf8.encode(jsonString);

    final encryptedPassword = await _encryptionService.encrypt(bytes);
    await _dbRef.push().set({
      'title': password.title,
      'username': password.username,
      'password': encryptedPassword,
    });
  }

  Future<List<PasswordEntry>> loadPasswords() async {
    final snapshot = await _dbRef.once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      List<PasswordEntry> passwords = [];
      for (var entry in data.entries) {
        final passwordData = entry.value;
        final decryptedPassword = utf8.decode(await _encryptionService.decrypt(passwordData['password']));
        passwords.add(PasswordEntry(
          id: entry.key,
          title: passwordData['title'],
          username: passwordData['username'],
          password: decryptedPassword,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ));
      }
      return passwords;
    }
    return [];
  }

  Future<void> deletePassword(String id) async {
    await _dbRef.child(id).remove();
  }
}
