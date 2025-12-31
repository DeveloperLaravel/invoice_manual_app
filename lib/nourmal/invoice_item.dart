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
  InvoiceItem(this.name, this.price, this.quantity);
  double get total => price * quantity;
}
