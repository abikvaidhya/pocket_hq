import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'shopping_cart.g.dart';

@HiveType(typeId: 5)
class CartItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late bool checked;

  @HiveField(3)
  late DateTime createdAt;

  CartItem({
    String? id,
    required this.name,
    this.checked = false,
    DateTime? createdAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }
}

@HiveType(typeId: 6)
class ShoppingCart extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  /// Optional purpose tag e.g. Grocery, Car parts
  @HiveField(2)
  late String purpose;

  @HiveField(3)
  late bool isPinned;

  @HiveField(4)
  late List<CartItem> items;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  ShoppingCart({
    String? id,
    this.title = '',
    this.purpose = '',
    this.isPinned = false,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.items = items ?? <CartItem>[];
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  int get totalCount => items.length;
  int get checkedCount => items.where((e) => e.checked).length;
  int get pendingCount => totalCount - checkedCount;

  /// Unchecked first (original order), checked at bottom.
  List<CartItem> get sortedItems {
    final pending = items.where((e) => !e.checked).toList();
    final done = items.where((e) => e.checked).toList();
    return [...pending, ...done];
  }

  String get preview {
    final t = title.trim();
    if (t.isNotEmpty) return t;
    final p = purpose.trim();
    if (p.isNotEmpty) return p;
    return 'Shopping list';
  }
}
