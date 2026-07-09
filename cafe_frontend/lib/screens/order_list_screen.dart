import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/order_bloc.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(FetchOrders());
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selesai':
        return Colors.green;
      case 'Diproses':
        return Colors.blue;
      case 'Menunggu':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Selesai':
        return Icons.check_circle;
      case 'Diproses':
        return Icons.autorenew;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderLoaded) {
            final orders = state.orders;
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Belum ada riwayat pesanan.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final menuName = order.menu?.name ?? 'Menu tidak diketahui';
                final status = order.status;
                final statusColor = _getStatusColor(status);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: nama menu + status badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(menuName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getStatusIcon(status), size: 14, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Detail
                        Row(
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text('Qty: ${order.quantity}', style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(width: 16),
                            Icon(Icons.payments_outlined, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text('Rp ${order.totalPrice}', style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Tombol selesaikan (hanya untuk status Menunggu)
                        if (status == 'Menunggu')
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                context.read<OrderBloc>().add(MarkOrderDone(orderId: order.id));
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Selesaikan'),
                              style: TextButton.styleFrom(foregroundColor: Colors.green),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          if (state is OrderError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Gagal memuat: ${state.message}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<OrderBloc>().add(FetchOrders()),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          // OrderActionLoading atau state lainnya: tetap tampilkan loading
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
