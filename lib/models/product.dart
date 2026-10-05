class Product {
  final int id;
  final String name;
  final int price;
  final int categoryId;
  final String? image;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.image,
  });
}
