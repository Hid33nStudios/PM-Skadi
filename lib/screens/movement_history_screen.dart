import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movement.dart';
import '../viewmodels/movement_viewmodel.dart';
import '../viewmodels/product_viewmodel.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../utils/error_cases.dart';

class MovementHistoryScreen extends StatefulWidget {
  const MovementHistoryScreen({super.key});

  @override
  State<MovementHistoryScreen> createState() => _MovementHistoryScreenState();
}

class _MovementHistoryScreenState extends State<MovementHistoryScreen> {
  String _searchQuery = '';
  MovementType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  final _authService = AuthService();
  int _pageSize = 10;
  int _currentMax = 0;
  ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        context.showError(e);
      }
    }
  }

  Future<void> _loadData() async {
    final movementViewModel = context.read<MovementViewModel>();
    final productViewModel = context.read<ProductViewModel>();
    
    await Future.wait([
      movementViewModel.loadInitialMovements(),
      productViewModel.loadInitialProducts(),
    ]);
  }

  List<Movement> _getFilteredMovements(List<Movement> movements) {
    return movements.where((movement) {
      final matchesSearch = movement.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == null || movement.type == _selectedType;
      final matchesDate = (_startDate == null || movement.date.isAfter(_startDate!)) &&
          (_endDate == null || movement.date.isBefore(_endDate!));
      return matchesSearch && matchesType && matchesDate;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora mismo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildMovementList(),
    );
  }

  Widget _buildMovementList() {
    final viewModel = context.watch<MovementViewModel>();
    final movements = viewModel.movements;
    if (viewModel.isLoading && movements.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      final errorType = viewModel.errorType ?? AppErrorType.desconocido;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAppError(context, errorType);
      });
      return const SizedBox.shrink();
    }
    if (movements.isEmpty) {
      return Center(child: Text('No hay movimientos registrados.'));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final movement = movements[index];
              return _buildMovementItem(movement);
            },
          ),
        ),
        if (viewModel.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: viewModel.isLoadingMore ? null : () => viewModel.loadMoreMovements(),
              child: viewModel.isLoadingMore
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cargar más'),
            ),
          ),
      ],
    );
  }

  Widget _buildMovementItem(Movement movement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: movement.type == MovementType.entry
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            movement.type == MovementType.entry
                ? Icons.add_circle_outline
                : Icons.remove_circle_outline,
            color: movement.type == MovementType.entry
                ? Colors.green
                : Colors.red,
            size: 24,
          ),
        ),
        title: Text(
          movement.productName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: movement.type == MovementType.entry
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${movement.type == MovementType.entry ? "Entrada" : "Salida"} de ${movement.quantity} unidades',
                style: TextStyle(
                  color: movement.type == MovementType.entry
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            if (movement.note != null && movement.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                movement.note!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(movement.date),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 