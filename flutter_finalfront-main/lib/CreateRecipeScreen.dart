import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageController = TextEditingController();

  List<Map<String, String>> ingredients = [];
  List<Map<String, String>> steps = [];

  final String baseUrl = 'https://finalback-sepia.vercel.app';

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
    final body = jsonEncode({
      'title': titleController.text,
      'description': descriptionController.text,
      'image': imageController.text,
      'ingredients': ingredients,
      'steps': steps.asMap().entries.map((e) => {
        'step_number': e.key + 1,
        'instruction': e.value['instruction']
      }).toList(),
    });

    final res = await http.post(
      Uri.parse('$baseUrl/recipes'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 201) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildIngredientFields() => Column(
    children: ingredients.asMap().entries.map((entry) {
      int index = entry.key;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'ส่วนผสม'),
                onChanged: (val) => ingredients[index]['name'] = val,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกส่วนผสม' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'ปริมาณ'),
                onChanged: (val) => ingredients[index]['quantity'] = val,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกปริมาณ' : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => setState(() => ingredients.removeAt(index)),
            ),
          ],
        ),
      );
    }).toList(),
  );

  Widget _buildStepFields() => Column(
    children: steps.asMap().entries.map((entry) {
      int index = entry.key;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(labelText: 'ขั้นตอน ${index + 1}'),
                onChanged: (val) => steps[index]['instruction'] = val,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกขั้นตอน' : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => setState(() => steps.removeAt(index)),
            )
          ],
        ),
      );
    }).toList(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("สร้างสูตรอาหาร")),
      body: SingleChildScrollView(
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
                validator: (value) => value!.isEmpty ? 'กรุณากรอก URL รูปภาพ' : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ส่วนผสม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add, color: Colors.white),
                  )
                ],
              ),
              _buildIngredientFields(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ขั้นตอน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    onPressed: _addStep,
                    icon: const Icon(Icons.add, color: Colors.white),
                  )
                ],
              ),
              _buildStepFields(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("CREATE"),
              )
            ],
          ),
        ),
      ),
    );
  }
}