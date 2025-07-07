import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Función para traducir errores de Firebase
  String _translateFirebaseError(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'La contraseña es demasiado débil. Debe tener al menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este email ya está registrado. Intenta con otro email o inicia sesión.';
      case 'user-not-found':
        return 'No se encontró una cuenta con estas credenciales.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Verifica tus credenciales.';
      case 'invalid-email':
        return 'El formato del email no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Esta operación no está permitida.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu conexión a internet.';
      default:
        return 'Ha ocurrido un error inesperado. Intenta nuevamente.';
    }
  }

  // Registro con email y contraseña usando transacciones para garantizar consistencia
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      print('🔄 AuthService: Iniciando registro con email: $email, username: $username');
      
      // Validaciones básicas
      if (email.trim().isEmpty) {
        print('❌ AuthService: Email vacío');
        throw 'El email es requerido';
      }
      if (password.trim().isEmpty) {
        print('❌ AuthService: Contraseña vacía');
        throw 'La contraseña es requerida';
      }
      if (username.trim().isEmpty) {
        print('❌ AuthService: Username vacío');
        throw 'El nombre de usuario es requerido';
      }
      if (password.length < 6) {
        print('❌ AuthService: Contraseña muy corta');
        throw 'La contraseña debe tener al menos 6 caracteres';
      }
      if (username.length < 3) {
        print('❌ AuthService: Username muy corto');
        throw 'El nombre de usuario debe tener al menos 3 caracteres';
      }

      print('✅ AuthService: Validaciones básicas pasadas');

      // Verificar si el email ya existe (esto sí se puede hacer antes)
      print('🔄 AuthService: Verificando si el email ya existe...');
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          print('❌ AuthService: Email ya registrado: $email');
          throw 'Este email ya está registrado. Intenta con otro email o inicia sesión.';
        }
        print('✅ AuthService: Email disponible');
      } catch (e) {
        print('⚠️ AuthService: Error al verificar email, continuando: $e');
      }

      print('🔄 AuthService: Creando usuario en Firebase Auth...');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('✅ AuthService: Usuario creado en Firebase Auth: ${userCredential.user?.uid}');

      // Crear perfil de usuario en Firestore con manejo de duplicados
      print('🔄 AuthService: Creando perfil en Firestore...');
      try {
        await _firestore.collection('pm').doc(userCredential.user!.uid).set({
          'username': username.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
        });
        print('✅ AuthService: Perfil creado en Firestore');
      } catch (e) {
        print('❌ AuthService: Error al crear perfil: $e');
        // Si falla, eliminar el usuario de Auth
        await userCredential.user?.delete();
        throw 'Error al crear el perfil de usuario. Intenta nuevamente.';
      }

      // Crear estructura inicial de datos del usuario (fuera de la transacción)
      print('🔄 AuthService: Creando estructura de datos inicial...');
      final userDoc = _firestore.collection('pm').doc(userCredential.user!.uid);
      
      // Crear subcolecciones vacías
      await Future.wait([
        userDoc.collection('products').doc('_placeholder').set({
          'createdAt': FieldValue.serverTimestamp(),
        }).then((_) => userDoc.collection('products').doc('_placeholder').delete()),
        
        userDoc.collection('categories').doc('_placeholder').set({
          'createdAt': FieldValue.serverTimestamp(),
        }).then((_) => userDoc.collection('categories').doc('_placeholder').delete()),
        
        userDoc.collection('sales').doc('_placeholder').set({
          'createdAt': FieldValue.serverTimestamp(),
        }).then((_) => userDoc.collection('sales').doc('_placeholder').delete()),
        
        userDoc.collection('movements').doc('_placeholder').set({
          'createdAt': FieldValue.serverTimestamp(),
        }).then((_) => userDoc.collection('movements').doc('_placeholder').delete()),
      ]);
      print('✅ AuthService: Estructura de datos inicial creada');

      print('✅ AuthService: Registro completado exitosamente');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ AuthService: FirebaseAuthException - Código: ${e.code}, Mensaje: ${e.message}');
      print('❌ AuthService: Stack trace: ${e.stackTrace}');
      throw _translateFirebaseError(e.code);
    } catch (e, stackTrace) {
      print('❌ AuthService: Error general - $e');
      print('❌ AuthService: Stack trace: $stackTrace');
      if (e is String) {
        throw e;
      }
      throw 'Error al crear la cuenta. Intenta nuevamente.';
    }
  }

  // Inicio de sesión con email/username y contraseña
  Future<UserCredential> signInWithEmailOrUsername(
      String emailOrUsername, String password) async {
    try {
      // Validaciones básicas
      if (emailOrUsername.trim().isEmpty) {
        throw 'El email o nombre de usuario es requerido';
      }
      if (password.trim().isEmpty) {
        throw 'La contraseña es requerida';
      }

      // Si el input parece un email, intentar iniciar sesión directamente
      if (emailOrUsername.contains('@')) {
        return await _auth.signInWithEmailAndPassword(
          email: emailOrUsername.trim(),
          password: password,
        );
      }

      // Si no es un email, buscar el usuario por nombre de usuario
      final userQuery = await _firestore
          .collection('pm')
          .where('username', isEqualTo: emailOrUsername.trim())
          .get();

      if (userQuery.docs.isEmpty) {
        throw 'No se encontró un usuario con el nombre "$emailOrUsername"';
      }

      final userEmail = userQuery.docs.first.get('email') as String;
      return await _auth.signInWithEmailAndPassword(
        email: userEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _translateFirebaseError(e.code);
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Error al iniciar sesión. Intenta nuevamente.';
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error al cerrar sesión. Intenta nuevamente.';
    }
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      if (email.trim().isEmpty) {
        throw 'El email es requerido';
      }
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _translateFirebaseError(e.code);
    } catch (e) {
      throw 'Error al enviar el email de restablecimiento. Intenta nuevamente.';
    }
  }

  // Actualizar perfil de usuario
  Future<void> updateUserProfile(String username) async {
    try {
      if (username.trim().isEmpty) {
        throw 'El nombre de usuario es requerido';
      }
      if (username.length < 3) {
        throw 'El nombre de usuario debe tener al menos 3 caracteres';
      }

      // Verificar si el nuevo nombre de usuario ya existe
      if (username != currentUser?.displayName) {
        final usernameQuery = await _firestore
            .collection('pm')
            .where('username', isEqualTo: username.trim())
            .get();

        if (usernameQuery.docs.isNotEmpty) {
          throw 'El nombre de usuario "$username" ya está en uso';
        }
      }

      await _firestore.collection('pm').doc(currentUser!.uid).update({
        'username': username.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Error al actualizar el perfil. Intenta nuevamente.';
    }
  }

  // Obtener perfil de usuario
  Future<DocumentSnapshot> getUserProfile() async {
    try {
      return await _firestore.collection('pm').doc(currentUser!.uid).get();
    } catch (e) {
      throw 'Error al obtener el perfil del usuario.';
    }
  }
} 