class User {
  final String id;
  final String username;
  final String token;
  final String accountType;


  User({
    required this.id,
    required this.username,
    required this.token,
    required this.accountType,

  });

factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] ?? '',  // Default to empty string if null
    username: json['username'] ?? '',
    token: json['token'] ?? '',
    accountType: json['accountType'] ?? '',
  );
}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'token': token,
      'accountType': accountType,
    };
  }
}
