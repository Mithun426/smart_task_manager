import 'package:hive_flutter/hive_flutter.dart';

class HiveStorageService {
  static const String tasksBoxName = 'tasksBox';
  static const String userPrefsBoxName = 'userPrefsBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(tasksBoxName);
    await Hive.openBox(userPrefsBoxName);
  }

  static Box get tasksBox => Hive.box(tasksBoxName);
  static Box get userPrefsBox => Hive.box(userPrefsBoxName);
}
