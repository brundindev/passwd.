import 'package:flutter/foundation.dart';
import '../models/password_entry.dart';
import '../services/encryption_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

class PasswordProvider extends ChangeNotifier {
  final List<PasswordEntry> _passwords = [];
  final EncryptionService _encryptionService = EncryptionService();
  bool _isInitialized = false;

  List<PasswordEntry> get passwords => List.unmodifiable(_passwords);
  bool get isInitialized => _isInitialized;

  Future<void> initialize(String masterPassword) async {
    await _encryptionService.initializeWithPassword(masterPassword);
    await _loadPasswords();
    _isInitialized = true;
    notifyListeners();
  }

  Future<List<PasswordEntry>> loadPasswords() async {
    await _loadPasswords();
    return List.unmodifiable(_passwords);
  }

  Future<void> _loadPasswords() async {
    try {
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref('passwords');
      final snapshot = await dbRef.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        _passwords.clear();
        for (var entry in data.entries) {
          final passwordData = entry.value;
          _passwords.add(PasswordEntry(
            id: entry.key,
            title: passwordData['title'],
            username: passwordData['username'],
            password: utf8.decode(await _encryptionService.decrypt(passwordData['password'])),
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading passwords: $e');
    }
  }

  Future<void> addPassword(PasswordEntry password) async {
    final passwordMap = password.toMap();
    final jsonString = jsonEncode(passwordMap);
    final bytes = utf8.encode(jsonString);

    final encryptedPassword = await _encryptionService.encrypt(bytes);
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('passwords');
    await dbRef.push().set({
      'title': password.title,
      'username': password.username,
      'password': encryptedPassword,
    });
    _passwords.add(password);
    notifyListeners();
  }

  Future<void> updatePassword(String id, PasswordEntry newPassword) async {
    final index = _passwords.indexWhere((p) => p.id == id);
    if (index != -1) {
      _passwords[index] = newPassword;
      await addPassword(newPassword); // Guardar en Firebase
      notifyListeners();
    }
  }

  Future<void> deletePassword(String id) async {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('passwords');
    await dbRef.child(id).remove();
    _passwords.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
