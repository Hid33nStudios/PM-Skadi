# Script de Despliegue - Stockcito
# Hid33nStudios para Planeta Motos

param(
    [string]$Platform = "firebase",
    [string]$Environment = "production"
)

Write-Host "🚀 Iniciando despliegue de Stockcito..." -ForegroundColor Green
Write-Host "📅 Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# Verificar que Flutter esté instalado
try {
    $flutterVersion = flutter --version
    Write-Host "✅ Flutter detectado" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Flutter no está instalado o no está en el PATH" -ForegroundColor Red
    exit 1
}

# Limpiar builds anteriores
Write-Host "🧹 Limpiando builds anteriores..." -ForegroundColor Yellow
flutter clean

# Obtener dependencias
Write-Host "📦 Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

# Ejecutar análisis de código
Write-Host "🔍 Analizando código..." -ForegroundColor Yellow
flutter analyze

# Build de producción
Write-Host "🏗️ Construyendo aplicación para producción..." -ForegroundColor Yellow
flutter build web --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build completado exitosamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error en el build" -ForegroundColor Red
    exit 1
}

# Verificar tamaño del build
$buildSize = (Get-ChildItem build\web -Recurse | Measure-Object -Property Length -Sum).Sum
$buildSizeMB = [math]::Round($buildSize / 1MB, 2)
Write-Host "📊 Tamaño del build: $buildSizeMB MB" -ForegroundColor Cyan

# Despliegue según plataforma
switch ($Platform.ToLower()) {
    "firebase" {
        Write-Host "🔥 Desplegando a Firebase Hosting..." -ForegroundColor Yellow
        
        # Verificar Firebase CLI
        try {
            $firebaseVersion = firebase --version
            Write-Host "✅ Firebase CLI detectado" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error: Firebase CLI no está instalado" -ForegroundColor Red
            Write-Host "💡 Instalar con: npm install -g firebase-tools" -ForegroundColor Yellow
            exit 1
        }
        
        # Desplegar a Firebase
        firebase deploy --only hosting
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Despliegue a Firebase completado" -ForegroundColor Green
        } else {
            Write-Host "❌ Error en el despliegue a Firebase" -ForegroundColor Red
            exit 1
        }
    }
    
    "netlify" {
        Write-Host "🌐 Preparando para Netlify..." -ForegroundColor Yellow
        Write-Host "📁 Carpeta build/web lista para subir a Netlify" -ForegroundColor Green
        Write-Host "💡 Sube manualmente la carpeta build/web a Netlify" -ForegroundColor Cyan
    }
    
    "vercel" {
        Write-Host "⚡ Preparando para Vercel..." -ForegroundColor Yellow
        Write-Host "📁 Carpeta build/web lista para Vercel" -ForegroundColor Green
        Write-Host "💡 Conecta tu repositorio a Vercel para despliegue automático" -ForegroundColor Cyan
    }
    
    default {
        Write-Host "❌ Plataforma no soportada: $Platform" -ForegroundColor Red
        Write-Host "💡 Plataformas soportadas: firebase, netlify, vercel" -ForegroundColor Yellow
        exit 1
    }
}

# Información final
Write-Host ""
Write-Host "🎉 ¡Despliegue completado!" -ForegroundColor Green
Write-Host "📋 Información del build:" -ForegroundColor Cyan
Write-Host "   - Versión: 1.0.0 (Alpha)" -ForegroundColor White
Write-Host "   - Tamaño: $buildSizeMB MB" -ForegroundColor White
Write-Host "   - Plataforma: $Platform" -ForegroundColor White
Write-Host "   - Ambiente: $Environment" -ForegroundColor White
Write-Host ""
Write-Host "📞 Soporte: Hid33nStudios" -ForegroundColor Yellow
Write-Host "👤 Cliente: Planeta Motos" -ForegroundColor Yellow 