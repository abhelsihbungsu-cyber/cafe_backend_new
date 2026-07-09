import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

abstract class OrderEvent {}

class FetchOrders extends OrderEvent {}

class MarkOrderDone extends OrderEvent {
  final int orderId;
  MarkOrderDone({required this.orderId});
}

abstract class OrderState {}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  OrderLoaded({required this.orders});
}

class OrderActionLoading extends OrderState {
  /// orderId null = loading action tanpa spesifik order
  final int? orderId;
  OrderActionLoading({this.orderId});
}

class OrderError extends OrderState {
  final String message;
  OrderError({required this.message});
}

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final String baseUrl = "http://127.0.0.1:3000/api";

  OrderBloc() : super(OrderInitial()) {
    on<FetchOrders>((event, emit) async {
      emit(OrderLoading());

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        // TANPA LOGIN: tampilkan halaman riwayat kosong.
        if (token == null) {
          emit(OrderLoaded(orders: const []));
          return;
        }

        final res = await http.get(
          Uri.parse('$baseUrl/orders'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body);
          final orders = data.map((e) => Order.fromJson(e)).toList();
          emit(OrderLoaded(orders: orders));
        } else {
          emit(OrderError(message: 'Gagal mengambil riwayat pesanan'));
        }
      } catch (e) {
        emit(OrderError(message: e.toString()));
      }
    });

    on<MarkOrderDone>((event, emit) async {
      // UX: tampilkan loading spesifik order saat tombol “selesai” ditekan
      emit(OrderActionLoading(orderId: event.orderId));

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        // TANPA LOGIN: tidak bisa mengubah status order.
        // Tetap refresh list agar UX stabil.
        if (token == null) {
          emit(OrderError(message: 'Silakan login untuk mengubah status pesanan'));
          add(FetchOrders());
          return;
        }

        final res = await http.post(
          Uri.parse('$baseUrl/orders/${event.orderId}/complete'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (res.statusCode == 200) {
          add(FetchOrders());
        } else {
          final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
          final msg = data?['message'] ?? 'Gagal mengubah status pesanan';
          emit(OrderError(message: msg));
          add(FetchOrders());
        }
      } catch (e) {
        emit(OrderError(message: e.toString()));
        add(FetchOrders());
      }
    });
  }
}

