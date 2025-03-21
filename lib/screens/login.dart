import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp/screens/mainpage1.dart';
import 'package:fyp/screens/signup.dart';
import 'package:fyp/widgets/button.dart';
import 'package:fyp/widgets/square_tile.dart';
import 'package:fyp/widgets/text_field.dart';
import 'forget.dart';
import 'package:fyp/screens/admin_dashboard.dart';
import 'package:fyp/utils/colors.dart';

class LoginScreen extends StatefulWidget {
  final Function()? onTap;
  const LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void singuserin() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Check if email and password fields are not empty
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      // Close the loading circle
      Navigator.pop(context);
      ShowErrorMessage("Please fill in all fields");
      return;
    }

    try {
      // sign in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Close the loading circle
      Navigator.pop(context);

      // Check if this is an admin account
      if (emailController.text.trim() == "admin@gmail.com") {
        // Navigate to admin dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
          (route) => false,
        );
      } else {
        // Navigate to normal user page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainPage1()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Close the loading circle
      Navigator.pop(context);

      // Show error message
      if (e.code == 'user-not-found') {
        ShowErrorMessage("No user found for that email");
      } else if (e.code == 'wrong-password') {
        ShowErrorMessage("Wrong password provided for that user");
      } else {
        ShowErrorMessage(e.message ?? "An error occurred during sign in");
      }
    }
  }


  void ShowErrorMessage(String msg) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.purple,
          title: Center(
            child: Text(
              msg,
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboard = MediaQuery
        .of(context)
        .viewInsets
        .bottom != 0;
    double height = MediaQuery
        .of(context)
        .size
        .height;
    return Scaffold(
      backgroundColor: const Color(0xFF3B57B2),
      body: SafeArea(
        child: SizedBox(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  // const Icon(
                  //   Icons.arrow_back_ios,
                  //   size: 20,
                  //   color: Colors.white,
                  // ),
                  const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Image.asset(
                    "asset/loginnn.png",
                    height: 200,
                    width: 300,
                  ),
                  TextFieldInput(
                    textEditingController: emailController,
                    hintText: "Enter your email",
                    obscureText: false,
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 10),
                  TextFieldInput(
                    textEditingController: passwordController,
                    hintText: "Enter your password",
                    obscureText: true,
                    icon: Icons.password,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 35),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        // Shrink-wrap the row to its content
                        children: [
                          GestureDetector(
                            onTap: (){
                              Navigator.push(
                                context, MaterialPageRoute(
                                  builder: (context){
                                    return ForgotPasswordScreen();
                                  },
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot your password?",
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          // Add some spacing between text and icon
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.amber,
                            size: 16, // Adjust size to match the text
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Button(
                    text: "LOGIN",
                    onTap: singuserin,
                  ),
                  const SizedBox(height: 25),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "or continue with",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Create a new account:',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignupScreen(onTap: widget.onTap)),
                            );
                          },  // Calls togglePages() from LoginOrRegister
                        child: const Text(
                          'Register Now',
                          style: TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
        ),
      ),
    );
  }
}