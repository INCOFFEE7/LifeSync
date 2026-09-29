import 'package:flutter/material.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/config/beebee_config.dart';
import 'package:lifesync_app/core/database/database_service.dart';
import 'package:lifesync_app/domain/entities/fasting_debt.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.setup(BeebeeConfig.config);
  
  final dbService = DatabaseService();
  await dbService.init();
  
  final debt = FastingDebt()
    ..ramadanYear = 1445
    ..initialDebt = 5
    ..currentDebt = 5
    ..createdAt = DateTime.now()
    ..updatedAt = DateTime.now();
    
  await dbService.db.writeTxn(() async {
    await dbService.db.fastingDebts.put(debt);
  });
  
  final debts = await dbService.db.fastingDebts.where().findAll();
  print("DEBTS COUNT: ${debts.length}");
}
