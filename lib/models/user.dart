  class User {
    final String id;
    final String username;
    final String token; // ✅ Make sure this is defined
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
      token: json['token'] ?? '', // ✅ Ensure this is mapped
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

      User copyWith({
    String? id,
    String? username,
    String? token,
    String? accountType,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      token: token ?? this.token,
      accountType: accountType ?? this.accountType,
    );
  }
  }
