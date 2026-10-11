import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/hive_boxes.dart';
import '../data/models/shopping_cart.dart';

final cartsProvider =
    StateNotifierProvider<CartsNotifier, List<ShoppingCart>>((ref) {
  return CartsNotifier();
});

final pinnedCartProvider = Provider<ShoppingCart?>((ref) {
  final carts = ref.watch(cartsProvider);
  try {
    return carts.firstWhere((c) => c.isPinned);
  } catch (_) {
    return null;
  }
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

  Future<ShoppingCart> create({
    String title = '',
    String purpose = '',
  }) async {
    final cart = ShoppingCart(title: title, purpose: purpose);
    await _box.put(cart.id, cart);
    _load();
    return cart;
  }

  Future<void> updateCart(ShoppingCart cart) async {
    cart.updatedAt = DateTime.now();
    await _box.put(cart.id, cart);
    _load();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _load();
  }

  /// Only one cart may be pinned. Pinning this one unpins others.
  Future<void> setPinned(String id, {bool pinned = true}) async {
    for (final c in _box.values) {
      final shouldPin = pinned && c.id == id;
      if (c.isPinned != shouldPin) {
        c.isPinned = shouldPin;
        c.updatedAt = DateTime.now();
        await c.save();
      }
    }
    _load();
  }

  Future<void> togglePin(String id) async {
    final cart = _box.get(id);
    if (cart == null) return;
    if (cart.isPinned) {
      cart.isPinned = false;
      cart.updatedAt = DateTime.now();
      await cart.save();
    } else {
      await setPinned(id, pinned: true);
      return;
    }
    _load();
  }

  Future<void> addItem(String cartId, String name) async {
    final cart = _box.get(cartId);
    if (cart == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    cart.items = [...cart.items, CartItem(name: trimmed)];
    cart.updatedAt = DateTime.now();
    await cart.save();
    _load();
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
  }

  Future<void> removeItem(String cartId, String itemId) async {
    final cart = _box.get(cartId);
    if (cart == null) return;
    cart.items = cart.items.where((e) => e.id != itemId).toList();
    cart.updatedAt = DateTime.now();
    await cart.save();
    _load();
  }

  Future<void> renameCart(String cartId, {String? title, String? purpose}) async {
    final cart = _box.get(cartId);
    if (cart == null) return;
    if (title != null) cart.title = title.trim();
    if (purpose != null) cart.purpose = purpose.trim();
    cart.updatedAt = DateTime.now();
    await cart.save();
    _load();
  }

  ShoppingCart? getById(String id) => _box.get(id);
}
