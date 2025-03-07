class Password {
  final String id;
  final String sitio;
  final String usuario;
  final String password;
  final DateTime fechaCreacion;
  final DateTime ultimaModificacion;
  final bool isFavorite;
  final bool isInTrash;
  final DateTime? deletedAt;
  final List<String> folderIds; // Lista de IDs de carpetas

  Password({
    this.id = '',
    required this.sitio,
    required this.usuario,
    required this.password,
    DateTime? fechaCreacion,
    DateTime? ultimaModificacion,
    this.isFavorite = false,
    this.isInTrash = false,
    this.deletedAt,
    this.folderIds = const [], // Por defecto, lista vacía
  }) : 
    fechaCreacion = fechaCreacion ?? DateTime.now(),
    ultimaModificacion = ultimaModificacion ?? DateTime.now();

  factory Password.fromMap(String id, Map<String, dynamic> data) {
    // Convertir el campo folderIds a List<String>
    List<String> folderIds = [];
    if (data['folderIds'] != null) {
      if (data['folderIds'] is List) {
        folderIds = List<String>.from(data['folderIds']);
      }
    }

    return Password(
      id: id,
      sitio: data['sitio'] ?? '',
      usuario: data['usuario'] ?? '',
      password: data['password'] ?? '',
      fechaCreacion: data['fechaCreacion']?.toDate() ?? DateTime.now(),
      ultimaModificacion: data['ultimaModificacion']?.toDate() ?? DateTime.now(),
      isFavorite: data['isFavorite'] ?? false,
      isInTrash: data['isInTrash'] ?? false,
      deletedAt: data['deletedAt']?.toDate(),
      folderIds: folderIds,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'sitio': sitio,
      'usuario': usuario,
      'password': password,
      'fechaCreacion': fechaCreacion,
      'ultimaModificacion': ultimaModificacion,
      'isFavorite': isFavorite,
      'isInTrash': isInTrash,
      'folderIds': folderIds, // Añadir folderIds al mapa
    };
    
    if (deletedAt != null) {
      map['deletedAt'] = deletedAt;
    }
    
    return map;
  }
  
  // Crear una copia de la contraseña con propiedades actualizadas
  Password copyWith({
    String? sitio,
    String? usuario,
    String? password,
    DateTime? fechaCreacion,
    DateTime? ultimaModificacion,
    bool? isFavorite,
    bool? isInTrash,
    DateTime? deletedAt,
    List<String>? folderIds,
  }) {
    return Password(
      id: id,
      sitio: sitio ?? this.sitio,
      usuario: usuario ?? this.usuario,
      password: password ?? this.password,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      ultimaModificacion: ultimaModificacion ?? this.ultimaModificacion,
      isFavorite: isFavorite ?? this.isFavorite,
      isInTrash: isInTrash ?? this.isInTrash,
      deletedAt: deletedAt ?? this.deletedAt,
      folderIds: folderIds ?? this.folderIds,
    );
  }
  
  // Método para añadir la contraseña a una carpeta
  Password addToFolder(String folderId) {
    if (folderIds.contains(folderId)) return this;
    
    List<String> updatedFolderIds = List.from(folderIds);
    updatedFolderIds.add(folderId);
    
    return copyWith(
      folderIds: updatedFolderIds,
      ultimaModificacion: DateTime.now(),
    );
  }
  
  // Método para quitar la contraseña de una carpeta
  Password removeFromFolder(String folderId) {
    if (!folderIds.contains(folderId)) return this;
    
    List<String> updatedFolderIds = List.from(folderIds);
    updatedFolderIds.remove(folderId);
    
    return copyWith(
      folderIds: updatedFolderIds,
      ultimaModificacion: DateTime.now(),
    );
  }
} 