import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/menu_bloc.dart';
import '../models/menu.dart';
import 'login_screen.dart';
import 'order_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showOrderDialog(BuildContext parentContext, Menu menu) {
    final menuBloc = parentContext.read<MenuBloc>();
    int quantity = 1;
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Pesan ${menu.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Harga: Rp ${menu.price}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() => quantity--);
                          }
                        },
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() => quantity++);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Total: Rp ${menu.price * quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    menuBloc.add(PlaceOrder(menuId: menu.id, quantity: quantity));
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                  child: const Text('Pesan Sekarang'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildMenuList(List<Menu> menuList, BuildContext context) {
    if (menuList.isEmpty) {
      return const Center(child: Text('Tidak ada menu di kategori ini.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: menuList.length,
      itemBuilder: (context, index) {
        final menu = menuList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.brown[100],
              child: Icon(
                menu.category == 'Kopi' ? Icons.coffee
                    : menu.category == 'Non-Kopi' ? Icons.local_drink
                    : Icons.fastfood,
                color: Colors.brown,
              ),
            ),
            title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rp ${menu.price}', style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.w600)),
                Text(menu.category, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showOrderDialog(context, menu),
              child: const Text('Pesan'),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthInitial) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
        ),
        BlocListener<MenuBloc, MenuState>(
          listener: (context, state) {
            if (state is OrderSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
            } else if (state is OrderFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error), backgroundColor: Colors.red));
            }
          },
        ),
      ],
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Menu Cafe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.brown[700],
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long, color: Colors.white),
                tooltip: 'Riwayat Pesanan',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListScreen()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Keluar',
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                },
              ),
            ],
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Semua'),
                Tab(text: 'Kopi'),
                Tab(text: 'Non-Kopi'),
                Tab(text: 'Snack'),
              ],
            ),
          ),
          body: BlocBuilder<MenuBloc, MenuState>(
            buildWhen: (previous, current) => current is MenuLoading || current is MenuLoaded || current is MenuError,
            builder: (context, state) {
              if (state is MenuLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is MenuError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(state.message, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<MenuBloc>().add(FetchMenus()),
                        child: const Text('Coba Lagi'),
                      )
                    ],
                  ),
                );
              } else if (state is MenuLoaded) {
                final menus = state.menus;
                if (menus.isEmpty) {
                  return const Center(child: Text('Belum ada menu tersedia.'));
                }
                
                final kKopi = menus.where((m) => m.category == 'Kopi').toList();
                final kNonKopi = menus.where((m) => m.category == 'Non-Kopi').toList();
                final kSnack = menus.where((m) => m.category == 'Snack').toList();

                return TabBarView(
                  children: [
                    _buildMenuList(menus, context),
                    _buildMenuList(kKopi, context),
                    _buildMenuList(kNonKopi, context),
                    _buildMenuList(kSnack, context),
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}
