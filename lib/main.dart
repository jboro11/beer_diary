import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:geolocator/geolocator.dart'; 
import 'package:url_launcher/url_launcher.dart'; 

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
  // Odkaz otevřenou krabici s daty
  final _pivaBox = Hive.box('piva_box');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beer Diary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // ValueListenableBuilder sleduje změny v databázi
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
              // Získání dat
              final pivo = box.getAt(index);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: pivo['imagePath'] != null
                      ? ClipOval(
                          child: Image.file(
                            File(pivo['imagePath']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const CircleAvatar(
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
                  // Otevření detailu s mapou
                  onTap: () => _showDetailDialog(context, pivo),
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

  // Zobrazení detailu a mapy
  void _showDetailDialog(BuildContext context, Map pivo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(pivo['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pivo['imagePath'] != null)
              SizedBox(
                height: 200, width: double.infinity,
                child: Image.file(File(pivo['imagePath']), fit: BoxFit.cover),
              ),
            const SizedBox(height: 10),
            Text("Hodnocení: ${pivo['rating']}/5"),
            const SizedBox(height: 10),
            
            // Tlačítko na mapu (pokud existují souřadnice)
            if (pivo['lat'] != 0.0 && pivo['lng'] != 0.0)
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("Ukázat na mapě"),
                onPressed: () async {
                  final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${pivo['lat']},${pivo['lng']}");
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nelze otevřít mapu")));
                  }
                },
              )
            else
              const Text("Poloha nebyla uložena.", style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Zavřít"))],
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
  File? _selectedImage;
  
  // Proměnné pro GPS
  String _locationStatus = "Poloha nezískána";
  double _lat = 0.0;
  double _lng = 0.0;
  bool _isGettingLocation = false;

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    // Otevře kameru
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      final directory = await getApplicationDocumentsDirectory();
      // vytvoreni nazvu soubroru podle casu
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${directory.path}/$fileName';
      
      // Zkopírujeme fotku do úložiště
      await File(photo.path).copy(savedPath);

      setState(() {
        _selectedImage = File(savedPath);
      });
    }
  }

  // Získání GPS souřadnic
  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      // Kontrola oprávnění
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationStatus = "Bez oprávnění"; _isGettingLocation = false; });
          return;
        }
      }

      // Získání polohy
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _locationStatus = "GPS: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}";
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() { _locationStatus = "Chyba GPS (zapni polohu)"; _isGettingLocation = false; });
    }
  }

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
      'imagePath': _selectedImage?.path,
      'lat': _lat, // Uložení skutečné polohy
      'lng': _lng,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nový úlovek")),
      body: SingleChildScrollView( // male displeje
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _takePicture,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Klikni a vyfoť pivo!", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

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
            
            const SizedBox(height: 20),

            // Sekce pro GPS
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  IconButton(
                    icon: _isGettingLocation ? const CircularProgressIndicator() : const Icon(Icons.my_location, color: Colors.blue),
                    onPressed: _getLocation,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_locationStatus)),
                ],
              ),
            ),

            const SizedBox(height: 30), 
            
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