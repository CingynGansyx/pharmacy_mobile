import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'admin/add_medicine_screen.dart';
import 'admin/branches_screen.dart';
import 'admin/inventory_screen.dart';
import 'admin/reports_screen.dart';
import 'admin/stock_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class StaffHome extends StatefulWidget {
  const StaffHome({super.key});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _index = 0;

  static const _pages = <Widget>[
    InventoryScreen(),
    StockScreen(embedded: true),
    BranchesScreen(embedded: true),
    ReportsScreen(embedded: true),
    ProfileScreen(),
  ];

  static const _titles = [
    'Эмийн нөөц',
    'Баркод',
    'Салбарууд',
    'Тайлан',
    'Профайл',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Гарах',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              state.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _pages[_index],
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Эм нэмэх'),
            )
          : null,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSoft, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Нөөц',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner),
              label: 'Баркод',
            ),
            NavigationDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store),
              label: 'Салбар',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Тайлан',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Профайл',
            ),
          ],
        ),
      ),
    );
  }
}
