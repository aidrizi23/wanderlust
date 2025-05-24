class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String email;
  final String password;
  final String confirmPassword;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'confirmPassword': confirmPassword,
    'firstName': firstName,
    'lastName': lastName,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
  };
}

class AuthResponse {
  final bool isSuccess;
  final String message;
  final String token;
  final String refreshToken;
  final DateTime expiration;
  final String userName;
  final String email;
  final List<String> roles;

  AuthResponse({
    required this.isSuccess,
    required this.message,
    required this.token,
    required this.refreshToken,
    required this.expiration,
    required this.userName,
    required this.email,
    required this.roles,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    isSuccess: json['isSuccess'] ?? false,
    message: json['message'] ?? '',
    token: json['token'] ?? '',
    refreshToken: json['refreshToken'] ?? '',
    expiration: DateTime.parse(
      json['expiration'] ?? DateTime.now().toIso8601String(),
    ),
    userName: json['userName'] ?? '',
    email: json['email'] ?? '',
    roles: List<String>.from(json['roles'] ?? []),
  );
}

class User {
  final String userName;
  final String email;
  final List<String> roles;

  User({required this.userName, required this.email, required this.roles});

  bool get isAdmin => roles.contains('Admin');
}
