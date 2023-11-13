import "dart:convert";

UserModel userModelJson(String str) => UserModel.fromJson(json.decode(str));

String userModeltoJson(UserModel data) => json.encode(data.toJson());
class UserModel {
  String email;
  String password;
  String nickname;
  String name;

  UserModel({required this.email, required this.password, required this.nickname , required this.name});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
      email: json["email"], nickname: json["nickname"], password: json["password"], name: json["name"]);

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
        "nickname": nickname,
        "name": name,
      };

  String get userEmail => email;
  String get userPassword => password;
  String get userNickname => nickname;
  String get userName => name;

}

