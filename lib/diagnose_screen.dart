import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

// ← Update this to your PC IP address
const String apiBase = 'http://192.168.0.159:5000';

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({super.key});

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sound
  bool _isRecording = false;
  bool _isSoundLoading = false;
  Map<String, dynamic>? _soundResult;
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordedPath;

  // Image
  bool _isImageLoading = false;
  Map<String, dynamic>? _imageResult;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/car_sound.wav';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _soundResult = null;
          _recordedPath = path;
        });
      } else {
        _showSnack('Microphone permission denied');
      }
    } catch (e) {
      _showSnack('Recording error: $e');
    }
  }

  Future<void> _stopAndDiagnose() async {
    try {
      await _recorder.stop();
      setState(() {
        _isRecording = false;
        _isSoundLoading = true;
      });

      if (_recordedPath == null) {
        setState(() => _isSoundLoading = false);
        return;
      }

      final file = File(_recordedPath!);
      if (!await file.exists()) {
        _showSnack('Recording file not found');
        setState(() => _isSoundLoading = false);
        return;
      }

      final uri = Uri.parse('$apiBase/predict_sound');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile(
          'audio',
          file.readAsBytes().asStream(),
          await file.length(),
          filename: 'car_sound.wav',
        ),
      );

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _soundResult = result;
          _isSoundLoading = false;
        });
      } else {
        _showSnack('Server error: ${response.statusCode}');
        setState(() => _isSoundLoading = false);
      }
    } catch (e) {
      setState(() => _isSoundLoading = false);
      _showSnack('Connection error: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _selectedImage = file;
        _isImageLoading = true;
        _imageResult = null;
      });

      final uri = Uri.parse('$apiBase/predict_image');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile(
          'image',
          file.readAsBytes().asStream(),
          await file.length(),
          filename: 'car_part.jpg',
        ),
      );

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _imageResult = result;
          _isImageLoading = false;
        });
      } else {
        _showSnack('Server error: ${response.statusCode}');
        setState(() => _isImageLoading = false);
      }
    } catch (e) {
      setState(() => _isImageLoading = false);
      _showSnack('Connection error: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF6B2B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Diagnostics',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Sound diagnosis & part recognition',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13)),
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFFE8C547),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: const Color(0xFF0A0A0F),
                      unselectedLabelColor: Colors.white38,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(text: 'Sound Diagnosis'),
                        Tab(text: 'Part Recognition'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSoundTab(),
                  _buildImageTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _isSoundLoading
                ? null
                : _isRecording
                    ? _stopAndDiagnose
                    : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF16161F),
                border: Border.all(
                  color: _isRecording
                      ? const Color(0xFFFF6B2B)
                      : const Color(0xFFE8C547).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: _isSoundLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFE8C547)))
                  : Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isRecording
                          ? const Color(0xFFFF6B2B)
                          : const Color(0xFFE8C547),
                      size: 60,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRecording
                ? 'Recording... Tap to stop'
                : _isSoundLoading
                    ? 'Analysing sound...'
                    : 'Tap to Record',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Hold phone near the engine while idling',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
          ),
          const SizedBox(height: 30),
          if (_soundResult != null) _buildSoundResult(_soundResult!),
          if (_soundResult == null && !_isSoundLoading)
            _buildDetectableFaults(),
        ],
      ),
    );
  }

  Widget _buildSoundResult(Map<String, dynamic> result) {
    final severity = result['severity'] ?? 'none';
    final Color color = severity == 'high'
        ? const Color(0xFFFF6B2B)
        : severity == 'medium'
            ? const Color(0xFFE8C547)
            : const Color(0xFF4CAF50);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                severity == 'none'
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result['title'] ?? 'Result',
                  style: TextStyle(
                      color: color, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${result['confidence']}%',
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _resultRow('Cause', result['cause'] ?? ''),
          const SizedBox(height: 8),
          _resultRow('Action', result['action'] ?? ''),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _soundResult = null),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16161F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Record Again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectableFaults() {
    final faults = [
      {
        'fault': 'Engine Knock',
        'icon': Icons.settings_rounded,
        'color': const Color(0xFFFF6B2B)
      },
      {
        'fault': 'Worn Out Brakes',
        'icon': Icons.album_rounded,
        'color': const Color(0xFFE8C547)
      },
      {
        'fault': 'Serpentine Belt',
        'icon': Icons.electric_bolt_rounded,
        'color': const Color(0xFF2196F3)
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detectable Faults',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...faults.map((f) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16161F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Icon(f['icon'] as IconData,
                      color: f['color'] as Color, size: 18),
                  const SizedBox(width: 12),
                  Text(f['fault'] as String,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildImageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF16161F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFE8C547).withValues(alpha: 0.2)),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          color: Colors.white.withValues(alpha: 0.2), size: 48),
                      const SizedBox(height: 8),
                      Text('Take or upload a photo of a car part',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 13)),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isImageLoading
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8C547),
                    foregroundColor: const Color(0xFF0A0A0F),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isImageLoading
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined,
                      size: 18, color: Color(0xFFE8C547)),
                  label: const Text('Gallery',
                      style: TextStyle(color: Color(0xFFE8C547))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: const Color(0xFFE8C547).withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isImageLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFFE8C547)),
                  SizedBox(height: 12),
                  Text('Identifying part...',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          if (_imageResult != null) _buildImageResult(_imageResult!),
          if (_imageResult == null && !_isImageLoading)
            _buildRecognizableParts(),
        ],
      ),
    );
  }

  Widget _buildImageResult(Map<String, dynamic> result) {
    final icons = {
      'sparkplug': Icons.electric_bolt_rounded,
      'fusebox': Icons.electrical_services_rounded,
      'battery': Icons.battery_charging_full_rounded,
      'brakepad': Icons.album_rounded,
      'unknown': Icons.help_outline_rounded,
    };
    final part = result['part'] ?? 'unknown';
    final icon = icons[part] ?? Icons.help_outline_rounded;
    final isUnknown = part == 'unknown';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnknown
              ? Colors.white24
              : const Color(0xFFE8C547).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              color: isUnknown ? Colors.white38 : const Color(0xFFE8C547),
              size: 40),
          const SizedBox(height: 10),
          Text(
            result['title'] ?? 'Unknown',
            style: TextStyle(
                color: isUnknown ? Colors.white54 : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            result['description'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${result['confidence']}%',
            style: const TextStyle(
                color: Color(0xFFE8C547),
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _imageResult = null;
                _selectedImage = null;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16161F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Try Another Image'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecognizableParts() {
    final parts = [
      {
        'name': 'Spark Plug',
        'icon': Icons.electric_bolt_rounded,
        'color': const Color(0xFFE8C547)
      },
      {
        'name': 'Fuse Box',
        'icon': Icons.electrical_services_rounded,
        'color': const Color(0xFF2196F3)
      },
      {
        'name': 'Battery',
        'icon': Icons.battery_charging_full_rounded,
        'color': const Color(0xFF4CAF50)
      },
      {
        'name': 'Brake Pad',
        'icon': Icons.album_rounded,
        'color': const Color(0xFFFF6B2B)
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recognizable Parts',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2,
          children: parts
              .map((p) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        Icon(p['icon'] as IconData,
                            color: p['color'] as Color, size: 20),
                        const SizedBox(width: 8),
                        Text(p['name'] as String,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _resultRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    );
  }
}
