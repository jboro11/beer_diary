import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  // Inicializace Flutter bindingu (nutné pro databázi)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start databáze
  await Hive.initFlutter();
  await Hive.openBox('piva_box');
  
  runApp(const BeerDiaryApp());
}

class BeerDiaryApp extends StatelessWidget {
  const BeerDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beer Diary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- HLAVNÍ OBRAZOVKA SE SEZNAMEM ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Odkaz na naši otevřenou krabici s daty
  final _pivaBox = Hive.box('piva_box');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beer Diary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // ValueListenableBuilder sleduje změny v databázi a hned překresluje seznam
      body: ValueListenableBuilder(
        valueListenable: _pivaBox.listenable(),
        builder: (context, Box box, widget) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                'Klikni na + a přidej první pivo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Seznam piv
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              // Získáme data
              final pivo = box.getAt(index);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.local_drink, color: Colors.white),
                  ),
                  title: Text(
                    pivo['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Hodnocení: ${pivo['rating']}/5\n${pivo['date']}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Smazání položky
                      box.deleteAt(index);
                    },
                  ),
                ),
              );
            },
          );
        },
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

// --- OBRAZOVKA PŘIDÁNÍ PIVA (FORMULÁŘ) ---
class AddBeerScreen extends StatefulWidget {
  const AddBeerScreen({super.key});

  @override
  State<AddBeerScreen> createState() => _AddBeerScreenState();
}

class _AddBeerScreenState extends State<AddBeerScreen> {
  final _nameController = TextEditingController();
  double _rating = 3.0;

  // Funkce pro uložení do databáze
  void _saveBeer() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Musíš zadat název piva!")),
      );
      return;
    }

    final box = Hive.box('piva_box');
    
    // Přidáme data do Hive
    box.add({
      'name': _nameController.text,
      'rating': _rating,
      'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
      // Zatím nevyužité (připraveno pro další krok)
      'imagePath': null,
      'lat': 0.0,
      'lng': 0.0,
    });

    // Vrátíme se zpět na seznam
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nový úlovek")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Jaké pivo piješ?", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Název piva",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_bar),
              ),
            ),
            const SizedBox(height: 30),
            
            const Text("Jak ti chutná?", style: TextStyle(fontSize: 18)),
            Slider(
              value: _rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.round().toString(),
              activeColor: Colors.amber,
              onChanged: (val) => setState(() => _rating = val),
            ),
            Center(
              child: Text(
                "${_rating.round()} hvězd",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBeer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("ULOŽIT", style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}