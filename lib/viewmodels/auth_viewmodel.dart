import 'package:flutter/foundation.dart' as foundation;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/error_handler.dart';
import '../utils/error_cases.dart';
import 'dart:async';

class AuthViewModel extends foundation.ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  AppErrorType? _errorType;
  bool _isAuthLoading = true;
  late final StreamSubscription<User?> _authSubscription;

  AuthViewModel(this._authService, this._firestoreService) {
    // Verificar usuario actual inmediatamente
    _currentUser = _authService.currentUser;
    _isAuthLoading = false;
    
    // Escuchar cambios de autenticación
    _authSubscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AppErrorType? get errorType => _errorType;
  bool get isAuthenticated => _currentUser != null;
  bool get isAuthLoading => _isAuthLoading;

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      _errorType = null;
      notifyListeners();

      print('🔄 AuthViewModel: Iniciando sesión con email: $email');
      
      final userCredential = await _authService.signInWithEmailOrUsername(email, password);
      _currentUser = userCredential.user;
      
      if (_currentUser != null) {
        print('✅ AuthViewModel: Sesión iniciada exitosamente');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Credenciales inválidas';
        _errorType = AppErrorType.autenticacion;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      // Manejo explícito de errores de Firebase
      print('❌ AuthViewModel: FirebaseAuthException - Código: \\${e.code}, Mensaje: \\${e.message}');
      if (e.code == 'wrong-password') {
        _error = 'Contraseña incorrecta.';
        _errorType = AppErrorType.contrasenaIncorrecta;
      } else if (e.code == 'user-not-found') {
        _error = 'El usuario no existe.';
        _errorType = AppErrorType.usuarioNoExiste;
      } else if (e.code == 'user-disabled') {
        _error = 'El usuario está deshabilitado.';
        _errorType = AppErrorType.usuarioDeshabilitado;
      } else if (e.code == 'too-many-requests') {
        _error = 'Demasiados intentos fallidos. Intenta más tarde.';
        _errorType = AppErrorType.cuentaBloqueada;
      } else if (e.code == 'invalid-email') {
        _error = 'El formato del email no es válido.';
        _errorType = AppErrorType.formatoInvalido;
      } else {
        _error = 'Error de autenticación. Intenta nuevamente.';
        _errorType = AppErrorType.autenticacion;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      if (e is String) {
        final msg = e.toLowerCase();
        if (msg.contains('contraseña')) {
          _error = e;
          _errorType = AppErrorType.contrasenaIncorrecta;
        } else if (msg.contains('usuario') && msg.contains('no se encontró')) {
          _error = e;
          _errorType = AppErrorType.usuarioNoExiste;
        } else if (msg.contains('deshabilitado')) {
          _error = e;
          _errorType = AppErrorType.usuarioDeshabilitado;
        } else if (msg.contains('demasiados intentos')) {
          _error = e;
          _errorType = AppErrorType.cuentaBloqueada;
        } else if (msg.contains('email') && msg.contains('válido')) {
          _error = e;
          _errorType = AppErrorType.formatoInvalido;
        } else {
          _error = e;
          _errorType = AppErrorType.autenticacion;
        }
      } else {
        final appError = AppError.fromException(e, stackTrace);
        _error = appError.message;
        _errorType = appError.appErrorType ?? AppErrorType.autenticacion;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String username) async {
    try {
      print('🔄 AuthViewModel: Iniciando signUp con email: $email, username: $username');
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 AuthViewModel: Llamando a AuthService.registerWithEmailAndPassword...');
      
      final userCredential = await _authService.registerWithEmailAndPassword(email, password, username);
      print('✅ AuthViewModel: AuthService.registerWithEmailAndPassword completado');
      
      _currentUser = userCredential.user;
      print('🔄 AuthViewModel: Usuario actual asignado: ${_currentUser?.uid}');
      
      if (_currentUser != null) {
        print('✅ AuthViewModel: Usuario registrado exitosamente - UID: ${_currentUser!.uid}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('❌ AuthViewModel: userCredential.user es null');
        _error = 'Error al crear el usuario';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ AuthViewModel: Error en signUp - $e');
      print('❌ AuthViewModel: Stack trace: $stackTrace');
      _error = AppError.fromException(e, stackTrace).message;
      print('❌ AuthViewModel: Error procesado: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔄 AuthViewModel: Cerrando sesión');
      
      await _authService.signOut();
      _currentUser = null;
      
      print('✅ AuthViewModel: Sesión cerrada exitosamente');
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 AuthViewModel: Cargando usuario actual');
      
      _currentUser = _authService.currentUser;
      
      if (_currentUser != null) {
        print('✅ AuthViewModel: Usuario cargado: ${_currentUser!.email}');
      } else {
        print('ℹ️ AuthViewModel: No hay usuario autenticado');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String username) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 AuthViewModel: Actualizando perfil de usuario');
      
      await _authService.updateUserProfile(username);
      
      print('✅ AuthViewModel: Perfil actualizado exitosamente');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 AuthViewModel: Enviando email de restablecimiento a: $email');
      
      await _authService.resetPassword(email);
      
      print('✅ AuthViewModel: Email de restablecimiento enviado');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    _errorType = null;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
} 