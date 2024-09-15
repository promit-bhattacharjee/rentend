import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentend/Components/AuthAppBar.dart';
import '../layout/HomeActivity.dart';
import 'SignupActivity.dart';
import '../Components/DefaultSnackBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Data/UserData.dart';

class UserLogin extends StatefulWidget {
  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Future<String> getUserData(email) async {
    var JsonData = await UserData().getUserData(_emailController.text);
    return JsonData;
    // try {
    //   FirebaseFirestore firestore = FirebaseFirestore.instance;
    //   var querySnapshot = await firestore.collection('users')
    //       .where("email", isEqualTo: email)
    //       .get();
    //   final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
    //   if(allData[0].isNotEmpty)
    //     {
    //       return jsonEncode(allData[0]).toString();
    //     }
    //   else{
    //     return "false";
    //   }
    // } catch (e) {
    //   print('Error: $e');
    //   return "false";
    // }
  }

  Future<void> setLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('user', true);
    prefs.setString('email', _emailController.text);
  }

  void checkLogin(BuildContext context) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Assuming getUserData returns a Future<String>
      await setLoginStatus();
      DefaultSnackbar.SuccessSnackBar("SuccessFully Loged In ", context);
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushNamed(context, "/homePage");
      });
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth exceptions
      DefaultSnackbar.AlertSnackBar(e.code, context);
    } catch (e) {
      // Handle other exceptions
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AuthAppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: () => checkLogin(context),
                child: Text("Submit"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, "/ChangePassword");
                      },
                      child: Text("Forget Password"),
                      style: TextButton.styleFrom(
                        minimumSize: Size(50, 50),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignupActivity()),
                        );
                      },
                      child: Text("Sign Up"),
                      style: TextButton.styleFrom(
                        minimumSize: Size(50, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
