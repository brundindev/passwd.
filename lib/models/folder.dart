class Folder {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime lastModified;
  final String color; // Color representado como código hexadecimal (ej: "#1E88E5")
  final int passwordCount; // Contador de contraseñas en la carpeta

  Folder({
    this.id = '',
    required this.name,
    this.description = '',
    DateTime? createdAt,
    DateTime? lastModified,
    this.color = '#1E88E5', // Azul por defecto
    this.passwordCount = 0,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastModified = lastModified ?? DateTime.now();

  factory Folder.fromMap(String id, Map<String, dynamic> data) {
    return Folder(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastModified: data['lastModified']?.toDate() ?? DateTime.now(),
      color: data['color'] ?? '#1E88E5',
      passwordCount: data['passwordCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdAt': createdAt,
      'lastModified': lastModified,
      'color': color,
      'passwordCount': passwordCount,
    };
  }
  
  // Crear una copia de la carpeta con propiedades actualizadas
  Folder copyWith({
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? lastModified,
    String? color,
    int? passwordCount,
  }) {
    return Folder(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      color: color ?? this.color,
      passwordCount: passwordCount ?? this.passwordCount,
    );
  }
} 