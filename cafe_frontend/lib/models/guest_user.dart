class GuestUser {
  final String userId;
  final String role;

  const GuestUser({required this.userId, required this.role});

  static const guest = GuestUser(userId: '0', role: 'user');
}

