// // TODO Implement this library.
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:sentichat/pages/SignUpPage.dart';
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 40,
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 RichText(
//                   text: TextSpan(
//                     children: [
//                       TextSpan(
//                         text: 'Senti',
//                         style: TextStyle(
//                           color: Color(0xFF663187), // Or any desired color for "Senti"
//                           fontSize: 40,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       TextSpan(
//                         text: 'Chat',
//                         style: TextStyle(
//                           color: Color(0xFFC490D1), // Or any desired color for "Chat"
//                           fontSize: 40,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 TextField(
//                   decoration: InputDecoration(
//                     labelText: "Email Address"
//                   ),
//                 ),
//                 SizedBox(height: 10,),
//                 TextField(
//                   obscureText: true,
//                   decoration: InputDecoration(
//                     labelText: "Password"
//                   ),
//                 ),
//                 SizedBox(height: 20,),
//                 CupertinoButton(
//                   child: Text("Log In"),
//                     onPressed: () {},
//                 color: Theme.of(context).colorScheme.secondary,
//                 )
//               ],
//             ),
//           ),
//         ),
//     ),
//       ),
//       bottomNavigationBar: Container(
//         child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text("Don't have an account?",style: TextStyle(
//             fontSize: 16
//           ),),
//           CupertinoButton(
//               child: Text("Sign up",style: TextStyle(
//             fontSize: 16
//           ),), onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context)
//                   {
//                     return SignUpPage();
//                   })
//                 );
//           })
//         ],
//     ),
//     ),
//     );
//   }
// }
import 'package:sentichat/models/UIHelper.dart';
import 'package:sentichat/models/UserModel.dart';
import 'package:sentichat/pages/HomePage.dart';
import 'package:sentichat/pages/SignUpPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({ Key? key }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void checkValues() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if(email == "" || password == "") {
      UIHelper.showAlertDialog(context, "Incomplete Data", "Please fill all the fields");
    }
    else {
      logIn(email, password);
    }
  }

  void logIn(String email, String password) async {
    UserCredential? credential;

    UIHelper.showLoadingDialog(context, "Logging In..");

    try {
      credential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch(ex) {
      // Close the loading dialog
      Navigator.pop(context);

      // Show Alert Dialog
      UIHelper.showAlertDialog(context, "An error occured", ex.message.toString());
    }

    if(credential != null) {
      String uid = credential.user!.uid;

      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      UserModel userModel = UserModel.fromMap(userData.data() as Map<String, dynamic>);

      // Go to HomePage
      print("Log In Successful!");
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) {
              return HomePage(userModel: userModel, firebaseUser: credential!.user!);
            }
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 40,
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Senti',
                          style: TextStyle(
                            color: Color(0xFF663187), // Or any desired color for "Senti"
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: 'Chat',
                          style: TextStyle(
                            color: Color(0xFFC490D1), // Or any desired color for "Chat"
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10,),

                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                        labelText: "Email Address"
                    ),
                  ),

                  SizedBox(height: 10,),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: "Password"
                    ),
                  ),

                  SizedBox(height: 20,),

                  CupertinoButton(
                    onPressed: () {
                      checkValues();
                    },
                    color: Theme.of(context).colorScheme.secondary,
                    child: Text("Log In"),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text("Don't have an account?", style: TextStyle(
                fontSize: 16
            ),),

            CupertinoButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) {
                        return SignUpPage();
                      }
                  ),
                );
              },
              child: Text("Sign Up", style: TextStyle(
                  fontSize: 16
              ),),
            ),

          ],
        ),
      ),
    );
  }
}