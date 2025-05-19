class User {
  final String ra;
  final String phone;
  final bool isAdmin;

  User({
    required this.ra,
    required this.phone,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      ra: json['ra'],
      phone: json['phone'],
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ra': ra,
      'phone': phone,
      'isAdmin': isAdmin,
    };
  }
}
