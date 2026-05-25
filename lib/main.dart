import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const KandangKuApp());
}

class KandangKuApp extends StatelessWidget {
  const KandangKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KandangKu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Database? db;

  int mortalitas = 0;
  int sakit = 0;
  int pakan = 0;
  int produksi = 0;

  String kandangAktif = "Kandang Pembesaran A";
  final List<String> daftarKandang = [
    "Kandang DOC",
    "Kandang Pembesaran A",
    "Kandang Indukan",
  ];

  List<Map<String, dynamic>> data = [];

  @override
  void initState() {
    super.initState();
    initDB();
  }

  Future<void> initDB() async {
    db = await openDatabase(
      join(await getDatabasesPath(), 'kandangku.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE rekording(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kandang TEXT,
            tanggal TEXT,
            mortalitas INTEGER,
            sakit INTEGER,
            pakan INTEGER,
            produksi INTEGER
          )
        ''');
      },
      version: 1,
    );

    loadData();
  }

  Future<void> loadData() async {
    final result = await db!.query('rekording', orderBy: 'id DESC');
    setState(() {
      data = result;
    });
  }

  Future<void> simpan() async {
    await db!.insert('rekording', {
      "kandang": kandangAktif,
      "tanggal": DateTime.now().toString(),
      "mortalitas": mortalitas,
      "sakit": sakit,
      "pakan": pakan,
      "produksi": produksi,
    });

    loadData();
  }

  Future<void> hapus(int id) async {
    await db!.delete('rekording', where: "id = ?", whereArgs: [id]);
    loadData();
  }

  Widget kartu(String judul, String nilai) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(nilai,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalM = data.fold(0, (a, b) => a + (b["mortalitas"] ?? 0));
    int totalP = data.fold(0, (a, b) => a + (b["pakan"] ?? 0));
    int totalPr = data.fold(0, (a, b) => a + (b["produksi"] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text("KandangKu"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: simpan,
        child: const Icon(Icons.save),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButton(
              value: kandangAktif,
              isExpanded: true,
              items: daftarKandang
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  kandangAktif = v.toString();
                });
              },
            ),

            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                kartu("Mortalitas", "$totalM"),
                kartu("Pakan", "$totalP Kg"),
                kartu("Produksi", "$totalPr"),
                kartu("Data", "${data.length}"),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "Input Harian",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            TextField(
              decoration: const InputDecoration(labelText: "Mortalitas"),
              keyboardType: TextInputType.number,
              onChanged: (v) => mortalitas = int.tryParse(v) ?? 0,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Sakit"),
              keyboardType: TextInputType.number,
              onChanged: (v) => sakit = int.tryParse(v) ?? 0,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Pakan"),
              keyboardType: TextInputType.number,
              onChanged: (v) => pakan = int.tryParse(v) ?? 0,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Produksi"),
              keyboardType: TextInputType.number,
              onChanged: (v) => produksi = int.tryParse(v) ?? 0,
            ),

            const SizedBox(height: 20),

            const Text(
              "Riwayat",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            ...data.map((e) {
              return Card(
                child: ListTile(
                  title: Text(e["kandang"] ?? ""),
                  subtitle: Text(
                      "M:${e["mortalitas"]} | P:${e["pakan"]} | T:${e["produksi"]}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => hapus(e["id"]),
                  ),
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
