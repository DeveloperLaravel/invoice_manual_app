import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'nourmal/invoice_item.dart';
import 'nourmal/invoice_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(InvoiceItemAdapter());
  await Hive.openBox<InvoiceItem>('invoiceBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: InvoicePage(),
    );
  }
}
