import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'medicines_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _index = 0;

  static const _pages = <Widget>[
    MedicinesScreen(),
    CartScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  static const _titles = ['Эмийн жагсаалт', 'Сагс', 'Хэтэвч', 'Профайл'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
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
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSoft, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.medication_outlined),
              selectedIcon: Icon(Icons.medication),
              label: 'Эм',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('${state.cartCount}'),
                isLabelVisible: state.cartCount > 0,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_bag),
              label: 'Сагс',
            ),
            const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Хэтэвч',
            ),
            const NavigationDestination(
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
