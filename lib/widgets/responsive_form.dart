import 'package:flutter/material.dart';
import '../theme/responsive.dart';

class ResponsiveForm extends StatelessWidget {
  final List<Widget> children;
  final String? title;
  final Widget? titleWidget;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final EdgeInsets? padding;
  final bool wrapInCard;
  final double? maxWidth;

  const ResponsiveForm({
    super.key,
    required this.children,
    this.title,
    this.titleWidget,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.padding,
    this.wrapInCard = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? Responsive.getResponsivePadding(context);
    final spacing = Responsive.getResponsiveSpacing(context);
    final screenWidth = Responsive.getScreenWidth(context);
    
    // Calcular ancho máximo responsive
    final formMaxWidth = maxWidth ?? (Responsive.isMobile(context) 
        ? screenWidth 
        : Responsive.isTablet(context) 
            ? 600.0 
            : 800.0);

    Widget form = Container(
      width: formMaxWidth,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          // Título si se proporciona
          if (title != null || titleWidget != null) ...[
            titleWidget ?? Text(
              title!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.getResponsiveFontSize(context, 24),
              ),
            ),
            SizedBox(height: spacing * 2),
          ],
          
          // Campos del formulario con espaciado responsive
          ...children.expand((child) => [
            child,
            SizedBox(height: spacing),
          ]).take(children.length * 2 - 1).toList(),
        ],
      ),
    );

    // Envolver en card si se especifica
    if (wrapInCard && !Responsive.isMobile(context)) {
      form = Card(
        elevation: 4,
        child: Padding(
          padding: responsivePadding,
          child: form,
        ),
      );
    }

    // Layout responsive
    if (Responsive.isMobile(context)) {
      return SingleChildScrollView(
        padding: responsivePadding,
        child: form,
      );
    } else {
      return Center(
        child: SingleChildScrollView(
          padding: responsivePadding,
          child: form,
        ),
      );
    }
  }
}

class ResponsiveFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isRequired;
  final String? helperText;
  final Widget? prefix;
  final Widget? suffix;

  const ResponsiveFormField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.helperText,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            if (prefix != null) ...[
              prefix!,
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: Responsive.getResponsiveFontSize(context, 14),
                color: isMobile ? Colors.white : null,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (suffix != null) ...[
              const Spacer(),
              suffix!,
            ],
          ],
        ),
        const SizedBox(height: 8),
        
        // Campo
        child,
        
        // Texto de ayuda
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isMobile ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: Responsive.getResponsiveFontSize(context, 12),
            ),
          ),
        ],
      ],
    );
  }
}

class ResponsiveButtonRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final bool forceColumn;

  const ResponsiveButtonRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.end,
    this.forceColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Responsive.getResponsiveSpacing(context);
    
    if (Responsive.isMobile(context) || forceColumn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.expand((child) => [
          child,
          if (child != children.last) SizedBox(height: spacing),
        ]).toList(),
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        children: children.expand((child) => [
          child,
          if (child != children.last) SizedBox(width: spacing),
        ]).toList(),
      );
    }
  }
} 