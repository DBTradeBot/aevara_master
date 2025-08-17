import 'package:flutter/material.dart'; import '../../app_routes.dart';
class VerifyEmailPage extends StatelessWidget{ const VerifyEmailPage({super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Verify Email')), body: Center(child: Column(mainAxisSize: MainAxisSize.min, children:[
    const Icon(Icons.mark_email_read_outlined, size: 64), const SizedBox(height: 12), const Text('We sent you a link.'),
    const SizedBox(height: 12), FilledButton(onPressed: ()=>Navigator.pushNamed(c, Routes.obIdentity), child: const Text('Continue'))])));
}
