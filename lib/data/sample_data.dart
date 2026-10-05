import 'package:client/models/category.dart';
import 'package:client/models/product.dart';
import 'package:client/models/user.dart';
import 'package:flutter/material.dart';

// Demo accounts. Passwords are stored in plain text for testing only.
const users = [
  AppUser(
    username: 'admin',
    password: 'admin123',
    name: 'Bobby',
    role: Role.admin,
  ),
  AppUser(
    username: 'staff',
    password: 'staff123',
    name: 'Noy',
    role: Role.employee,
  ),
  AppUser(
    username: 'kitchen',
    password: 'kitchen123',
    name: 'Kham',
    role: Role.kitchen,
  ),
];

final tables = [for (var i = 1; i <= 12; i++) 'Table $i'];

const categories = [
  Category(id: 1, name: 'Drink', icon: Icons.local_drink_outlined),
  Category(id: 2, name: 'Fried', icon: Icons.set_meal_outlined),
  Category(id: 3, name: 'Soup', icon: Icons.soup_kitchen_outlined),
  Category(id: 4, name: 'Grilled', icon: Icons.outdoor_grill_outlined),
  Category(id: 5, name: 'Rice', icon: Icons.rice_bowl_outlined),
];

const products = [
  Product(id: 1, name: 'Lao beer', price: 25000, categoryId: 1, image: 'assets/images/products/Laobeer.jpg',),
  Product(id: 2, name: 'Fried French fries', price: 35000, categoryId: 2, image: 'assets/images/products/frenchfries.jpg',),
  Product(id: 3, name: 'Spicy prawn soup', price: 30000, categoryId: 3, image: 'assets/images/products/TomYumKung.jpg',),
  Product(id: 4, name: 'Fried chicken tendon', price: 45000, categoryId: 2, image: 'assets/images/products/Fried-chicken-tendon.jpg',),
  Product(id: 5, name: 'Fried yellow tendon', price: 30000, categoryId: 2, image: 'assets/images/products/FriedYellowTendon.jpg',),
  Product(id: 6, name: 'Grilled chicken', price: 60000, categoryId: 4, image: 'assets/images/products/grilledChicken.jpg',),
  Product(id: 7, name: 'Water', price: 5000, categoryId: 1, image: '',),
  Product(id: 8, name: 'Coca-Cola', price: 10000, categoryId: 1, image: '',),
  Product(id: 9, name: 'Tom yum soup', price: 40000, categoryId: 3, image: '',),
  Product(id: 10, name: 'Grilled pork', price: 50000, categoryId: 4, image: '',),
  Product(id: 11, name: 'Sticky rice', price: 5000, categoryId: 5, image: '',),
  Product(id: 12, name: 'Fried rice', price: 30000, categoryId: 5, image: '',),
];
