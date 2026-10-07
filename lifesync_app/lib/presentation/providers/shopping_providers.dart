import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:isar/isar.dart';

final shoppingItemsProvider = StreamProvider<List<ShoppingItem>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  if (kIsWeb) return Stream.value([]);
  return dbService.db.shoppingItems
      .filter()
      .deletedEqualTo(false)
      .sortByCreatedAtDesc()
      .watch(fireImmediately: true);
});
