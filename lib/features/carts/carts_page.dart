import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../data/models/shopping_cart.dart';
import '../../providers/carts_provider.dart';
import '../../services/widget_sync_service.dart';
import 'cart_detail_page.dart';

class CartsPage extends ConsumerWidget {
  const CartsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carts = ref.watch(cartsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping carts'),
        actions: [
          IconButton(
            tooltip: 'New cart',
            onPressed: () => _createCart(context, ref),
            icon: const Icon(Iconsax.add),
          ),
        ],
      ),
      body: carts.isEmpty
          ? _Empty(onAdd: () => _createCart(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: carts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cart = carts[index];
                return _CartCard(
                  cart: cart,
                  onOpen: () => _openCart(context, ref, cart),
                  onPin: () async {
                    await ref.read(cartsProvider.notifier).togglePin(cart.id);
                    await WidgetSyncService.instance.sync(ref);
                  },
                  onDelete: () => _confirmDelete(context, ref, cart),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCart(context, ref),
        icon: const Icon(Iconsax.shopping_cart),
        label: const Text('New cart'),
      ),
    );
  }

  Future<void> _createCart(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New shopping cart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Weekend grocery',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: purposeCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Purpose (optional)',
                hintText: 'Grocery, car parts, home…',
              ),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final cart = await ref.read(cartsProvider.notifier).create(
          title: titleCtrl.text.trim().isEmpty
              ? 'Shopping list'
              : titleCtrl.text.trim(),
          purpose: purposeCtrl.text.trim(),
        );
    if (!context.mounted) return;
    await _openCart(context, ref, cart);
  }

  Future<void> _openCart(
    BuildContext context,
    WidgetRef ref,
    ShoppingCart cart,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CartDetailPage(cartId: cart.id)),
    );
    // Auto-saved in detail page; refresh widget when returning
    await WidgetSyncService.instance.sync(ref);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ShoppingCart cart,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cart?'),
        content: Text('“${cart.preview}” and its items will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(cartsProvider.notifier).delete(cart.id);
      await WidgetSyncService.instance.sync(ref);
    }
  }
}

class _CartCard extends StatelessWidget {
  final ShoppingCart cart;
  final VoidCallback onOpen;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _CartCard({
    required this.cart,
    required this.onOpen,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d');

    return Dismissible(
      key: ValueKey(cart.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Iconsax.trash, color: theme.colorScheme.error),
      ),
      child: Card(
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (cart.isPinned) ...[
                      Icon(
                        Iconsax.attach_circle5,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Iconsax.shopping_cart,
                      size: 16,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cart.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onPin,
                      tooltip: cart.isPinned ? 'Unpin' : 'Pin to widget',
                      icon: Icon(
                        cart.isPinned
                            ? Iconsax.attach_circle5
                            : Iconsax.attach_circle,
                        size: 20,
                        color: cart.isPinned
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (cart.purpose.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    cart.purpose,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${cart.pendingCount} left · ${cart.checkedCount} done',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateFmt.format(cart.updatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;
  const _Empty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.shopping_cart,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No shopping carts',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a list for grocery, car parts, or anything else.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Iconsax.add),
              label: const Text('New cart'),
            ),
          ],
        ),
      ),
    );
  }
}
