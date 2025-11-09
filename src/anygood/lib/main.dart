import 'dart:convert';

import 'package:anygood/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: BeerListPage());
  }
}

class BeerListPage extends StatefulWidget {
  const BeerListPage({super.key});

  @override
  State<BeerListPage> createState() => _BeerListPageState();
}

class _BeerListPageState extends State<BeerListPage> {
  List<dynamic> _beers = [];
  List<dynamic> _filteredBeers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _hideReviewed = false;

  @override
  void initState() {
    super.initState();
    readJson();
    _searchController.addListener(() {
      _applyFilters();
    });
  }

  Future<void> readJson() async {
    final String response = await rootBundle.loadString('assets/beers.json');
    final data = await json.decode(response);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _beers = data.map((beer) {
        beer['rating'] = prefs.getInt('${beer['name']}_rating') ?? 0;
        beer['comment'] = prefs.getString('${beer['name']}_comment') ?? '';
        return beer;
      }).toList();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<dynamic> filtered = _beers;

    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((beer) {
        final beerName = beer['name'].toLowerCase();
        final searchQuery = _searchController.text.toLowerCase();
        return beerName.contains(searchQuery);
      }).toList();
    }

    if (_hideReviewed) {
      filtered = filtered.where((beer) => beer['rating'] == 0).toList();
    }

    setState(() {
      _filteredBeers = filtered;
    });
  }

  Future<void> _showRatingDialog(Map<String, dynamic> beer) async {
    final prefs = await SharedPreferences.getInstance();
    int rating = beer['rating'] ?? 0;
    final commentController = TextEditingController(text: beer['comment'] ?? '');

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Rate ${beer['name']}'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                          ),
                          onPressed: () {
                            setState(() {
                              rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    prefs.setInt('${beer['name']}_rating', rating);
                    prefs.setString(
                        '${beer['name']}_comment', commentController.text);
                    readJson();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Any Good?')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by beer name',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                ),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Hide reviewed beers'),
            value: _hideReviewed,
            onChanged: (value) {
              setState(() {
                _hideReviewed = value;
                _applyFilters();
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredBeers.length,
              itemBuilder: (context, index) {
                final beer = _filteredBeers[index];
                return Card(
                  child: ListTile(
                    title: Text(beer['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${beer['brewery']} - ${beer['style']} - ${beer['abv']}'),
                        Text(beer['description']),
                        if (beer['rating'] > 0)
                          Row(
                            children: List.generate(
                              beer['rating'],
                              (index) => const Icon(Icons.star, size: 16),
                            ),
                          ),
                        if (beer['comment'] != null &&
                            beer['comment'].isNotEmpty)
                          Text('Comment: ${beer['comment']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.rate_review),
                      onPressed: () => _showRatingDialog(beer),
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
