import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/validators.dart';

class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    if (json['productId'] == null || json['productName'] == null || json['quantity'] == null || json['unitPrice'] == null || json['subtotal'] == null) {
      throw Exception('SaleItem con campos nulos o inválidos: $json');
    }
    return SaleItem(
      productId: json['productId'].toString(),
      productName: json['productName'].toString(),
      quantity: (json['quantity'] is int) ? json['quantity'] as int : int.tryParse(json['quantity'].toString()) ?? 0,
      unitPrice: (json['unitPrice'] is double) ? json['unitPrice'] as double : (json['unitPrice'] is num) ? (json['unitPrice'] as num).toDouble() : double.tryParse(json['unitPrice'].toString()) ?? 0.0,
      subtotal: (json['subtotal'] is double) ? json['subtotal'] as double : (json['subtotal'] is num) ? (json['subtotal'] as num).toDouble() : double.tryParse(json['subtotal'].toString()) ?? 0.0,
    );
  }
}

class Sale {
  final String id;
  final String userId;
  final String customerName;
  final double total;
  final List<SaleItem> items;
  final DateTime date;
  final String? notes;

  Sale({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.total,
    required this.items,
    required this.date,
    this.notes,
  });

  factory Sale.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        return DateTime.tryParse(dateValue) ?? DateTime.now();
      } else {
        return DateTime.now(); // Fallback
      }
    }
    // Defensas para campos críticos
    if (map['userId'] == null || map['customerName'] == null || map['total'] == null || map['items'] == null || map['date'] == null) {
      throw Exception('Venta con campos nulos o inválidos: $map');
    }
    return Sale(
      id: id,
      userId: map['userId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      total: (map['total'] is num) ? (map['total'] as num).toDouble() : 0.0,
      items: (map['items'] as List?)?.map((e) => SaleItem.fromJson(Map<String, dynamic>.from(e))).toList() ?? [],
      date: parseDate(map['date']),
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerName': customerName,
      'total': total,
      'items': items.map((e) => e.toJson()).toList(),
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(date);
  String get formattedTotal => ' [${formatPrice(total)}';
} 