import 'package:hive/hive.dart';

part 'invoice_item.g.dart';

@HiveType(typeId: 0)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final double price;
  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final DateTime createdAt; // 👈 تاريخ الإضافة
  InvoiceItem(this.name, this.price, this.quantity, {DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();
  double get total => price * quantity;
}
