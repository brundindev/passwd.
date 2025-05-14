import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/password.dart';

class PasswordListItem extends StatefulWidget {
  final Password password;
  final Function()? onToggleFavorite;
  final Function()? onDelete;
  final Function()? onView;
  final Function()? onEdit;
  final Function()? onRestore;
  final Function()? onAddToFolder;
  final bool isInTrash;

  const PasswordListItem({
    super.key,
    required this.password,
    this.onToggleFavorite,
    this.onDelete,
    this.onView,
    this.onEdit,
    this.onRestore,
    this.onAddToFolder,
    this.isInTrash = false,
  });

  @override
  State<PasswordListItem> createState() => _PasswordListItemState();
}

class _PasswordListItemState extends State<PasswordListItem> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    String domain = _extractDomain(widget.password.sitio);

    return Slidable(
      key: Key(widget.password.id),
      startActionPane: widget.isInTrash ? null : ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (widget.onEdit != null)
            SlidableAction(
              onPressed: (_) => widget.onEdit!(),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Editar',
            ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (widget.isInTrash && widget.onRestore != null)
            SlidableAction(
              onPressed: (_) => widget.onRestore!(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.restore,
              label: 'Restaurar',
            ),
          SlidableAction(
            onPressed: (_) => widget.onDelete != null ? widget.onDelete!() : null,
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: widget.isInTrash ? Icons.delete_forever : Icons.delete,
            label: widget.isInTrash ? 'Eliminar' : 'Papelera',
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: Color(0xFF1E1E1E).withOpacity(0.3),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _buildWebsiteIcon(domain),
                title: Text(
                  widget.password.sitio,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  widget.password.usuario,
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.isInTrash && widget.onToggleFavorite != null)
                      IconButton(
                        icon: Icon(
                          widget.password.isFavorite ? Icons.star : Icons.star_border,
                          color: widget.password.isFavorite ? Colors.amber : null,
                        ),
                        onPressed: widget.onToggleFavorite,
                        tooltip: 'Favorito',
                      ),
                    if (!widget.isInTrash && widget.onAddToFolder != null)
                      IconButton(
                        icon: Icon(Icons.folder_open, color: Colors.orange),
                        onPressed: widget.onAddToFolder,
                        tooltip: 'Añadir a carpeta',
                      ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.blue),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.password.password));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Contraseña copiada al portapapeles'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      tooltip: 'Copiar contraseña',
                    ),
                    if (widget.isInTrash && widget.onRestore != null)
                      IconButton(
                        icon: Icon(
                          Icons.restore,
                          color: Colors.green,
                        ),
                        onPressed: widget.onRestore,
                        tooltip: 'Restaurar contraseña',
                      ),
                    IconButton(
                      icon: Icon(
                        widget.isInTrash ? Icons.delete_forever : Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: widget.onDelete,
                      tooltip: widget.isInTrash ? 'Eliminar permanentemente' : 'Mover a papelera',
                    ),
                  ],
                ),
                onTap: widget.onView,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 52.0, top: 0, right: 16.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Contraseña: ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      _showPassword ? widget.password.password : '••••••••••••',
                      style: TextStyle(
                        fontFamily: _showPassword ? null : 'monospace',
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                      tooltip: _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              if (widget.isInTrash && widget.password.deletedAt != null)
                Padding(
                  padding: const EdgeInsets.only(left: 72.0, bottom: 8.0),
                  child: Text(
                    'Se eliminará automáticamente en ${_getRemainingDays(widget.password.deletedAt!)} días',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRemainingDays(DateTime deletedAt) {
    final deletionDate = deletedAt.add(Duration(days: 30));
    final now = DateTime.now();
    final remaining = deletionDate.difference(now).inDays;
    return remaining.toString();
  }

  // Método para extraer el dominio de una URL
  String _extractDomain(String url) {
    if (url.isEmpty) return '';
    
    String domain = url.toLowerCase();
    
    // Eliminar protocolo
    if (domain.startsWith('http://')) {
      domain = domain.substring(7);
    } else if (domain.startsWith('https://')) {
      domain = domain.substring(8);
    }
    
    // Eliminar www.
    if (domain.startsWith('www.')) {
      domain = domain.substring(4);
    }
    
    // Eliminar rutas y parámetros
    int slashIndex = domain.indexOf('/');
    if (slashIndex != -1) {
      domain = domain.substring(0, slashIndex);
    }
    
    return domain;
  }

  // Método para construir el icono del sitio web
  Widget _buildWebsiteIcon(String domain) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getColorForDomain(domain),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          domain.isNotEmpty ? domain[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // Método para obtener un color basado en el dominio
  Color _getColorForDomain(String domain) {
    if (domain.isEmpty) return Colors.grey;
    
    // Colores para sitios populares
    Map<String, Color> knownDomains = {
      'google.com': Colors.blue,
      'facebook.com': Color(0xFF1877F2),
      'twitter.com': Color(0xFF1DA1F2),
      'instagram.com': Colors.purple,
      'amazon.com': Color(0xFFFF9900),
      'apple.com': Colors.black,
      'microsoft.com': Color(0xFF00A4EF),
      'netflix.com': Color(0xFFE50914),
      'github.com': Colors.black,
    };
    
    for (var knownDomain in knownDomains.keys) {
      if (domain.contains(knownDomain)) {
        return knownDomains[knownDomain]!;
      }
    }
    
    // Color basado en hash para otros dominios
    int hash = domain.hashCode;
    return Color((hash & 0x00FFFFFF) | 0xFF000000);
  }
}

class TOTPWidget extends StatefulWidget {
  final String secret;

  const TOTPWidget({
    super.key,
    required this.secret,
  });

  @override
  State<TOTPWidget> createState() => _TOTPWidgetState();
}

class _TOTPWidgetState extends State<TOTPWidget> {
  String? _currentCode;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // No actualizar el código - deshabilitado
    _currentCode = "------";
    // Mantener el timer para evitar errores pero no actualizar el código
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {});
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateCode() {
    // Método deshabilitado
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      cursor: SystemMouseCursors.forbidden,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade200.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 12,
              color: Colors.grey,
            ),
            SizedBox(width: 4),
            Text(
              '- TOTP deshabilitado -',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
