# TODO

## Implement “Tidak mau login” (direct to Home)
- [ ] Update `cafe_frontend/lib/main.dart` to route to `HomeScreen` by default.
- [ ] Update `cafe_frontend/lib/blocs/menu_bloc.dart`, `cafe_frontend/lib/blocs/order_bloc.dart` to allow actions without token (optional / bypass).
- [ ] Update `HomeScreen` auth listener to not force back to `LoginScreen`.
- [ ] Verify navigation flow: app starts -> HomeScreen -> place order -> view order list.

