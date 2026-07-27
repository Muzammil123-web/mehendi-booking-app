import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showProductDialog(context, firestoreService),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Product>>(
        stream: firestoreService.streamProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(
                child: Text('No products yet. Tap + to add a henna cone.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.spa, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${AppConstants.currencySymbol}${p.price.toStringAsFixed(0)} • Stock: ${p.stock}',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      onPressed: () => _showProductDialog(context, firestoreService, product: p),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showProductDialog(BuildContext context, FirestoreService service, {Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name);
    final descCtrl = TextEditingController(text: product?.description);
    final priceCtrl = TextEditingController(text: product?.price.toStringAsFixed(0));
    final stockCtrl = TextEditingController(text: product?.stock.toString());
    final imageCtrl = TextEditingController(text: product?.imageUrl);
    final categoryCtrl = TextEditingController(text: product?.category ?? 'Henna Cone');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (₹)'), keyboardType: TextInputType.number),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newProduct = Product(
                id: product?.id ?? '',
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text) ?? 0,
                imageUrl: imageCtrl.text.trim(),
                stock: int.tryParse(stockCtrl.text) ?? 0,
                category: categoryCtrl.text.trim(),
              );
              if (product == null) {
                await service.addProduct(newProduct);
              } else {
                await service.updateProduct(newProduct);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
