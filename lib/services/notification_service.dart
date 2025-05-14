import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/password.dart';

class NotificationService {
  // Tiempo recomendado para cambiar contraseñas (90 días por defecto)
  static const int passwordExpirationDays = 90;
  
  // Verifica si una contraseña necesita ser actualizada
  static bool isPasswordExpired(Password password) {
    final DateTime now = DateTime.now();
    final DateTime expirationDate = password.ultimaModificacion.add(
      Duration(days: passwordExpirationDays)
    );
    
    return now.isAfter(expirationDate);
  }
  
  // Días restantes antes de recomendar cambio
  static int daysUntilExpiration(Password password) {
    final DateTime now = DateTime.now();
    final DateTime expirationDate = password.ultimaModificacion.add(
      Duration(days: passwordExpirationDays)
    );
    
    final int daysRemaining = expirationDate.difference(now).inDays;
    return daysRemaining > 0 ? daysRemaining : 0;
  }
  
  // Obtener contraseñas que necesitan actualización
  static Future<List<Password>> getPasswordsNeedingUpdate() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('pass')
        .where('isInTrash', isEqualTo: false)
        .get();
        
      final List<Password> allPasswords = snapshot.docs
        .map((doc) => Password.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
      
      // Filtrar contraseñas vencidas o próximas a vencer (menos de 7 días)
      return allPasswords.where((password) {
        int days = daysUntilExpiration(password);
        return days <= 7; // Notificar cuando falten 7 días o menos
      }).toList();
    } catch (e) {
      print('Error al obtener contraseñas para actualizar: $e');
      return [];
    }
  }
  
  // Mostrar notificación en la app
  static void showPasswordUpdateReminder(
    BuildContext context, 
    List<Password> passwordsToUpdate
  ) {
    if (passwordsToUpdate.isEmpty) return;
    
    // No mostrar más de una notificación al mismo tiempo
    ScaffoldMessenger.of(context).clearSnackBars();
    
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.update_rounded,
                  color: Colors.amber,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    passwordsToUpdate.length == 1
                      ? 'Una contraseña necesita actualización'
                      : '${passwordsToUpdate.length} contraseñas necesitan actualización',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (passwordsToUpdate.length <= 3) ...passwordsToUpdate.map(
              (password) => Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                child: Text(
                  '• ${password.sitio}',
                  style: TextStyle(fontSize: 14),
                ),
              )
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 6),
        margin: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDarkMode 
                ? Colors.grey.withOpacity(0.2) 
                : Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        action: SnackBarAction(
          label: 'VER',
          textColor: Colors.blue,
          onPressed: () {
            // Aquí se podría abrir una página con todas las contraseñas a actualizar
            showPasswordUpdateDialog(context, passwordsToUpdate);
          },
        ),
      ),
    );
  }
  
  // Diálogo para mostrar contraseñas que necesitan actualización
  static void showPasswordUpdateDialog(
    BuildContext context, 
    List<Password> passwordsToUpdate
  ) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Ordenar por urgencia (primero las más urgentes)
    passwordsToUpdate.sort((a, b) {
      int daysA = daysUntilExpiration(a);
      int daysB = daysUntilExpiration(b);
      return daysA.compareTo(daysB);
    });
    
    showDialog(
      context: context,
      builder: (context) {
        // Agregar variable de estado para cada contraseña
        Map<String, String> updateStates = {};
        Map<String, Color> statusColors = {};
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              title: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.update_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contraseñas a actualizar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Se recomienda actualizar cada ${passwordExpirationDays} días',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Divider(height: 1),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: passwordsToUpdate.length,
                  itemBuilder: (context, index) {
                    final password = passwordsToUpdate[index];
                    final int days = daysUntilExpiration(password);
                    final bool isExpired = days == 0;
                    final bool isUrgent = days <= 3;
                    
                    // Estado por defecto si no está en proceso de actualización
                    Color statusColor = statusColors[password.id] ?? 
                      (isExpired ? Colors.red : (isUrgent ? Colors.deepOrange : Colors.amber));
                    
                    // Determinar texto del botón según el estado
                    String buttonText = "Actualizar";
                    Color buttonColor = statusColor;
                    bool isUpdating = false;
                    
                    if (updateStates.containsKey(password.id)) {
                      if (updateStates[password.id] == "updating") {
                        buttonText = "Actualizando...";
                        buttonColor = Colors.amber;
                        isUpdating = true;
                      } else if (updateStates[password.id] == "success") {
                        buttonText = "¡Actualizada!";
                        buttonColor = Colors.green;
                      } else if (updateStates[password.id] == "error") {
                        buttonText = "Error";
                        buttonColor = Colors.red;
                      }
                    }
                    
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? Colors.grey.shade900.withOpacity(0.5) 
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColors[password.id]?.withOpacity(0.3) ?? 
                            statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColors[password.id]?.withOpacity(0.2) ??
                              statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            updateStates[password.id] == "updating" 
                                ? Icons.shield
                                : updateStates[password.id] == "success"
                                    ? Icons.check_circle_outline
                                    : updateStates[password.id] == "error"
                                        ? Icons.error_outline
                                        : isExpired 
                                            ? Icons.error_outline 
                                            : (isUrgent ? Icons.timer : Icons.lock_clock),
                            color: statusColors[password.id] ?? statusColor,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          password.sitio,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              'Actualizada: ${_formatDate(password.ultimaModificacion)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              updateStates[password.id] == "updating"
                                  ? "Actualizando contraseña..."
                                  : updateStates[password.id] == "success"
                                      ? "¡Contraseña actualizada correctamente!"
                                      : updateStates[password.id] == "error"
                                          ? "Error al actualizar la contraseña"
                                          : isExpired 
                                              ? '¡Actualización necesaria ahora!' 
                                              : 'Actualizar en ${days} ${days == 1 ? 'día' : 'días'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: statusColors[password.id] ?? statusColor,
                              ),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: isUpdating ? null : () async {
                            // Actualizar el estado a "actualizando"
                            setState(() {
                              updateStates[password.id] = "updating";
                              statusColors[password.id] = Colors.amber;
                            });
                            
                            try {
                              // Simulación de la actualización de contraseña
                              await Future.delayed(Duration(seconds: 2));
                              
                              // Actualizar estado a "éxito"
                              setState(() {
                                updateStates[password.id] = "success";
                                statusColors[password.id] = Colors.green;
                              });
                              
                              // Esperar un momento para mostrar el éxito antes de cerrar
                              await Future.delayed(Duration(seconds: 1));
                              
                              // Cerrar el diálogo y redirigir a pantalla de edición
                              if (context.mounted) {
                                Navigator.pop(context);
                                // Aquí se puede abrir la pantalla de edición de contraseña
                              }
                            } catch (e) {
                              // Actualizar estado a "error"
                              setState(() {
                                updateStates[password.id] = "error";
                                statusColors[password.id] = Colors.red;
                              });
                            }
                          },
                          child: Text(buttonText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            textStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            minimumSize: Size(100, 36),
                            disabledBackgroundColor: Colors.amber.withOpacity(0.7),
                            disabledForegroundColor: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cerrar'),
                  style: TextButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white70 : Colors.black54,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Actualizar todas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: isDarkMode ? Color(0xFF121214) : Colors.white,
              elevation: 10,
            );
          }
        );
      },
    );
  }
  
  // Formatear fecha para mostrar al usuario
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 