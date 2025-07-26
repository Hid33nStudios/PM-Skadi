# 🚀 Despliegue de Producción - Stockcito

## 📋 Información del Build

- **Versión**: 1.0.0 (Alpha)
- **Tamaño del build**: ~32.3 MB
- **Plataforma**: Web (Flutter Web)
- **Fecha de build**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 📁 Estructura del Build

```
build/web/
├── index.html              # Página principal
├── main.dart.js           # Código principal (3.5MB)
├── flutter.js             # Runtime de Flutter
├── flutter_bootstrap.js   # Bootstrap de Flutter
├── manifest.json          # PWA manifest
├── _redirects             # Redirecciones (Netlify/Vercel)
├── robots.txt             # SEO
├── assets/                # Assets de la aplicación
├── icons/                 # Iconos PWA
└── canvaskit/             # Canvas Kit (renderizado)
```

## 🌐 Opciones de Despliegue

### 1. Firebase Hosting (Recomendado)

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login a Firebase
firebase login

# Inicializar proyecto (si no existe)
firebase init hosting

# Desplegar
firebase deploy --only hosting
```

### 2. Netlify

1. Subir la carpeta `build/web` a Netlify
2. Configurar dominio personalizado
3. El archivo `_redirects` ya está incluido

### 3. Vercel

1. Conectar repositorio a Vercel
2. Configurar build command: `flutter build web`
3. Configurar output directory: `build/web`

### 4. GitHub Pages

1. Subir contenido de `build/web` a la rama `gh-pages`
2. Configurar GitHub Pages en el repositorio

## 🔧 Configuración de Producción

### Variables de Entorno

Asegúrate de configurar estas variables en tu plataforma de hosting:

- `FIREBASE_API_KEY`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_APP_ID`

### Dominio Personalizado

Configura tu dominio personalizado en la plataforma de hosting elegida.

## 📱 PWA (Progressive Web App)

La aplicación está configurada como PWA con:

- ✅ Manifest.json configurado
- ✅ Iconos en múltiples tamaños
- ✅ Meta tags para iOS/Android
- ✅ Service worker incluido
- ✅ Offline capability

## 🔍 SEO

- ✅ Meta tags optimizados
- ✅ Robots.txt incluido
- ✅ Viewport configurado para móvil
- ✅ Descripción y título optimizados

## 🚨 Consideraciones de Seguridad

1. **Firebase Security Rules**: Configurar reglas de seguridad en Firestore
2. **CORS**: Configurar políticas CORS si es necesario
3. **HTTPS**: Asegurar que el hosting use HTTPS
4. **API Keys**: No exponer claves sensibles en el frontend

## 📊 Monitoreo

### Firebase Analytics
- Configurar Firebase Analytics para tracking
- Monitorear métricas de uso

### Error Tracking
- Implementar sistema de logging local para debugging
- Monitorear logs de Firebase

## 🔄 Actualizaciones

Para actualizar la aplicación:

1. Hacer cambios en el código
2. Ejecutar `flutter build web --release`
3. Desplegar el nuevo build
4. Verificar que todo funcione correctamente

## 📞 Soporte

- **Desarrollador**: Hid33nStudios
- **Cliente**: Planeta Motos
- **Versión**: Alpha v1.0.0

---

**¡Listo para producción! 🎉** 