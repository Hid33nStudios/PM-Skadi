// error_cases.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Enum de tipos de error extendido para toda la app
enum AppErrorType {
  // Conexión y red
  conexion,
  red,
  timeout,
  servidor,
  apiNoDisponible,
  apiRespuestaInvalida,
  apiLimiteExcedido,
  apiClaveInvalida,
  errorFirebase,
  errorHive,
  errorSqlite,
  errorAlDescargarDatos,
  errorAlSubirDatos,

  // Usuario y autenticación
  autenticacion,
  usuarioNoExiste,
  usuarioDeshabilitado,
  emailNoVerificado,
  contrasenaIncorrecta,
  cuentaBloqueada,
  cambioContrasenaFallido,
  registroFallido,
  emailYaRegistrado,
  sesionExpirada,
  tokenInvalido,
  intentoDeAccesoNoAutorizado,

  // Permisos y seguridad
  permisos,
  accesoDenegado,
  accesoRestringido,
  rolInsuficiente,
  operacionNoPermitida,

  // Productos y stock
  productoNoEncontrado,
  productoDuplicado,
  stockInsuficiente,
  stockNegativo,
  categoriaNoEncontrada,
  categoriaDuplicada,
  movimientoInvalido,
  operacionNoPermitidaEnProducto,

  // Ventas
  ventaNoEncontrada,
  ventaDuplicada,
  ventaCancelada,
  errorAlGuardarVenta,
  errorAlActualizarVenta,

  // Sincronización
  sincronizacion,
  sincronizacionEnCurso,
  conflictoDeSincronizacion,
  datosDesactualizados,

  // Base de datos
  baseDeDatos,
  backupFallido,
  restauracionFallida,
  backupNoEncontrado,

  // Archivos y multimedia
  archivoNoEncontrado,
  archivoDemasiadoGrande,
  formatoArchivoNoSoportado,
  errorAlSubirArchivo,
  errorAlDescargarArchivo,

  // Validación y formularios
  validacion,
  campoObligatorio,
  valorFueraDeRango,
  formatoInvalido,
  datosIncompletos,
  seleccionInvalida,
  duplicado,
  formato,

  // Configuración y sistema
  configuracionInvalida,
  errorDeInicializacion,
  errorDeActualizacion,
  versionNoSoportada,
  errorDeLicencia,

  // Notificaciones
  notificacionNoEnviada,
  notificacionNoRecibida,

  // Otros
  operacionCancelada,
  errorCritico,
  noEncontrado,
  desconocido,
}

/// Mapeo de mensajes amigables para cada tipo de error
String getErrorMessage(AppErrorType type, {String? detalle}) {
  switch (type) {
    // Conexión y red
    case AppErrorType.conexion:
      return 'Sin conexión a internet.';
    case AppErrorType.red:
      return 'Error de red. Verifica tu conexión.';
    case AppErrorType.timeout:
      return 'La operación tardó demasiado. Intenta de nuevo.';
    case AppErrorType.servidor:
      return 'Error del servidor. Intenta más tarde.';
    case AppErrorType.apiNoDisponible:
      return 'El servicio externo no está disponible.';
    case AppErrorType.apiRespuestaInvalida:
      return 'Respuesta inválida de la API externa.';
    case AppErrorType.apiLimiteExcedido:
      return 'Límite de uso de la API alcanzado.';
    case AppErrorType.apiClaveInvalida:
      return 'Clave de API inválida.';
    case AppErrorType.errorFirebase:
      return 'Error de comunicación con Firebase.';
    case AppErrorType.errorHive:
      return 'Error en la base de datos local (Hive).';
    case AppErrorType.errorSqlite:
      return 'Error en la base de datos local (SQLite).';
    case AppErrorType.errorAlDescargarDatos:
      return 'Error al descargar datos.';
    case AppErrorType.errorAlSubirDatos:
      return 'Error al subir datos.';

    // Usuario y autenticación
    case AppErrorType.autenticacion:
      return 'Error de autenticación. Por favor, inicia sesión nuevamente.';
    case AppErrorType.usuarioNoExiste:
      return 'El usuario no existe.';
    case AppErrorType.usuarioDeshabilitado:
      return 'El usuario está deshabilitado.';
    case AppErrorType.emailNoVerificado:
      return 'Debes verificar tu correo electrónico.';
    case AppErrorType.contrasenaIncorrecta:
      return 'Contraseña incorrecta.';
    case AppErrorType.cuentaBloqueada:
      return 'La cuenta está bloqueada.';
    case AppErrorType.cambioContrasenaFallido:
      return 'No se pudo cambiar la contraseña.';
    case AppErrorType.registroFallido:
      return 'No se pudo registrar el usuario.';
    case AppErrorType.emailYaRegistrado:
      return 'El correo ya está registrado.';
    case AppErrorType.sesionExpirada:
      return 'Tu sesión ha expirado. Inicia sesión nuevamente.';
    case AppErrorType.tokenInvalido:
      return 'Token de sesión inválido.';
    case AppErrorType.intentoDeAccesoNoAutorizado:
      return 'Intento de acceso no autorizado.';

    // Permisos y seguridad
    case AppErrorType.permisos:
      return 'Permiso denegado para realizar esta acción.';
    case AppErrorType.accesoDenegado:
      return 'Acceso denegado.';
    case AppErrorType.accesoRestringido:
      return 'Acceso restringido.';
    case AppErrorType.rolInsuficiente:
      return 'No tienes permisos suficientes.';
    case AppErrorType.operacionNoPermitida:
      return 'Operación no permitida.';

    // Productos y stock
    case AppErrorType.productoNoEncontrado:
      return 'Producto no encontrado.';
    case AppErrorType.productoDuplicado:
      return 'El producto ya existe.';
    case AppErrorType.stockInsuficiente:
      return 'Stock insuficiente.';
    case AppErrorType.stockNegativo:
      return 'El stock no puede ser negativo.';
    case AppErrorType.categoriaNoEncontrada:
      return 'Categoría no encontrada.';
    case AppErrorType.categoriaDuplicada:
      return 'La categoría ya existe.';
    case AppErrorType.movimientoInvalido:
      return 'Movimiento de stock inválido.';
    case AppErrorType.operacionNoPermitidaEnProducto:
      return 'Operación no permitida en este producto.';

    // Ventas
    case AppErrorType.ventaNoEncontrada:
      return 'Venta no encontrada.';
    case AppErrorType.ventaDuplicada:
      return 'La venta ya existe.';
    case AppErrorType.ventaCancelada:
      return 'La venta fue cancelada.';
    case AppErrorType.errorAlGuardarVenta:
      return 'Error al guardar la venta.';
    case AppErrorType.errorAlActualizarVenta:
      return 'Error al actualizar la venta.';

    // Sincronización
    case AppErrorType.sincronizacion:
      return 'Error al sincronizar datos. Intenta más tarde.';
    case AppErrorType.sincronizacionEnCurso:
      return 'Sincronización en curso. Espera a que termine.';
    case AppErrorType.conflictoDeSincronizacion:
      return 'Conflicto de sincronización detectado.';
    case AppErrorType.datosDesactualizados:
      return 'Tus datos están desactualizados.';

    // Base de datos
    case AppErrorType.baseDeDatos:
      return 'Error en la base de datos local.';
    case AppErrorType.backupFallido:
      return 'No se pudo realizar el backup.';
    case AppErrorType.restauracionFallida:
      return 'No se pudo restaurar el backup.';
    case AppErrorType.backupNoEncontrado:
      return 'No se encontró el backup.';

    // Archivos y multimedia
    case AppErrorType.archivoNoEncontrado:
      return 'Archivo no encontrado.';
    case AppErrorType.archivoDemasiadoGrande:
      return 'El archivo es demasiado grande.';
    case AppErrorType.formatoArchivoNoSoportado:
      return 'Formato de archivo no soportado.';
    case AppErrorType.errorAlSubirArchivo:
      return 'Error al subir el archivo.';
    case AppErrorType.errorAlDescargarArchivo:
      return 'Error al descargar el archivo.';

    // Validación y formularios
    case AppErrorType.validacion:
      return 'Datos inválidos. Revisa los campos e inténtalo de nuevo.';
    case AppErrorType.campoObligatorio:
      return 'Este campo es obligatorio.';
    case AppErrorType.valorFueraDeRango:
      return 'El valor está fuera del rango permitido.';
    case AppErrorType.formatoInvalido:
      return 'Formato de datos incorrecto.';
    case AppErrorType.datosIncompletos:
      return 'Faltan datos requeridos.';
    case AppErrorType.seleccionInvalida:
      return 'Selección inválida.';
    case AppErrorType.duplicado:
      return 'El registro ya existe.';
    case AppErrorType.formato:
      return 'Formato incorrecto.';

    // Configuración y sistema
    case AppErrorType.configuracionInvalida:
      return 'Configuración inválida.';
    case AppErrorType.errorDeInicializacion:
      return 'Error al inicializar la aplicación.';
    case AppErrorType.errorDeActualizacion:
      return 'Error al actualizar la aplicación.';
    case AppErrorType.versionNoSoportada:
      return 'Versión de la app no soportada.';
    case AppErrorType.errorDeLicencia:
      return 'Error de licencia.';

    // Notificaciones
    case AppErrorType.notificacionNoEnviada:
      return 'No se pudo enviar la notificación.';
    case AppErrorType.notificacionNoRecibida:
      return 'No se recibió la notificación.';

    // Otros
    case AppErrorType.operacionCancelada:
      return 'La operación fue cancelada.';
    case AppErrorType.errorCritico:
      return 'Ocurrió un error crítico. Contacta al soporte.';
    case AppErrorType.noEncontrado:
      return 'No se encontró el recurso solicitado.';
    case AppErrorType.desconocido:
    default:
      return detalle ?? 'Ocurrió un error desconocido.';
  }
}

/// Función para mostrar el error al usuario según la plataforma
void showAppError(BuildContext context, AppErrorType type, {String? detalle, Duration? duration}) {
  final mensaje = getErrorMessage(type, detalle: detalle);
  if (kIsWeb) {
    // En web: usar MaterialBanner (más visible y persistente)
    ScaffoldMessenger.of(context).clearMaterialBanners();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade50,
        leading: const Icon(Icons.error_outline, color: Colors.red),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  } else {
    // En móvil: usar SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade700,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
} 