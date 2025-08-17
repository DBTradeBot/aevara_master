import 'package:flutter/material.dart';
void snack(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
