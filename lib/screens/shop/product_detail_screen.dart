import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.accent.withOpacity(0.2),
                      child: const Icon(Icons.spa, size: 80, color: AppColors.accent),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category,
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(product.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${AppConstants.currencySymbol}${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      StreamBuilder<List<Review>>(
                        stream: FirestoreService().streamReviewsForTarget(product.id),
                        builder: (context, snap) {
                          final reviews = snap.data ?? [];
                          final avg = reviews.isEmpty
                              ? product.rating
                              : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                                  reviews.length;
                          return Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                              const SizedBox(width: 2),
                              Text(
                                reviews.isEmpty
                                    ? '${avg.toStringAsFixed(1)}'
                                    : '${avg.toStringAsFixed(1)} (${reviews.length})',
                                style: const TextStyle(color: AppColors.textLight),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.stock > 0 ? '${product.stock} in stock' : 'Out of stock',
                    style: TextStyle(
                        color: product.stock > 0 ? AppColors.success : AppColors.error,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'Premium quality natural henna cone, finely sifted and hand-rolled for smooth, long-lasting stain. Free from harmful chemicals.',
                    style: const TextStyle(color: AppColors.textLight, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Review>>(
                    stream: FirestoreService().streamReviewsForTarget(product.id),
                    builder: (context, snap) {
                      final reviews = snap.data ?? [];
                      if (reviews.isEmpty) {
                        return const Text('No reviews yet — be the first to try it!',
                            style: TextStyle(color: AppColors.textLight, fontSize: 13));
                      }
                      return Column(
                        children: reviews.take(5).map((r) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(r.userName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(width: 6),
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        i < r.rating ? Icons.star : Icons.star_border,
                                        size: 13,
                                        color: Colors.amber.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (r.comment.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(r.comment,
                                        style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _qtyButton(Icons.remove, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_quantity',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      _qtyButton(Icons.add, () => setState(() => _quantity++)),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
        ),
        child: SafeArea(
          child: CustomButton(
            label: product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
            onPressed: product.stock > 0
                ? () {
                    context.read<CartProvider>().addToCart(product, quantity: _quantity);
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const CartScreen()));
                  }
                : null,
            icon: Icons.shopping_bag_outlined,
          ),
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
