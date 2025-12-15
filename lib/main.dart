import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  // nutne pro inicializaci pluginu
  WidgetsFlutterBinding.ensureInitialized();

  // start lokalni databaze
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pivní deník',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.black)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              // mrizka pro tlacitka menu
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
                children: [
                  _MenuButton(
                    title: "Moje piva",
                    icon: Icons.sports_bar,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BeerListScreen())),
                  ),

                  _MenuButton(
                    title: "Přidat pivo",
                    icon: Icons.add,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBeerScreen())),
                  ),

                  _MenuButton(
                    title: "Statistiky",
                    icon: Icons.bar_chart,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsScreen())),
                  ),

                  // misto pro mapu pozdeji
                  const SizedBox(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// vlastni widget pro tlacitko menu
class _MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuButton({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BeerListScreen extends StatefulWidget {
  const BeerListScreen({super.key});

  @override
  State<BeerListScreen> createState() => _BeerListScreenState();
}

class _BeerListScreenState extends State<BeerListScreen> {
  // reference na otevreny box
  final _pivaBox = Hive.box('piva_box');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje piva'),
        backgroundColor: Colors.green[50],
      ),
      // sleduje zmeny v databazi
      body: ValueListenableBuilder(
        valueListenable: _pivaBox.listenable(),
        builder: (context, Box box, widget) {
          if (box.isEmpty) {
            return const Center(
              child: Text('Zatím jsi nic nepřidal.'),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              // razeni od nejnovejsiho
              final key = box.keyAt(box.length - 1 - index);
              final pivo = box.get(key);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  // zobrazi fotku nebo ikonu
                  leading: pivo['imagePath'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(pivo['imagePath']),
                            width: 60, height: 60, fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.local_drink, color: Colors.green),
                        ),
                  title: Text(pivo['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${'⭐' * (pivo['rating'] ?? 0).round()}\n${pivo['date']}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => box.delete(key),
                  ),
                  onTap: () => _showDetailDialog(context, pivo),
                ),
              );
            },
          );
        },
      ),
    );
  }

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
            // pokud mame souradnice ukazeme tlacitko
            if (pivo['lat'] != 0.0 && pivo['lng'] != 0.0)
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("Otevřít v Google Mapách"),
                onPressed: () async {
                  final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${pivo['lat']},${pivo['lng']}");
                  //Oddeleni await a kontroly contextu
                  bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                  
                  // Pokud byl widget zahozen behem nacitani, nepokracujeme
                  if (!context.mounted) return;

                  if (!launched) {
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

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('piva_box');
    int celkem = box.length;
    double prumer = 0;

    // vypocet prumerneho hodnoceni
    if (celkem > 0) {
      double soucet = 0;
      for (var i = 0; i < celkem; i++) {
        soucet += box.getAt(i)['rating'];
      }
      prumer = soucet / celkem;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Statistiky"), backgroundColor: Colors.green[50]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statCard("Celkem vypito", "$celkem", Icons.sports_bar),
            const SizedBox(height: 20),
            _statCard("Průměrné hodnocení", "${prumer.toStringAsFixed(1)} ⭐", Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.green),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }
}

class AddBeerScreen extends StatefulWidget {
  const AddBeerScreen({super.key});

  @override
  State<AddBeerScreen> createState() => _AddBeerScreenState();
}

class _AddBeerScreenState extends State<AddBeerScreen> {
  final _nameController = TextEditingController();
  double _rating = 3.0;
  File? _selectedImage;
  String _locationStatus = "Poloha nezískána";
  double _lat = 0.0;
  double _lng = 0.0;
  bool _isGettingLocation = false;

  // logika pro fotoaparat
  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // ziskani cesty kam ulozit fotku
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${directory.path}/$fileName';

      // zkopirovani do trvaleho uloziste
      await File(photo.path).copy(savedPath);
      
      if (!mounted) return; // Pro jistotu kontrola i zde
      setState(() => _selectedImage = File(savedPath));
    }
  }

  // logika pro gps
  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationStatus = "Bez oprávnění"; _isGettingLocation = false; });
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _locationStatus = "GPS: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}";
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() { _locationStatus = "Chyba GPS"; _isGettingLocation = false; });
    }
  }

  void _saveBeer() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Musíš zadat název piva!")));
      return;
    }
    final box = Hive.box('piva_box');
    // ulozeni dat do hive mapy
    box.add({
      'name': _nameController.text,
      'rating': _rating,
      'date': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
      'imagePath': _selectedImage?.path,
      'lat': _lat,
      'lng': _lng,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nový úlovek"), backgroundColor: Colors.green[50]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _takePicture,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.camera_alt, size: 50, color: Colors.grey), Text("Klikni a vyfoť pivo!", style: TextStyle(color: Colors.grey))],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Název piva", border: OutlineInputBorder(), prefixIcon: Icon(Icons.sports_bar))),
            const SizedBox(height: 20),
            const Text("Hodnocení:", style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(value: _rating, min: 1, max: 5, divisions: 4, label: _rating.round().toString(), activeColor: Colors.green, onChanged: (val) => setState(() => _rating = val)),
            Center(child: Text("${_rating.round()} hvězd", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  IconButton(icon: _isGettingLocation ? const CircularProgressIndicator() : const Icon(Icons.my_location, color: Colors.green), onPressed: _getLocation),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_locationStatus)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveBeer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 15),
                foregroundColor: Colors.white,
              ),
              child: const Text("ULOŽIT DO DENÍČKU", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}