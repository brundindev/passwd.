import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/snackbar_utils.dart';

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
      final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      showSnackBar(context, 'Error al seleccionar la imagen: $e');
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
          .child('${user.uid}.jpg');
        
        // Subir la imagen
        await storageRef.putFile(_imageFile!);
        
        // Obtener la URL de la imagen
        final downloadUrl = await storageRef.getDownloadURL();
        
        // Actualizar el perfil del usuario con la nueva URL de imagen
        await user.updatePhotoURL(downloadUrl);
        
        setState(() {
          _profileImageUrl = downloadUrl;
        });
        
        showSnackBar(context, 'Imagen de perfil actualizada correctamente');
      }
    } catch (e) {
      showSnackBar(context, 'Error al subir la imagen: $e');
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
        
        showSnackBar(context, 'Contraseña actualizada correctamente');
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
      showSnackBar(context, errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de información del usuario
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Imagen de perfil
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
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
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          // Información del usuario
                          Text(
                            user?.email ?? 'Email no disponible',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Miembro desde ${user?.metadata.creationTime?.day}/${user?.metadata.creationTime?.month}/${user?.metadata.creationTime?.year}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Sección de cambio de contraseña
                  Text(
                    'Cambiar Contraseña',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Contraseña actual
                            TextFormField(
                              controller: _currentPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Contraseña actual',
                                prefixIcon: Icon(Icons.lock),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureCurrentPassword = !_obscureCurrentPassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscureCurrentPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu contraseña actual';
                                }
                                return null;
                              },
                              style: TextStyle(color: Colors.black87),
                            ),
                            SizedBox(height: 16),
                            
                            // Nueva contraseña
                            TextFormField(
                              controller: _newPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Nueva contraseña',
                                prefixIcon: Icon(Icons.lock),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureNewPassword = !_obscureNewPassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscureNewPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa una nueva contraseña';
                                }
                                if (value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                              style: TextStyle(color: Colors.black87),
                            ),
                            SizedBox(height: 16),
                            
                            // Confirmar nueva contraseña
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Confirmar nueva contraseña',
                                prefixIcon: Icon(Icons.lock),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscureConfirmPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor confirma tu nueva contraseña';
                                }
                                if (value != _newPasswordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                              style: TextStyle(color: Colors.black87),
                            ),
                            SizedBox(height: 24),
                            
                            ElevatedButton(
                              onPressed: _changePassword,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Cambiar Contraseña',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 