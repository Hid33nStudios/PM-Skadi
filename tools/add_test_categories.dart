import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/firebase_options.dart';
import 'dart:math';

Future<void> main() async {
  const email = 'test02@gmail.com';
  const password = '15429102Hh';

  print('Inicializando Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Autenticando usuario...');
  final auth = FirebaseAuth.instance;
  try {
    await auth.signInWithEmailAndPassword(email: email, password: password);
    print('✅ Usuario autenticado: \\${auth.currentUser?.uid}');
  } catch (e) {
    print('❌ Error autenticando: \\${e.toString()}');
    return;
  }

  final userId = auth.currentUser?.uid;
  if (userId == null) {
    print('❌ No se pudo obtener el UID del usuario.');
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final categoriesRef = firestore.collection('pm').doc(userId).collection('categories');

  print('Agregando 90 categorías de prueba...');
  final now = DateTime.now();
  for (int i = 1; i <= 90; i++) {
    final name = 'Categoría Test $i';
    final description = 'Descripción de prueba $i';
    final createdAt = now.subtract(Duration(minutes: 90 - i));
    final updatedAt = createdAt;
    final data = {
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    try {
      await categoriesRef.add(data);
      print('[$i/90] ✅ $name agregada');
    } catch (e) {
      print('[$i/90] ❌ Error agregando $name: \\${e.toString()}');
    }
  }
  print('✅ Proceso completado. ¡90 categorías agregadas!');
}

// Ejecuta este script con:
// dart run tools/add_test_categories.dart 