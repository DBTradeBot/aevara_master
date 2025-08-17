import 'package:flutter/material.dart';
import '../../core/widgets/number_stepper_field.dart';
class AccountPage extends StatefulWidget{ const AccountPage({super.key}); @override State<AccountPage> createState()=>_AccountPageState();}
class _AccountPageState extends State<AccountPage>{
  String gender='Prefer not to say'; String units='Metric'; double height=170; double weight=70;
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Account')), body: ListView(padding: const EdgeInsets.all(16), children:[
    Center(child: Stack(alignment: Alignment.bottomRight, children:[
      const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
      IconButton.filledTonal(onPressed: (){}, icon: const Icon(Icons.edit))
    ])),
    const SizedBox(height:12),
    const TextField(decoration: InputDecoration(labelText:'Display name')),
    const SizedBox(height:8),
    const TextField(decoration: InputDecoration(labelText:'Username')),
    const SizedBox(height:8),
    const TextField(decoration: InputDecoration(labelText:'Email')),
    const SizedBox(height:8),
    FilledButton.tonal(onPressed: (){}, child: const Text('Change password')),
    const Divider(height:32),
    ListTile(title: const Text('Date of Birth'), subtitle: const Text('Tap to set'), trailing: const Icon(Icons.calendar_today), onTap: (){}),
    const SizedBox(height:8),
    DropdownButtonFormField<String>(value: gender, items: const ['Female','Male','Non-binary','Prefer not to say'].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=>setState(()=>gender=v??gender), decoration: const InputDecoration(labelText:'Gender')),
    const SizedBox(height:8),
    SegmentedButton<String>(segments: const [ButtonSegment(value:'Metric', label: Text('Metric')), ButtonSegment(value:'Imperial', label: Text('Imperial'))], selected:{units}, onSelectionChanged:(s)=>setState(()=>units=s.first)),
    const SizedBox(height:8),
    NumberStepperField(label:'Height', value: height, min: units=='Metric'?120:47, max: units=='Metric'?220:86, step:1, unit: units=='Metric'?'cm':'in', onChanged:(v)=>setState(()=>height=v)),
    const SizedBox(height:8),
    NumberStepperField(label:'Weight', value: weight, min: units=='Metric'?40:88, max: units=='Metric'?160:352, step:1, unit: units=='Metric'?'kg':'lb', onChanged:(v)=>setState(()=>weight=v)),
    const SizedBox(height:16),
    FilledButton(onPressed: (){}, child: const Text('Save changes')),
  ]));
}
