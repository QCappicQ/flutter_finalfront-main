import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:convert';
import 'recipedetailscreen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> favoriteRecipes = [];
  final String baseUrl = 'https://finalback-sepia.vercel.app';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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

  Future<void> _loadFavorites() async {
    try {
      final favoriteIds = await _getFavorites();
      List<dynamic> recipes = [];
      for (String id in favoriteIds) {
        final res = await http.get(Uri.parse('$baseUrl/recipes/$id'));
        if (res.statusCode == 200) {
          recipes.add(json.decode(res.body));
        }
      }
      setState(() {
        favoriteRecipes = recipes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดสูตรโปรด')),
      );
    }
  }

  void _navigateToDetail(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(id: id),
      ),
    );
    if (result == true) _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สูตรโปรด')),
      body: favoriteRecipes.isEmpty
          ? const Center(child: Text('ยังไม่มีสูตรโปรด', style: TextStyle(fontSize: 18)))
          : ListView.builder(
              itemCount: favoriteRecipes.length,
              itemBuilder: (context, index) {
                final recipe = favoriteRecipes[index];
                final recipeId = recipe['id'];
                if (recipeId == null) {
                  return const ListTile(title: Text('สูตรนี้ไม่มี ID'));
                }
                return Card(
                  color: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          recipe['image']?.toString() ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.white),
                        ),
                      ),
                    ),
                    title: Text(recipe['title']?.toString() ?? 'No Title'),
                    subtitle: Text(
                      recipe['description']?.toString() ?? 'No Description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _navigateToDetail(recipeId),
                  ),
                );
              },
            ),
    );
  }
}