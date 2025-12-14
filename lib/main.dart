import 'package:flutter/material.dart';

void main() {
  runApp(const BeerDiaryApp());
}

class BeerDiaryApp extends StatelessWidget {
  const BeerDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beer Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beer Diary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Klikni na + a přidej první pivo.',
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBeerScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddBeerScreen extends StatelessWidget {
  const AddBeerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("nové pivo")),
      body: const Center(child: Text("přidání piva.")),
    );
  }
}