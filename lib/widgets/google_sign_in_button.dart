import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Iniciar sesión con Google',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Image.asset(
        'assets/google_logo.png',
        height: 24.0,
      ),
      label: Text(text),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
} 