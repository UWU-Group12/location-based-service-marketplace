import 'package:flutter/material.dart';

class ProviderListScreen extends StatefulWidget {

  final String category;
  const ProviderListScreen({super.key,required this.category});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The back button is automatically added by Navigator.push
        title: Text(widget.category),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Text("Under Development"),
      ),
    );
  }
}
