import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../data/models/shopping_cart.dart';
import '../../providers/carts_provider.dart';

/// Edits items live — no Save button; Hive writes on every change.
class CartDetailPage extends ConsumerStatefulWidget {
  final String cartId;

  const CartDetailPage({super.key, required this.cartId});

  @override
  ConsumerState<CartDetailPage> createState() => _CartDetailPageState();
}

class _CartDetailPageState extends ConsumerState<CartDetailPage> {
  final _itemCtrl = TextEditingController();
  final _itemFocus = FocusNode();

  @override
  void dispose() {
    _itemCtrl.dispose();
    _itemFocus.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final text = _itemCtrl.text;
    if (text.trim().isEmpty) return;
    await ref.read(cartsProvider.notifier).addItem(widget.cartId, text);
    _itemCtrl.clear();
    _itemFocus.requestFocus();
  }

  Future<void> _editTitle(ShoppingCart cart) async {
    final titleCtrl = TextEditingController(text: cart.title);
    final purposeCtrl = TextEditingController(text: cart.purpose);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit cart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: purposeCtrl,
              decoration: const InputDecoration(labelText: 'Purpose'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(cartsProvider.notifier).renameCart(
            widget.cartId,
            title: titleCtrl.text,
            purpose: purposeCtrl.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final carts = ref.watch(cartsProvider);
    ShoppingCart? cart;
    for (final c in carts) {
      if (c.id == widget.cartId) {
        cart = c;
        break;
      }
    }

    if (cart == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(child: Text('Cart not found')),
      );
    }

    final items = cart.sortedItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(cart.preview),
        actions: [
          IconButton(
            tooltip: cart.isPinned ? 'Unpin from widget' : 'Pin to widget',
            onPressed: () =>
                ref.read(cartsProvider.notifier).togglePin(cart!.id),
            icon: Icon(
              cart.isPinned ? Iconsax.attach_circle5 : Iconsax.attach_circle,
              color: cart.isPinned ? theme.colorScheme.primary : null,
            ),
          ),
          IconButton(
            tooltip: 'Edit name',
            onPressed: () => _editTitle(cart!),
            icon: const Icon(Iconsax.edit_2),
          ),
        ],
      ),
      body: Column(
        children: [
          if (cart.purpose.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  cart.purpose,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemCtrl,
                    focusNode: _itemFocus,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addItem(),
                    decoration: const InputDecoration(
                      hintText: 'Add item…',
                      prefixIcon: Icon(Iconsax.add, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addItem,
                  icon: const Icon(Iconsax.arrow_right_3),
                ),
              ],
            ),
          ),
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
                      'Add items above.\nChecked items move to the bottom.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          ref
                              .read(cartsProvider.notifier)
                              .removeItem(widget.cartId, item.id);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Iconsax.trash,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: CheckboxListTile(
                            value: item.checked,
                            onChanged: (_) {
                              ref
                                  .read(cartsProvider.notifier)
                                  .toggleItem(widget.cartId, item.id);
                            },
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
