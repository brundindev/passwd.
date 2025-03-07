import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/folder.dart';
import '../models/password.dart';

class FolderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener el ID del usuario actual
  String? get userId => _auth.currentUser?.uid;

  // Obtener referencia a la colección de carpetas del usuario
  CollectionReference<Map<String, dynamic>> get foldersCollection {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore.collection('usuarios').doc(userId).collection('folders');
  }

  // Obtener referencia a la colección de contraseñas del usuario
  CollectionReference<Map<String, dynamic>> get passwordsCollection {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore.collection('usuarios').doc(userId).collection('pass');
  }

  // Obtener todas las carpetas del usuario
  Stream<List<Folder>> getFolders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
      .collection('usuarios')
      .doc(user.uid)
      .collection('folders')
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => 
          Folder.fromMap(doc.id, doc.data())
        ).toList()
      );
  }

  // Añadir una nueva carpeta
  Future<String> addFolder(Folder folder) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    final docRef = await foldersCollection.add(folder.toMap());
    return docRef.id;
  }

  // Actualizar una carpeta existente
  Future<void> updateFolder(Folder folder) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    await foldersCollection.doc(folder.id).update(folder.toMap());
  }

  // Eliminar una carpeta
  Future<void> deleteFolder(String folderId) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    // Primero actualizamos todas las contraseñas que tienen esta carpeta
    final querySnapshot = await passwordsCollection
      .where('folderIds', arrayContains: folderId)
      .get();
      
    for (var doc in querySnapshot.docs) {
      List<dynamic> folderIds = List.from(doc.data()['folderIds'] ?? []);
      folderIds.remove(folderId);
      
      await doc.reference.update({
        'folderIds': folderIds
      });
    }
    
    // Finalmente eliminamos la carpeta
    await foldersCollection.doc(folderId).delete();
  }
  
  // Obtener contraseñas en una carpeta específica
  Stream<List<Password>> getPasswordsInFolder(String folderId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
      .collection('usuarios')
      .doc(user.uid)
      .collection('pass')
      .where('folderIds', arrayContains: folderId)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => 
          Password.fromMap(doc.id, doc.data())
        ).toList()
      );
  }
  
  // Añadir una contraseña a una carpeta
  Future<void> addPasswordToFolder(String passwordId, String folderId) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    // Obtenemos la contraseña actual
    final docSnapshot = await passwordsCollection.doc(passwordId).get();
    if (!docSnapshot.exists) {
      throw Exception('La contraseña no existe');
    }
    
    // Obtenemos la lista actual de carpetas
    List<dynamic> folderIds = List.from(docSnapshot.data()?['folderIds'] ?? []);
    
    // Evitamos duplicados
    if (!folderIds.contains(folderId)) {
      folderIds.add(folderId);
      
      // Actualizamos la contraseña
      await passwordsCollection.doc(passwordId).update({
        'folderIds': folderIds,
        'ultimaModificacion': DateTime.now()
      });
      
      // Actualizamos el contador de la carpeta (opcional)
      await foldersCollection.doc(folderId).update({
        'passwordCount': FieldValue.increment(1)
      });
    }
  }
  
  // Quitar una contraseña de una carpeta
  Future<void> removePasswordFromFolder(String passwordId, String folderId) async {
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    // Obtenemos la contraseña actual
    final docSnapshot = await passwordsCollection.doc(passwordId).get();
    if (!docSnapshot.exists) {
      throw Exception('La contraseña no existe');
    }
    
    // Obtenemos la lista actual de carpetas
    List<dynamic> folderIds = List.from(docSnapshot.data()?['folderIds'] ?? []);
    
    // Quitamos la carpeta si existe
    if (folderIds.contains(folderId)) {
      folderIds.remove(folderId);
      
      // Actualizamos la contraseña
      await passwordsCollection.doc(passwordId).update({
        'folderIds': folderIds,
        'ultimaModificacion': DateTime.now()
      });
      
      // Actualizamos el contador de la carpeta (opcional)
      await foldersCollection.doc(folderId).update({
        'passwordCount': FieldValue.increment(-1)
      });
    }
  }
} 