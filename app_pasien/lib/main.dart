import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// --- Variabel Otentikasi (Sesuai Permintaan) ---
// PASTIKAN kredensial ini TERDAFTAR di Firebase Authentication!
const String AUTH_EMAIL = 'pasien@testmail.com';
const String AUTH_PASSWORD = '12345678';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Anda harus memastikan inisialisasi Firebase Core dilakukan di sini
  // sesuai dengan konfigurasi flutterfire Anda. Contoh:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // Karena ini adalah aplikasi Flutter demo, kita akan menganggap Firebase sudah terinisialisasi.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Menganggap inisialisasi default
  runApp(const PatientApp());
}

class PatientApp extends StatelessWidget {
  const PatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Pasien',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const PatientScreen(),
    );
  }
}

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  User? _user;
  String _authStatus = 'Mencoba Otentikasi...';

  // State lokal untuk Pasien 1 dan Pasien 2
  int _p1Status = 0;
  String _p1Pesan = 'aman';
  int _p2Status = 0;
  String _p2Pesan = 'aman';

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
        _authStatus = 'Otentikasi Berhasil. UID: ${_user!.uid}';
      });

      // Mulai mendengarkan data setelah otentikasi berhasil
      _listenToPatientData();
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

  // Mendengarkan data status pasien secara realtime
  void _listenToPatientData() {
    // Listener untuk Pasien 1
    _dbRef.child('rumahsakit/pasien1/status').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final status = (event.snapshot.value as int? ?? 0);
        setState(() {
          _p1Status = status;
        });
      }
    });
    _dbRef.child('rumahsakit/pasien1/pesan').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final pesan = (event.snapshot.value as String? ?? 'aman');
        setState(() {
          _p1Pesan = pesan;
        });
      }
    });

    // Listener untuk Pasien 2
    _dbRef.child('rumahsakit/pasien2/status').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final status = (event.snapshot.value as int? ?? 0);
        setState(() {
          _p2Status = status;
        });
      }
    });
    _dbRef.child('rumahsakit/pasien2/pesan').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final pesan = (event.snapshot.value as String? ?? 'aman');
        setState(() {
          _p2Pesan = pesan;
        });
      }
    });
  }

  // Logika utama untuk tombol Pasien 1 atau Pasien 2
  Future<void> _toggleStatus(int patientNumber, int currentStatus) async {
    if (_user == null) {
      print('Otentikasi belum berhasil.');
      return;
    }

    final String path = 'rumahsakit/pasien$patientNumber';
    final bool currentlySafe = currentStatus == 0;
    final int newStatus = currentlySafe ? 1 : 0;
    final String newMessage = currentlySafe ? 'butuh bantuan' : 'aman';

    // 1. Update Status dan Pesan
    await _dbRef.child('$path/status').set(newStatus);
    await _dbRef.child('$path/pesan').set(newMessage);

    // 2. Transaksi Counter (Hanya jika berubah dari 0 ke 1)
    if (currentlySafe) {
      final counterRef = _dbRef.child('rumahsakit/counter');

      // Update counter value without using transaction
      final counterSnapshot = await counterRef.get();
      int currentValue = counterSnapshot.value as int? ?? 0;
      await counterRef.set(currentValue + 1);
      print('Counter berhasil dinaikkan. Nilai baru: ${currentValue + 1}');
    }
  }

  // Widget Tombol Interaktif
  Widget _buildPatientButton({
    required int patientNumber,
    required int status,
    required String pesan,
    required Color color,
  }) {
    final bool needsHelp = status == 1;
    final String buttonText = needsHelp
        ? 'Pasien $patientNumber: BUTUH BANTUAN (Klik untuk Aman)'
        : 'Pasien $patientNumber: AMAN (Klik untuk Panggil)';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: needsHelp
              ? Colors.red.shade700
              : Colors.green.shade600,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: _user == null
            ? null // Nonaktifkan jika belum login
            : () => _toggleStatus(patientNumber, status),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(buttonText),
            const SizedBox(height: 4),
            Text(
              'Status DB: ${pesan.toUpperCase()}',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Panggilan Pasien'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              color: Colors.lightBlue.shade50,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Otentikasi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_authStatus),
                    const SizedBox(height: 8),
                    const Text(
                      'PENTING: Aplikasi ini menggunakan kredensial tetap untuk simulasi lingkungan Canvas.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const Center(
              child: Text(
                'Tekan tombol di bawah untuk mengubah status bantuan Anda.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Pasien 1
            _buildPatientButton(
              patientNumber: 1,
              status: _p1Status,
              pesan: _p1Pesan,
              color: Colors.blue,
            ),

            const Divider(height: 40),

            // Tombol Pasien 2
            _buildPatientButton(
              patientNumber: 2,
              status: _p2Status,
              pesan: _p2Pesan,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}
