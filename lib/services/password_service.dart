import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/password.dart';

class PasswordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener el ID del usuario actual
  String? get userId => _auth.currentUser?.uid;

  // Obtener referencia a la colección de contraseñas del usuario
  CollectionReference<Map<String, dynamic>> get passwordsCollection {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore.collection('usuarios').doc(userId).collection('pass');
  }

  // Obtener todas las contraseñas del usuario (excluyendo las que están en la papelera)
  Stream<List<Password>> getPasswords() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
      .collection('usuarios')
      .doc(user.uid)
      .collection('pass')
      .where('isInTrash', isEqualTo: false)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => 
          Password.fromMap(doc.id, doc.data())
        ).toList()
      );
  }
  
  // Nuevo método: Obtener contraseñas por sitio web
  Future<List<Password>> getPasswordsForSite(String sitio) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    // Comprobamos si el sitio es un dominio exacto o si necesitamos buscar coincidencias parciales
    final query = await passwordsCollection
      .where('isInTrash', isEqualTo: false)
      .get();
      
    final List<Password> passwords = query.docs
      .map((doc) => Password.fromMap(doc.id, doc.data()))
      .toList();
      
    // Filtramos para encontrar coincidencias con el sitio/dominio
    return passwords.where((password) {
      // Convertimos ambos a minúsculas para una comparación insensible a mayúsculas
      final passwordSitio = password.sitio.toLowerCase();
      final searchSitio = sitio.toLowerCase();
      
      // Primero buscamos coincidencia exacta
      if (passwordSitio == searchSitio) {
        return true;
      }
      
      // Luego buscamos si el sitio está contenido en la URL guardada o viceversa
      if (passwordSitio.contains(searchSitio) || searchSitio.contains(passwordSitio)) {
        return true;
      }
      
      // Finalmente, intentamos extraer el dominio base y comparar
      try {
        // Convertimos a URL si es posible
        Uri? passwordUri = Uri.tryParse(passwordSitio);
        Uri? searchUri = Uri.tryParse(searchSitio);
        
        if (passwordUri != null && searchUri != null) {
          // Comparamos los hosts (dominios)
          return passwordUri.host == searchUri.host;
        }
        
        // Si alguno no es una URL válida, comprobamos si uno contiene al otro
        if (passwordSitio.contains(searchSitio) || searchSitio.contains(passwordSitio)) {
          return true;
        }
      } catch (_) {
        // Si ocurre algún error, fallback a la comparación simple
        return passwordSitio.contains(searchSitio) || searchSitio.contains(passwordSitio);
      }
      
      return false;
    }).toList();
  }
  
  // Obtener las contraseñas favoritas del usuario
  Stream<List<Password>> getFavoritePasswords() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
      .collection('usuarios')
      .doc(user.uid)
      .collection('pass')
      .where('isFavorite', isEqualTo: true)
      .where('isInTrash', isEqualTo: false)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => 
          Password.fromMap(doc.id, doc.data())
        ).toList()
      );
  }
  
  // Obtener las contraseñas en la papelera del usuario
  Stream<List<Password>> getTrashPasswords() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
      .collection('usuarios')
      .doc(user.uid)
      .collection('pass')
      .where('isInTrash', isEqualTo: true)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => 
          Password.fromMap(doc.id, doc.data())
        ).toList()
      );
  }

  // Añadir una nueva contraseña
  Future<void> addPassword(Password password) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    // Nos aseguramos de que las nuevas contraseñas no estén en la papelera
    final passwordData = password.toMap();
    passwordData['isInTrash'] = false;
    
    await passwordsCollection.add(passwordData);
  }

  // Actualizar una contraseña existente
  Future<void> updatePassword(Password password) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    // Actualizar la fecha de modificación
    final passwordData = password.toMap();
    passwordData['ultimaModificacion'] = DateTime.now();
    
    await passwordsCollection.doc(password.id).update(passwordData);
  }
  
  // Marcar/desmarcar una contraseña como favorita
  Future<void> toggleFavorite(String passwordId, bool isFavorite) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    await passwordsCollection.doc(passwordId).update({
      'isFavorite': isFavorite,
      'ultimaModificacion': DateTime.now(),
    });
  }
  
  // Mover una contraseña a la papelera
  Future<void> movePasswordToTrash(String passwordId) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    await passwordsCollection.doc(passwordId).update({
      'isInTrash': true,
      'deletedAt': DateTime.now(),
      'ultimaModificacion': DateTime.now(),
    });
    
    // Programar eliminación automática después de 30 días
    _scheduleTrashCleanup();
  }
  
  // Restaurar una contraseña desde la papelera
  Future<void> restorePasswordFromTrash(String passwordId) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    await passwordsCollection.doc(passwordId).update({
      'isInTrash': false,
      'deletedAt': null,
      'ultimaModificacion': DateTime.now(),
    });
  }
  
  // Eliminar permanentemente una contraseña
  Future<void> deletePasswordPermanently(String passwordId) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    await passwordsCollection.doc(passwordId).delete();
  }
  
  // La función anterior de eliminar ahora mueve a la papelera
  Future<void> deletePassword(String passwordId) async {
    await movePasswordToTrash(passwordId);
  }
  
  // Programar limpieza de papelera
  Future<void> _scheduleTrashCleanup() async {
    // En una aplicación real, esto se haría con Cloud Functions
    // Aquí simplemente limpiaremos las contraseñas que tengan más de 30 días en la papelera
    if (userId == null) return;
    
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    
    try {
      final querySnapshot = await passwordsCollection
        .where('isInTrash', isEqualTo: true)
        .where('deletedAt', isLessThan: thirtyDaysAgo)
        .get();
        
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error al limpiar la papelera: $e');
    }
  }
  
  // Limpiar manualmente toda la papelera
  Future<void> emptyTrash() async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    final querySnapshot = await passwordsCollection
      .where('isInTrash', isEqualTo: true)
      .get();
      
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }
  
  // Forzar una actualización de las contraseñas desde la base de datos
  Future<void> refreshPasswords() async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    // Simular una carga para dar feedback visual al usuario
    await Future.delayed(Duration(milliseconds: 800));
    
    // En una implementación real, aquí podrías:
    // 1. Invalidar cualquier caché local de contraseñas
    // 2. Sincronizar con un servidor remoto si es necesario
    // 3. Realizar alguna lógica adicional de sincronización
    
    try {
      // Obtener las contraseñas actualizadas (forzar una nueva consulta)
      await passwordsCollection.get();
      print('Contraseñas actualizadas correctamente');
      return;
    } catch (e) {
      print('Error al actualizar contraseñas: $e');
      throw Exception('Error al sincronizar las contraseñas: $e');
    }
  }
}
