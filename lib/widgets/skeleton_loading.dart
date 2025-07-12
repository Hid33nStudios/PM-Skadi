import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/responsive.dart';

/// Widget base para crear efectos de skeleton loading
class SkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? color;

  const SkeletonWidget({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 4.0,
    this.color,
  });

  @override
  State<SkeletonWidget> createState() => _SkeletonWidgetState();
}

class _SkeletonWidgetState extends State<SkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Skeleton para cards del dashboard
class DashboardCardSkeleton extends StatelessWidget {
  const DashboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const SkeletonWidget(height: 20, width: 120),
            const SizedBox(height: 16),
            // Contenido
            Row(
              children: [
                // Icono
                const SkeletonWidget(height: 40, width: 40, borderRadius: 20),
                const SizedBox(width: 16),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonWidget(height: 16, width: 80),
                      const SizedBox(height: 8),
                      const SkeletonWidget(height: 12, width: 60),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para lista de productos
class ProductListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ProductListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Imagen del producto
                const SkeletonWidget(height: 60, width: 60, borderRadius: 8),
                const SizedBox(width: 16),
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonWidget(height: 16, width: 150),
                      const SizedBox(height: 8),
                      const SkeletonWidget(height: 12, width: 100),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SkeletonWidget(height: 12, width: 60),
                          const Spacer(),
                          const SkeletonWidget(height: 12, width: 40),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton para gráficos
class ChartSkeleton extends StatelessWidget {
  final double height;
  
  const ChartSkeleton({
    super.key,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del gráfico
            const SkeletonWidget(height: 20, width: 150),
            const SizedBox(height: 16),
            // Área del gráfico
            SkeletonWidget(
              height: height,
              borderRadius: 8,
            ),
            const SizedBox(height: 16),
            // Leyenda
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) => 
                Row(
                  children: [
                    SkeletonWidget(
                      height: 12,
                      width: 12,
                      borderRadius: 6,
                    ),
                    const SizedBox(width: 8),
                    const SkeletonWidget(height: 12, width: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para tabla de ventas
class SalesTableSkeleton extends StatelessWidget {
  final int rowCount;
  
  const SalesTableSkeleton({
    super.key,
    this.rowCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const SkeletonWidget(height: 20, width: 120),
            const SizedBox(height: 16),
            // Encabezados
            Row(
              children: [
                const Expanded(flex: 2, child: SkeletonWidget(height: 16, width: 80)),
                const SizedBox(width: 16),
                const Expanded(child: SkeletonWidget(height: 16, width: 60)),
                const SizedBox(width: 16),
                const Expanded(child: SkeletonWidget(height: 16, width: 60)),
              ],
            ),
            const SizedBox(height: 12),
            // Filas
            ...List.generate(rowCount, (index) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Expanded(flex: 2, child: SkeletonWidget(height: 14, width: 100)),
                    const SizedBox(width: 16),
                    const Expanded(child: SkeletonWidget(height: 14, width: 50)),
                    const SizedBox(width: 16),
                    const Expanded(child: SkeletonWidget(height: 14, width: 50)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para grid de productos
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto
                const Expanded(
                  child: SkeletonWidget(height: 120, borderRadius: 8),
                ),
                const SizedBox(height: 12),
                // Nombre del producto
                const SkeletonWidget(height: 16, width: 120),
                const SizedBox(height: 8),
                // Precio
                const SkeletonWidget(height: 14, width: 60),
                const SizedBox(height: 8),
                // Stock
                const SkeletonWidget(height: 12, width: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton para formularios
class FormSkeleton extends StatelessWidget {
  final int fieldCount;
  
  const FormSkeleton({
    super.key,
    this.fieldCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del formulario
            const SkeletonWidget(height: 24, width: 150),
            const SizedBox(height: 24),
            // Campos del formulario
            ...List.generate(fieldCount, (index) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    const SkeletonWidget(height: 14, width: 80),
                    const SizedBox(height: 8),
                    // Campo
                    const SkeletonWidget(height: 48, borderRadius: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Botones
            Row(
              children: [
                const Expanded(child: SkeletonWidget(height: 48, borderRadius: 8)),
                const SizedBox(width: 16),
                const Expanded(child: SkeletonWidget(height: 48, borderRadius: 8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsets? margin;

  const SkeletonLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              SkeletonLoading(
                width: 24,
                height: 24,
                borderRadius: 6,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonLoading(
                  height: 20,
                  borderRadius: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
                  child: SkeletonLoading(
                    height: 16,
                    borderRadius: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;
  final int itemCount;

  const SkeletonGrid({
    super.key,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.2,
    this.spacing = 24,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonCard(),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? padding;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 60,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        height: itemHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SkeletonLoading(
              width: 40,
              height: 40,
              borderRadius: 8,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonLoading(
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoading(
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            SkeletonLoading(
              width: 60,
              height: 20,
              borderRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
} 