import 'package:flutter/material.dart';
import 'package:invoice_manual_app/nourmal/invoice_item.dart';
import 'package:hive/hive.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

enum FilterType { today, week }

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
  FilterType selectedFilter = FilterType.today;
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

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool isThisWeek(DateTime date) {
    final now = DateTime.now();

    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(
          DateTime(endOfWeek.year, startOfWeek.month, startOfWeek.day - 1),
        ) &&
        date.isBefore(
          DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day + 1),
        );
  }

  List<InvoiceItem> get todayItems {
    return box.values.where((item) => isToday(item.createdAt)).toList();
  }

  List<InvoiceItem> get filteredItems {
    return box.values.where((item) {
      if (selectedFilter == FilterType.today) {
        return isToday(item.createdAt);
      } else {
        return isThisWeek(item.createdAt);
      }
    }).toList();
  }

  double get filteredTotal {
    double sum = 0;
    for (var item in filteredItems) {
      sum += item.total;
    }
    return sum;
  }

  Future<void> exportToPdfAndSave() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                selectedFilter == FilterType.today
                    ? 'تقرير فواتير اليوم'
                    : 'تقرير فواتير الأسبوع',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ['المنتج', 'السعر', 'الكمية', 'المجموع', 'التاريخ'],
                data: filteredItems.map((item) {
                  return [
                    item.name,
                    item.price.toString(),
                    item.quantity.toString(),
                    item.total.toString(),
                    item.createdAt.toLocal().toString().split(' ')[0],
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 20),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  selectedFilter == FilterType.today
                      ? 'إجمالي اليوم: $filteredTotal د.ل'
                      : 'إجمالي الأسبوع: $filteredTotal د.ل',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 📂 مسار الحفظ
    final directory = await getApplicationDocumentsDirectory();
    final fileName = selectedFilter == FilterType.today
        ? 'invoice_today.pdf'
        : 'invoice_week.pdf';

    final file = File('${directory.path}/$fileName');

    // 💾 حفظ الملف
    await file.writeAsBytes(await pdf.save());

    // ✅ رسالة نجاح
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ الملف في الجهاز:\n${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('إدارة الفواتير ')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // -------- إدخال البيانات --------
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
            // -------- فلترة --------
            Row(
              children: [
                DropdownButton<FilterType>(
                  value: selectedFilter,
                  items: const [
                    DropdownMenuItem(
                      value: FilterType.today,
                      child: Text('فواتير اليوم'),
                    ),
                    DropdownMenuItem(
                      value: FilterType.week,
                      child: Text('فواتير هذا الأسبوع '),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                  },
                ),

                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: addItem,
                  child: const Text('إضافة فاتور'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: exportToPdfAndSave,
                    icon: const Icon(Icons.download),
                    label: const Text('تصدير وحفظ PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            // -------- قائمة الفواتير --------
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Text('لا توجد فواتير اليوم'))
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              "السعر: ${item.price} × ${item.quantity}\n"
                              "التاريخ: ${item.createdAt.toLocal().toString().split(' ')[0]}",
                            ),
                            trailing: Text(
                              "${item.total} د.ل",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            // -------- الإجمالي --------
            Text(
              selectedFilter == FilterType.today
                  ? 'إجمالي اليوم: $filteredTotal د.ل'
                  : 'إجمالي الأسبوع: $filteredTotal د.ل',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
