class UserModel {
  String? uid;
  String? fullname;
  String? email;
  String? profilepic; // Should be of type String?

  UserModel({this.uid, this.fullname, this.email, this.profilepic});

  // Factory method to create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      fullname: map['fullname'],
      email: map['email'],
      profilepic: map['profilepic'], // Ensure profilepic is assigned correctly
    );
  }

  // Method to convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullname': fullname,
      'email': email,
      'profilepic': profilepic,
    };
  }
}