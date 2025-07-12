import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';
import '../router/app_router.dart';
import '../utils/error_cases.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberUser = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authViewModel = context.read<AuthViewModel>();
      final success = await authViewModel.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (success && mounted) {
        CustomSnackBar.showSuccess(
          context: context,
          message: '¡Bienvenido a Planeta Motos!',
        );
        context.goToDashboard();
      }
    } catch (e) {
      if (mounted) {
        final authViewModel = context.read<AuthViewModel>();
        final errorType = authViewModel.errorType ?? AppErrorType.desconocido;
        showAppError(context, errorType);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Construye el formulario de login responsive
  Widget _buildLoginForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de email
          ResponsiveFormField(
            label: 'Correo Electrónico',
            isRequired: true,
            helperText: 'Ingresa tu correo electrónico registrado',
            prefix: Icon(Icons.email_outlined, color: theme.primaryColor),
            child: TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'ejemplo@planetamotos.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || value.trim().isEmpty 
                  ? 'Por favor, ingresa tu email' 
                  : null,
            ),
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context)),
          
          // Campo de contraseña
          ResponsiveFormField(
            label: 'Contraseña',
            isRequired: true,
            helperText: 'Ingresa tu contraseña',
            prefix: Icon(Icons.lock_outline, color: theme.primaryColor),
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Tu contraseña segura',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty 
                  ? 'Por favor, ingresa tu contraseña' 
                  : null,
            ),
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context)),
          
          // Checkbox y enlace
          Row(
            children: [
              Checkbox(
                value: _rememberUser,
                onChanged: (value) {
                  setState(() {
                    _rememberUser = value ?? false;
                  });
                },
                activeColor: theme.primaryColor,
              ),
              Expanded(
                child: Text(
                  'Recordar mi usuario',
                  style: TextStyle(
                    color: Responsive.isMobile(context) 
                        ? Colors.white 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: Responsive.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => CustomSnackBar.showInfo(
                  context: context,
                  message: 'Funcionalidad de recuperación en desarrollo.',
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: Responsive.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context) * 2),
          
          // Botón de iniciar sesión
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _signIn,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(
              _isLoading ? 'Iniciando...' : 'Iniciar Sesión',
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.getResponsiveSpacing(context) * 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context) * 2),
          
          // Enlace para registro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No tienes cuenta? ',
                style: TextStyle(
                  color: Responsive.isMobile(context) 
                      ? Colors.white 
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: Responsive.getResponsiveFontSize(context, 14),
                ),
              ),
              TextButton(
                onPressed: () => context.goToRegister(),
                child: Text(
                  'Regístrate aquí',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: Responsive.getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el header con logo y título
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // Logo animado
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.webp',
            height: 120,
          ),
        ),
        
        SizedBox(height: Responsive.getResponsiveSpacing(context) * 1.5),
        
        // Títulos
        Column(
          children: [
            Text(
              'Bienvenido a',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: Responsive.getResponsiveFontSize(context, 18),
              ),
            ),
            Text(
              'Planeta Motos',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                height: 1.2,
                fontSize: Responsive.getResponsiveFontSize(context, 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gestión Inteligente de Stock',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                fontSize: Responsive.getResponsiveFontSize(context, 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construye el footer con información de copyright
  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        Text(
          'De Stockcito para Planeta Motos',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: Responsive.getResponsiveFontSize(context, 11),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Desarrollado por Hid33n-Studiios © ${DateTime.now().year}',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: Responsive.getResponsiveFontSize(context, 11),
          ),
        ),
        const SizedBox(height: 12),
        // Badge de versión
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.yellow, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withValues(alpha: 0.4),
                spreadRadius: 1,
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            'Versión Única',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: Responsive.getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el panel lateral para desktop
  Widget _buildSidePanel(ThemeData theme, bool isLargeDesktop) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Fondo animado con puntos
          CustomPaint(
            painter: _DotPainter(),
            child: Container(),
          ),
          // Contenido del panel
          Center(
            child: Padding(
              padding: EdgeInsets.all(Responsive.getResponsiveSpacing(context) * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo grande
                  Image.asset(
                    'assets/images/logo.webp',
                    height: isLargeDesktop ? 180 : 140,
                  ),
                  
                  SizedBox(height: Responsive.getResponsiveSpacing(context) * 1.5),
                  
                  // Símbolo &
                  Text(
                    '&',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: theme.primaryColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.getResponsiveFontSize(context, 36),
                    ),
                  ),
                  
                  SizedBox(height: Responsive.getResponsiveSpacing(context) * 1.5),
                  
                  // Logo principal
                  Image.asset(
                    'assets/images/logo.webp',
                    height: isLargeDesktop ? 220 : 180,
                  ),
                  
                  if (isLargeDesktop) ...[
                    SizedBox(height: Responsive.getResponsiveSpacing(context) * 2),
                    Text(
                      'Sistema de Gestión de Inventario',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w300,
                        fontSize: Responsive.getResponsiveFontSize(context, 20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Control total de tu negocio',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                        fontSize: Responsive.getResponsiveFontSize(context, 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    final isLargeDesktop = Responsive.isLargeDesktop(context);

    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: isMobile 
            ? _buildMobileLayout(theme)
            : _buildDesktopLayout(theme, isTablet, isDesktop, isLargeDesktop),
      ),
    );
  }

  /// Layout para móvil
  Widget _buildMobileLayout(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Responsive.getResponsiveSpacing(context)),
          child: Column(
            children: [
              // Header más compacto
              _buildMobileHeader(theme),
              const Spacer(flex: 1),
              // Formulario compacto
              _buildMobileLoginForm(theme),
              const Spacer(flex: 1),
              // Footer compacto
              _buildMobileFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// Header optimizado para móvil
  Widget _buildMobileHeader(ThemeData theme) {
    return Column(
      children: [
        // Logo más pequeño
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.webp',
            height: 150,
          ),
        ),
        
        SizedBox(height: Responsive.getResponsiveSpacing(context)),
        
        // Títulos más compactos
        Column(
          children: [
            Text(
              'Bienvenido a',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            Text(
              'Planeta Motos',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                height: 1.1,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gestión Inteligente de Stock',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Formulario optimizado para móvil
  Widget _buildMobileLoginForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de email compacto
          ResponsiveFormField(
            label: 'Correo Electrónico',
            isRequired: true,
            helperText: 'Ingresa tu correo electrónico',
            prefix: Icon(Icons.email_outlined, color: theme.primaryColor, size: 18),
            child: TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'ejemplo@planetamotos.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || value.trim().isEmpty 
                  ? 'Por favor, ingresa tu email' 
                  : null,
            ),
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context) * 0.5),
          
          // Campo de contraseña compacto
          ResponsiveFormField(
            label: 'Contraseña',
            isRequired: true,
            helperText: 'Ingresa tu contraseña',
            prefix: Icon(Icons.lock_outline, color: theme.primaryColor, size: 18),
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Tu contraseña segura',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (value) => value == null || value.trim().isEmpty 
                  ? 'Por favor, ingresa tu contraseña' 
                  : null,
            ),
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context) * 0.5),
          
          // Checkbox y enlace más compactos
          Row(
            children: [
              Checkbox(
                value: _rememberUser,
                onChanged: (value) {
                  setState(() {
                    _rememberUser = value ?? false;
                  });
                },
                activeColor: theme.primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Expanded(
                child: Text(
                  'Recordar mi usuario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => CustomSnackBar.showInfo(
                  context: context,
                  message: 'Funcionalidad de recuperación en desarrollo.',
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context)),
          
          // Botón de iniciar sesión compacto
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _signIn,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login, size: 18),
            label: Text(
              _isLoading ? 'Iniciando...' : 'Iniciar Sesión',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context)),
          
          // Enlace para registro compacto
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No tienes cuenta? ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              TextButton(
                onPressed: () => context.goToRegister(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Regístrate aquí',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Footer optimizado para móvil
  Widget _buildMobileFooter(ThemeData theme) {
    return Column(
      children: [
        Text(
          'De Stockcito para Planeta Motos',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Desarrollado por Hid33n-Studiios © ${DateTime.now().year}',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        // Badge de versión más pequeño
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.yellow, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withValues(alpha: 0.4),
                spreadRadius: 1,
                blurRadius: 3,
              ),
            ],
          ),
          child: Text(
            'Versión Única',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Layout para desktop/tablet
  Widget _buildDesktopLayout(ThemeData theme, bool isTablet, bool isDesktop, bool isLargeDesktop) {
    return Row(
      children: [
        // Panel lateral (solo en desktop)
        if (isDesktop || isLargeDesktop)
          Expanded(
            flex: isLargeDesktop ? 2 : 1,
            child: _buildSidePanel(theme, isLargeDesktop),
          ),
        // Panel principal
        Expanded(
          flex: isLargeDesktop ? 3 : 2,
          child: Container(
            color: theme.colorScheme.surface,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Responsive.getResponsiveSpacing(context) * 3),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLargeDesktop ? 600 : 500,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header (solo en tablet)
                      if (isTablet) ...[
                        _buildHeader(theme),
                        SizedBox(height: Responsive.getResponsiveSpacing(context) * 4),
                      ],
                      // Formulario
                      _buildLoginForm(theme),
                      SizedBox(height: Responsive.getResponsiveSpacing(context) * 4),
                      // Footer
                      _buildFooter(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    const double spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 