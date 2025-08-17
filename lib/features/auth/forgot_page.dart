import 'package:flutter/material.dart';
import '../../widgets/layout/auth_scaffold.dart';
import '../../widgets/atoms/aev_text_field.dart';
import '../../widgets/atoms/aev_button.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset Password', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              AevTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress, prefixIcon: const Icon(Icons.mail_outline)),
              const SizedBox(height: 16),
              AevButton.primary(_sent? 'Link sent' : 'Send reset link', onPressed: _sent? null : (){
                setState(()=>_sent=true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset link sent (stub).')));
              }),
              const SizedBox(height: 12),
              TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Back'))
            ],
          ),
        ),
      ),
    );
  }
}
