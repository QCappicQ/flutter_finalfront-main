import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'recipedetailscreen.dart';
import 'createrecipescreen.dart';
import 'updaterecipescreen.dart';
import 'favoritesscreen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<dynamic> _recipes = [];
  List<dynamic> filteredRecipes = [];
  final String baseUrl = 'https://finalback-sepia.vercel.app';
  String searchQuery = '';
  Map<int, bool> favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recipes'));
      if (response.statusCode == 200) {
        setState(() {
          _recipes = json.decode(response.body);
          filteredRecipes = _recipes;
          _loadFavoriteStatus();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถโหลดสูตรได้: ${response.statusCode}')),
        );
      }
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดสูตร')),
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

  Future<void> _loadFavoriteStatus() async {
    try {
      final favorites = await _getFavorites();
      setState(() {
        favoriteStatus.clear();
        for (var recipe in _recipes) {
          final id = recipe['id'];
          if (id != null) {
            favoriteStatus[id] = favorites.contains(id.toString());
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดสถานะสูตรโปรด')),
      );
    }
  }

  Future<void> _toggleFavorite(int recipeId) async {
    try {
      List<String> favorites = await _getFavorites();
      bool currentStatus = favoriteStatus[recipeId] ?? false;
      if (currentStatus) {
        favorites.remove(recipeId.toString());
      } else {
        favorites.add(recipeId.toString());
      }
      await _setFavorites(favorites);
      setState(() {
        favoriteStatus[recipeId] = !currentStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStatus ? 'ลบออกจากสูตรโปรด' : 'เพิ่มในสูตรโปรด'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเพิ่มสูตรโปรด: $e')),
      );
    }
  }

  void _filterRecipes(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredRecipes = _recipes;
      } else {
        filteredRecipes = _recipes.where((recipe) =>
            recipe['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
            recipe['description'].toString().toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  Future<void> _deleteRecipe(int id, int index) async {
    try {
      final url = Uri.parse('$baseUrl/recipes/$id');
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() {
          _recipes.removeAt(index);
          filteredRecipes = _recipes;
          favoriteStatus.remove(id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบสูตรเรียบร้อย')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถลบสูตรได้')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการลบสูตร')),
      );
    }
  }

  void _navigateToUpdate(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateRecipeScreen(id: id)),
    );
    if (result == true) _fetchRecipes();
  }

  void _navigateToDetail(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecipeDetailScreen(id: id)),
    );
    if (result == true) _fetchRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Recipes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            tooltip: 'ดูสูตรโปรด',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ).then((_) => _fetchRecipes());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterRecipes,
              decoration: const InputDecoration(
                labelText: 'ค้นหาสูตร',
                prefixIcon: Icon(Icons.search, color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateRecipeScreen()),
              ).then((_) => _fetchRecipes());
            },
            child: const Text('CREATE RECIPE'),
          ),
          Expanded(
            child: _recipes.isEmpty
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)))
                : ListView.builder(
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  favoriteStatus[recipeId] ?? false
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: favoriteStatus[recipeId] ?? false ? Colors.red : Colors.white,
                                ),
                                onPressed: () => _toggleFavorite(recipeId),
                              ),
                              ElevatedButton(
                                onPressed: () => _deleteRecipe(recipeId, index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("DEL"),
                              ),
                              const SizedBox(width: 5),
                              ElevatedButton(
                                onPressed: () => _navigateToUpdate(recipeId),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("EDIT"),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}