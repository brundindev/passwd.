import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/password.dart';
import '../services/password_service.dart';
import '../widgets/password_list_item.dart';

class TrashPasswordsScreen extends StatelessWidget {
  const TrashPasswordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final passwordService = Provider.of<PasswordService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Papelera'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Vaciar papelera',
            onPressed: () {
              _showEmptyTrashDialog(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Password>>(
        stream: passwordService.getTrashPasswords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar la papelera: ${snapshot.error}'),
            );
          }
          
          final passwords = snapshot.data ?? [];
          
          if (passwords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'La papelera está vacía',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Las contraseñas en la papelera se eliminarán automáticamente después de 30 días.',
                  style: TextStyle(
                    color: Colors.red[300],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: passwords.length,
                  itemBuilder: (context, index) {
                    final password = passwords[index];
                    return PasswordListItem(
                      password: password,
                      onToggleFavorite: () {},
                      onDelete: () => _deletePasswordPermanently(context, password),
                      onRestore: () => _restorePassword(context, password),
                      isInTrash: true,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showEmptyTrashDialog(BuildContext context) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_sweep,
            size: 40,
            color: Colors.red,
          ),
        ),
        SizedBox(height: 24),
        Text(
          '¿Estás seguro de que quieres eliminar permanentemente todas las contraseñas de la papelera?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Esta acción no se puede deshacer.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    List<Widget> actions = [
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text('Cancelar', style: TextStyle(fontSize: 16)),
      ),
      SizedBox(width: 8),
      ElevatedButton(
        onPressed: () async {
          Navigator.pop(context);
          await _emptyTrash(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('Vaciar papelera', style: TextStyle(fontSize: 16)),
      ),
    ];

    _showModernModal(
      context,
      content,
      title: 'Vaciar papelera',
      actions: actions,
    );
  }
  
  Future<void> _emptyTrash(BuildContext context) async {
    try {
      final passwordService = Provider.of<PasswordService>(context, listen: false);
      await passwordService.emptyTrash();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Papelera vaciada'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al vaciar la papelera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _deletePasswordPermanently(BuildContext context, Password password) async {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_forever,
            size: 40,
            color: Colors.red,
          ),
        ),
        SizedBox(height: 24),
        Text(
          '¿Estás seguro de que quieres eliminar esta contraseña permanentemente?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Esta acción no se puede deshacer.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    List<Widget> actions = [
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text('Cancelar', style: TextStyle(fontSize: 16)),
      ),
      SizedBox(width: 8),
      ElevatedButton(
        onPressed: () async {
          Navigator.pop(context);
          try {
            final passwordService = Provider.of<PasswordService>(context, listen: false);
            await passwordService.deletePasswordPermanently(password.id);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Contraseña eliminada permanentemente'),
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
                content: Text('Error al eliminar la contraseña: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('Eliminar', style: TextStyle(fontSize: 16)),
      ),
    ];

    _showModernModal(
      context,
      content,
      title: 'Eliminar permanentemente',
      actions: actions,
    );
  }
  
  void _restorePassword(BuildContext context, Password password) async {
    try {
      final passwordService = Provider.of<PasswordService>(context, listen: false);
      await passwordService.restorePasswordFromTrash(password.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contraseña restaurada'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al restaurar la contraseña: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              backgroundColor: Colors.white,
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