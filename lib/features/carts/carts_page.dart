import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/carts_provider.dart';
import 'cart_detail_page.dart';

class CartsPage extends ConsumerWidget {
  const CartsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carts = ref.watch(cartsProvider);
    if (carts.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return CartDetailPage(cartId: carts.first.id);
  }
}
