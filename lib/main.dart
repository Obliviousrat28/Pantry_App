import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/inventory_item.dart';
import 'models/meal_log.dart';
import 'models/storage_zone.dart';
import 'screens/main_navigation_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register all 3 adapters
  Hive.registerAdapter(StorageZoneAdapter());
  Hive.registerAdapter(InventoryItemAdapter());
  Hive.registerAdapter(MealLogAdapter());

  // Open Hive boxes
  await Hive.openBox<InventoryItem>('inventory_box');
  await Hive.openBox<MealLog>('meal_logs_box');
  await Hive.openBox('settings_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainNavigationScreen(),
    );
  }
}