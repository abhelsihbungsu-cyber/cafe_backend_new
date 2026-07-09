import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  LoginRequested(this.username, this.password);
}

class RegisterRequested extends AuthEvent {
  final String username;
  final String password;
  RegisterRequested(this.username, this.password);
}

class LogoutRequested extends AuthEvent {}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final String userId;
  final String role;

  AuthSuccess({required this.userId, required this.role});
}
class AuthRegistered extends AuthState {}
class AuthFailure extends AuthState {
  final String error;
  AuthFailure({required this.error});
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Gunakan 127.0.0.1 agar konsisten untuk emulator/device & Flutter Web.
  final String baseUrl = "http://127.0.0.1:3000/api";


  AuthBloc() : super(AuthInitial()) {
    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': event.username, 'password': event.password}),
        );
        if (res.statusCode == 201) {
          emit(AuthRegistered());
        } else {
          final data = jsonDecode(res.body);
          emit(AuthFailure(error: data['message'] ?? 'Gagal mendaftar'));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString()));
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': event.username, 'password': event.password}),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          final userId = data['userId'] ?? '';
          final role = data['role'] ?? 'user';
          emit(AuthSuccess(userId: userId.toString(), role: role.toString()));

        } else {
          final data = jsonDecode(res.body);
          emit(AuthFailure(error: data['message'] ?? 'Gagal login'));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString()));
      }
    });

    on<LogoutRequested>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      emit(AuthInitial());
    });
  }
}