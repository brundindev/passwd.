import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.photoURL != null) {
        setState(() {
          _profileImageUrl = user.photoURL;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar la imagen: $e', isError: true);
    }
  }
  
  Future<void> _uploadProfileImage() async {
    if (_imageFile == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Crear una referencia con un nombre único para la imagen
        final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        // Subir la imagen
        await storageRef.putFile(_imageFile!);
        
        // Obtener la URL de la imagen
        final downloadUrl = await storageRef.getDownloadURL();
        
        // Actualizar el perfil del usuario con la nueva URL de imagen
        await user.updatePhotoURL(downloadUrl);
        
        setState(() {
          _profileImageUrl = downloadUrl;
        });
        
        _showSnackBar('Imagen de perfil actualizada correctamente', isError: false);
      }
    } catch (e) {
      _showSnackBar('Error al subir la imagen: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        // Primero reautenticar al usuario
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        
        await user.reauthenticateWithCredential(credential);
        
        // Cambiar la contraseña
        await user.updatePassword(_newPasswordController.text);
        
        // Limpiar los campos
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        _showSnackBar('Contraseña actualizada correctamente', isError: false);
      }
    } catch (e) {
      String errorMessage = 'Error al cambiar la contraseña';
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password') {
          errorMessage = 'La contraseña actual es incorrecta';
        } else if (e.code == 'weak-password') {
          errorMessage = 'La nueva contraseña es demasiado débil';
        }
      }
      _showSnackBar(errorMessage, isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Color(0xFFF2F2F7), // Fondo estilo iOS
      appBar: AppBar(
        title: Text('Mi Perfil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de información del usuario
                  _buildProfileCard(user),
                  
                  SizedBox(height: 24),
                  
                  // Sección de cambio de contraseña
                  _buildSectionHeader('CAMBIAR CONTRASEÑA'),
                  SizedBox(height: 8),
                  _buildPasswordChangeCard(),
                  
                  // Sección de opciones de cuenta
                  SizedBox(height: 24),
                  _buildSectionHeader('OPCIONES DE CUENTA'),
                  SizedBox(height: 8),
                  _buildAccountOptionsCard(),
                  
                  SizedBox(height: 30),
                  
                  // Texto de copyright
                  Center(
                    child: Text(
                      'PASSWD. © 2025 brundindev.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
  
  Widget _buildProfileCard(User? user) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          // Banner superior con degradado
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade700,
                  Colors.indigo.shade500,
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          
          // Avatar del usuario (encima del banner)
          Transform.translate(
            offset: Offset(0, -40),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fondo del avatar
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: _profileImageUrl != null 
                        ? Colors.transparent 
                        : Colors.blue.shade200,
                    backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                    child: _profileImageUrl == null
                        ? Text(
                            user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                
                // Botón de cambio de imagen
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Nombre de usuario y correo
          Transform.translate(
            offset: Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    user?.displayName ?? 'Usuario',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Email no disponible',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Miembro desde ${user?.metadata.creationTime?.day}/${user?.metadata.creationTime?.month}/${user?.metadata.creationTime?.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPasswordChangeCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contraseña actual
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Contraseña actual',
                obscure: _obscureCurrentPassword,
                toggleObscure: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu contraseña actual';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Nueva contraseña
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'Nueva contraseña',
                obscure: _obscureNewPassword,
                toggleObscure: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una nueva contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Confirmar nueva contraseña
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirmar nueva contraseña',
                obscure: _obscureConfirmPassword,
                toggleObscure: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor confirma tu nueva contraseña';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              // Botón de actualizar contraseña
              ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Actualizar contraseña',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggleObscure,
    required String? Function(String?) validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey : Colors.grey.shade700,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: Colors.blue,
          size: 22,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey,
            size: 22,
          ),
          onPressed: toggleObscure,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      obscureText: obscure,
      validator: validator,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }
  
  Widget _buildAccountOptionsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          _buildOptionItem(
            icon: Icons.verified_user_rounded,
            iconColor: Colors.green,
            title: 'Verificar correo electrónico',
            showDivider: true,
            onTap: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && !user.emailVerified) {
                  await user.sendEmailVerification();
                  _showSnackBar('Correo de verificación enviado', isError: false);
                } else {
                  _showSnackBar('Tu correo ya está verificado', isError: false);
                }
              } catch (e) {
                _showSnackBar('Error al enviar correo de verificación: $e', isError: true);
              }
            },
          ),
          _buildOptionItem(
            icon: Icons.logout_rounded,
            iconColor: Colors.red,
            title: 'Cerrar sesión',
            showDivider: false,
            onTap: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/welcome');
              } catch (e) {
                _showSnackBar('Error al cerrar sesión: $e', isError: true);
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.withOpacity(0.5),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: Colors.grey.withOpacity(0.2),
          ),
      ],
    );
  }
} 