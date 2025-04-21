import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateRecipeScreen extends StatefulWidget {
  final int id;
  const UpdateRecipeScreen({super.key, required this.id});

  @override
  State<UpdateRecipeScreen> createState() => _UpdateRecipeScreenState();
}

class _UpdateRecipeScreenState extends State<UpdateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageController = TextEditingController();
  List<Map<String, String>> ingredients = [];
  List<Map<String, String>> steps = [];
  final String baseUrl = 'https://finalback-sepia.vercel.app';
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/recipes/${widget.id}')),
        http.get(Uri.parse('$baseUrl/recipes/${widget.id}/ingredients')),
        http.get(Uri.parse('$baseUrl/recipes/${widget.id}/steps')),
      ]);

      if (responses.every((res) => res.statusCode == 200)) {
        final data = json.decode(responses[0].body);
        final ingredientData = json.decode(responses[1].body);
        final stepData = json.decode(responses[2].body);

        setState(() {
          titleController.text = data['title']?.toString() ?? '';
          descriptionController.text = data['description']?.toString() ?? '';
          imageController.text = data['image']?.toString() ?? '';
          ingredients = List<Map<String, String>>.from(
            ingredientData.map((i) => {
              'name': i['name']?.toString() ?? '',
              'quantity': i['quantity']?.toString() ?? '',
            }),
          );
          steps = List<Map<String, String>>.from(
            stepData.map((s) => {
              'instruction': s['instruction']?.toString() ?? '',
            }),
          );
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load recipe data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถโหลดข้อมูลได้ กรุณาลองอีกครั้ง')),
      );
      setState(() => isLoading = false);
    }
  }

  void _addIngredient() {
    setState(() {
      ingredients.add({'name': '', 'quantity': ''});
    });
  }

  void _addStep() {
    setState(() {
      steps.add({'instruction': ''});
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && !isSubmitting) {
      setState(() => isSubmitting = true);
      try {
        // อัปเดตข้อมูลสูตร
        final recipeBody = jsonEncode({
          'title': titleController.text,
          'description': descriptionController.text,
          'image': imageController.text,
        });
        final recipeRes = await http.put(
          Uri.parse('$baseUrl/recipes/${widget.id}'),
          headers: {'Content-Type': 'application/json'},
          body: recipeBody,
        ).timeout(const Duration(seconds: 7));

        if (recipeRes.statusCode != 200) {
          throw Exception('Failed to update recipe: ${recipeRes.statusCode}');
        }

        // ลบ ingredients และ steps เดิม
        final deleteRes = await http.delete(
          Uri.parse('$baseUrl/recipes/${widget.id}'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 7));

        if (deleteRes.statusCode != 200 && deleteRes.statusCode != 204) {
          throw Exception('Failed to delete ingredients and steps: ${deleteRes.statusCode}');
        }

        // สร้างสูตรใหม่
        final createBody = jsonEncode({
          'title': titleController.text,
          'description': descriptionController.text,
          'image': imageController.text,
          'ingredients': ingredients,
          'steps': steps.asMap().entries.map((e) => {
                'step_number': e.key + 1,
                'instruction': e.value['instruction'],
              }).toList(),
        });

        final createRes = await http.post(
          Uri.parse('$baseUrl/recipes'),
          headers: {'Content-Type': 'application/json'},
          body: createBody,
        ).timeout(const Duration(seconds: 7));

        if (createRes.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตสูตรอาหารสำเร็จ')),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to create recipe: ${createRes.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถอัปเดตสูตรอาหารได้ กรุณาลองอีกครั้ง')),
        );
      } finally {
        setState(() => isSubmitting = false);
      }
    }
  }

  Widget _buildIngredientFields() => Column(
        children: ingredients.asMap().entries.map((entry) {
          int index = entry.key;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'ส่วนผสม'),
                  initialValue: ingredients[index]['name'],
                  onChanged: (val) => ingredients[index]['name'] = val,
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกส่วนผสม' : null,
                ),
              ),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'ปริมาณ'),
                  initialValue: ingredients[index]['quantity'],
                  onChanged: (val) => ingredients[index]['quantity'] = val,
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกปริมาณ' : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() => ingredients.removeAt(index)),
              ),
            ],
          );
        }).toList(),
      );

  Widget _buildStepFields() => Column(
        children: steps.asMap().entries.map((entry) {
          int index = entry.key;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(labelText: 'ขั้นตอน ${index + 1}'),
                  initialValue: steps[index]['instruction'],
                  onChanged: (val) => steps[index]['instruction'] = val,
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกขั้นตอน' : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() => steps.removeAt(index)),
              ),
            ],
          );
        }).toList(),
      );

  Widget _buildImagePreview() {
    final url = imageController.text;
    return url.isNotEmpty
        ? Image.network(
            url,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Text('URL รูปภาพไม่ถูกต้อง'),
          )
        : const Text('ไม่มีรูปภาพ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("แก้ไขสูตรอาหาร")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'ชื่อสูตร'),
                      validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อสูตร' : null,
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'คำอธิบาย'),
                      validator: (value) => value!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null,
                    ),
                    TextFormField(
                      controller: imageController,
                      decoration: const InputDecoration(labelText: 'URL รูปภาพ'),
                      keyboardType: TextInputType.url,
                      onChanged: (val) => setState(() {}),
                      validator: (value) => value!.isEmpty ? 'กรุณากรอก URL รูปภาพ' : null,
                    ),
                    _buildImagePreview(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ส่วนผสม', style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(onPressed: _addIngredient, icon: const Icon(Icons.add)),
                      ],
                    ),
                    _buildIngredientFields(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ขั้นตอน', style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(onPressed: _addStep, icon: const Icon(Icons.add)),
                      ],
                    ),
                    _buildStepFields(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("อัปเดต"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}