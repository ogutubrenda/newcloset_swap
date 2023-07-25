
import 'package:betterclosetswap/pages/login_page.dart';
import 'package:betterclosetswap/widgets/textinputs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
final _emailController = TextEditingController();
  @override
  void dispose(){
    _emailController.dispose();
    super.dispose();
  }
  Future passwordReset() async{
    try{
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      showDialog(context: context,
      builder: (context){
        return AlertDialog(
          content: Text('Your reset link has been sent. Please check your emali.'),
        );
      });
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(context: context,
      builder: (context){
        return AlertDialog(
          content: Text(e.message.toString()),
        );
      });
    }
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClosetSwap'),
        centerTitle: true,
      ),
      
      body: SafeArea(
        
        child: Container(
          
          padding: const EdgeInsets.symmetric(vertical: 35),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(child: Container(),flex: 2,),
              SvgPicture.asset(
               'assets/image2vector.svg',
               
               height: 120,
              ),
              const SizedBox(height: 64),
              TextFieldInput(
                hintText: 'Enter your email to send reset link',
                textInputType: TextInputType.emailAddress,
                textEditingController: _emailController,
              ),
              const SizedBox(
                height: 24,
              ),
              MaterialButton(onPressed: passwordReset,
              child: Text(' Reset '),
              color: Colors.blueGrey, )
            ]
  
          )
          ), 
          ),
    );
  }
}