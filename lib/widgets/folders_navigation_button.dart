import 'package:flutter/material.dart';

class FoldersNavigationButton extends StatelessWidget {
  final bool showText;
  final bool useBadge;
  
  const FoldersNavigationButton({
    Key? key,
    this.showText = true,
    this.useBadge = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, '/folders');
      },
      icon: Badge(
        isLabelVisible: useBadge,
        label: const Text('Nuevo'),
        child: const Icon(Icons.folder_outlined),
      ),
      label: showText ? const Text('Carpetas') : const SizedBox.shrink(),
    );
  }
}

class FoldersDrawerItem extends StatelessWidget {
  const FoldersDrawerItem({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: const Text('Mis Carpetas'),
      onTap: () {
        Navigator.pop(context); // Cierra el drawer
        Navigator.pushNamed(context, '/folders');
      },
    );
  }
}

// Este es un widget de cajón flotante que se puede mostrar en cualquier pantalla
// para acceder rápidamente a carpetas, favoritos y otros destinos importantes
class QuickAccessDrawer extends StatelessWidget {
  const QuickAccessDrawer({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Acceso Rápido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const ListTile(
            leading: Icon(Icons.home),
            title: Text('Inicio'),
          ),
          const FoldersDrawerItem(),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Favoritos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/favorites');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Papelera'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/trash');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }
} 