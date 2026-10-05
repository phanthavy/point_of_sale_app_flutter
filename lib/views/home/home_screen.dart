import 'package:client/models/user.dart';
import 'package:client/state/auth_store.dart';
import 'package:client/state/pos_store.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/views/history/history_screen.dart';
import 'package:client/views/kitchen/kitchen_screen.dart';
import 'package:client/views/order/order_screen.dart';
import 'package:client/views/product/product_list.dart';
import 'package:client/views/stats/stats_screen.dart';
import 'package:flutter/material.dart';

class _AppTab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
  final Set<Role> roles;
  final int Function()? badgeCount;

  const _AppTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
    required this.roles,
    this.badgeCount,
  });
}

final _allTabs = [
  const _AppTab(
    label: 'Product',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
    page: ProductList(),
    roles: {Role.admin, Role.employee},
  ),
  _AppTab(
    label: 'Orders',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
    page: const OrderScreen(),
    roles: const {Role.admin, Role.employee},
    badgeCount: () => posStore.cartCount,
  ),
  _AppTab(
    label: 'Kitchen',
    icon: Icons.soup_kitchen_outlined,
    selectedIcon: Icons.soup_kitchen,
    page: const KitchenScreen(),
    roles: const {Role.admin, Role.kitchen},
    badgeCount: () => posStore.pendingTickets.length,
  ),
  const _AppTab(
    label: 'History',
    icon: Icons.history,
    selectedIcon: Icons.history,
    page: HistoryScreen(),
    roles: {Role.admin, Role.employee},
  ),
  const _AppTab(
    label: 'Stats',
    icon: Icons.bar_chart,
    selectedIcon: Icons.bar_chart,
    page: StatsScreen(),
    roles: {Role.admin},
  ),
];

class HomeScreen extends StatefulWidget {
  final AppUser user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  late final _tabs = _allTabs
      .where((tab) => tab.roles.contains(widget.user.role))
      .toList();

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: Text('Signed in as ${widget.user.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    posStore.clearCart();
    authStore.logout();
  }

  void _showProfile() {
    final user = widget.user;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.account_circle,
          size: 56,
          color: AppColors.primary,
        ),
        title: Text(user.name),
        content: Text(
          'Role: ${user.role.label}\nUsername: ${user.username}',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _badgeIcon(_AppTab tab, IconData icon) {
    final count = tab.badgeCount?.call() ?? 0;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        toolbarHeight: 72,
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 2),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'POS SYSTEM',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Bobby Restaurant · ${widget.user.name} (${widget.user.role.label})',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton.filled(
            tooltip: 'Logout',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.danger,
              fixedSize: const Size(44, 44),
            ),
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Profile',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F3F2),
              side: const BorderSide(color: AppColors.border, width: 2),
              fixedSize: const Size(44, 44),
            ),
            onPressed: _showProfile,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [for (final tab in _tabs) tab.page],
      ),
      bottomNavigationBar: _tabs.length < 2
          ? null
          : ListenableBuilder(
              listenable: posStore,
              builder: (context, _) => NavigationBar(
                backgroundColor: Colors.white,
                indicatorColor: AppColors.primaryLight,
                selectedIndex: _tabIndex,
                onDestinationSelected: (i) => setState(() => _tabIndex = i),
                destinations: [
                  for (final tab in _tabs)
                    NavigationDestination(
                      icon: _badgeIcon(tab, tab.icon),
                      selectedIcon: _badgeIcon(tab, tab.selectedIcon),
                      label: tab.label,
                    ),
                ],
              ),
            ),
    );
  }
}
