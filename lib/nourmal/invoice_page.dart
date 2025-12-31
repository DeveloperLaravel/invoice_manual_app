import 'package:flutter/material.dart';
import 'package:invoice_manual_app/nourmal/invoice_item.dart';
import 'package:hive/hive.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final qtyController = TextEditingController();
  late Box<InvoiceItem> box;

  @override
  void initState() {
    super.initState();
    box = Hive.box<InvoiceItem>('invoiceBox');
  }

  double get total {
    double sum = 0;
    for (var item in box.values) {
      sum += item.total;
    }
    return sum;
  }

  void addItem() {
    final item = InvoiceItem(
      nameController.text,
      double.parse(priceController.text),
      int.parse(qtyController.text),
    );
    box.add(item);

    nameController.clear();
    priceController.clear();
    qtyController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فاتورة بسيطة')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم المنتج'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,

              decoration: const InputDecoration(labelText: 'السعر'),
            ),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: addItem, child: const Text('إضافة')),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: box.length,
                itemBuilder: (context, index) {
                  final item = box.getAt(index)!;
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text("${item.price}  *  ${item.quantity}"),
                    trailing: Text('${item.total}'),
                  );
                },
              ),
            ),
            Text(
              'الاجمالي $total دينار',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
