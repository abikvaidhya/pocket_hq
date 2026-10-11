// GENERATED CODE — manual adapters for CartItem + ShoppingCart

part of 'shopping_cart.dart';

class CartItemAdapter extends TypeAdapter<CartItem> {
  @override
  final int typeId = 5;

  @override
  CartItem read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return CartItem(
      id: fields[0] as String,
      name: fields[1] as String? ?? '',
      checked: fields[2] as bool? ?? false,
      createdAt: fields[3] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, CartItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.checked)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}

class ShoppingCartAdapter extends TypeAdapter<ShoppingCart> {
  @override
  final int typeId = 6;

  @override
  ShoppingCart read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return ShoppingCart(
      id: fields[0] as String,
      title: fields[1] as String? ?? '',
      purpose: fields[2] as String? ?? '',
      isPinned: fields[3] as bool? ?? false,
      items: (fields[4] as List?)?.cast<CartItem>() ?? <CartItem>[],
      createdAt: fields[5] as DateTime? ?? DateTime.now(),
      updatedAt: fields[6] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingCart obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.purpose)
      ..writeByte(3)
      ..write(obj.isPinned)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }
}
