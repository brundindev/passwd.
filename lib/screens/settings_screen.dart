import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useBiometrics = false;
  bool _autoLock = true;
  int _autoLockDelay = 1;
  bool _showTOTPCodes = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Usar autenticación biométrica'),
            subtitle: const Text('Desbloquear con huella digital o Face ID'),
            trailing: Switch(
              value: _useBiometrics,
              onChanged: (value) {
                setState(() {
                  _useBiometrics = value;
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Bloqueo automático'),
            subtitle: const Text('Bloquear la aplicación al cambiar de app'),
            trailing: Switch(
              value: _autoLock,
              onChanged: (value) {
                setState(() {
                  _autoLock = value;
                });
              },
            ),
          ),
          if (_autoLock)
            ListTile(
              title: const Text('Retraso de bloqueo'),
              subtitle: Text('$_autoLockDelay minutos'),
              trailing: DropdownButton<int>(
                value: _autoLockDelay,
                items: [1, 2, 5, 10].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value min'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _autoLockDelay = newValue;
                    });
                  }
                },
              ),
            ),
          ListTile(
            title: const Text('Mostrar códigos TOTP'),
            subtitle: const Text('Mostrar códigos de autenticación en la lista'),
            trailing: Switch(
              value: _showTOTPCodes,
              onChanged: (value) {
                setState(() {
                  _showTOTPCodes = value;
                });
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Cambiar contraseña maestra'),
            leading: const Icon(Icons.lock),
            onTap: () {
              // Implementar cambio de contraseña maestra
            },
          ),
          ListTile(
            title: const Text('Exportar base de datos'),
            leading: const Icon(Icons.download),
            onTap: () {
              // Implementar exportación
            },
          ),
          ListTile(
            title: const Text('Importar base de datos'),
            leading: const Icon(Icons.upload),
            onTap: () {
              // Implementar importación
            },
          ),
        ],
      ),
    );
  }
}
