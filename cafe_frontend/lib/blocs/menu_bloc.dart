import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu.dart';

// Events
abstract class MenuEvent {}

class FetchMenus extends MenuEvent {}

class PlaceOrder extends MenuEvent {
  final int menuId;
  final int quantity;
  PlaceOrder({required this.menuId, required this.quantity});
}

// States
abstract class MenuState {}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<Menu> menus;
  MenuLoaded({required this.menus});
}

class MenuError extends MenuState {
  final String message;
  MenuError({required this.message});
}

class OrderSuccess extends MenuState {
  final String message;
  OrderSuccess({required this.message});
}

class OrderFailure extends MenuState {
  final String error;
  OrderFailure({required this.error});
}

// BLoC
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final String baseUrl = "http://localhost:3000/api";

  MenuBloc() : super(MenuInitial()) {
    on<FetchMenus>((event, emit) async {
      emit(MenuLoading());
      try {
        final res = await http.get(Uri.parse('$baseUrl/menus'));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body);
          final menus = data.map((e) => Menu.fromJson(e)).toList();
          emit(MenuLoaded(menus: menus));
        } else {
          emit(MenuError(message: 'Gagal mengambil menu'));
        }
      } catch (e) {
        emit(MenuError(message: e.toString()));
      }
    });

    on<PlaceOrder>((event, emit) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) {
          // Bypass login agar user bisa tetap pesan tanpa autentikasi.
          // Untuk versi asli, token null harusnya mengarah ke login.
          final res = await http.post(
            Uri.parse('$baseUrl/orders'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'menuId': event.menuId,
              'quantity': event.quantity,
            }),
          );

          if (res.statusCode == 201) {
            final data = jsonDecode(res.body);
            emit(OrderSuccess(message: data['message'] ?? 'Pesanan berhasil dibuat!'));
            add(FetchMenus());
          } else {
            final data = jsonDecode(res.body);
            emit(OrderFailure(error: data['message'] ?? 'Gagal membuat pesanan'));
            add(FetchMenus());
          }
          return;
        }


        final res = await http.post(
          Uri.parse('$baseUrl/orders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'menuId': event.menuId,
            'quantity': event.quantity,
          }),
        );

        if (res.statusCode == 201) {
          final data = jsonDecode(res.body);
          emit(OrderSuccess(message: data['message'] ?? 'Pesanan berhasil dibuat!'));
          // Re-fetch menus or just return to loaded state
          add(FetchMenus());
        } else {
          final data = jsonDecode(res.body);
          emit(OrderFailure(error: data['message'] ?? 'Gagal membuat pesanan'));
          add(FetchMenus());
        }
      } catch (e) {
        emit(OrderFailure(error: e.toString()));
        add(FetchMenus());
      }
    });
  }
}
