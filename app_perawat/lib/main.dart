import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// --- Variabel Otentikasi (Sesuai Permintaan) ---
const String AUTH_EMAIL = 'perawat@testmail.com';
const String AUTH_PASSWORD = '12345678';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Firebase dengan opsi yang telah dibuat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NurseApp());
}

class NurseApp extends StatelessWidget {
  const NurseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Perawat',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const NurseScreen(),
    );
  }
}

class NurseScreen extends StatefulWidget {
  const NurseScreen({super.key});

  @override
  State<NurseScreen> createState() => _NurseScreenState();
}

class _NurseScreenState extends State<NurseScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('rumahsakit');
  User? _user;
  String _authStatus = 'Mencoba Otentikasi...';

  // State untuk Data Realtime
  int _p1Status = 0;
  int _p2Status = 0;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _signInAndListen();
  }

  // Otentikasi Otomatis
  Future<void> _signInAndListen() async {
    try {
      final auth = FirebaseAuth.instance;
      // Otentikasi menggunakan kredensial yang ditentukan
      final userCredential = await auth.signInWithEmailAndPassword(
        email: AUTH_EMAIL,
        password: AUTH_PASSWORD,
      );
      setState(() {
        _user = userCredential.user;
        _authStatus = 'Otentikasi Berhasil.';
      });

      // Mulai mendengarkan data setelah otentikasi berhasil
      _listenToRealtimeData();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _authStatus = 'Otentikasi Gagal: ${e.message}';
      });
      print('Otentikasi Gagal: $e');
    } catch (e) {
      setState(() {
        _authStatus = 'Error: $e';
      });
      print('Error: $e');
    }
  }

  // Mendengarkan data status pasien dan counter secara realtime
  void _listenToRealtimeData() {
    if (_user == null) return;

    // Pasien 1 Status
    _dbRef.child('pasien1/status').onValue.listen((event) {
      final status = (event.snapshot.value as int? ?? 0);
      setState(() {
        _p1Status = status;
      });
    });

    // Pasien 2 Status
    _dbRef.child('pasien2/status').onValue.listen((event) {
      final status = (event.snapshot.value as int? ?? 0);
      setState(() {
        _p2Status = status;
      });
    });

    // Counter
    _dbRef.child('counter').onValue.listen((event) {
      final counter = (event.snapshot.value as int? ?? 0);
      setState(() {
        _counter = counter;
      });
    });
  }

  // Logika untuk menentukan status gabungan
  ({String message, Color color}) _getOverallStatus() {
    final bool p1NeedsHelp = _p1Status == 1;
    final bool p2NeedsHelp = _p2Status == 1;

    if (p1NeedsHelp && p2NeedsHelp) {
      return (
        message: "PASIEN 1 & 2 BUTUH BANTUAN!",
        color: Colors.deepPurple.shade700,
      );
    } else if (p1NeedsHelp) {
      return (message: "PASIEN 1 BUTUH BANTUAN", color: Colors.red.shade700);
    } else if (p2NeedsHelp) {
      return (message: "PASIEN 2 BUTUH BANTUAN", color: Colors.red.shade700);
    } else {
      return (message: "SEMUA AMAN", color: Colors.green.shade600);
    }
  }

  // Widget untuk menampilkan detail status
  Widget _buildStatusTile(String title, int status) {
    final bool needsHelp = status == 1;
    return ListTile(
      leading: needsHelp
          ? const Icon(Icons.warning, color: Colors.red)
          : const Icon(Icons.check_circle, color: Colors.green),
      title: Text(title),
      trailing: Text(
        needsHelp ? 'BUTUH BANTUAN' : 'AMAN',
        style: TextStyle(
          color: needsHelp ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overallStatus = _getOverallStatus();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Perawat: Monitoring'),
        backgroundColor: Colors.lightGreen,
        elevation: 4,
      ),
      body: _user == null && _authStatus.startsWith('Mencoba')
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_authStatus),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Status Gabungan (Paling Atas)
                  Card(
                    color: overallStatus.color,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        overallStatus.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              blurRadius: 5.0,
                              color: Colors.black38,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Detail Status Pasien
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Status Detail Pasien:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusTile('Pasien 1', _p1Status),
                          const Divider(),
                          _buildStatusTile('Pasien 2', _p2Status),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Frekuensi Panggilan
                  Card(
                    color: Colors.orange.shade50,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            'Frekuensi Total Panggilan Bantuan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_counter KALI',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const Text(
                            'Sejak terakhir direset (Realtime)',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Status Otentikasi: $_authStatus',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
