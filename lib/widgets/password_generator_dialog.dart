import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/password_generator.dart';

class PasswordGeneratorDialog extends StatefulWidget {
  const PasswordGeneratorDialog({super.key});

  @override
  State<PasswordGeneratorDialog> createState() => _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  bool _useUpperCase = true;
  bool _useLowerCase = true;
  bool _useNumbers = true;
  bool _useSpecialChars = true;
  int _passwordLength = 16;
  String _generatedPassword = '';
  bool _useDiceware = false;
  int _wordCount = 4;

  void _generatePassword() {
    setState(() {
      if (_useDiceware) {
        _generatedPassword = PasswordGenerator.generateDicewarePassword(
          wordCount: _wordCount,
        );
      } else {
        _generatedPassword = PasswordGenerator.generateRandomPassword(
          length: _passwordLength,
          useUpperCase: _useUpperCase,
          useLowerCase: _useLowerCase,
          useNumbers: _useNumbers,
          useSpecialChars: _useSpecialChars,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generador de Contraseñas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Usar Diceware'),
              subtitle: const Text('Genera contraseñas memorables'),
              value: _useDiceware,
              onChanged: (value) {
                setState(() {
                  _useDiceware = value;
                });
              },
            ),
            if (_useDiceware)
              ListTile(
                title: const Text('Número de palabras'),
                trailing: DropdownButton<int>(
                  value: _wordCount,
                  items: [3, 4, 5, 6].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() {
                        _wordCount = value;
                      });
                    }
                  },
                ),
              )
            else ...[
              CheckboxListTile(
                title: const Text('Mayúsculas (A-Z)'),
                value: _useUpperCase,
                onChanged: (value) {
                  setState(() {
                    _useUpperCase = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Minúsculas (a-z)'),
                value: _useLowerCase,
                onChanged: (value) {
                  setState(() {
                    _useLowerCase = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Números (0-9)'),
                value: _useNumbers,
                onChanged: (value) {
                  setState(() {
                    _useNumbers = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Caracteres especiales (!@#\$%)'),
                value: _useSpecialChars,
                onChanged: (value) {
                  setState(() {
                    _useSpecialChars = value ?? true;
                  });
                },
              ),
              ListTile(
                title: const Text('Longitud'),
                trailing: DropdownButton<int>(
                  value: _passwordLength,
                  items: [8, 12, 16, 20, 24, 32].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() {
                        _passwordLength = value;
                      });
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_generatedPassword.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _generatedPassword,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _generatedPassword),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contraseña copiada al portapapeles'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                PasswordGenerator.evaluatePasswordStrength(_generatedPassword)
                    ? 'Contraseña fuerte'
                    : 'Contraseña débil',
                style: TextStyle(
                  color: PasswordGenerator.evaluatePasswordStrength(_generatedPassword)
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _generatePassword,
          child: const Text('Generar'),
        ),
        if (_generatedPassword.isNotEmpty)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(_generatedPassword);
            },
            child: const Text('Usar'),
          ),
      ],
    );
  }
}
