import 'package:flutter/material.dart'; import '../../core/inputs/text_input.dart'; import '../../core/utils/snack.dart';
class AccountSettingsPage extends StatelessWidget{ const AccountSettingsPage({super.key});
  void _changeEmail(BuildContext c){
    showModalBottomSheet(context:c, isScrollControlled:true, builder: (_)=>Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom), child: ListView(shrinkWrap:true, padding: const EdgeInsets.all(16), children:[
      const Text('Change Email', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height:8), const TextInput(label:'New email'),
      const SizedBox(height:12), FilledButton(onPressed: (){Navigator.pop(c); snack(c,'Verification sent (placeholder)');}, child: const Text('Send verification')),
    ])));
  }
  void _changePassword(BuildContext c){
    showModalBottomSheet(context:c, isScrollControlled:true, builder: (_)=>Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom), child: ListView(shrinkWrap:true, padding: const EdgeInsets.all(16), children:[
      const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height:8), const TextInput(label:'Current password', obscure:true),
      const SizedBox(height:8), const TextInput(label:'New password', obscure:true),
      const SizedBox(height:8), const TextInput(label:'Confirm new password', obscure:true),
      const SizedBox(height:12), FilledButton(onPressed: (){Navigator.pop(c); snack(c,'Password updated (placeholder)');}, child: const Text('Update')),
    ])));
  }
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Account Settings')), body: ListView(padding: const EdgeInsets.all(16), children:[
    const TextInput(label:'Display name'), const SizedBox(height:12), const TextInput(label:'Username'),
    const SizedBox(height:12), FilledButton(onPressed: ()=>_changeEmail(c), child: const Text('Change Email')),
    const SizedBox(height:8), FilledButton(onPressed: ()=>_changePassword(c), child: const Text('Change Password')),
  ]));
}
