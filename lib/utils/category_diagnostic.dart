import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category.dart';
import '../utils/error_handler.dart';

class CategoryDiagnostic {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Diagnóstico completo del problema de conteo de categorías
  static Future<Map<String, dynamic>> diagnoseCategoryCount(String userId) async {
    try {
      print('🔍 CategoryDiagnostic: Iniciando diagnóstico para usuario: $userId');
      
      final results = <String, dynamic>{};
      
      // 1. Conteo directo con count()
      final countResult = await _firestore
          .collection('pm')
          .doc(userId)
          .collection('categories')
          .count()
          .get();
      
      results['direct_count'] = countResult.count ?? 0;
      print('📊 CategoryDiagnostic: Conteo directo: ${results['direct_count']}');
      
      // 2. Conteo manual con get()
      final snapshot = await _firestore
          .collection('pm')
          .doc(userId)
          .collection('categories')
          .get();
      
      results['manual_count'] = snapshot.docs.length;
      print('📊 CategoryDiagnostic: Conteo manual: ${results['manual_count']}');
      
      // 3. Verificar duplicados
      final categoryIds = <String>{};
      final duplicates = <String>[];
      
      for (final doc in snapshot.docs) {
        final categoryId = doc.id;
        if (categoryIds.contains(categoryId)) {
          duplicates.add(categoryId);
        } else {
          categoryIds.add(categoryId);
        }
      }
      
      results['unique_count'] = categoryIds.length;
      results['duplicates'] = duplicates;
      results['duplicate_count'] = duplicates.length;
      
      print('📊 CategoryDiagnostic: Conteo único: ${results['unique_count']}');
      print('📊 CategoryDiagnostic: Duplicados encontrados: ${results['duplicate_count']}');
      
      // 4. Verificar datos corruptos
      final corruptedDocs = <String>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data['name'] == null || data['name'].toString().isEmpty) {
            corruptedDocs.add(doc.id);
          }
        } catch (e) {
          corruptedDocs.add(doc.id);
        }
      }
      
      results['corrupted_count'] = corruptedDocs.length;
      results['corrupted_docs'] = corruptedDocs;
      
      print('📊 CategoryDiagnostic: Documentos corruptos: ${results['corrupted_count']}');
      
      // 5. Análisis de timestamps
      final timestamps = <DateTime>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data['createdAt'] != null) {
            timestamps.add((data['createdAt'] as Timestamp).toDate());
          }
        } catch (e) {
          // Ignorar errores de timestamp
        }
      }
      
      timestamps.sort();
      results['oldest_timestamp'] = timestamps.isNotEmpty ? timestamps.first : null;
      results['newest_timestamp'] = timestamps.isNotEmpty ? timestamps.last : null;
      
      print('📊 CategoryDiagnostic: Timestamp más antiguo: ${results['oldest_timestamp']}');
      print('📊 CategoryDiagnostic: Timestamp más reciente: ${results['newest_timestamp']}');
      
      // 6. Resumen del diagnóstico
      results['diagnosis'] = _generateDiagnosis(results);
      
      print('✅ CategoryDiagnostic: Diagnóstico completado');
      return results;
      
    } catch (e, stackTrace) {
      print('❌ CategoryDiagnostic: Error en diagnóstico: $e');
      final appError = AppError.fromException(e, stackTrace);
      return {
        'error': appError.message,
        'error_type': appError.appErrorType.toString(),
      };
    }
  }

  /// Generar diagnóstico basado en los resultados
  static String _generateDiagnosis(Map<String, dynamic> results) {
    final directCount = results['direct_count'] as int? ?? 0;
    final manualCount = results['manual_count'] as int? ?? 0;
    final uniqueCount = results['unique_count'] as int? ?? 0;
    final duplicateCount = results['duplicate_count'] as int? ?? 0;
    final corruptedCount = results['corrupted_count'] as int? ?? 0;
    
    if (directCount != manualCount) {
      return '❌ INCONSISTENCIA: Conteo directo ($directCount) vs manual ($manualCount)';
    }
    
    if (duplicateCount > 0) {
      return '⚠️ DUPLICADOS: $duplicateCount documentos duplicados encontrados';
    }
    
    if (corruptedCount > 0) {
      return '⚠️ CORRUPCIÓN: $corruptedCount documentos corruptos encontrados';
    }
    
    if (uniqueCount == directCount) {
      return '✅ NORMAL: Conteo correcto ($uniqueCount categorías)';
    }
    
    return '❓ DESCONOCIDO: No se pudo determinar la causa del problema';
  }

  /// Obtener información del usuario
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      print('🔍 CategoryDiagnostic: Obteniendo información del usuario: $userId');
      
      final userDoc = await _firestore
          .collection('pm')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        print('❌ CategoryDiagnostic: Usuario no encontrado: $userId');
        return null;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      print('✅ CategoryDiagnostic: Información del usuario obtenida');
      
      return {
        'username': userData['username'] ?? 'Sin nombre',
        'email': userData['email'] ?? 'Sin email',
        'role': userData['role'] ?? 'user',
        'createdAt': userData['createdAt'] ?? null,
      };
      
    } catch (e) {
      print('❌ CategoryDiagnostic: Error obteniendo información del usuario: $e');
      return null;
    }
  }

  /// Verificar si el usuario actual es admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        print('❌ CategoryDiagnostic: Usuario no autenticado');
        return false;
      }
      
      print('🔍 CategoryDiagnostic: Verificando rol de admin para usuario: $currentUserId');
      
      final userDoc = await _firestore
          .collection('pm')
          .doc(currentUserId)
          .get();
      
      if (!userDoc.exists) {
        print('❌ CategoryDiagnostic: Usuario actual no encontrado en Firestore');
        return false;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'] ?? 'user';
      
      print('📊 CategoryDiagnostic: Rol del usuario actual: $role');
      return role == 'admin';
      
    } catch (e) {
      print('❌ CategoryDiagnostic: Error verificando rol de admin: $e');
      return false;
    }
  }

  /// Cambiar temporalmente el rol del usuario actual a admin
  static Future<bool> setCurrentUserAsAdmin() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        print('❌ CategoryDiagnostic: Usuario no autenticado');
        return false;
      }
      
      print('🔧 CategoryDiagnostic: Cambiando rol a admin para usuario: $currentUserId');
      
      await _firestore
          .collection('pm')
          .doc(currentUserId)
          .update({'role': 'admin'});
      
      print('✅ CategoryDiagnostic: Rol cambiado a admin exitosamente');
      return true;
      
    } catch (e) {
      print('❌ CategoryDiagnostic: Error cambiando rol a admin: $e');
      return false;
    }
  }

  /// Limpiar categorías duplicadas
  static Future<bool> cleanDuplicateCategories(String userId) async {
    try {
      print('🧹 CategoryDiagnostic: Limpiando categorías duplicadas para usuario: $userId');
      
      final snapshot = await _firestore
          .collection('pm')
          .doc(userId)
          .collection('categories')
          .get();
      
      final seenIds = <String>{};
      final duplicatesToDelete = <String>[];
      
      for (final doc in snapshot.docs) {
        final categoryId = doc.id;
        if (seenIds.contains(categoryId)) {
          duplicatesToDelete.add(categoryId);
        } else {
          seenIds.add(categoryId);
        }
      }
      
      if (duplicatesToDelete.isEmpty) {
        print('✅ CategoryDiagnostic: No se encontraron duplicados para limpiar');
        return true;
      }
      
      print('🗑️ CategoryDiagnostic: Eliminando ${duplicatesToDelete.length} duplicados');
      
      final batch = _firestore.batch();
      for (final duplicateId in duplicatesToDelete) {
        batch.delete(_firestore
            .collection('pm')
            .doc(userId)
            .collection('categories')
            .doc(duplicateId));
      }
      
      await batch.commit();
      
      print('✅ CategoryDiagnostic: Duplicados eliminados exitosamente');
      return true;
      
    } catch (e, stackTrace) {
      print('❌ CategoryDiagnostic: Error limpiando duplicados: $e');
      return false;
    }
  }
} 