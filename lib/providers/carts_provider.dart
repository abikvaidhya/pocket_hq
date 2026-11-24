import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/hive_boxes.dart';
import '../data/models/shopping_cart.dart';
import '../core/widget_sync_bus.dart';

final cartsProvider =
    StateNotifierProvider<CartsNotifier, List<ShoppingCart>>((ref) {
  return CartsNotifier();
});

final pinnedCartProvider = Provider<ShoppingCart?>((ref) {
  final carts = ref.watch(cartsProvider);
  return carts.isEmpty ? null : carts.first;
});

class CartsNotifier extends StateNotifier<List<ShoppingCart>> {
  CartsNotifier() : super([]) {
    _load();
  }

  Box<ShoppingCart> get _box => Hive.box<ShoppingCart>(HiveBoxes.shoppingCarts);

  void _load() {
    final list = _box.values.toList();
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    state = list;
  }

  Future<void> updateCart(ShoppingCart cart) async {
    cart.updatedAt = DateTime.now();
    await _box.put(cart.id, cart);
    _load();
    WidgetSyncBus.notify(WidgetSyncSection.carts);
  }

  Future<void> addItems(String cartId, Iterable<String> names) async {
    final cart = _box.get(cartId);
    if (cart == null) return;
    final items = names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .map((name) => CartItem(name: name))
        .toList();
    if (items.isEmpty) return;
    cart.items = [...cart.items, ...items];
    cart.updatedAt = DateTime.now();
    await cart.save();
    _load();
    WidgetSyncBus.notify(WidgetSyncSection.carts);
  }

  Future<void> toggleItem(String cartId, String itemId) async {
    final cart = _box.get(cartId);
    if (cart == null) return;
    final items = cart.items.map((e) {
      if (e.id == itemId) {
        return CartItem(
          id: e.id,
          name: e.name,
          checked: !e.checked,
          createdAt: e.createdAt,
        );
      }
      return e;
    }).toList();
    cart.items = items;
    cart.updatedAt = DateTime.now();
    await cart.save();
    _load();
    WidgetSyncBus.notify(WidgetSyncSection.carts);
  }

  Future<void> renameItem(String cartId, String itemId, String name) async {
    final cart = _box.get(cartId);
    if (cart == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    cart.items = cart.items.map((e) {
      if (e.id == itemId) {
        return CartItem(
          id: e.id,
          name: trimmed,
          checked: e.checked,
          createdAt: e.createdAt,
        );
      }
      return e;
    }).toList();
    cart.updatedAt = DateTime.now();
    await cart.save();
    _load();
    WidgetSyncBus.notify(WidgetSyncSection.carts);
  }

  Future<void> removeItem(String cartId, String itemId) async {
    final cart = _box.get(cartId);
    if (cart == null) return;
    cart.items = cart.items.where((e) => e.id != itemId).toList();
    cart.updatedAt = DateTime.now();
    await cart.save();
    _load();
    WidgetSyncBus.notify(WidgetSyncSection.carts);
  }

  Future<void> clearChecked(String cartId) async {
    final cart = _box.get(cartId);
    if (cart == null) return;
    cart.items = cart.items.where((item) => !item.checked).toList();
    cart.updatedAt = DateTime.now();
    await cart.save();
    _load();
    WidgetSyncBus.notify(WidgetSyncSection.carts);
  }

  ShoppingCart? get cart => _box.values.isEmpty ? null : _box.values.first;

  Future<void> toggleItemById(String itemId) async {
    final cart = this.cart;
    if (cart != null) await toggleItem(cart.id, itemId);
  }
}
