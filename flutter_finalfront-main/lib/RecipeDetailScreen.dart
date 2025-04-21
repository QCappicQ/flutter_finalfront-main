import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:async'; // เพิ่มสำหรับ Timer

class RecipeDetailScreen extends StatefulWidget {
  final int id;
  const RecipeDetailScreen({super.key, required this.id});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? recipe;
  List<dynamic> ingredients = [];
  List<dynamic> steps = [];
  final String baseUrl = 'https://finalback-sepia.vercel.app';
  bool isFavorite = false;

  // ตัวแปรสำหรับจับเวลา
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    fetchDetails();
    _checkFavorite();
  }

  @override
  void dispose() {
    _timer?.cancel(); // ยกเลิก Timer เมื่อ widget ถูก dispose
    super.dispose();
  }

  // ฟังก์ชันเริ่มจับเวลา
  void _startTimer() {
    if (!_isRunning) {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });
    }
  }

  // ฟังก์ชันหยุดจับเวลา
  void _pauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
      setState(() {});
    }
  }

  // ฟังก์ชันรีเซ็ตจับเวลา
  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isRunning = false;
    });
  }

  // แปลงวินาทีเป็นรูปแบบ mm:ss
  String _formatTime(int seconds) {
    int minutes = (seconds ~/ 60);
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> fetchDetails() async {
    try {
      final res1 = await http.get(Uri.parse('$baseUrl/recipes/${widget.id}'));
      final res2 = await http.get(Uri.parse('$baseUrl/recipes/${widget.id}/ingredients'));
      final res3 = await http.get(Uri.parse('$baseUrl/recipes/${widget.id}/steps'));

      if (res1.statusCode == 200 && res2.statusCode == 200 && res3.statusCode == 200) {
        setState(() {
          recipe = json.decode(res1.body);
          ingredients = json.decode(res2.body);
          steps = json.decode(res3.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถโหลดรายละเอียดสูตรได้')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดรายละเอียดสูตร')),
      );
    }
  }

  Future<List<String>> _getFavorites() async {
    if (kIsWeb) {
      return html.window.localStorage['favorites']?.split(',').where((id) => id.isNotEmpty).toList() ?? [];
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('favorites') ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _setFavorites(List<String> favorites) async {
    if (kIsWeb) {
      html.window.localStorage['favorites'] = favorites.join(',');
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('favorites', favorites);
      } catch (e) {}
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final favorites = await _getFavorites();
      setState(() {
        isFavorite = favorites.contains(widget.id.toString());
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการตรวจสอบสถานะสูตรโปรด')),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      List<String> favorites = await _getFavorites();
      if (isFavorite) {
        favorites.remove(widget.id.toString());
      } else {
        favorites.add(widget.id.toString());
      }
      await _setFavorites(favorites);
      setState(() {
        isFavorite = !isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFavorite ? 'เพิ่มในสูตรโปรด' : 'ลบออกจากสูตรโปรด'),
          duration: const Duration(seconds: 1),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเพิ่มสูตรโปรด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (recipe == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe!['title']?.toString() ?? 'No Title'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            tooltip: 'เพิ่มในสูตรโปรด',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // รูปภาพสูตร
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    recipe!['image']?.toString() ?? '',
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.3,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
              // คำอธิบาย
              Text(
                recipe!['description']?.toString() ?? 'No Description',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              // Ingredients
              Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ingredients",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      ...ingredients.map(
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            "- ${i['quantity']?.toString() ?? ''} ${i['name']?.toString() ?? ''}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // เพิ่มส่วนจับเวลา
              Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cooking Timer",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(_seconds),
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _isRunning ? null : _startTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("START"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isRunning ? _pauseTimer : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("PAUSE"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _resetTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("RESET"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Divider เพื่อแยกส่วน
              const Divider(color: Colors.white54, thickness: 1),
              const SizedBox(height: 16),
              // Steps
              Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Steps",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      ...steps.map(
                        (s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            "${s['step_number']?.toString() ?? ''}. ${s['instruction']?.toString() ?? ''}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}