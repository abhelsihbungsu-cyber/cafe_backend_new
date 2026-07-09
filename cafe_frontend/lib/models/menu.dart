class Menu {
  final int id;
  final String name;
  final int price;
  final String category;

  Menu({required this.id, required this.name, required this.price, required this.category});

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      category: json['category'] ?? 'Uncategorized',
    );
  }
}
