import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../dtos/category_dto.dart';
import '../../interfaces/repositories/ibudget_repository.dart';
import '../mapper/budget_mapper.dart';

class LocalBudgetRepository implements IBudgetRepository {
  static const String _legacyCategoriesKey = 'tet_budget_categories_v1';
  static const String _legacyMigratedFlagKey = 'tet_budget_sqlite_migrated_v1';
  static const String _dbName = 'tet_budget.db';
  static const int _dbVersion = 1;

  static const String _tableCategories = 'categories';
  static const String _tableItems = 'items';
  static const String _tablePriceLogs = 'price_logs';

  Future<Database>? _dbFuture;
  bool _checkedLegacyMigration = false;

  Future<Database> get _database async {
    _dbFuture ??= _openDatabase();
    return _dbFuture!;
  }

  bool get _isTestEnv {
    if (kIsWeb) return false;
    return Platform.environment.containsKey('FLUTTER_TEST');
  }

  bool get _useFfiFactory {
    if (kIsWeb) return false;
    if (_isTestEnv) return true;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  DatabaseFactory get _databaseFactory {
    if (_useFfiFactory) {
      sqfliteFfiInit();
      return _isTestEnv ? databaseFactoryFfiNoIsolate : databaseFactoryFfi;
    }
    return sqflite.databaseFactory;
  }

  Future<Database> _openDatabase() async {
    final factory = _databaseFactory;
    final dbPath = _isTestEnv
        ? inMemoryDatabasePath
        : p.join(await factory.getDatabasesPath(), _dbName);

    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
        },
      ),
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableCategories (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        icon_str TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tableItems (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        target_price REAL NOT NULL,
        current_price REAL NOT NULL,
        is_purchased INTEGER NOT NULL,
        image_path TEXT,
        date_added TEXT NOT NULL,
        purchased_date TEXT,
        sort_order INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $_tableCategories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tablePriceLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id TEXT NOT NULL,
        price REAL NOT NULL,
        observed_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES $_tableItems(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_items_category ON $_tableItems(category_id, sort_order)',
    );
    await db.execute(
      'CREATE INDEX idx_logs_item_time ON $_tablePriceLogs(item_id, observed_at)',
    );
  }

  @override
  Future<List<ShoppingCategory>> loadCategories() async {
    final db = await _database;
    await _migrateLegacySharedPreferencesIfNeeded(db);

    final categoryRows = await db.query(
      _tableCategories,
      orderBy: 'sort_order ASC',
    );

    if (categoryRows.isEmpty) {
      final defaults = _getDefaultCategories();
      await _writeAllCategories(db, defaults);
      return defaults;
    }

    final result = <ShoppingCategory>[];

    for (final categoryRow in categoryRows) {
      final categoryId = (categoryRow['id'] as String?) ?? '';
      if (categoryId.isEmpty) continue;

      final itemRows = await db.query(
        _tableItems,
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'sort_order ASC',
      );

      final items = <ShoppingItem>[];
      for (final itemRow in itemRows) {
        final itemId = (itemRow['id'] as String?) ?? '';
        if (itemId.isEmpty) continue;

        final logRows = await db.query(
          _tablePriceLogs,
          where: 'item_id = ?',
          whereArgs: [itemId],
          orderBy: 'observed_at ASC',
        );

        final priceHistory = logRows
            .map(
              (logRow) => PriceLog(
                price: (logRow['price'] as num?)?.toDouble() ?? 0,
                observedAt:
                    DateTime.tryParse(logRow['observed_at'] as String? ?? '') ??
                    DateTime.now(),
              ),
            )
            .toList();

        items.add(
          ShoppingItem(
            id: itemId,
            name: (itemRow['name'] as String?) ?? '',
            targetPrice: (itemRow['target_price'] as num?)?.toDouble() ?? 0,
            currentPrice: (itemRow['current_price'] as num?)?.toDouble() ?? 0,
            isPurchased: (itemRow['is_purchased'] as int? ?? 0) == 1,
            imagePath: itemRow['image_path'] as String?,
            date: DateTime.tryParse(itemRow['date_added'] as String? ?? ''),
            purchasedDate: DateTime.tryParse(
              itemRow['purchased_date'] as String? ?? '',
            ),
            priceHistory: priceHistory,
          ),
        );
      }

      result.add(
        ShoppingCategory(
          id: categoryId,
          title: (categoryRow['title'] as String?) ?? '',
          iconStr: (categoryRow['icon_str'] as String?) ?? '',
          items: items,
        ),
      );
    }

    return result;
  }

  @override
  Future<void> saveCategories(List<ShoppingCategory> categories) async {
    final db = await _database;
    await _writeAllCategories(db, categories);
  }

  Future<void> _writeAllCategories(
    Database db,
    List<ShoppingCategory> categories,
  ) async {
    await db.transaction((txn) async {
      await txn.delete(_tableCategories);

      for (
        var categoryIndex = 0;
        categoryIndex < categories.length;
        categoryIndex++
      ) {
        final category = categories[categoryIndex];
        await txn.insert(_tableCategories, {
          'id': category.id,
          'title': category.title,
          'icon_str': category.iconStr,
          'sort_order': categoryIndex,
        });

        for (
          var itemIndex = 0;
          itemIndex < category.items.length;
          itemIndex++
        ) {
          final item = category.items[itemIndex];
          await txn.insert(_tableItems, {
            'id': item.id,
            'category_id': category.id,
            'name': item.name,
            'target_price': item.targetPrice,
            'current_price': item.currentPrice,
            'is_purchased': item.isPurchased ? 1 : 0,
            'image_path': item.imagePath,
            'date_added': item.dateAdded.toIso8601String(),
            'purchased_date': item.purchasedDate?.toIso8601String(),
            'sort_order': itemIndex,
          });

          final logs = List<PriceLog>.from(item.priceHistory)
            ..sort((a, b) => a.observedAt.compareTo(b.observedAt));
          for (final log in logs) {
            await txn.insert(_tablePriceLogs, {
              'item_id': item.id,
              'price': log.price,
              'observed_at': log.observedAt.toIso8601String(),
            });
          }
        }
      }
    });
  }

  Future<void> _migrateLegacySharedPreferencesIfNeeded(Database db) async {
    if (_checkedLegacyMigration) return;

    final prefs = await SharedPreferences.getInstance();
    final hasMigrated = prefs.getBool(_legacyMigratedFlagKey) ?? false;
    if (hasMigrated) {
      _checkedLegacyMigration = true;
      return;
    }

    final legacyJson = prefs.getString(_legacyCategoriesKey);
    if (legacyJson == null || legacyJson.isEmpty) {
      await prefs.setBool(_legacyMigratedFlagKey, true);
      _checkedLegacyMigration = true;
      return;
    }

    try {
      final List<dynamic> decodedList = jsonDecode(legacyJson);
      final categories = decodedList
          .map((json) => CategoryDto.fromJson(json as Map<String, dynamic>))
          .map((dto) => BudgetMapper.categoryToEntity(dto))
          .toList();

      if (categories.isNotEmpty) {
        await _writeAllCategories(db, categories);
      }
      await prefs.remove(_legacyCategoriesKey);
      await prefs.setBool(_legacyMigratedFlagKey, true);
    } catch (_) {
      await prefs.setBool(_legacyMigratedFlagKey, true);
    } finally {
      _checkedLegacyMigration = true;
    }
  }

  List<ShoppingCategory> _getDefaultCategories() {
    return [
      ShoppingCategory(
        id: 'c1',
        title: 'Quà biếu Tết',
        iconStr: '🎁',
        items: [
          ShoppingItem(
            id: 'i1',
            name: 'Giỏ quà ông bà',
            targetPrice: 1000000,
            currentPrice: 1200000,
            isPurchased: true,
            purchasedDate: DateTime.now().subtract(const Duration(days: 3)),
          ),
          ShoppingItem(
            id: 'i2',
            name: 'Biếu bố mẹ',
            targetPrice: 2000000,
            currentPrice: 2000000,
            isPurchased: true,
            purchasedDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      ),
      ShoppingCategory(
        id: 'c2',
        title: 'Bánh kẹo & Mứt',
        iconStr: '🍬',
        items: [
          ShoppingItem(
            id: 'i3',
            name: 'Hạt dưa',
            targetPrice: 100000,
            currentPrice: 110000,
            isPurchased: true,
            purchasedDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ShoppingItem(
            id: 'i4',
            name: 'Mứt dừa',
            targetPrice: 150000,
            currentPrice: 0,
            isPurchased: false,
          ),
        ],
      ),
      ShoppingCategory(
        id: 'c3',
        title: 'Trang trí nhà cửa',
        iconStr: '🏮',
        items: [
          ShoppingItem(
            id: 'i5',
            name: 'Cây đào/mai',
            targetPrice: 800000,
            currentPrice: 0,
            isPurchased: false,
          ),
          ShoppingItem(
            id: 'i6',
            name: 'Câu đối đỏ',
            targetPrice: 50000,
            currentPrice: 0,
            isPurchased: false,
          ),
        ],
      ),
      ShoppingCategory(
        id: 'c4',
        title: 'Tiền Lì Xì',
        iconStr: '🧧',
        items: [
          ShoppingItem(
            id: 'i7',
            name: 'Đổi tiền mới',
            targetPrice: 3000000,
            currentPrice: 0,
            isPurchased: false,
          ),
        ],
      ),
    ];
  }
}
