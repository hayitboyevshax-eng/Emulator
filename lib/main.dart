import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

typedef StartQemuNative = ffi.Int32 Function(
    ffi.Pointer<Utf8> imgPath, ffi.Pointer<Utf8> kernelPath, ffi.Int32 ramMb);
typedef StartQemu = int Function(
    ffi.Pointer<Utf8> imgPath, ffi.Pointer<Utf8> kernelPath, int ramMb);

void main() {
  runApp(const GsiEmulatorApp());
}

class GsiEmulatorApp extends StatelessWidget {
  const GsiEmulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GSI Emulator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isEngineRunning = false;
  double _ramAllocation = 2048;
  String? _gsiPath;
  String? _kernelPath;
  final List<String> _logs = [
    "[SYSTEM] Emulyator boshqaruv markazi tayyor.",
    "[INFO] ARM64 GSI (.img) faylini tanlang."
  ];

  ffi.DynamicLibrary? _qemuLib;

  @override
  void initState() {
    super.initState();
    _initNativeLib();
  }

  void _initNativeLib() {
    if (Platform.isAndroid) {
      try {
        _qemuLib = ffi.DynamicLibrary.open("libqemu_wrapper.so");
        _addLog("[NATIVE] libqemu_wrapper.so muvaffaqiyatli yuklandi.");
      } catch (e) {
        _addLog("[WARNING] Native kutubxona topilmadi: $e");
      }
    }
  }

  void _addLog(String msg) {
    setState(() {
      _logs.add(msg);
    });
  }

  Future<void> _pickFile(bool isGsi) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isGsi) {
          _gsiPath = result.files.single.path;
          _addLog("[FILE] GSI tanlandi: ${_gsiPath!.split('/').last}");
        } else {
          _kernelPath = result.files.single.path;
          _addLog("[FILE] Kernel tanlandi: ${_kernelPath!.split('/').last}");
        }
      });
    }
  }

  void _toggleEmulator() {
    if (_isEngineRunning) {
      setState(() {
        _isEngineRunning = false;
      });
      _addLog("[SYSTEM] Emulyator to'xtatildi.");
      return;
    }

    if (_gsiPath == null) {
      _addLog("[ERROR] Iltimos, avval GSI (.img) faylini tanlang!");
      return;
    }

    setState(() {
      _isEngineRunning = true;
    });
    _addLog("[QEMU] Ishga tushirilmoqda (RAM: ${_ramAllocation.toInt()} MB)...");

    if (_qemuLib != null) {
      try {
        final startFunc = _qemuLib!
            .lookupFunction<StartQemuNative, StartQemu>('start_qemu_instance');
        final imgPtr = _gsiPath!.toNativeUtf8();
        final kernelPtr = (_kernelPath ?? "").toNativeUtf8();

        int res = startFunc(imgPtr, kernelPtr, _ramAllocation.toInt());
        _addLog("[QEMU] Exit code: $res");

        malloc.free(imgPtr);
        malloc.free(kernelPtr);
      } catch (e) {
        _addLog("[ERROR] FFI chaqiruvida xatolik: $e");
      }
    } else {
      _addLog("[SIMULATION] QEMU dvigateli (UI demo rejimida) faollashdi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Control Center',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isEngineRunning
                      ? Colors.green.withOpacity(0.6)
                      : Colors.blue.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isEngineRunning ? Colors.green : Colors.grey,
                      boxShadow: [
                        if (_isEngineRunning)
                          BoxShadow(
                              color: Colors.green.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2)
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEngineRunning
                              ? 'Tizim ishlamoqda'
                              : 'Tizim to\'xtatilgan',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEngineRunning
                              ? 'QEMU ARM64 Virtual Machine faol'
                              : 'GSI imijini yuklashga tayyor',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // File Selection Buttons
            Row(
              children: [
                Expanded(
                  child: _buildFileCard(
                    title: 'GSI Image (.img)',
                    subtitle: _gsiPath != null
                        ? _gsiPath!.split('/').last
                        : 'Tanlanmagan',
                    icon: Icons.sd_storage_outlined,
                    onTap: () => _pickFile(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFileCard(
                    title: 'Kernel (Ixtiyoriy)',
                    subtitle: _kernelPath != null
                        ? _kernelPath!.split('/').last
                        : 'Standart',
                    icon: Icons.memory_outlined,
                    onTap: () => _pickFile(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // RAM Slider
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tezkor xotira (RAM):',
                          style: TextStyle(color: Colors.white)),
                      Text('${_ramAllocation.toInt()} MB',
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _ramAllocation,
                    min: 1024,
                    max: 6144,
                    divisions: 5,
                    activeColor: Colors.blueAccent,
                    onChanged: _isEngineRunning
                        ? null
                        : (val) => setState(() => _ramAllocation = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Terminal Log View
            const Text('Tizim loglari:',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.greenAccent),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start/Stop Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isEngineRunning ? Colors.redAccent : Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _toggleEmulator,
                child: Text(
                  _isEngineRunning
                      ? 'EMULYATORNI TO\'XTATISH'
                      : 'EMULYATORNI ISHGA TUSHIRISH',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 24),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 4),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
