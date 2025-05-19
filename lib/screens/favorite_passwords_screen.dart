import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/password.dart';
import '../services/password_service.dart';
import '../services/password_generator.dart';
import '../widgets/password_list_item.dart';

class FavoritePasswordsScreen extends StatelessWidget {
  const FavoritePasswordsScreen({super.key});

  String generateRandomPassword({int length = 12}) {
    return PasswordGenerator.generateRandomPassword(
      length: length,
      useUpperCase: true,
      useLowerCase: true,
      useNumbers: true,
      useSpecialChars: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordService = Provider.of<PasswordService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Contraseñas favoritas'),
      ),
      body: StreamBuilder<List<Password>>(
        stream: passwordService.getFavoritePasswords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final passwords = snapshot.data ?? [];

          if (passwords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 72, color: Colors.amber[300]),
                  SizedBox(height: 16),
                  Text(
                    'No tienes contraseñas favoritas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: passwords.length,
            itemBuilder: (context, index) {
              final password = passwords[index];
              return PasswordListItem(
                password: password,
                onToggleFavorite: () => _toggleFavorite(context, password),
                onDelete: () => _deletePassword(context, password),
                onView: () => _showPasswordDetails(context, password),
                onEdit: () => _editPassword(context, password),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleFavorite(BuildContext context, Password password) async {
    final passwordService = Provider.of<PasswordService>(context, listen: false);
    try {
      // Crear un nuevo objeto Password con el valor de favorito actualizado
      final bool newFavoriteStatus = !password.isFavorite;
      
      // Actualizar en Firebase
      await passwordService.toggleFavorite(password.id, newFavoriteStatus);
      
      // Mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(password.isFavorite 
            ? 'Eliminado de favoritos' 
            : 'Añadido a favoritos'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.amber[300],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      // Forzar una actualización de la UI después de un breve delay
      // para permitir que Firebase procese el cambio
      Future.delayed(Duration(milliseconds: 300), () {
        // Actualizar la UI - en lugar de setState, refrescamos la página
        if (context.mounted) {
          Navigator.of(context).pop(); // Cerrar el diálogo actual si está abierto
          // Navegar a la misma pantalla para forzar un refresh
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => FavoritePasswordsScreen())
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar favorito: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _deletePassword(BuildContext context, Password password) async {
    final passwordService = Provider.of<PasswordService>(context, listen: false);
    try {
      await passwordService.movePasswordToTrash(password.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contraseña movida a la papelera'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showPasswordDetails(BuildContext context, Password password) {
    bool showPassword = false;
    String domain = password.sitio.toLowerCase();
    
    // Extraer dominio para el icono
    if (domain.startsWith('http://')) {
      domain = domain.substring(7);
    } else if (domain.startsWith('https://')) {
      domain = domain.substring(8);
    }
    if (domain.startsWith('www.')) {
      domain = domain.substring(4);
    }
    int slashIndex = domain.indexOf('/');
    if (slashIndex != -1) {
      domain = domain.substring(0, slashIndex);
    }
    
    Widget content = StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      domain.isNotEmpty ? domain[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              _buildDetailItem(context, Icons.web, 'Sitio web', password.sitio),
              SizedBox(height: 12),
              _buildDetailItem(context, Icons.person, 'Usuario', password.usuario),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock, color: Colors.grey.shade700, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Contraseña',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            showPassword ? password.password : '••••••••••••',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: showPassword ? null : 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey.shade700,
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, color: Theme.of(context).primaryColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: password.password));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Contraseña copiada al portapapeles'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(context, Icons.calendar_today, 'Creada', _formatDate(password.fechaCreacion)),
                  ),
                  Expanded(
                    child: _buildDetailItem(context, Icons.update, 'Modificada', _formatDate(password.ultimaModificacion)),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Botón para cambiar estado de favorito
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(); // Cerrar el diálogo actual
                  _toggleFavorite(context, password); // Cambiar estado
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: password.isFavorite ? Colors.amber.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: password.isFavorite ? Colors.amber : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        password.isFavorite ? Icons.star : Icons.star_border,
                        color: password.isFavorite ? Colors.amber : Colors.grey.shade400,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        password.isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
                        style: TextStyle(
                          color: password.isFavorite ? Colors.amber.shade700 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );

    List<Widget> actions = [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text('Cerrar', style: TextStyle(fontSize: 16)),
      ),
      SizedBox(width: 8),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          _editPassword(context, password);
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('Editar', style: TextStyle(fontSize: 16)),
      ),
    ];

    _showModernModal(
      context,
      content,
      title: 'Detalles de la contraseña',
      actions: actions,
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade300, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _editPassword(BuildContext context, Password password) {
    // Variables para almacenar los datos del formulario
    String sitio = password.sitio;
    String usuario = password.usuario;
    String passwordText = password.password;
    bool isFavorite = password.isFavorite;
    final formKey = GlobalKey<FormState>();
    bool showPassword = false;
    
    Widget content = StatefulBuilder(
      builder: (context, setDialogState) {
        return Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: sitio,
                  style: TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Sitio web',
                    prefixIcon: Icon(Icons.web),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el nombre del sitio';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    sitio = value ?? '';
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  initialValue: usuario,
                  style: TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    // El usuario es opcional
                    return null;
                  },
                  onSaved: (value) {
                    usuario = value ?? '';
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: TextEditingController(text: passwordText),
                  style: TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey.shade700,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
                          tooltip: 'Generar contraseña segura',
                          onPressed: () {
                            final newPassword = generateRandomPassword();
                            setDialogState(() {
                              passwordText = newPassword;
                              showPassword = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  obscureText: !showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la contraseña';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    passwordText = value ?? '';
                  },
                  onChanged: (value) {
                    passwordText = value;
                  },
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: isFavorite,
                      onChanged: (value) {
                        setDialogState(() {
                          isFavorite = value ?? false;
                        });
                      },
                      activeColor: Colors.amber,
                      checkColor: Colors.white,
                    ),
                    Text(
                      'Marcar como favorito', 
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isFavorite ? FontWeight.bold : FontWeight.normal,
                        color: isFavorite ? Colors.amber : null,
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );

    List<Widget> actions = [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text('Cancelar', style: TextStyle(fontSize: 16)),
      ),
      SizedBox(width: 8),
      ElevatedButton(
        onPressed: () async {
          if (formKey.currentState!.validate()) {
            formKey.currentState!.save();
            
            // Mostrar indicador de carga
            _showLoadingDialog(context, 'Actualizando contraseña...');
            
            try {
              final passwordService = Provider.of<PasswordService>(context, listen: false);
              
              // Crear la contraseña actualizada
              final updatedPassword = password.copyWith(
                sitio: sitio,
                usuario: usuario,
                password: passwordText,
                isFavorite: isFavorite,
                ultimaModificacion: DateTime.now(),
              );
              
              // Actualizar la contraseña
              await passwordService.updatePassword(updatedPassword);
              
              // Cerrar el diálogo de carga y el formulario
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              
              // Mostrar mensaje de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Contraseña actualizada correctamente'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } catch (e) {
              // Cerrar el diálogo de carga
              Navigator.of(context).pop();
              
              // Mostrar error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al actualizar la contraseña: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('Guardar', style: TextStyle(fontSize: 16)),
      ),
    ];

    _showModernModal(
      context, 
      content, 
      title: 'Editar contraseña',
      actions: actions,
    );
  }

  void _showLoadingDialog(BuildContext context, String message) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(width: 24),
        Text(message, style: TextStyle(fontSize: 16)),
      ],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: content,
          ),
        );
      },
    );
  }

  void _showModernModal(BuildContext context, Widget content, {String title = '', List<Widget>? actions}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            ),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              backgroundColor: Color(0xFF212121),
              insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: content,
                    ),
                    if (actions != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 