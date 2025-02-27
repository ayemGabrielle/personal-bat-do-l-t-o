class User {
  final String id;
  final String username;
  final String access_token;
  final String accountType;


  User({
    required this.id,
    required this.username,
    required this.access_token,
    required this.accountType,

  });

factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] ?? '',  // Default to empty string if null
    username: json['username'] ?? '',
    access_token: json['access_token'] ?? '',
    accountType: json['accountType'] ?? '',
  );
}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'access_token': access_token,
      'accountType': accountType,
    };
  }
}
