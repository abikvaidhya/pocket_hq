import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../data/models/shopping_cart.dart';
import '../../providers/carts_provider.dart';

class CartDetailPage extends ConsumerStatefulWidget {
  final String? cartId;

  const CartDetailPage({super.key, this.cartId});

  @override
  ConsumerState<CartDetailPage> createState() => _CartDetailPageState();
}

class _CartDetailPageState extends ConsumerState<CartDetailPage> {
  final _itemsCtrl = TextEditingController();

  @override
  void dispose() {
    _itemsCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItems(ShoppingCart cart) async {
    final item = _itemsCtrl.text.trim();
    if (item.isEmpty) return;
    await ref.read(cartsProvider.notifier).addItems(cart.id, [item]);
    _itemsCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final carts = ref.watch(cartsProvider);
    ShoppingCart? cart;
    for (final value in carts) {
      if (widget.cartId == null || value.id == widget.cartId) {
        cart = value;
        break;
      }
    }

    if (cart == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('To Get')),
        body: const Center(child: Text('Shopping cart not found')),
      );
    }

    final items = cart.sortedItems;
    return Scaffold(
      appBar: AppBar(
        title: const Text('To Get'),
        actions: [
          PopupMenuButton<_CartAction>(
            tooltip: 'Shopping cart options',
            onSelected: (action) {
              if (action == _CartAction.clearChecked) {
                ref.read(cartsProvider.notifier).clearChecked(cart!.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _CartAction.clearChecked,
                enabled: cart!.checkedCount > 0,
                child: const Text('Clear checked items'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${cart.pendingCount} remaining · ${cart.checkedCount} checked',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Add an item below.\nChecked items move to the bottom.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final row = Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: CheckboxListTile(
                          value: item.checked,
                          onChanged: (_) => ref
                              .read(cartsProvider.notifier)
                              .toggleItem(cart!.id, item.id),
                          title: Text(
                            item.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              decoration: item.checked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.checked
                                  ? theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4)
                                  : null,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      );
                      if (!item.checked) return row;
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => ref
                            .read(cartsProvider.notifier)
                            .removeItem(cart!.id, item.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Iconsax.trash,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        child: row,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemsCtrl,
                    minLines: 1,
                    maxLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                    ],
                    onSubmitted: (_) => _addItems(cart!),
                    decoration: const InputDecoration(
                      hintText: 'Add an item…',
                      prefixIcon: Icon(Iconsax.add, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Add item',
                  onPressed: () => _addItems(cart!),
                  icon: const Icon(Iconsax.arrow_right_3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CartAction { clearChecked }
