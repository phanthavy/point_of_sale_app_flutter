import 'package:client/data/sample_data.dart';
import 'package:client/state/pos_store.dart';
import 'package:client/views/category/category_chips.dart';
import 'package:client/views/product/product_card.dart';
import 'package:flutter/material.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategoryId == null
        ? products
        : products.where((p) => p.categoryId == _selectedCategoryId).toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        CategoryChips(
          categories: categories,
          selectedId: _selectedCategoryId,
          onSelected: (id) => setState(() => _selectedCategoryId = id),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No products in this category'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return ListenableBuilder(
                      listenable: posStore,
                      builder: (context, _) => ProductCard(
                        product: product,
                        quantity: posStore.quantityOf(product.id),
                        onAdd: () => posStore.add(product),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
